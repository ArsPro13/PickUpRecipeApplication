// Экран 07 «Мои рецепты» — вторая вкладка.
//
// Цепочка версий выглядит физической стопкой карточек: сверху последняя, из-под
// неё торчат края прошлых. Толщина стопки и есть число поправок — считать
// нечего, слова «версия 4» не нужны нигде. Рецепт с четырьмя правками
// физически толще одноразового, и это видно раньше, чем прочитано.
//
// Глубже трёх краёв стопка не растёт: четыре и больше уже не читаются как
// «несколько прошлых», а выглядят списком, который забыли закрыть. Всё, что не
// поместилось, сворачивается в счётчик на нижнем крае.
//
// Группа — пара «кофе + метод» (ответ Q23b), а не цепочка prev_id/next_id:
// на экране это выглядит одинаково, но владелец выбрал пару.
//
// Чего здесь нет: оценки. Она лежит в `/recipe/estimations` по одному запросу
// на рецепт, и ради звезды в списке платить запросом за карточку рано —
// на месте оценки стоит повтор заваривания.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/app_router.dart';
import '../features/packs/application/state/active_packs_state.dart';
import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/application/state/recipes_list_state.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'packs_page.dart';

/// Высота карточки и глубина выступа края. Одна шкала на весь экран — от неё
/// считается всё остальное, поэтому список не разъезжается.
const double _cardHeight = AppSpacing.s18 + AppSpacing.s12 + AppSpacing.s2;
const double _peek = AppSpacing.s6;

/// Больше трёх краёв стопка не показывает.
const int _maxPeek = 3;

@RoutePage()
class RecipesPage extends ConsumerStatefulWidget {
  const RecipesPage({super.key});

  @override
  ConsumerState<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends ConsumerState<RecipesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recipesListProvider.notifier).load();
      // Пачки нужны ради фото и имени обжарщика: история их не отдаёт.
      // Провайдер общий с первой вкладкой, лишнего запроса не выходит.
      ref.read(activePacksNotifierProvider.notifier).fetchPacks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipesListProvider);
    final packs = ref.watch(activePacksNotifierProvider).activePacks;

    return Scaffold(
      appBar: AppBar(title: const Text('Мои рецепты')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(recipesListProvider.notifier).load(),
        child: _body(state, packs),
      ),
    );
  }

  Widget _body(RecipesListState state, List<PackData> packs) {
    if (state.isLoading && state.groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.groups.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height / 6),
          AppState(
            icon: AppIcons.uiHistory,
            title: 'Ещё ни одного заваривания',
            description: 'Заварите кофе по рецепту — он появится здесь вместе с оценкой',
            primaryAction: AppButton(
              label: 'К пачкам',
              onPressed: () => AutoTabsRouter.of(context).setActiveIndex(0),
            ),
          ),
        ],
      );
    }

    final byId = {for (final pack in packs) pack.packId: pack};

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s5,
      ),
      itemCount: state.groups.length,
      itemBuilder: (context, index) {
        final group = state.groups[index];
        return _Group(
          group: group,
          pack: byId[group.packId],
          // Единственный главный элемент экрана — верхняя карточка первой
          // стопки. Поднимать все значит не поднять ни одну.
          hero: index == 0,
          first: index == 0,
        );
      },
    );
  }
}

/// Одна группа: шапка и стопка версий под ней.
class _Group extends StatefulWidget {
  const _Group({
    required this.group,
    required this.pack,
    required this.hero,
    required this.first,
  });

  final RecipeGroup group;
  final PackData? pack;
  final bool hero;
  final bool first;

  @override
  State<_Group> createState() => _GroupState();
}

class _GroupState extends State<_Group> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return Container(
      padding: EdgeInsets.only(top: widget.first ? 0 : AppSpacing.s4),
      decoration: widget.first
          ? null
          : BoxDecoration(
              border: Border(top: BorderSide(color: context.palette.border)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            group: group,
            pack: widget.pack,
            expanded: _expanded,
            onToggle: group.depth == 0
                ? null
                : () => setState(() => _expanded = !_expanded),
          ),
          const SizedBox(height: AppSpacing.s2),
          if (_expanded)
            _Unstacked(group: group, pack: widget.pack, hero: widget.hero)
          else
            _Stack(group: group, pack: widget.pack, hero: widget.hero),
          const SizedBox(height: AppSpacing.s4),
        ],
      ),
    );
  }
}

