// Выбор того, чем заканчивается шаг.
//
// Раньше это был сегментированный переключатель на три ячейки. Он не работал
// сразу в четырёх местах:
//
//   * выбранный сегмент ничем не заливался — его выдавала только галочка,
//     и она же сдвигала надпись вправо, отчего текст «плясал» при каждом
//     переключении;
//   * «по признаку» в ячейку шириной в треть экрана не помещалось и
//     переносилось с разрывом слова: «по / признак / у»;
//   * контрол брал зелёный по умолчанию M3, а зелёный в этом приложении
//     означает «шаг завершён» и на форме заготовки не к месту;
//   * три коротких подписи без пояснений читаются как синонимы — по ним
//     не понять, чем «по кнопке» отличается от «по признаку».
//
// Карточки-радио вместо сегментов лечат всё разом: каждой достаётся вся
// ширина, поэтому переносить нечего, под названием помещается строка
// пояснения, а метка стоит в колонке постоянной ширины — текст не двигается.

import 'package:flutter/material.dart';

import '../features/recipes/domain/models/user_step_type_model.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

/// Насколько выбранная карточка темнее остальных. Заливка — главный признак
/// выбора: галочка сбоку читается хуже и на светлой теме теряется вовсе.
const double _selectedTint = 0.16;

/// Чем варианты отличаются друг от друга.
///
/// `label` перечисления говорит, ЧТО выбрано, но не говорит, что из этого
/// следует. Пояснение отвечает на один вопрос: кто кого ждёт.
extension StepEndsWithHint on StepEndsWith {
  String get hint => switch (this) {
        StepEndsWith.timer => 'идёт по таймеру и кончается сам',
        StepEndsWith.user => 'заваривание ждёт, пока вы нажмёте «дальше»',
        StepEndsWith.none => 'тоже ждёт вас, но вы ждёте признака: стекло, осело',
      };
}

/// Список карточек «чем шаг заканчивается»: по одной на вариант.
class StepEndingChoice extends StatelessWidget {
  const StepEndingChoice({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final StepEndsWith value;
  final ValueChanged<StepEndsWith> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in StepEndsWith.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
            child: _EndingCard(
              option: option,
              selected: option == value,
              onTap: () => onChanged(option),
            ),
          ),
      ],
    );
  }
}

class _EndingCard extends StatelessWidget {
  const _EndingCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final StepEndsWith option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    final fill = selected
        ? Color.alphaBlend(
            accent.withValues(alpha: _selectedTint),
            context.colors.secondaryContainer,
          )
        : context.colors.secondaryContainer;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      child: Material(
        color: fill,
        borderRadius: AppRadius.medium,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.medium,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.tapTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s3,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.medium,
              // Толщина обводки одна на оба состояния: рамка рисуется внутрь,
              // и утолщение на выбранном сдвинуло бы содержимое на точку —
              // ровно та пляска текста, из-за которой контрол и переделан.
              border: Border.all(
                color: selected ? accent : context.palette.border,
                width: AppStroke.thin,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Mark(selected: selected),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: context.texts.bodyMedium?.copyWith(
                          color: context.colors.onSurface,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      Text(option.hint, style: context.texts.labelSmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Кружок выбора. Размер один на оба состояния — колонка под метку не
/// меняет ширину, и надпись справа стоит на месте.
class _Mark extends StatelessWidget {
  const _Mark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;

    return Container(
      width: AppSizes.icon20,
      height: AppSizes.icon20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? accent : context.palette.border,
          width: AppStroke.thick,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: AppSpacing.s2,
                height: AppSpacing.s2,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
            )
          : null,
    );
  }
}
