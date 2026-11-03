// Шторка «Сколько воды» — вариант 1 из витрины
// design/mockups/variants/water-scale.html, его выбрал владелец.
//
// Нажали «250 мл» в строке параметров экрана заваривания — открылась шторка
// с барабаном, таким же, как у времени шага и даты обжарки. Деления барабана
// задаёт прибор: у воронки — от 120 до 1000 мл с шагом 5, у эспрессо —
// 36, 72, 108 г (ещё шот), у дрип-пакетов — по пакету. Под барабаном сразу
// видно, что поменяется: кофе, помол или заходы, время, сколько окажется в
// чашке. «Готово» пересчитывает экран, «Как в рецепте» возвращает барабан к
// воде рецепта.
//
// Считает не шторка, а recipe_scaler.dart: шторка спрашивает его на каждом
// щелчке барабана. Это дёшево — пара сотен шагов арифметики.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../features/grinders/domain/grind_translation.dart';
import '../features/recipes/domain/scaling/recipe_scaler.dart';
import '../features/recipes/domain/scaling/scaling_profile.dart';
import '../pages/brew_page.dart' show formatAmount, formatDuration;
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'app_icon.dart';
import 'app_wheel.dart';

/// Открывает шторку и возвращает выбранную воду.
///
/// [values] — деления барабана (scaleWheelValues). [baseWater] — вода
/// рецепта, к ней ведёт «Как в рецепте». [current] — с чего барабан
/// открывается: вода рецепта или прошлый выбор. [unit] — «мл», у эспрессо
/// «г» (вес в чашке). [preview] — пересчёт на любое деление, для сводки.
/// null — шторку закрыли.
Future<int?> showWaterScaleSheet(
  BuildContext context, {
  required List<int> values,
  required int baseWater,
  required int current,
  required String unit,
  required ScaledRecipe Function(int water) preview,
}) {
  return showWheelSheet<int>(
    context,
    builder: (context) => _WaterScaleSheet(
      values: values,
      baseWater: baseWater,
      current: current,
      unit: unit,
      preview: preview,
    ),
  );
}

class _WaterScaleSheet extends StatefulWidget {
  const _WaterScaleSheet({
    required this.values,
    required this.baseWater,
    required this.current,
    required this.unit,
    required this.preview,
  });

  final List<int> values;
  final int baseWater;
  final int current;
  final String unit;
  final ScaledRecipe Function(int water) preview;

  @override
  State<_WaterScaleSheet> createState() => _WaterScaleSheetState();
}

class _WaterScaleSheetState extends State<_WaterScaleSheet> {
  late final List<int> _values = <int>{
    ...widget.values,
    widget.baseWater,
    widget.current,
  }.toList()
    ..sort();

  late int _shown = widget.current;

  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: _values.indexOf(_shown));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Барабан едет к воде рецепта тем же движением, что и палец: видно,
  /// откуда и куда он вернулся.
  void _backToRecipe() {
    _controller.animateToItem(
      _values.indexOf(widget.baseWater),
      duration: AppDuration.base,
      curve: AppCurves.out,
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return WheelSheetBody(
      title: texts.brewWaterSheetTitle,
      caption:
          texts.brewWaterSheetCaption('${widget.baseWater} ${widget.unit}'),
      wheels: AppWheelRow(
        marks: [WheelMark.after(widget.unit, 2)],
        children: [
          Expanded(
            child: AppWheel(
              controller: _controller,
              itemCount: _values.length,
              initialItem: _values.indexOf(widget.current),
              alignment: Alignment.centerRight,
              labelBox: 0.5,
              labelOf: (index) => '${_values[index]}',
              onChanged: (index) => setState(() => _shown = _values[index]),
            ),
          ),
        ],
      ),
      footer: WaterScaleSummary(
        scaled: widget.preview(_shown),
        unit: widget.unit,
      ),
      secondaryLabel: texts.brewWaterAsInRecipe,
      onSecondary: _backToRecipe,
      onDone: () => Navigator.of(context).pop(_shown),
    );
  }
}