/// Шапка группы: значок прибора в кружке, «кофе · метод» и число версий.
class _Header extends StatelessWidget {
  const _Header({
    required this.group,
    required this.pack,
    required this.expanded,
    required this.onToggle,
  });

  final RecipeGroup group;
  final PackData? pack;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;

    return Row(
      children: [
        Container(
          height: AppSpacing.s8,
          width: AppSpacing.s8,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AppIcon(
              AppIcons.byKey('method-${group.methodIconKey.replaceAll('_', '-')}') ??
                  AppIcons.methodHarioV60,
              size: AppSizes.icon20,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название не обрезается: длинное переносится на две строки,
              // кнопка и стопка подстраиваются по высоте.
              Text(
                _title(),
                style: context.texts.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(_subtitle(), style: context.texts.labelSmall),
            ],
          ),
        ),
        // Тач-таргет 48 есть только там, где есть глубина.
        if (onToggle != null)
          SizedBox(
            height: AppSizes.tapTarget,
            width: AppSizes.tapTarget,
            child: IconButton(
              onPressed: onToggle,
              tooltip: expanded ? 'Сложить стопку' : 'Разложить стопку',
              icon: AppIcon(
                expanded ? AppIcons.uiChevronUp : AppIcons.uiChevronDown,
                size: AppSizes.icon20,
                color: context.colors.secondary,
              ),
            ),
          ),
      ],
    );
  }

  String _title() {
    final coffee = pack?.packName ?? '';
    return coffee.isEmpty ? group.methodName : '$coffee · ${group.methodName}';
  }

  String _subtitle() {
    final parts = [
      if (pack != null && pack!.roasterName.isNotEmpty) pack!.roasterName,
      formatRecipeDate(group.latest.date),
      if (group.versions.length > 1)
        '${group.versions.length} ${_versionWord(group.versions.length)}',
    ];
    return parts.join(' · ');
  }
}

/// Стопка: верхняя карточка и до трёх краёв под ней.
class _Stack extends StatelessWidget {
  const _Stack({required this.group, required this.pack, required this.hero});

  final RecipeGroup group;
  final PackData? pack;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final hidden = group.versions.skip(1).toList();
    final edges = hidden.length > _maxPeek ? _maxPeek : hidden.length;

    return SizedBox(
      height: _cardHeight + _peek * edges,
      child: Stack(
        children: [
          // Края рисуются с дальнего: ближний должен лечь поверх.
          for (var depth = edges; depth >= 1; depth--)
            Positioned(
              top: _peek * depth,
              left: AppSpacing.s1 * depth,
              right: AppSpacing.s1 * depth,
              height: _cardHeight,
              child: Opacity(
                opacity: 1 - 0.1 * (depth - 1),
                child: _Edge(
                  // Нижний край показывает счётчик, если версий больше, чем
                  // краёв: остальное сворачивается в одну строку.
                  label: depth == edges && hidden.length > _maxPeek
                      ? _restLabel(hidden)
                      : _edgeLabel(hidden[depth - 1]),
                  counter: depth == edges && hidden.length > _maxPeek,
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _cardHeight,
            child: _TopCard(version: group.latest, pack: pack, hero: hero),
          ),
        ],
      ),
    );
  }

  String _edgeLabel(RecipeVersion version) {
    final parts = [
      formatRecipeDate(version.date),
      if (version.temperatureC != null) '${version.temperatureC!.toStringAsFixed(0)} °C',
      _formatTime(version.timeSec),
    ];
    return parts.join(' · ');
  }

  String _restLabel(List<RecipeVersion> hidden) {
    final rest = hidden.length - (_maxPeek - 1);
    final oldest = hidden.last;
    return 'ещё $rest ${_versionWord(rest)}, с ${formatRecipeDate(oldest.date)}';
  }
}

/// Край прошлой версии: наружу выходит только нижняя полоса.
class _Edge extends StatelessWidget {
  const _Edge({required this.label, required this.counter});

