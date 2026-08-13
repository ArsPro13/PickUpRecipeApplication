// Лист выбора типа шага.
//
// Показываются только те типы, что метод поддерживает: у V60 их восемь из
// семнадцати. Остальные девять не показываются вовсе — ни приглушёнными, ни
// под «показать все». Довод «список один и тот же у всех приборов» не выдержал
// чисел: у медианного метода живых семь клеток из семнадцати, то есть больше
// половины таблицы — мёртвые клетки, которые просматривают заново каждый раз.
//
// Постоянство при этом не теряется: пять типов есть у всех методов
// (пролив, пауза, подать, ремарка, своё), ещё три — больше чем у трети.
// Верх таблицы у любого прибора одинаковый, меняется хвост.
//
// По макетам ночи 4 (S03–S06, S08):
//   * в шапке — метод и счёт «восемь типов из семнадцати»;
//   * у «Обслуживания» подзаголовок «меняет состояние прибора» — иначе
//     непонятно, чем «открыть клапан» отличается от «ремарки»;
//   * тип с предупреждением помечен жёлтым уже в листе, а не выскакивает
//     потом: человек должен видеть, что кладёт в рецепт опасный шаг;
//   * свои заготовки стоят четвёртой группой, а не последней: человек их
//     только что завёл и ищет наверху. «Пауза и текст» уходит вниз.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/recipes/application/step_types_state.dart';
import '../features/recipes/domain/models/step_type_model.dart';
import '../features/recipes/domain/models/user_step_type_model.dart';
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

/// Своя заготовка из группы «Ваши типы».
class UserStepPick extends StepTypePick {
  const UserStepPick(this.type);

  final UserStepType type;
}

/// «Новый» — не тип, а выход за справочник: открывает форму своего шага.
class CustomStepPick extends StepTypePick {
  const CustomStepPick();
}

/// Открывает лист и возвращает выбранное. null — закрыли, ничего не выбрав.
Future<StepTypePick?> showStepTypeSheet(
  BuildContext context, {
  required List<String> allowedStepTypes,
  String? currentSlug,
  int brewMethodId = 0,
  String? methodName,
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
      brewMethodId: brewMethodId,
      methodName: methodName,
    ),
  );
}

class _StepTypeSheet extends ConsumerWidget {
  const _StepTypeSheet({
    required this.allowedStepTypes,
    required this.brewMethodId,
    this.currentSlug,
    this.methodName,
  });

  final List<String> allowedStepTypes;
  final int brewMethodId;
  final String? currentSlug;
  final String? methodName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = ref.watch(stepTypesProvider);
    // Свои заготовки грузятся параллельно со справочником; их отсутствие не
    // блокирует лист — группа просто останется с одной клеткой «новый».
    final own = ref.watch(userStepTypesProvider(brewMethodId)).valueOrNull ??
        const <UserStepType>[];

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
            reference.maybeWhen(
              data: (data) => _Header(
                methodName: methodName,
                shown: data.allowedFor(allowedStepTypes).fold<int>(
                    0, (sum, group) => sum + group.types.length),
                total: data.types.length,
                own: own.length,
              ),
              orElse: () => const SizedBox.shrink(),
            ),
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
                  own: own,
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

/// Шапка листа: что выбираем и сколько типов у этого прибора.
class _Header extends StatelessWidget {
  const _Header({
    required this.methodName,
    required this.shown,
    required this.total,
    required this.own,
  });

  final String? methodName;
  final int shown;
  final int total;
  final int own;