/// Что поменяется: кофе, помол, время, в чашке.
///
/// Высота у сводки одна и та же при любой воде — две строки, по два числа в
/// каждой. Шторка растёт снизу вверх, и сводка, менявшая число строк, тянула
/// за собой барабан: он прыгал под пальцем, пока его крутят. Предупреждения
/// поэтому здесь не стоят — их число меняется с объёмом; они встают над
/// рамкой экрана заваривания после «Готово», как в выбранном варианте
/// витрины.
///
/// Отдельным виджетом: его проверяют тестом без шторки.
class WaterScaleSummary extends StatelessWidget {
  const WaterScaleSummary({super.key, required this.scaled, this.unit = ''});

  final ScaledRecipe scaled;

  /// «мл» или «г» — как подписан барабан. Пусто — «мл».
  final String unit;

  /// Высота строки сводки: кегль bodyMedium с запасом на межстрочное.
  static const double _line = 24;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final muted = context.texts.bodySmall;
    final strong = context.texts.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    if (scaled.isOriginal) {
      return SizedBox(
        height: _line * 2 + AppSpacing.s1,
        width: double.infinity,
        child: Center(
          child: Text(texts.brewWaterSameAsRecipe, style: muted),
        ),
      );
    }

    // Одна ячейка: подпись тихо, число жирно. FittedBox — на узком экране
    // лучше уменьшить кегль, чем перенести строку и сдвинуть барабан.
    Widget cell(String label, String value, Alignment alignment,
            [String? note]) =>
        SizedBox(
          height: _line,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: Text.rich(
              TextSpan(
                style: muted,
                children: [
                  if (label.isNotEmpty) TextSpan(text: '$label '),
                  TextSpan(text: value, style: strong),
                  if (note != null) TextSpan(text: ' $note'),
                ],
              ),
              maxLines: 1,
            ),
          ),
        );

    Widget row(Widget left, Widget right) => Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: AppSpacing.s4),
            Expanded(child: right),
          ],
        );

    // У заходов и порций вместо помола — сколько их: помол у них прежний,
    // а «2 шота по 18 г» и есть то, что меняется.
    final (secondLabel, secondValue, secondNote) = scaled.runs > 1
        ? (
            '',
            scaleUnitsText(texts, scaled.unit, scaled.runs),
            texts.brewScalePerUnit(formatAmount(scaled.dosePerRun)),
          )
        : (texts.brewScaleGrind, _grind(texts).$1, _grind(texts).$2);
    final cupUnit = unit.isEmpty ? null : unit;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(
          cell(
            texts.brewScaleCoffee,
            texts.unitGrams(formatAmount(scaled.dose)),
            Alignment.centerRight,
          ),
          cell(secondLabel, secondValue, Alignment.centerLeft, secondNote),
        ),
        const SizedBox(height: AppSpacing.s1),
        row(
          cell(
            texts.brewScaleTime,
            formatDuration(Duration(seconds: scaled.totalSeconds)),
            Alignment.centerRight,
          ),
          cell(
            texts.brewScaleInCup,
            cupUnit == null
                ? texts.unitMillilitres('${scaled.cupMl}')
                : '${scaled.cupMl} $cupUnit',
            Alignment.centerLeft,
          ),
        ),
      ],
    );
  }

  /// Помол: клики кофемолки человека и на сколько крупнее, а без
  /// кофемолки — только на сколько.
  (String, String?) _grind(AppLocalizations texts) {
    final percent = ((scaled.grindRatio - 1) * 100).round();

    if (scaled.grindStep case final step?) {
      // Деления с сервера приходят как «27.0» — на экране они «27».
      final clicks = grindClicksLabel(grinderDivisionLabel(step), texts);
      if (percent == 0) return (clicks, null);
      final signed = percent > 0 ? '+$percent' : '−${-percent}';
      return (clicks, '(${texts.brewScalePercent(signed)})');
    }

    if (percent == 0) return (texts.brewScaleGrindSame, null);

    return (
      percent > 0
          ? texts.brewScaleGrindCoarser('$percent')
          : texts.brewScaleGrindFiner('${-percent}'),
      null,
    );
  }
}

