// Экран 02 «Мои пачки» — корень приложения.
//
// Пачка — это то, что стоит на кухне, поэтому приложение открывается ею,
// а не списком рецептов. Кофемолка вынесена кнопкой в шапку: от неё зависят
// щелчки в каждом рецепте, и менять её приходится чаще, чем что-либо в профиле.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../features/grinders/application/grinder_state.dart';
import '../features/packs/application/state/active_packs_state.dart';
import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/application/rating_draft.dart';
import '../features/recipes/application/state/recipes_list_state.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../themes/app_icons.dart';
import '../features/brew_methods/application/brew_methods_state.dart';
import '../themes/method_family.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class PacksPage extends ConsumerStatefulWidget {
  const PacksPage({super.key});

  @override
  ConsumerState<PacksPage> createState() => _PacksPageState();
}

class _PacksPageState extends ConsumerState<PacksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activePacksNotifierProvider.notifier).fetchPacks();
      ref.read(grinderStateProvider.notifier).loadUserGrinders();
      // История нужна ради двух вещей: меток «чем эту пачку заваривали» и
      // того, какая пачка открыта. Провайдер общий со второй вкладкой, так
      // что запрос один на обе.
      ref.read(recipesListProvider.notifier).load();
      // Справочник приборов нужен меткам: по нему они узнают семью и цвет.
      // Загружается один раз на всё приложение, поэтому лишнего запроса
      // при переходах не выходит.
      if (ref.read(brewMethodsProvider).grouped.isEmpty) {
        ref.read(brewMethodsProvider.notifier).load();
      }
      // Незаконченная оценка ищется здесь: это первая вкладка, и после
      // перезапуска человек оказывается ровно на ней.
      RatingDrafts.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final packs = ref.watch(activePacksNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).packsTitle),
        actions: const [GrinderButton(), SizedBox(width: AppSpacing.s4)],
      ),
      // Плашка стоит над списком, а не строкой в нём: недосказанная оценка не
      // должна уезжать вверх при первой же прокрутке полки.
      body: Column(
        children: [
          const UnfinishedRatingPlate(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(activePacksNotifierProvider.notifier).fetchPacks();
                await ref.read(recipesListProvider.notifier).load();
              },
              child: _body(packs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(ActivePacksState packs) {
    if (packs.isLoading && packs.activePacks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (packs.activePacks.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height / 6),
          AppState(
            icon: AppIcons.stateEmpty,
            title: AppLocalizations.of(context).packsEmpty,
            description: AppLocalizations.of(context).packsEmptyNote,
            primaryAction: AppButton(
              label: AppLocalizations.of(context).packsScanCode,
              icon: AppIcons.uiScan,
              onPressed: () => AutoTabsRouter.of(context).setActiveIndex(2),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s5,
      ),
      itemCount: packs.activePacks.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
      itemBuilder: (context, index) {
        if (index == packs.activePacks.length) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s1),
            child: AppButton(
              label: AppLocalizations.of(context).packsAdd,
              icon: AppIcons.uiPlus,
              kind: AppButtonKind.secondary,
              onPressed: () => AutoTabsRouter.of(context).setActiveIndex(2),
            ),
          );
        }

        final groups = ref.watch(recipesListProvider).groups;
        final pack = packs.activePacks[index];

        return PackCard(
          pack: pack,
          methods: methodsOfPack(groups, pack.packId),
          // Открытая — та, которой заваривали последней. Отдельного признака
          // в схеме нет, а «с ней и заваривают» — ровно это и значит.
          highlighted: groups.isNotEmpty && groups.first.packId == pack.packId,
          onTap: () => context.router.push(CoffeeRoute(packId: pack.packId)),
        );
      },
    );
  }
}