  @override
  Widget build(BuildContext context) {
    final counts = own > 0
        ? '$shown ${_typesWord(shown)} из $total и ${_ownCount(own)}'
        : '$shown ${_typesWord(shown)} из $total';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('Тип шага', style: context.texts.bodyMedium),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              methodName == null ? counts : '$methodName · $counts',
              style: context.texts.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static String _typesWord(int count) => switch (count % 10) {
        1 when count % 100 != 11 => 'тип',
        2 || 3 || 4 when count % 100 < 12 || count % 100 > 14 => 'типа',
        _ => 'типов',
      };

  static String _ownCount(int count) =>
      count == 1 ? 'одна ваша заготовка' : '$count ваших';
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
  const _Types({required this.groups, required this.own, this.currentSlug});

  final List<GroupedStepTypes> groups;
  final List<UserStepType> own;
  final String? currentSlug;

  @override
  Widget build(BuildContext context) {
    // «Ваши типы» встают четвёртой группой, перед «Паузой и текстом»:
    // человек их только что завёл и ищет наверху, а пауза с ремаркой — самая
    // редкая группа, ей место внизу (макет S08).
    final tail = groups.where(_isPauseText).toList();
    final head = groups.where((group) => !_isPauseText(group)).toList();

    return ListView(
      shrinkWrap: true,
      children: [
        for (final group in head) ..._group(context, group),
        _GroupHeader(own.isEmpty ? 'Ваши типы' : 'Ваши типы · только для этого прибора'),
        _Grid(
          children: [
            for (final type in own)
              _TypeCell(
                icon: AppIcons.step(type.icon),
                label: type.label,
                warn: type.warning.isNotEmpty,
                own: true,
                onTap: () => Navigator.of(context).pop(UserStepPick(type)),
              ),
            _TypeCell(
              icon: AppIcons.uiPlus,
              label: 'новый',
              dashed: true,
              onTap: () => Navigator.of(context).pop(const CustomStepPick()),
            ),
          ],
        ),
        for (final group in tail) ..._group(context, group),
      ],
    );
  }

  static bool _isPauseText(GroupedStepTypes group) => group.slug == 'pause_text';

  List<Widget> _group(BuildContext context, GroupedStepTypes group) {
    // Подзаголовок «меняет состояние прибора» — у группы, чьи типы ставят
    // строку состояния в шапку заваривания: «Клапан закрыт», «Перевёрнут».
    final statefulGroup = group.types.any((type) => type.deviceState.isNotEmpty);

    return [
      _GroupHeader(
        statefulGroup ? '${group.name} · меняет состояние прибора' : group.name,
      ),
      _Grid(
        children: [
          for (final type in group.types)
            _TypeCell(
              icon: AppIcons.step(type.iconKey),
              label: type.label,
              selected: type.slug == currentSlug,
              warn: type.warning.isNotEmpty,
              onTap: () => Navigator.of(context).pop(BuiltInStepPick(type)),
            ),
        ],
      ),
    ];
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
          Flexible(child: Text(name, style: context.texts.labelSmall)),
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
    this.warn = false,
    this.own = false,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  /// Пунктир — у «нового»: он открывает форму, а не выбирает существующее.
  final bool dashed;

  /// Жёлтая метка — у типа с непустым предупреждением: человек должен
  /// видеть уже в листе, что кладёт в рецепт опасный шаг (макет S05).
  final bool warn;

  /// Своя заготовка: пунктирная рамка отличает её от встроенного, чтобы не
  /// искать потом, почему шаг не приехал на другом приборе.
  final bool own;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    final warnColor = context.colors.tertiary;
    final highlighted = selected || dashed || own;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AppIcon(
              icon,
              size: AppSizes.icon24,
              color: highlighted ? accent : context.colors.onSurface,
            ),
            if (warn)
              Positioned(
                top: -AppSpacing.s1,
                right: -AppSpacing.s2,
                child: Container(
                  width: AppSpacing.s2,
                  height: AppSpacing.s2,
                  decoration: BoxDecoration(color: warnColor, shape: BoxShape.circle),
                ),
              ),
          ],
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

    if (dashed || own) {
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
            border: Border.all(
              color: selected
                  ? accent
                  : warn
                      ? warnColor
                      : context.palette.border,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
