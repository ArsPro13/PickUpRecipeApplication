// Лист выбора типа шага.
//
// Показываются только те типы, что метод поддерживает: у V60 их восемь из
// семнадцати. Остальные девять не показываются вовсе — ни приглушёнными, ни
// под «показать все». Довод «список один и тот же у всех приборов» не выдержал
// чисел: у медианного метода живых семь клеток из семнадцати, то есть больше
// половины таблицы — мёртвые клетки, которые просматривают заново каждый раз.
//
// Постоянство при этом не теряется: пять типов есть у всех двадцати методов
// (пролив, пауза, подать, ремарка, своё), ещё три — больше чем у трети.
// Верх таблицы у любого прибора одинаковый, меняется хвост.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/recipes/application/step_types_state.dart';
import '../features/recipes/domain/models/step_type_model.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'app_icon.dart';
import 'app_kit.dart';

/// Что выбрали в листе.
sealed class StepTypePick {
  const StepTypePick();
}

/// Встроенный тип из справочника.
class BuiltInStepPick extends StepTypePick {
  const BuiltInStepPick(this.type);

  final StepType type;
}

/// «Своё» — не тип, а выход за справочник: открывает форму своего шага.
class CustomStepPick extends StepTypePick {
  const CustomStepPick();
}

/// Открывает лист и возвращает выбранное. null — закрыли, ничего не выбрав.
Future<StepTypePick?> showStepTypeSheet(
  BuildContext context, {
  required List<String> allowedStepTypes,
  String? currentSlug,
}) {
  return showModalBottomSheet<StepTypePick>(
    context: context,
    // Высота по содержимому: восемь типов в листе на весь экран выглядели бы
    // издевательством — пустота внизу читается как «тут ещё что-то есть».
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _StepTypeSheet(
      allowedStepTypes: allowedStepTypes,
      currentSlug: currentSlug,
    ),
  );
}

class _StepTypeSheet extends ConsumerWidget {
  const _StepTypeSheet({required this.allowedStepTypes, this.currentSlug});

  final List<String> allowedStepTypes;
  final String? currentSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = ref.watch(stepTypesProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
        boxShadow: context.shadows.level3,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s3,
        AppSpacing.s5,
        AppSpacing.s6,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _GrabHandle(),
            Flexible(
              child: reference.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => AppState(
                  icon: AppIcons.stateError,
                  title: 'Справочник не пришёл',
                  description: 'Без него неизвестно, какие шаги умеет этот прибор.',
                  isError: true,
                  primaryAction: AppButton(
                    label: 'Повторить',
                    onPressed: () => ref.invalidate(stepTypesProvider),
                  ),
                ),
                data: (data) => _Types(
                  groups: data.allowedFor(allowedStepTypes),
                  currentSlug: currentSlug,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Container(
        height: AppSpacing.s1,
        width: AppSpacing.s12,
        decoration: BoxDecoration(
          color: context.palette.border,
          borderRadius: AppRadius.rounded,
        ),
      ),
    );
  }
}

class _Types extends StatelessWidget {
  const _Types({required this.groups, this.currentSlug});

  final List<GroupedStepTypes> groups;
  final String? currentSlug;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        for (final group in groups) ...[
          _GroupHeader(group.name),
          _Grid(
            children: [
              for (final type in group.types)
                _TypeCell(
                  icon: AppIcons.step(type.iconKey),
                  label: type.label,
                  selected: type.slug == currentSlug,
                  onTap: () => Navigator.of(context).pop(BuiltInStepPick(type)),
                ),
            ],
          ),
        ],
        // «Своё» стоит последним и отдельной группой: это не ещё один тип
        // рядом с проливом, а выход за справочник.
        const _GroupHeader('Ваши типы'),
        _Grid(
          children: [
            _TypeCell(
              icon: AppIcons.stepCustom,
              label: 'своё',
              dashed: true,
              onTap: () => Navigator.of(context).pop(const CustomStepPick()),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: Row(
        children: [
          Text(name, style: context.texts.labelSmall),
          const SizedBox(width: AppSpacing.s2),
          Expanded(child: Divider(height: AppStroke.thin, color: context.palette.border)),
        ],
      ),
    );
  }
}

/// Сетка четыре в ряд. Четыре, а не три: при трёх колонках восемь типов V60
/// разъезжаются на три ряда, и хвост из двух клеток выглядит обрывом.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.s2,
        crossAxisSpacing: AppSpacing.s2,
        childAspectRatio: 0.9,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      ),
    );
  }
}

class _TypeCell extends StatelessWidget {
  const _TypeCell({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.dashed = false,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  /// Пунктир — у «своего»: оно открывает форму, а не выбирает существующее.
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    final highlighted = selected || dashed;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIcon(
          icon,
          size: AppSizes.icon24,
          color: highlighted ? accent : context.colors.onSurface,
        ),
        const SizedBox(height: AppSpacing.s1),
        Text(
          label,
          style: context.texts.labelSmall?.copyWith(
            color: highlighted ? accent : context.colors.onSurface,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    if (dashed) {
      return DashedBorderBox(
        color: accent,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s1, vertical: AppSpacing.s3),
        child: content,
      );
    }

    return Material(
      color: context.colors.surface,
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s1,
            vertical: AppSpacing.s3,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            border: Border.all(color: selected ? accent : context.palette.border),
          ),
          child: content,
        ),
      ),
    );
  }
}
