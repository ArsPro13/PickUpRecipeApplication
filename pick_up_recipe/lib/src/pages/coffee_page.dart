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

import '../../routing/app_router.dart';
import '../features/codes/application/coffee_state.dart';
import '../features/codes/domain/pack_code.dart';
import '../features/packs/domain/models/pack_model.dart';
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

  void _openMethod(CoffeeMethod method, int packId) {
    context.router.push(
      ChoosingRecipeRoute(packId: packId, method: method.slug, methodName: method.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coffeeStateProvider);

    return Scaffold(
      appBar: AppBar(title: Text(state.pack?.packName ?? 'Кофе')),
      body: switch (state.status) {
        CoffeeStatus.loading => const Center(child: CircularProgressIndicator()),
        CoffeeStatus.notFound => _notFound(),
        CoffeeStatus.failed => AppState(
            icon: AppIcons.stateError,
            title: 'Не удалось открыть кофе',
            description: state.error,
            isError: true,
            primaryAction: AppButton(
              label: 'Повторить',
              onPressed: () => ref
                  .read(coffeeStateProvider.notifier)
                  .open(code: widget.code, packId: widget.packId),
            ),
          ),
        CoffeeStatus.ready => _ready(state),
      },
    );
  }

  /// Код не найден. Не тупик: у человека на руках пачка, и он пришёл сюда
  /// не просто так — предлагаем собрать рецепт по справочнику.
  Widget _notFound() {
    return AppState(
      icon: AppIcons.stateError,
      title: 'Код не найден',
      description: widget.code == null
          ? 'Такого кофе нет в системе'
          : 'Кода ${PackCode.format(widget.code!)} нет в системе. '
              'Возможно, обжарщик ещё не завёл рецепт под эту партию',
      isError: true,
      primaryAction: AppButton(
        label: 'Ввести код заново',
        kind: AppButtonKind.secondary,
        onPressed: () => context.router.maybePop(),
      ),
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
        _PackHeader(pack: pack),
        if (descriptors.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4),
          Text('Обжарщик обещает', style: context.texts.bodySmall),
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
            onStart: () => _openMethod(state.lastBrewed!.method, pack.packId),
          ),
        ],
        if (state.groups.isEmpty)
          const _MethodsUnavailable()
        else ...[
          const SizedBox(height: AppSpacing.s6),
          // Счётчика «рецепт есть у 1 из 20» здесь нет намеренно: он считает
          // не то, что человек выбирает. Разницу несёт сама строка метода —
          // с рецептом поднятая и белая, без рецепта прозрачная.
          Text('Чем заварить', style: context.texts.titleMedium),
          for (final group in state.groups) ...[
            _GroupHeader(group: group),
            for (final method in group.methods)
              _MethodRow(
                method: method,
                onTap: () => _openMethod(method, pack.packId),
              ),
          ],
        ],
      ],
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
    return HeroSurface(
      child: Row(
        children: [
          AppIcon(
            AppIcons.byKey('method-${method.iconKey}') ?? AppIcons.methodHarioV60,
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
                Text('так вы заваривали ${formatRecipeDate(date)}', style: context.texts.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          _PlayButton(onTap: onStart, label: 'Заварить на ${method.name}'),
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
      child: Text(group.name, style: context.texts.bodyMedium),
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
    final icon = AppIcons.byKey('method-${method.iconKey}') ?? AppIcons.methodHarioV60;

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
              child: Text('Способы заваривания не загрузились', style: context.texts.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
