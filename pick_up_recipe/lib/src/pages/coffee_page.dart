// Страница кофе — то, куда ведёт код с упаковки.
//
// Открывается двумя путями: по коду (диплинк и ручной ввод) и по пачке из
// списка. Оба приводят к одному экрану — страница кофе одна, «кофе без
// рецептов» отдельным экраном не делается.
//
// Способы заваривания лежат прямо здесь, а не за кнопкой «Выбрать метод».
// Кнопка имела смысл, пока сверху стояло фото пачки и занимало пол-экрана;
// фотографии нет, и единственным содержимым страницы оказывались три
// дескриптора и кнопка — то есть лишний шаг ради пустоты.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../features/codes/application/coffee_state.dart';
import '../features/codes/domain/pack_code.dart';
import '../features/recipes/domain/models/step_type_model.dart';
import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/application/last_brew_cache.dart';
import '../features/recipes/application/state/recipes_list_state.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class CoffeePage extends ConsumerStatefulWidget {
  const CoffeePage({super.key, @QueryParam('code') this.code, @QueryParam('pack') this.packId});

  /// Код с упаковки. Заполнен, если пришли по диплинку или ручным вводом.
  final String? code;

  /// Пачка. Заполнена, если пришли из списка своих пачек.
  final int? packId;

  @override
  ConsumerState<CoffeePage> createState() => _CoffeePageState();
}

class _CoffeePageState extends ConsumerState<CoffeePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(coffeeStateProvider.notifier).open(code: widget.code, packId: widget.packId);
    });
  }

  void _openMethod(CoffeeMethod method, PackData pack) {
    context.router.push(
      ChoosingRecipeRoute(
        packId: pack.packId,
        method: method.slug,
        methodName: method.name,
        // Пачка едет объектом: ниже по пути она нужна и шапке выбора, и
        // экрану базового рецепта — без неё правка базового не знает,
        // с какого зерна началась (C7).
        pack: pack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coffeeStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.pack?.packName ?? AppLocalizations.of(context).coffeeTitle),
      ),
      body: switch (state.status) {
        CoffeeStatus.loading => const Center(child: CircularProgressIndicator()),
        CoffeeStatus.notFound => _notFound(),
        CoffeeStatus.withdrawn => _withdrawn(state),
        CoffeeStatus.failed => _failed(state),
        CoffeeStatus.ready => _ready(state),
      },
    );
  }

  /// Такого кода нет (S11). Проверять символы бессмысленно — контрольный
  /// символ уже сошёлся, значит код набран верно и его правда нет.
  Widget _notFound() {
    final code = widget.code;
    final texts = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s8,
        AppSpacing.s5,
        AppSpacing.s8,
      ),
      children: [
        AppState(
          icon: AppIcons.stateError,
          title: texts.coffeeNotFound,
          description:
              code == null ? texts.coffeeNotFoundNoCode : texts.coffeeNotFoundNote,
        ),
        if (code != null) ...[
          const SizedBox(height: AppSpacing.s3),
          Center(
            child: Text(
              PackCode.format(code),
              style: context.texts.titleMedium?.copyWith(letterSpacing: 2),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s6),
        // navigate, а не maybePop: по коду с пачки сюда приходят диплинком,
        // и тогда под этим экраном нет ничего — обе кнопки просто молчали.
        // Ввод и камера живут на одной вкладке, поэтому кнопка одна.
        AppButton(
          label: texts.coffeeScanAgain,
          icon: AppIcons.uiScan,
          onPressed: () => context.router.navigate(const ScanRoute()),
        ),
        const SizedBox(height: AppSpacing.s3),
        AppButton(
          label: texts.coffeeToPacks,
          kind: AppButtonKind.secondary,
          onPressed: () => context.router.navigate(const PacksRoute()),
        ),
      ],
    );
  }

  /// Кофе снят с продажи, а пачка чужая — показать нечего, кроме имени (S12).
  Widget _withdrawn(CoffeeState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s8,
      ),
      children: [
        _WithdrawnPlate(name: state.withdrawnName, roaster: state.withdrawnRoaster),
        const SizedBox(height: AppSpacing.s6),
        AppButton(
          label: AppLocalizations.of(context).coffeeToPacks,
          kind: AppButtonKind.secondary,
          onPressed: () => context.router.navigate(const PacksRoute()),
        ),
      ],
    );
  }

  /// Сеть не ответила (S13). Если в памяти лежит свежий рецепт — по нему
  /// можно заваривать прямо сейчас, об этом и говорим.
  Widget _failed(CoffeeState state) {
    return _OfflineFallback(
      error: state.error,
      onRetry: () => ref
          .read(coffeeStateProvider.notifier)
          .open(code: widget.code, packId: widget.packId),
    );
  }

  Widget _ready(CoffeeState state) {
    final pack = state.pack!;
    final descriptors = pack.packDescriptors ?? const <String>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s2,
        AppSpacing.s5,
        AppSpacing.s8,
      ),
      children: [
        // Пачка на полке никуда не делась: снятие с продажи — обычный случай,
        // и рецепты остаются доступны (DECISIONS §2.3). Плашка, а не тупик.
        if (state.withdrawn) ...[
          _WithdrawnPlate(name: pack.packName, roaster: ''),
          const SizedBox(height: AppSpacing.s4),
        ],
        _PackHeader(pack: pack),
        // Обещает именно обжарщик, а не мы. У пачки, заведённой руками,
        // обжарщика нет: дескрипторы в неё вписал сам человек, и выдавать их
        // за чужое обещание — неправда. Раньше блок показывался всегда, и на
        // ручной пачке в нём висел одинокий чип с обрывком слова.
        if (pack.roasterName.isNotEmpty && descriptors.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            AppLocalizations.of(context).coffeeRoasterPromises,
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: AppSpacing.s2),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [for (final descriptor in descriptors) AppChip(label: descriptor)],
          ),
        ],
        if (state.lastBrewed != null) ...[
          const SizedBox(height: AppSpacing.s5),
          _QuickStart(
            method: state.lastBrewed!.method,
            date: state.lastBrewed!.date,
            onStart: () => _openMethod(state.lastBrewed!.method, pack),
          ),
        ],
        if (state.groups.isEmpty)
          const _MethodsUnavailable()
        else ...[
          const SizedBox(height: AppSpacing.s6),
          // Счётчика «рецепт есть у 1 из 20» здесь нет намеренно: он считает
          // не то, что человек выбирает. Разницу несёт сама строка метода —
          // с рецептом поднятая и белая, без рецепта прозрачная.
          Text(AppLocalizations.of(context).methodsTitle, style: context.texts.titleMedium),
          for (final group in state.groups) ...[
            _GroupHeader(group: group),
            for (final method in group.methods)
              _MethodRow(
                method: method,
                onTap: () => _openMethod(method, pack),
              ),
          ],
        ],
      ],
    );
  }
}

