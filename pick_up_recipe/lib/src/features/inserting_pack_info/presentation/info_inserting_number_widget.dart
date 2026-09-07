// Оценка SCA: число от 70 до 100 и заливка, показывающая, насколько это много.
//
// Заливка здесь не украшение: «86» ничего не говорит человеку, который держит
// пачку впервые, а полоса, дошедшая до двух третей, говорит. Числа шкалы
// приходят снаружи — у SCA осмысленный диапазон начинается с 70.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';

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
  final String? hintText;
  final int minimalPercentageNumber;
  final VoidCallback? onEditingFinished;

  @override
  State<NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<NumberInput> {
  late final FocusNode _focusNode;
  double _fill = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
    widget.controller.addListener(_updateFill);
    _fill = _fillFor(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateFill);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted || _focusNode.hasFocus) return;
    widget.onEditingFinished?.call();
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
    if (number >= 100) return 1;
    if (number <= widget.minimalPercentageNumber) return 0;

    return (number - widget.minimalPercentageNumber) /
        (100 - widget.minimalPercentageNumber);
  }

  @override
  Widget build(BuildContext context) {
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
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onFieldSubmitted: (_) => widget.onEditingFinished?.call(),
              style: context.texts.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hintText,
                // Заливка лежит под полем, поэтому само поле прозрачное:
                // иначе она была бы не видна.
                filled: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
