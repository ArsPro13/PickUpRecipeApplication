// Экран 02 «Мои пачки» — корень приложения.
//
// Пачка — это то, что стоит на кухне, поэтому приложение открывается ею,
// а не списком рецептов. Кофемолка вынесена кнопкой в шапку: от неё зависят
// щелчки в каждом рецепте, и менять её приходится чаще, чем что-либо в профиле.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../routing/app_router.dart';
import '../features/grinders/application/grinder_state.dart';
import '../features/packs/application/state/active_packs_state.dart';
import '../features/packs/domain/models/pack_model.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../themes/app_icons.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final packs = ref.watch(activePacksNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои пачки'),
        actions: const [GrinderButton(), SizedBox(width: AppSpacing.s4)],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(activePacksNotifierProvider.notifier).fetchPacks(),
        child: _body(packs),
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
            title: 'Пачек пока нет',
            description: 'Отсканируйте код с упаковки — рецепт обжарщика подтянется сам',
            primaryAction: AppButton(
              label: 'Сканировать код',
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
              label: 'Добавить пачку',
              icon: AppIcons.uiPlus,
              kind: AppButtonKind.secondary,
              onPressed: () => AutoTabsRouter.of(context).setActiveIndex(2),
            ),
          );
        }

        final pack = packs.activePacks[index];
        return PackCard(
          pack: pack,
          onTap: () => context.router.push(CoffeeRoute(packId: pack.packId)),
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
      label: 'Сменить кофемолку',
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
                  primary?.name ?? 'Выбрать кофемолку',
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

/// Карточка пачки: фото, название, обжарщик и дата.
class PackCard extends StatelessWidget {
  const PackCard({super.key, required this.pack, this.onTap});

  final PackData pack;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Row(
        children: [
          _Photo(image: pack.packImage),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
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
                  [pack.packCountry, pack.packVariety].where((it) => it.isNotEmpty).join(' · '),
                  style: context.texts.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AppIcon(
            AppIcons.uiForward,
            size: AppSizes.icon20,
            color: context.colors.secondary,
          ),
        ],
      ),
    );
  }
}

/// Фото пачки. Приходит base64-строкой прямо из БД.
class _Photo extends StatelessWidget {
  const _Photo({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.s16,
      width: AppSpacing.s12,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadius.small,
      ),
      clipBehavior: Clip.antiAlias,
      child: PackImage(base64Image: image),
    );
  }
}

/// Картинка пачки с запасным значком.
///
/// Отдельным виджетом: битая или пустая строка встречается часто — фото
/// хранится в базе, а не в файловом хранилище, и обрезается при переносах.
class PackImage extends StatelessWidget {
  const PackImage({super.key, required this.base64Image, this.fit = BoxFit.cover});

  final String base64Image;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final bytes = decodePackImage(base64Image);

    if (bytes == null) {
      return Center(
        child: AppIcon(
          AppIcons.uiPack,
          size: AppSizes.icon24,
          color: context.colors.secondary,
        ),
      );
    }

    return Image.memory(
      bytes,
      fit: fit,
      errorBuilder: (context, _, __) => Center(
        child: AppIcon(
          AppIcons.uiPack,
          size: AppSizes.icon24,
          color: context.colors.secondary,
        ),
      ),
    );
  }
}