/// Плашка «оценка не дописана».
///
/// Место выбрано так же, как у плашки офлайна на странице кофе: рядом с тем,
/// ради чего экран открыли, и без своего экрана. Первая вкладка — то, что
/// человек видит после перезапуска, и другого места, где он сам додумался бы
/// искать позавчерашнюю недооценённую чашку, попросту нет.
///
/// Смотрит прямо за `RatingDrafts.current`, а не через провайдер: черновик
/// пишет чужой экран, и второй источник правды между ними только разошёлся бы
/// с первым.
class UnfinishedRatingPlate extends StatelessWidget {
  const UnfinishedRatingPlate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RatingDraft?>(
      valueListenable: RatingDrafts.current,
      builder: (context, draft, _) {
        if (draft == null) return const SizedBox.shrink();

        final texts = AppLocalizations.of(context);

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s2,
            AppSpacing.s4,
            0,
          ),
          child: AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s3,
            ),
            onTap: () => context.router.push(
              RatingRoute(recipe: draft.recipe, pack: draft.pack),
            ),
            child: Row(
              children: [
                AppIcon(
                  AppIcons.uiStar,
                  size: AppSizes.icon20,
                  color: context.colors.primary,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(texts.ratingDraftTitle, style: context.texts.bodyMedium),
                      Text(
                        draft.summaryFor(texts).isEmpty
                            ? texts.ratingDraftContinue
                            : texts.ratingDraftContinueWith(draft.summaryFor(texts)),
                        style: context.texts.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: RatingDrafts.clear,
                  tooltip: texts.remove,
                  icon: AppIcon(
                    AppIcons.uiClose,
                    size: AppSizes.icon16,
                    color: context.colors.secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Кнопка кофемолки в шапке.
///
/// Показывает название основной кофемолки, а не значок с многоточием: человек
/// должен видеть, в чьих делениях считаются щелчки, не нажимая ничего.
class GrinderButton extends ConsumerWidget {
  const GrinderButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = ref.watch(grinderStateProvider).primary;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).packsChangeGrinder,
      child: InkWell(
        onTap: () => context.router.push(const GrinderSelectRoute()),
        borderRadius: AppRadius.rounded,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.tapTarget - AppSpacing.s2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s3,
            vertical: AppSpacing.s2,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rounded,
            border: Border.all(color: context.palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                AppIcons.metricGrind,
                size: AppSizes.icon20,
                color: context.metrics.grind,
              ),
              const SizedBox(width: AppSpacing.s2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  primary?.name ?? AppLocalizations.of(context).profileChooseGrinder,
                  style: context.texts.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка пачки: фото, название, обжарщик с датой и строка меток.
///
/// Высота задана жёстко. Карточки с метками и без них обязаны стоять в одну
/// линейку, иначе список выглядит рваным; а раз высота жёсткая, каждая строка
/// внутри — ровно одна строка, длинное режется многоточием. Перенос здесь
/// ломал бы не свою карточку, а высоту всего списка.
class PackCard extends StatelessWidget {
  const PackCard({
    super.key,
    required this.pack,
    this.onTap,
    this.methods = const [],
    this.highlighted = false,
  });

  final PackData pack;
  final VoidCallback? onTap;

  /// Приборы, которыми эту пачку уже заваривали: название для подписи,
  /// slug — чтобы метка узнала семью прибора и покрасилась в её цвет.
  final List<({String name, String slug})> methods;

  /// Открытая пачка — та, с которой заваривают сейчас. Обводка акцентом.
  final bool highlighted;

  /// Фото 72 при 3:4 даёт 96, плюс отступы — ровно высота карточки.
  static const double _photoWidth = AppSpacing.s18;
  static const double _height = AppSpacing.s18 + AppSpacing.s12;

  @override
  Widget build(BuildContext context) {
    final done = !pack.isActive;
    final border = highlighted
        ? context.colors.primary
        : (done ? context.palette.border : null);

    final card = SizedBox(
      height: _height,
      child: AppCard(
        onTap: onTap,
        // Допитая пачка уходит в тень, но не прячется: по ней ещё смотрят
        // рецепты — плоская рамка вместо поднятой поверхности.
        flat: done,
        borderColor: border,
        padding: const EdgeInsets.all(AppSpacing.s3),
        child: Row(
          children: [
            _Photo(image: pack.packImage, roastLevel: pack.roastLevel),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.packName,
                    style: context.texts.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    _subtitle(AppLocalizations.of(context)),
                    style: context.texts.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  _Tags(methods: methods, done: done),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            AppIcon(
              AppIcons.uiForward,
              size: AppSizes.icon20,
              color: context.colors.secondary,
            ),
          ],
        ),
      ),
    );

    // Приглушается карточка целиком, а не каждая строка по отдельности:
    // иначе рамка остаётся яркой и спорит с содержимым.
    return done ? Opacity(opacity: 0.55, child: card) : card;
  }

  /// «Tasty Coffee · 28 июля». Без обжарщика остаётся страна и сорт: пустая
  /// строка на его месте читалась бы как потерянные данные.
  String _subtitle(AppLocalizations texts) {
    final date = formatRecipeDate(texts, pack.packDate);
    if (pack.roasterName.isNotEmpty) return '${pack.roasterName} · $date';

    final origin = [pack.packCountry, pack.packVariety].where((it) => it.isNotEmpty).join(' · ');
    return origin.isEmpty ? date : '$origin · $date';
  }
}

/// Строка меток. Держит высоту, даже когда меток нет: иначе имя пачки
/// у карточки без меток съезжает относительно соседей.
class _Tags extends ConsumerWidget {
  const _Tags({required this.methods, required this.done});

  final List<({String name, String slug})> methods;
  final bool done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Семья прибора приходит из справочника; пока он не загружен, метки
    // остаются серыми — это лучше, чем мигать цветом на каждой загрузке.
    final families = ref.watch(brewMethodsProvider).groupSlugBySlug;

    final labels = <({String text, Color? color})>[
      if (done) (text: AppLocalizations.of(context).packsFinished, color: null),
      for (final method in methods)
        (text: method.name, color: methodFamilyColor(families[method.slug])),
    ];

    return Container(
      height: AppSpacing.s6,
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(top: AppSpacing.s2),
      // Не переносим и не растём: лишняя метка уезжает за край, а не роняет
      // вниз соседнюю карточку.
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          maxWidth: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final label in labels) ...[
                _Tag(label.text, color: label.color),
                const SizedBox(width: AppSpacing.s2),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {this.color});

  final String label;

  /// Цвет семьи прибора. null — метка не про прибор («допита») или семья
  /// ещё не приехала из справочника.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final family = color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: AppSpacing.s1 / 2,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.rounded,
        // Заливка в 12% и рамка в 40%: цвет должен читаться как принадлежность,
        // а не спорить с текстом внутри метки.
        color: family?.withValues(alpha: 0.12),
        border: Border.all(
          color: family?.withValues(alpha: 0.4) ?? context.palette.border,
        ),
      ),
      child: Text(label, style: context.texts.labelSmall, maxLines: 1),
    );
  }
}

/// Фото пачки. Приходит base64-строкой прямо из БД.
///
/// Пропорция 3:4 — как на упаковке: квадрат обрезает высокие пачки по самому
/// заметному, по имени зерна.
class _Photo extends StatelessWidget {
  const _Photo({required this.image, required this.roastLevel});

  final String image;
  final String roastLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: PackCard._photoWidth,
      height: PackCard._photoWidth * 4 / 3,
      decoration: BoxDecoration(
        color: context.palette.border,
        borderRadius: AppRadius.medium,
      ),
      clipBehavior: Clip.antiAlias,
      child: PackImage(base64Image: image, roastLevel: roastLevel),
    );
  }
}

/// Картинка пачки с запасным значком.
///
/// Отдельным виджетом: битая или пустая строка встречается часто — фото
/// хранится в базе, а не в файловом хранилище, и обрезается при переносах.
class PackImage extends StatelessWidget {
  const PackImage({
    super.key,
    required this.base64Image,
    this.fit = BoxFit.cover,
    this.roastLevel = '',
  });

  final String base64Image;
  final BoxFit fit;

  /// Степень обжарки: ею закрашивается место фото, пока фото нет.
  final String roastLevel;

  @override
  Widget build(BuildContext context) {
    final bytes = decodePackImage(base64Image);

    // Фото у большинства пачек ещё нет, и серый прямоугольник со значком
    // повторялся на всей полке — десять одинаковых пятен. Заливка цвета
    // обжарки различает пачки с расстояния и ничего не обещает: это
    // очевидно не фотография.
    if (bytes == null) return _RoastFill(roastLevel: roastLevel);

    return Image.memory(
      bytes,
      fit: fit,
      errorBuilder: (context, _, __) => _RoastFill(roastLevel: roastLevel),
    );
  }
}

/// Заливка на месте фото: тёплый песок у светлой обжарки, тёмный кофе у
/// тёмной. Подпись словом — чтобы цвет не пришлось расшифровывать.
class _RoastFill extends StatelessWidget {
  const _RoastFill({required this.roastLevel});

  final String roastLevel;

  static const _light = [Color(0xFFDCB68A), Color(0xFFB07E4F)];
  static const _medium = [Color(0xFFB98A5F), Color(0xFF6D4426)];
  static const _dark = [Color(0xFF6B4A34), Color(0xFF322115)];

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final (colors, label) = switch (roastLevel) {
      'light' => (_light, texts.roastLight),
      'medium' || 'medium_light' || 'medium_dark' => (_medium, texts.roastMedium),
      'dark' => (_dark, texts.roastDark),
      _ => (_medium, ''),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AppIcon(
              AppIcons.uiPack,
              size: AppSizes.icon24,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          if (label.isNotEmpty)
            Positioned(
              left: AppSpacing.s1,
              right: AppSpacing.s1,
              bottom: AppSpacing.s1,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: context.texts.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