/// Предупреждения пересчёта — строками со значком, тихо, без красных плашек.
///
/// Стоят над рамкой экрана заваривания, под плашкой «Пересчитано на …»:
/// человек видит их перед тем, как молоть, и может вернуть рецепт.
class ScaleWarningList extends StatelessWidget {
  const ScaleWarningList({
    super.key,
    required this.warnings,
    this.grinderName = '',
  });

  final List<ScaleWarning> warnings;
  final String grinderName;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final warning in warnings)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: AppIcon(
                    AppIcons.uiWarning,
                    size: AppSizes.icon16,
                    color: context.metrics.temperature,
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Text(
                    scaleWarningText(texts, warning, grinderName: grinderName),
                    style: context.texts.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Текст предупреждения на языке экрана.
String scaleWarningText(
  AppLocalizations texts,
  ScaleWarning warning, {
  String grinderName = '',
}) {
  final click = grinderDivisionLabel(warning.click);
  // Края шкалы бывают только у выбранной кофемолки, и имя у неё есть;
  // «помол:» — на случай, если имя не доехало.
  final grinder = grinderName.isEmpty ? texts.brewScaleGrind : grinderName;

  return switch (warning.kind) {
    ScaleWarningKind.deepBed => texts.brewScaleWarnDeepBed('${warning.grams}'),
    ScaleWarningKind.tooDeep => texts.brewScaleWarnTooDeep(
        '${warning.grams}', texts.unitMillilitres('${warning.halfWater}')),
    ScaleWarningKind.split => [
        warning.size.isEmpty
            ? texts.brewScaleWarnSplitAny(warning.parts)
            : texts.brewScaleWarnSplit(warning.size, warning.parts),
        if (warning.biggerSize.isNotEmpty)
          texts.brewScaleWarnSplitBigger(warning.biggerSize),
      ].join(' '),
    ScaleWarningKind.grinderEdgeCoarse => warning.tempDrop > 0
        ? texts.brewScaleWarnEdgeTemp(grinder, click, '${warning.tempDrop}')
        : texts.brewScaleWarnEdgePauses(grinder, click),
    ScaleWarningKind.grinderEdgeFine =>
      texts.brewScaleWarnEdgePauses(grinder, click),
    ScaleWarningKind.tooThin => texts.brewScaleWarnTooThin('${warning.grams}'),
    ScaleWarningKind.overCapacity => texts.brewScaleWarnOverCapacity,
    ScaleWarningKind.bypass =>
      texts.brewScaleWarnBypass('${warning.chamber}', '${warning.water}'),
    ScaleWarningKind.runs =>
      texts.brewScaleWarnRuns('${warning.chamber}', warning.parts),
    ScaleWarningKind.refill => texts.brewScaleWarnRefill('${warning.chamber}'),
  };
}

/// «2 шота», «3 пакета», «2 захода» — сколько порций и как они зовутся.
String scaleUnitsText(AppLocalizations texts, ScalingUnit unit, int count) =>
    switch (unit) {
      ScalingUnit.run => texts.brewScaleUnitRun(count),
      ScalingUnit.shot => texts.brewScaleUnitShot(count),
      ScalingUnit.capsule => texts.brewScaleUnitCapsule(count),
      ScalingUnit.bag => texts.brewScaleUnitBag(count),
      ScalingUnit.bowl => texts.brewScaleUnitBowl(count),
      ScalingUnit.cup => texts.brewScaleUnitCup(count),
    };
