// Экран 07 «Рецепты» — вторая вкладка.
//
// Группа — пара «кофе + метод» (ответ Q23b), а не цепочка prev_id/next_id: на
// экране это выглядит одинаково, но владелец выбрал пару. Версии внутри
// группы лежат барабаном: стопка карточек, верхнюю уводят свайпом вбок, она
// улетает с наклоном, а следующая поднимается на её место — по кругу.
//
// Две прошлые попытки и чем они не подошли:
//   * стопка с торчащими краями — толщина читалась как число правок, но
//     попасть в узкую полоску прошлой версии пальцем почти невозможно;
//   * лента с прокруткой — попасть легко, но пропадает сама стопка: версии
//     выглядели соседними карточками, а не историей одного рецепта.
// Барабан оставляет стопку и делает её листаемой жестом, который знают все.
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
import '../features/brew_methods/application/brew_methods_state.dart';
import '../themes/method_family.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'packs_page.dart';

/// Высота карточки версии. Одна шкала на весь экран — от неё считается
/// остальное, поэтому список не разъезжается.
const double _cardHeight = 170;

/// Сколько карточек видно под верхней. Больше двух не помогает: третий край
/// уже не читается как «ещё есть», а выглядит мусором под карточкой.
const int _deckDepth = 2;

/// На сколько сдвинута и ужата каждая следующая карточка стопки.
const double _deckStep = 10;
const double _deckScale = 0.045;

/// Насколько далеко нужно увести карточку, чтобы она улетела, а не вернулась.
const double _flyThreshold = 90;

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
      appBar: AppBar(title: const Text('Рецепты')),
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

    // Ошибка загрузки — не то же самое, что «ещё ни одного заваривания»:
    // пустой экран с бодрым текстом на месте сбоя врал бы человеку.
    if (state.groups.isEmpty && state.error != null) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height / 6),
          AppState(
            icon: AppIcons.stateError,
            title: 'Рецепты не загрузились',
            description: state.error,
            isError: true,
            primaryAction: AppButton(
              label: 'Повторить',
              onPressed: () => ref.read(recipesListProvider.notifier).load(),
            ),
          ),
        ],
      );
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
          // группы. Поднимать все значит не поднять ни одну.
          hero: index == 0,
          first: index == 0,
        );
      },
    );
  }
}

/// Одна группа: шапка и лента версий под ней.
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

