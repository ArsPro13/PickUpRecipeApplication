// Оценка SCA: число от 70 до 100 и заливка, показывающая, насколько это много.
//
// Заливка здесь не украшение: «86» ничего не говорит человеку, который держит
// пачку впервые, а полоса, дошедшая до двух третей, говорит. Числа шкалы
// приходят снаружи — у SCA осмысленный диапазон начинается с 70.
//
// Число крутится барабаном, а не печатается: тот же барабан, что у дозы и
// воды в рецепте. Тридцать возможных значений — ровно тот случай, когда
// выбрать быстрее, чем набрать, и набрать «8» вместо «86» на нём нельзя.

import 'package:flutter/material.dart';

import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/general_widgets/app_icon.dart';
import 'package:pick_up_recipe/src/general_widgets/number_wheel_sheet.dart';
import 'package:pick_up_recipe/src/themes/app_icons.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';

/// Верх шкалы SCA.
const int _scaMax = 100;

class NumberInput extends StatefulWidget {
  const NumberInput({
    super.key,
    required this.controller,
    required this.labelText,
    required this.minimalPercentageNumber,
    this.hintText,
    this.onEditingFinished,
  });

  final TextEditingController controller;
  final String labelText;

  /// Пример в пустом поле. С него же открывается барабан, пока числа нет.
  final String? hintText;
  final int minimalPercentageNumber;
  final VoidCallback? onEditingFinished;

  @override
  State<NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<NumberInput> {
  double _fill = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateFill);
    _fill = _fillFor(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateFill);
    super.dispose();
  }

  void _updateFill() {
    if (!mounted) return;
    final fill = _fillFor(widget.controller.text);
    if (fill == _fill) return;
    setState(() => _fill = fill);
  }

  double _fillFor(String value) {
    final number = int.tryParse(value.trim());
    if (number == null) return 0;
    if (number >= _scaMax) return 1;
    if (number <= widget.minimalPercentageNumber) return 0;

    return (number - widget.minimalPercentageNumber) /
        (_scaMax - widget.minimalPercentageNumber);
  }

  void _set(String text) {
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onEditingFinished?.call();
  }

  Future<void> _pick() async {
    // Клавиатура соседнего поля ушла бы под шторку и закрывала барабан.
    FocusScope.of(context).unfocus();

    final current = int.tryParse(widget.controller.text.trim()) ??
        int.tryParse(widget.hintText ?? '') ??
        widget.minimalPercentageNumber;
    final picked = await showNumberSheet(
      context,
      title: widget.labelText,
      value: current.toDouble(),
      min: widget.minimalPercentageNumber,
      max: _scaMax,
      // «Готово» без поворота у пустого поля — согласие с числом, на котором
      // барабан открылся: человек его видел и нажал «Готово».
      acceptShown: true,
    );
    if (picked == null || !mounted) return;
    _set('${picked.round()}');
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.labelText, style: context.texts.labelSmall),
        const SizedBox(height: AppSpacing.s1),
        Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: AppRadius.medium,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: _fill),
                    duration: AppDuration.base,
                    curve: AppCurves.out,
                    builder: (context, value, _) => FractionallySizedBox(
                      widthFactor: value == 0 ? 0.0001 : value,
                      child: ColoredBox(
                        color: context.colors.primary.withValues(alpha: 0.25),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            TextFormField(
              controller: widget.controller,
              // Поле только показывает число: крутят его барабаном.
              readOnly: true,
              showCursor: false,
              enableInteractiveSelection: false,
              onTap: _pick,
              style: context.texts.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hintText,
                // Заливка лежит под полем, поэтому само поле прозрачное:
                // иначе она была бы не видна.
                filled: false,
                // Оценки на пачке может и не быть — крестик возвращает поле
                // к пустому, не открывая барабан.
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller,
                  builder: (context, value, _) => value.text.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.s3),
                          child: AppIcon(
                            AppIcons.uiChevronDown,
                            size: AppSizes.icon20,
                            color: context.colors.secondary,
                          ),
                        )
                      : IconButton(
                          onPressed: () => _set(''),
                          tooltip: texts.clear,
                          icon: AppIcon(
                            AppIcons.uiClose,
                            size: AppSizes.icon20,
                            color: context.colors.secondary,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
