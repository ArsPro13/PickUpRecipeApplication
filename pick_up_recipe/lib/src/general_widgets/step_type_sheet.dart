// Лист выбора типа шага.
//
// Два блока. Сверху — шаги этого метода одной сеткой, без групп: у V60 их
// восемь из семнадцати, и в девяти случаях из десяти шаг берут отсюда. Там же
// свои заготовки под этот прибор и «новый». Ниже — все семнадцать по группам.
//
// Раньше лист показывал только типы метода, разложенные по группам, а
// остальные не показывал вовсе. Владелец попросил иначе: «шаги для этого
// метода в начале, просто единым блоком, а потом все возможные шаги по
// категориям». Группы над четырьмя клетками дробили короткий список на
// заголовки, а нужного прибору шага, которого нет в его списке, было не
// взять никак — сервер такой шаг не запрещает, запрещал только лист.
//
// По макетам ночи 4 (S03–S06, S08):
//   * в шапке — метод и счёт «восемь типов из семнадцати»;
//   * у «Обслуживания» подзаголовок «меняет состояние прибора» — иначе
//     непонятно, чем «открыть клапан» отличается от «ремарки»;
//   * тип с предупреждением помечен жёлтым уже в листе, а не выскакивает
//     потом: человек должен видеть, что кладёт в рецепт опасный шаг.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
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
    // Палец на списке крутит список, а не тащит шторку вниз.
    //
    // Та же беда, что у барабана длительности: шторка тянется за пальцем всей
    // площадью, и её распознаватель вертикального перетаскивания забирал жест
    // у списка — у прибора с полной таблицей типов до нижних групп было не
    // добраться вовсе. Закрывают лист выбором клетки, нажатием мимо и
    // системной кнопкой «назад».
    //
    // Ручку-полоску лист рисует сам, внутри своей карточки (`_GrabHandle`):
    // системную просить незачем, тем более что при прозрачном фоне она
    // оказывалась не на карточке, а над ней — белой чертой поверх рецепта.
    enableDrag: false,
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
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
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
                shown: data
                    .allowedFor(allowedStepTypes)
                    .fold<int>(0, (sum, group) => sum + group.types.length),
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
                  title: AppLocalizations.of(context).stepTypesFailed,
                  description: AppLocalizations.of(context).stepTypesFailedNote,
                  isError: true,
                  primaryAction: AppButton(
                    label: AppLocalizations.of(context).retry,
                    onPressed: () => ref.invalidate(stepTypesProvider),
                  ),
                ),
                data: (data) => _Types(
                  method: allowedStepTypes.isEmpty
                      ? const []
                      : data.allowedFor(allowedStepTypes),
                  all: data.allowedFor(const []),
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
    final texts = AppLocalizations.of(context);
    // Склонение «1 тип / 2 типа / 5 типов» и «одна ваша заготовка / 3 ваших»
    // считает ICU, а не эта шапка: таблица форм у каждого языка своя, и
    // написанная руками была верной ровно для одного из них — на 21 своей
    // заготовке она говорила «21 ваших».
    final counts = own > 0
        ? texts.stepTypesCountWithOwn(shown, total, own)
        : texts.stepTypesCount(shown, total);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(texts.stepTypeLabel, style: context.texts.bodyMedium),
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
  const _Types({
    required this.method,
    required this.all,
    required this.own,
    this.currentSlug,
  });

  /// Типы метода по группам. Пусто — метод неизвестен, и первого блока нет.
  final List<GroupedStepTypes> method;

  /// Весь справочник по группам.
  final List<GroupedStepTypes> all;

  final List<UserStepType> own;
  final String? currentSlug;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    // Метод неизвестен — показать «шаги этого метода» не из чего. Тогда лист
    // остаётся прежним: справочник по группам, и свои заготовки с «новым»
    // перед «Паузой и текстом» — самой редкой группой, ей место внизу.
    if (method.isEmpty) {
      final tail = all.where(_isPauseText).toList();
      final head = all.where((group) => !_isPauseText(group)).toList();

      return ListView(
        shrinkWrap: true,
        children: [
          for (final group in head) ..._group(context, group),
          _GroupHeader(
            own.isEmpty ? texts.stepTypesOwnGroup : texts.stepTypesOwnGroupOnly,
          ),
          _Grid(children: _ownCells(context)),
          for (final group in tail) ..._group(context, group),
        ],
      );
    }

    return ListView(
      shrinkWrap: true,
      children: [
        // «Для этого прибора», а не «Для Аэропресс»: имя метода приходит с
        // сервера и не склоняется, а сам метод назван строкой выше, в шапке.
        _GroupHeader(texts.stepTypesForThisDevice),
        // Одной сеткой, без групп: у метода клеток немного, и заголовки
        // групп над каждой парой дробили их на куски. Порядок — тот же, что
        // в справочнике: сначала вода, потом обслуживание, пауза в конце.
        _Grid(
          children: [
            for (final group in method)
              for (final type in group.types) _builtIn(context, type),
            ..._ownCells(context),
          ],
        ),
        Padding(
          padding:
              const EdgeInsets.only(top: AppSpacing.s2, bottom: AppSpacing.s3),
          child: Text(texts.stepTypesAll, style: context.texts.bodyMedium),
        ),
        for (final group in all) ..._group(context, group),
      ],
    );
  }

  static bool _isPauseText(GroupedStepTypes group) =>
      group.slug == 'pause_text';

  /// Свои заготовки и «новый». Заготовка привязана к прибору, поэтому живёт
  /// в блоке метода, а не среди всех шагов.
  List<Widget> _ownCells(BuildContext context) {
    return [
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
        label: AppLocalizations.of(context).stepTypeNew,
        dashed: true,
        onTap: () => Navigator.of(context).pop(const CustomStepPick()),
      ),
    ];
  }

  Widget _builtIn(BuildContext context, StepType type) {
    return _TypeCell(
      icon: AppIcons.step(type.iconKey),
      label: type.label,
      selected: type.slug == currentSlug,
      warn: type.warning.isNotEmpty,
      onTap: () => Navigator.of(context).pop(BuiltInStepPick(type)),
    );
  }

  List<Widget> _group(BuildContext context, GroupedStepTypes group) {
    // Подзаголовок «меняет состояние прибора» — у группы, чьи типы ставят
    // строку состояния в шапку заваривания: «Клапан закрыт», «Перевёрнут».
    final statefulGroup =
        group.types.any((type) => type.deviceState.isNotEmpty);

    final texts = AppLocalizations.of(context);
    // Группа «Прочие» собирается на телефоне, и имени с сервера у неё нет.
    final name =
        group.slug == otherGroupSlug ? texts.svcGroupOther : group.name;

    return [
      _GroupHeader(
        statefulGroup ? texts.stepTypesStateful(name) : name,
      ),
      _Grid(
        children: [
          for (final type in group.types) _builtIn(context, type),
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
          Expanded(
              child: Divider(
                  height: AppStroke.thin, color: context.palette.border)),
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
                  decoration:
                      BoxDecoration(color: warnColor, shape: BoxShape.circle),
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
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s1, vertical: AppSpacing.s3),
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