  final String label;
  final bool counter;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s3,
        0,
        AppSpacing.s3,
        AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        borderRadius: AppRadius.medium,
        boxShadow: context.shadows.level1,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.texts.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.clip,
              softWrap: false,
            ),
          ),
          if (counter)
            AppIcon(
              AppIcons.uiChevronDown,
              size: AppSizes.icon16,
              color: context.colors.secondary,
            ),
        ],
      ),
    );
  }
}

/// Верхняя карточка стопки: фото слева, числа рецепта справа.
class _TopCard extends StatelessWidget {
  const _TopCard({required this.version, required this.pack, required this.hero});

  final RecipeVersion version;
  final PackData? pack;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        borderRadius: hero ? AppRadius.large : AppRadius.medium,
        boxShadow: hero ? context.shadows.level2 : context.shadows.level1,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(child: _Photo(pack: pack, caption: formatRecipeDate(version.date))),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s3,
                vertical: AppSpacing.s2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('так завариваю', style: context.texts.labelSmall),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    '${_formatDose(version.doseG)} г → ${version.waterG} мл',
                    style: context.texts.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    [
                      if (version.temperatureC != null)
                        '${version.temperatureC!.toStringAsFixed(0)} °C',
                      _formatTime(version.timeSec),
                    ].join(' · '),
                    style: context.texts.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Spacer(),
                      _PlayButton(version: version, pack: pack, filled: hero),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Фото пачки с затемнением и датой поверх него.
class _Photo extends StatelessWidget {
  const _Photo({required this.pack, required this.caption});

  final PackData? pack;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: context.palette.border,
          child: PackImage(base64Image: pack?.packImage ?? ''),
        ),
        // Подпись читается поверх любого фото только с затемнением: пачки
        // бывают и очень светлые, и очень тёмные.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s3,
              vertical: AppSpacing.s1,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
              ),
            ),
            child: Text(
              caption,
              style: context.texts.labelSmall?.copyWith(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

/// Круглая кнопка «заварить снова».
///
/// Своего размера, а не `AppButton`: тот держит высоту 50 и разрезал бы
/// карточку пополам. У неглавных групп повтор тише — контур вместо заливки.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.version, required this.pack, required this.filled});

  final RecipeVersion version;
  final PackData? pack;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;

    return Semantics(
      button: true,
      label: 'Заварить снова',
      child: InkWell(
        onTap: () => context.router.push(BrewRoute(recipe: version.recipe, pack: pack)),
        customBorder: const CircleBorder(),
        child: Container(
          height: AppSpacing.s8,
          width: AppSpacing.s8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? accent : Colors.transparent,
            border: filled ? null : Border.all(color: context.palette.border),
          ),
          child: Center(
            child: AppIcon(
              AppIcons.uiPlay,
              size: AppSizes.icon16,
              color: filled ? context.colors.secondaryContainer : context.colors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Разложенная стопка: та же верхняя карточка и прошлые версии строками.
class _Unstacked extends StatelessWidget {
  const _Unstacked({required this.group, required this.pack, required this.hero});

  final RecipeGroup group;
  final PackData? pack;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: _cardHeight,
          child: _TopCard(version: group.latest, pack: pack, hero: hero),
        ),
        for (final version in group.versions.skip(1))
          AppRow(
            label: formatRecipeDate(version.date),
            value: [
              if (version.temperatureC != null)
                '${version.temperatureC!.toStringAsFixed(0)} °C',
              _formatTime(version.timeSec),
            ].join(' · '),
            onTap: () => context.router.push(
              BrewRoute(recipe: version.recipe, pack: pack),
            ),
          ),
      ],
    );
  }
}

/// м:сс — тот же формат, что на экране заваривания.
String _formatTime(int seconds) {
  final rest = (seconds % 60).toString().padLeft(2, '0');
  return '${seconds ~/ 60}:$rest';
}

/// Доза без лишнего хвоста: 15 вместо 15.0.
String _formatDose(double value) {
  final rounded = (value * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return rounded.round().toString();
  return rounded.toStringAsFixed(1).replaceAll('.', ',');
}

String _versionWord(int count) {
  if (count % 10 == 1 && count % 100 != 11) return 'версия';
  if ([2, 3, 4].contains(count % 10) && !(count % 100 >= 12 && count % 100 <= 14)) {
    return 'версии';
  }
  return 'версий';
}