class _GroupState extends State<_Group> with SingleTickerProviderStateMixin {
  /// Полёт улетающей карточки и её же возврат на место. Один контроллер на
  /// оба движения: одновременно они случиться не могут.
  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: AppDuration.base,
  );

  /// Верхняя карточка барабана. Барабан кольцевой: после последней версии
  /// снова первая — иначе после третьего свайпа человек упирается в пустоту
  /// и не понимает, сломалось или закончилось.
  int _top = 0;

  /// Насколько карточку увели пальцем прямо сейчас.
  Offset _drag = Offset.zero;

  /// Идёт полёт — жесты в это время не принимаем.
  bool _flying = false;

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  int _at(int offset) {
    final count = widget.group.versions.length;
    return (_top + offset) % count;
  }

  void _animateDrag(Offset target, {VoidCallback? then}) {
    final tween = Tween<Offset>(begin: _drag, end: target)
        .animate(CurvedAnimation(parent: _fly, curve: AppCurves.out));

    void tick() => setState(() => _drag = tween.value);

    _fly
      ..reset()
      ..addListener(tick);

    _fly.forward().whenComplete(() {
      _fly.removeListener(tick);
      then?.call();
    });
  }

  void _release(double width) {
    if (_drag.dx.abs() < _flyThreshold) {
      // Не дотянули — карточка возвращается на место, а не остаётся косой.
      _animateDrag(Offset.zero, then: () => setState(() => _flying = false));
      return;
    }

    final direction = _drag.dx.isNegative ? -1 : 1;
    setState(() => _flying = true);

    _animateDrag(
      Offset(direction * width * 1.4, _drag.dy),
      then: () {
        setState(() {
          // Влево — к следующей версии, вправо — к предыдущей: барабан
          // крутится в обе стороны, как его ни толкни.
          _top = direction < 0 ? _at(1) : _at(widget.group.versions.length - 1);
          _drag = Offset.zero;
          _flying = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final versions = widget.group.versions;
    final single = versions.length == 1;

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
          _Header(group: widget.group, pack: widget.pack),
          const SizedBox(height: AppSpacing.s2),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              return SizedBox(
                // Место под стопку: карточка плюс сдвиг задних краёв.
                height: _cardHeight + _deckStep * _deckDepth,
                child: Stack(
                  children: [
                    // Задние карточки рисуются с дальней: ближняя ложится
                    // поверх неё, как в настоящей стопке.
                    for (var depth = _deckDepth; depth >= 1; depth--)
                      if (versions.length > depth)
                        Positioned(
                          top: _deckStep * depth,
                          left: 0,
                          right: 0,
                          height: _cardHeight,
                          child: Transform.scale(
                            scale: 1 - _deckScale * depth,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 1 - 0.18 * depth,
                                child: _VersionCard(
                                  version: versions[_at(depth)],
                                  pack: widget.pack,
                                  hero: false,
                                  latest: _at(depth) == 0,
                                ),
                              ),
                            ),
                          ),
                        ),

                    // Верхняя карточка: её и таскают.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: _cardHeight,
                      child: Transform.translate(
                        offset: _drag,
                        child: Transform.rotate(
                          // Наклон от того, насколько увели: движение
                          // читается как «карточку отбрасывают», а не как
                          // «она едет по рельсам».
                          angle: _drag.dx / width * 0.22,
                          child: GestureDetector(
                            onHorizontalDragUpdate: single || _flying
                                ? null
                                : (details) => setState(() => _drag += details.delta),
                            onHorizontalDragEnd:
                                single || _flying ? null : (_) => _release(width),
                            child: _VersionCard(
                              version: versions[_top],
                              pack: widget.pack,
                              hero: widget.hero && _top == 0,
                              latest: _top == 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (!single) ...[
            const SizedBox(height: AppSpacing.s2),
            _Pager(count: versions.length, index: _top),
          ],
          const SizedBox(height: AppSpacing.s4),
        ],
      ),
    );
  }
}

/// Шапка группы: значок прибора в кружке, «кофе · метод» и число версий.
class _Header extends ConsumerWidget {
  const _Header({required this.group, required this.pack});

  final RecipeGroup group;
  final PackData? pack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Кружок значка красится в цвет семьи прибора: воронка, пресс и холодные
    // методы перестают выглядеть одинаково при беглом просмотре списка.
    final family = methodFamilyColor(
      ref.watch(brewMethodsProvider).groupSlugBySlug[group.method],
    );
    final accent = family ?? context.colors.primary;

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
              AppIcons.method(group.methodIconKey),
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
              // Название не обрезается: длинное переносится на две строки.
              Text(
                _title(),
                style: context.texts.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(_subtitle(), style: context.texts.labelSmall),
            ],
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

/// Где мы в ленте версий: точки и подпись словами.
///
/// Точки без подписи читаются как украшение, подпись без точек — как текст,
/// который не к чему привязать. Вместе они говорят «здесь есть что листать».
class _Pager extends StatelessWidget {
  const _Pager({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s1),
          Container(
            height: AppSpacing.s1 + 2,
            width: i == index ? AppSpacing.s4 : AppSpacing.s1 + 2,
            decoration: BoxDecoration(
              color: i == index
                  ? context.colors.primary
                  : context.palette.border,
              borderRadius: AppRadius.rounded,
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.s3),
        Text(
          index == 0 ? 'сейчас · смахните вбок' : 'версия ${index + 1} из $count',
          style: context.texts.labelSmall,
        ),
      ],
    );
  }
}

/// Карточка версии: фото слева, показатели метками справа.
///
/// Тап в любом месте открывает рецепт — на экране заваривания он и живёт,
/// вместе с шагами и числами. Кружок «заварить» на карточке сразу пускает
/// таймер: рецепт человек уже видел, если жмёт именно сюда.
class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.version,
    required this.pack,
    required this.hero,
    required this.latest,
  });

  final RecipeVersion version;
  final PackData? pack;
  final bool hero;
  final bool latest;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.secondaryContainer,
      borderRadius: hero ? AppRadius.large : AppRadius.medium,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () => context.router.push(
          BrewRoute(recipe: version.recipe, pack: pack),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: hero ? AppRadius.large : AppRadius.medium,
            boxShadow: hero ? context.shadows.level2 : context.shadows.level1,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: _Photo(pack: pack, caption: formatRecipeDate(version.date)),
              ),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latest ? 'так завариваю' : 'прошлая версия',
                        style: context.texts.labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      // Показатели метками, а не строкой текста: цвет метки
                      // и есть её подпись — дозу от воды отличают, не читая.
                      Wrap(
                        spacing: AppSpacing.s2,
                        runSpacing: AppSpacing.s2,
                        children: [
                          MetricTag(
                            kind: MetricKind.dose,
                            label: '${_formatDose(version.doseG)} г',
                          ),
                          MetricTag(
                            kind: MetricKind.water,
                            label: '${version.waterG} мл',
                          ),
                          if (version.temperatureC != null)
                            MetricTag(
                              kind: MetricKind.temperature,
                              label: '${version.temperatureC!.toStringAsFixed(0)} °C',
                            ),
                          MetricTag(
                            kind: MetricKind.time,
                            label: _formatTime(version.timeSec),
                          ),
                        ],
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
        ),
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
          child: PackImage(
            base64Image: pack?.packImage ?? '',
            roastLevel: pack?.roastLevel ?? '',
          ),
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
/// карточку пополам. У неглавных версий повтор тише — контур вместо заливки.
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
        onTap: () => context.router.push(
          BrewRoute(recipe: version.recipe, pack: pack, autoStart: true),
        ),
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
