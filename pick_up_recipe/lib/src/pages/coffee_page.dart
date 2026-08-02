// Страница кофе — то, куда ведёт код с упаковки.
//
// Открывается двумя путями: по коду (диплинк и ручной ввод) и по пачке из
// списка. Оба приводят к одному экрану — страница кофе одна, «кофе без
// рецептов» отдельным экраном не делается.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/app_router.dart';
import '../features/codes/application/coffee_state.dart';
import '../features/codes/domain/pack_code.dart';
import '../general_widgets/app_kit.dart';
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

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        Text(pack.packName, style: context.texts.titleLarge),
        const SizedBox(height: AppSpacing.s1),
        Text(
          [pack.packCountry, pack.packVariety].where((it) => it.isNotEmpty).join(' · '),
          style: context.texts.bodySmall,
        ),
        if (pack.packDescriptors != null && pack.packDescriptors!.isNotEmpty) ...[
          const SectionTitle('Обжарщик обещает'),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              for (final descriptor in pack.packDescriptors!) AppChip(label: descriptor),
            ],
          ),
        ],
        const SectionTitle('Чем заварить'),
        AppButton(
          label: 'Выбрать метод',
          onPressed: () => context.router.push(RecipesForCoffeeRoute(packId: pack.packId)),
        ),
      ],
    );
  }
}
