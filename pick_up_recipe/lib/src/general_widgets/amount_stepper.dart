// Счётчик с плюсом и минусом.
//
// Плоское поле открывало системный диалог с клавиатурой: чтобы поднять воду
// на шаге со ста граммов до ста пяти, человек тыкал в число, ждал клавиатуру,
// стирал три цифры, набирал три другие и жал «Готово». Кнопками это два
// нажатия, и рецепт при этом остаётся на экране.
//
// Крупный сдвиг кнопками не делается: набрать 250 с нуля — двести пятьдесят
// нажатий, и зажатие спасает не всегда. Тап по самому числу открывает барабан
// — тот же, что у дозы и воды рецепта: клавиатуры в конструкторе больше нет.
//
// Счётчик ставится не у каждого числа подряд, а там, где значение двигают
// маленькими шагами. Четыре пары стрелок в столбик превращают экран
// параметров в калькулятор — по этой же причине их нет у дозы и температуры.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'app_icon.dart';
import 'number_wheel_sheet.dart';

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

/// Счётчик целого значения: минус, число, плюс.
class AmountStepper extends StatefulWidget {
  const AmountStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = _defaultMax,
    this.step = 1,
    this.suffix = '',
    this.title = '',
  });

  final int value;
  final ValueChanged<int> onChanged;

  final int min;
  final int max;

  /// На сколько меняет одно нажатие.
  final int step;

  /// Единица рядом с числом: «г», «мл». Пусто — только число.
  final String suffix;

  /// Заголовок шторки с барабаном, который открывается тапом по числу.
  final String title;

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

  Timer? _repeat;
  Duration _held = Duration.zero;

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

  /// Барабан вместо поля: на нём не набрать ни пустоты, ни мусора, а закрытая
  /// без поворота шторка оставляет значение прежним.
  Future<void> _pick() async {
    final picked = await showNumberSheet(
      context,
      title: widget.title,
      value: _value.toDouble(),
      min: widget.min,
      max: widget.max,
      unit: widget.suffix,
    );
    if (picked == null || !mounted) return;
    _set(picked.round());
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
          width: AppSpacing.s18,
          child: _number(context),
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
      onTap: _pick,
      borderRadius: AppRadius.small,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.tapTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppRadius.small,
          border: Border.all(color: context.palette.border),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.suffix.isEmpty ? '$_value' : '$_value ${widget.suffix}',
          style: context.texts.bodyMedium,
          maxLines: 1,
        ),
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
                color:
                    enabled ? context.colors.onSurface : context.palette.border,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
