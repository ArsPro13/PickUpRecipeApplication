// Счётчик с плюсом и минусом.
//
// Плоское поле открывало системный диалог с клавиатурой: чтобы поднять воду
// на шаге со ста граммов до ста пяти, человек тыкал в число, ждал клавиатуру,
// стирал три цифры, набирал три другие и жал «Готово». Кнопками это два
// нажатия, и рецепт при этом остаётся на экране.
//
// Ввод руками никуда не делся: набрать 250 с нуля — двести пятьдесят нажатий,
// и зажатие спасает не всегда. Тап по самому числу открывает поле.
//
// Счётчик стоит у каждого числа, которое двигают: и у воды на шаге, и у всех
// четырёх параметров рецепта. Раньше у дозы, температуры и помола его не
// было — считалось, что четыре пары стрелок в столбик превращают экран в
// калькулятор. Владелец попросил обратное, и по делу: без стрелок каждое
// число правилось через окно с клавиатурой, а поправить дозу на грамм — это
// одно нажатие, а не пять.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/numbers.dart';
import '../../l10n/app_localizations.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'app_icon.dart';

/// Во сколько раз крупнее шаг, когда кнопку держат [held].
///
/// Пороги отсчитаны от [AppDuration.ambient]: пока держат меньше вдоха,
/// человек поправляет значение на грамм-другой; после — он явно едет к
/// другому числу, и по грамму за тик он туда не доедет.
int holdFactor(Duration held) {
  if (held < AppDuration.ambient) return 1;
  if (held < AppDuration.ambient * 2) return _nudgeFactor;
  return _rushFactor;
}

const int _nudgeFactor = 5;
const int _rushFactor = 10;

/// Наибольшее значение по умолчанию. Больше десяти литров в шаге не бывает
/// даже у колд брю, а без потолка зажатая кнопка уезжает в бесконечность.
const int _defaultMax = 9999;

/// Ширина коробки с числом.
///
/// Под число без единицы: «250», «17,1», «93». Единица стоит подписью под
/// названием параметра, и вот почему. Пока она жила в коробке, на неё уходило
/// двадцать шесть точек, коробка была в семьдесят две, и на слово слева
/// оставалось девяносто две — а «Температура» занимает сто одну и ломалась
/// пополам. На самом тесном телефоне, 360 точек в ширину, весь ряд — двести
/// восемьдесят: два пальцевых квадрата по сорок восемь не ужать, значит
/// ужимается всё остальное.
const double _valueWidth = 44;

/// Счётчик целого значения: минус, число, плюс.
class AmountStepper extends StatefulWidget {
  const AmountStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = _defaultMax,
    this.step = 1,
    this.scale = 1,
  });

  /// Значение в мелких единицах — тех, в которых заданы [min], [max] и [step].
  final int value;
  final ValueChanged<int> onChanged;

  final int min;
  final int max;

  /// На сколько меняет одно нажатие. В мелких единицах: при [scale] 10 шаг в
  /// один грамм — это `step: 10`.
  final int step;

  /// Во сколько раз хранимое значение мельче показанного.
  ///
  /// 1 — счётчик целых: вода на шаге и есть целые миллилитры. 10 — значение
  /// живёт десятыми долями, а на экране стоит «17,1 г». Доза приходит именно
  /// такой: её двигает пересчёт под вкус, и округлить её до целых граммов
  /// значило бы молча испортить рецепт при первом же нажатии на стрелку.
  final int scale;

  @override
  State<AmountStepper> createState() => _AmountStepperState();
}

class _AmountStepperState extends State<AmountStepper> {
  /// Своя копия значения, а не `widget.value`.
  ///
  /// Автоповтор успевает тикнуть несколько раз между перерисовками, и, читая
  /// значение из родителя, вторая прибавка считалась бы от того же числа,
  /// что и первая: кнопку держат, а счётчик стоит на месте.
  late int _value = widget.value;

  final TextEditingController _typed = TextEditingController();
  final FocusNode _focus = FocusNode();

  Timer? _repeat;
  Duration _held = Duration.zero;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    // Уход из поля равносилен «Готово»: человек тапнул мимо, потому что уже
    // набрал нужное, а не потому, что передумал.
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(covariant AmountStepper old) {
    super.didUpdateWidget(old);
    // Родитель поменял значение сам — например, отменил поправку рецепта.
    if (widget.value != old.value && widget.value != _value) {
      _value = widget.value;
    }
  }