/// «Этой партии больше нет в продаже» — жёлтая плашка, не тупик (S12).
class _WithdrawnPlate extends StatelessWidget {
  const _WithdrawnPlate({required this.name, required this.roaster});

  final String name;
  final String roaster;

  @override
  Widget build(BuildContext context) {
    final what = [name, roaster].where((it) => it.isNotEmpty).join(' · ');
    final texts = AppLocalizations.of(context);

    return QuietSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIcons.uiInfo, size: AppSizes.icon20, color: context.colors.tertiary),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: texts.coffeeWithdrawnTitle,
                  style: context.texts.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: texts.coffeeWithdrawnNote(what.isEmpty ? '' : ' ($what)'),
                ),
              ]),
              style: context.texts.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Сети нет, но заваривать можно: из памяти достаётся последний рецепт (S13).
class _OfflineFallback extends StatefulWidget {
  const _OfflineFallback({required this.onRetry, this.error});

  final VoidCallback onRetry;
  final String? error;

  @override
  State<_OfflineFallback> createState() => _OfflineFallbackState();
}

class _OfflineFallbackState extends State<_OfflineFallback> {
  CachedBrew? _cached;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    LastBrewCache.load().then((cached) {
      if (!mounted) return;
      setState(() {
        _cached = cached;
        _checked = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cached = _cached;
    final texts = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s8,
      ),
      children: [
        QuietSurface(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(AppIcons.stateOffline, size: AppSizes.icon20, color: context.colors.tertiary),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  cached == null
                      ? texts.coffeeOfflineNoCache
                      : texts.coffeeOfflineCached(_when(texts, cached.savedAt)),
                  style: context.texts.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(texts.coffeeOfflineCantTitle, style: context.texts.bodyMedium),
        const SizedBox(height: AppSpacing.s2),
        _OfflineRow(
          icon: AppIcons.uiScan,
          title: texts.coffeeOfflineScan,
          note: texts.coffeeOfflineScanNote,
        ),
        _OfflineRow(
          icon: AppIcons.uiStar,
          title: texts.coffeeOfflineRating,
          note: texts.coffeeOfflineRatingNote,
        ),
        _OfflineRow(
          icon: AppIcons.uiRefresh,
          title: texts.coffeeOfflineCorrection,
          note: texts.coffeeOfflineCorrectionNote,
        ),
        const SizedBox(height: AppSpacing.s6),
        if (_checked && cached != null) ...[
          AppButton(
            label: texts.coffeeBrewCached,
            icon: AppIcons.uiPlay,
            onPressed: () => context.router.push(
              BrewRoute(recipe: cached.recipe, pack: cached.pack),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
        ],
        AppButton(
          label: texts.retry,
          kind: AppButtonKind.secondary,
          onPressed: widget.onRetry,
        ),
      ],
    );
  }

  static String _when(AppLocalizations texts, DateTime savedAt) =>
      formatDayMonth(texts, savedAt);
}

class _OfflineRow extends StatelessWidget {
  const _OfflineRow({required this.icon, required this.title, required this.note});

  final String icon;
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: Row(
        children: [
          AppIcon(icon, size: AppSizes.icon20, color: context.colors.secondary),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.texts.bodySmall),
                Text(note, style: context.texts.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Шапка зерна: название, происхождение, обжарщик и оценка.
class _PackHeader extends StatelessWidget {
  const _PackHeader({required this.pack});

  final PackData pack;

  @override
  Widget build(BuildContext context) {
    final origin = [pack.packCountry, pack.packVariety].where((it) => it.isNotEmpty).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pack.packName, style: context.texts.titleLarge),
        if (origin.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s1),
          Text(origin, style: context.texts.bodySmall),
        ],
      ],
    );
  }
}

/// Быстрый старт: чем заваривали это зерно в прошлый раз.
///
/// Поднят тенью и стоит выше списка из двадцати строк: в девяти случаях из
/// десяти человек вернулся именно за этим, и заставлять его искать свой
/// прибор среди двадцати — то же самое, что не помнить его выбор.
class _QuickStart extends StatelessWidget {
  const _QuickStart({required this.method, required this.date, required this.onStart});

  final CoffeeMethod method;
  final String date;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return HeroSurface(
      child: Row(
        children: [
          AppIcon(
            AppIcons.method(method.iconKey),
            size: AppSizes.icon40,
            color: context.colors.primary,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.name,
                  style: context.texts.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  texts.coffeeLastBrewed(formatRecipeDate(texts, date)),
                  style: context.texts.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          _PlayButton(onTap: onStart, label: texts.coffeeBrewOn(method.name)),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: context.colors.primary,
        borderRadius: AppRadius.rounded,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rounded,
          child: SizedBox(
            height: AppSizes.tapTarget,
            width: AppSizes.tapTarget,
            child: Center(
              child: AppIcon(
                AppIcons.uiPlay,
                size: AppSizes.icon20,
                color: context.colors.secondaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Заголовок группы методов со счётчиком рецептов.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final CoffeeMethodGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s4, bottom: AppSpacing.s2),
      child: Text(
        group.slug == otherGroupSlug
            ? AppLocalizations.of(context).svcGroupOther
            : group.name,
        style: context.texts.bodyMedium,
      ),
    );
  }
}

/// Строка метода.
///
/// Метка «рецепт есть» в каждой второй строке превращала список в лоскутное
/// одеяло, поэтому разницу несёт сама строка: с рецептом — поднятая и белая,
/// без рецепта — прозрачная и приглушённая.
class _MethodRow extends StatelessWidget {
  const _MethodRow({required this.method, required this.onTap});

  final CoffeeMethod method;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = AppIcons.method(method.iconKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.medium,
          boxShadow: method.hasRecipe ? context.shadows.level1 : null,
        ),
        child: Material(
          color: method.hasRecipe ? context.colors.secondaryContainer : Colors.transparent,
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
                border: Border.all(color: context.palette.border),
              ),
              child: Row(
                children: [
                  Opacity(
                    opacity: method.hasRecipe ? 1 : 0.45,
                    child: AppIcon(icon, size: AppSizes.icon24),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Text(
                      method.name,
                      style: method.hasRecipe
                          ? context.texts.bodyMedium
                          : context.texts.bodyMedium?.copyWith(color: context.colors.secondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Справочник методов не открылся. Зерно при этом показано — экран не пустой,
/// и человеку видно, что именно не загрузилось.
class _MethodsUnavailable extends StatelessWidget {
  const _MethodsUnavailable();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s6),
      child: QuietSurface(
        child: Row(
          children: [
            AppIcon(
              AppIcons.uiWarning,
              size: AppSizes.icon20,
              color: context.colors.secondary,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                AppLocalizations.of(context).coffeeMethodsFailed,
                style: context.texts.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