  @override
  void dispose() {
    _repeat?.cancel();
    _typed.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _set(int next) {
    final clamped = next.clamp(widget.min, widget.max);
    if (clamped == _value) return;
    setState(() => _value = clamped);
    widget.onChanged(clamped);
  }

  void _press(int direction) {
    _set(_value + direction * widget.step);

    _held = Duration.zero;
    _repeat?.cancel();
    _repeat = Timer.periodic(AppDuration.instant, (_) {
      _held += AppDuration.instant;
      // Пауза до первого автоповтора: без неё обычный тап давал бы сразу
      // два шага, и попасть в ровное число стало бы невозможно.
      if (_held < AppDuration.slow) return;
      _set(_value + direction * widget.step * holdFactor(_held));
    });
  }

  void _release() {
    _repeat?.cancel();
    _repeat = null;
  }

  /// Значение так, как его читает человек.
  String get _shown =>
      widget.scale == 1 ? '$_value' : formatDecimal(_value / widget.scale);

  void _startTyping() {
    setState(() {
      _editing = true;
      _typed.text = _shown;
      _typed.selection = TextSelection(baseOffset: 0, extentOffset: _typed.text.length);
    });
  }

  void _commit() {
    if (!_editing) return;
    final typed = parseNumber(_typed.text);
    setState(() => _editing = false);
    // Пустое и мусор оставляют прежнее значение: очистить поле легко
    // случайно, и превращать это в ноль граммов — потеря рецепта.
    if (typed != null) _set((typed * widget.scale).round());
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: AppIcons.uiMinus,
          hint: texts.builderDecrease,
          enabled: _value > widget.min,
          onPress: () => _press(-1),
          onRelease: _release,
        ),
        const SizedBox(width: AppSpacing.s1),
        SizedBox(
          width: _valueWidth,
          child: _editing ? _field(context) : _number(context),
        ),
        const SizedBox(width: AppSpacing.s1),
        _StepperButton(
          icon: AppIcons.uiPlus,
          hint: texts.builderIncrease,
          enabled: _value < widget.max,
          onPress: () => _press(1),
          onRelease: _release,
        ),
      ],
    );
  }

  Widget _number(BuildContext context) {
    return InkWell(
      onTap: _startTyping,
      borderRadius: AppRadius.small,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.tapTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppRadius.small,
          border: Border.all(color: context.palette.border),
        ),
        alignment: Alignment.center,
        child: Text(_shown, style: context.texts.bodyMedium, maxLines: 1),
      ),
    );
  }

  Widget _field(BuildContext context) {
    return SizedBox(
      height: AppSizes.tapTarget,
      child: TextField(
        controller: _typed,
        focusNode: _focus,
        autofocus: true,
        textAlign: TextAlign.center,
        style: context.texts.bodyMedium,
        keyboardType: TextInputType.numberWithOptions(decimal: widget.scale > 1),
        // У целого счётчика — только цифры. У дробного к ним добавлен
        // разделитель: клавиатура на разных прошивках даёт то запятую, то
        // точку, и отказать одной из них значит отказать половине телефонов.
        inputFormatters: [
          widget.scale == 1
              ? FilteringTextInputFormatter.digitsOnly
              : FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.s1),
        ),
        onSubmitted: (_) => _commit(),
      ),
    );
  }
}

/// Кнопка счётчика. Ровно в наименьшую цель для пальца: меньше — промахи,
/// а промах здесь стоит не пропущенного нажатия, а лишнего грамма.
class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.hint,
    required this.enabled,
    required this.onPress,
    required this.onRelease,
  });

  final String icon;
  final String hint;
  final bool enabled;
  final VoidCallback onPress;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: hint,
      child: Material(
        color: context.colors.surface,
        borderRadius: AppRadius.small,
        child: InkWell(
          borderRadius: AppRadius.small,
          // Прибавка на нажатии, а не на отпускании: зажатие должно начать
          // считать сразу, иначе первое из десяти нажатий теряется.
          onTapDown: enabled ? (_) => onPress() : null,
          onTapUp: enabled ? (_) => onRelease() : null,
          onTapCancel: enabled ? onRelease : null,
          child: Container(
            height: AppSizes.tapTarget,
            width: AppSizes.tapTarget,
            decoration: BoxDecoration(
              borderRadius: AppRadius.small,
              border: Border.all(color: context.palette.border),
            ),
            child: Center(
              child: AppIcon(
                icon,
                size: AppSizes.icon20,
                color: enabled ? context.colors.onSurface : context.palette.border,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
