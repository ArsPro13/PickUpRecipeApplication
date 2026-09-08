// Экран «Чем заварить» — выбор метода под конкретное зерно.
//
// Все двадцать методов, сгруппированные по виду (пуровер, иммерсия, давление,
// холодный). «Мои приборы» список не фильтруют, а поднимают наверх (ответ C9):
// человек, купивший аэропресс сегодня, не должен искать его в настройках.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../features/brew_methods/application/brew_methods_state.dart';
import '../features/recipes/domain/models/step_type_model.dart';
import '../general_widgets/app_kit.dart';
import '../themes/app_icons.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class RecipesForCoffeePage extends ConsumerStatefulWidget {
  const RecipesForCoffeePage({super.key, @QueryParam('pack') this.packId});

  final int? packId;

  @override
  ConsumerState<RecipesForCoffeePage> createState() => _RecipesForCoffeePageState();
}

class _RecipesForCoffeePageState extends ConsumerState<RecipesForCoffeePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(brewMethodsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(brewMethodsProvider);
    final texts = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(texts.methodsTitle)),
      body: switch (state.status) {
        BrewMethodsStatus.loading => const Center(child: CircularProgressIndicator()),
        BrewMethodsStatus.failed => AppState(
            icon: AppIcons.stateError,
            title: texts.methodsFailed,
            description: state.error,
            isError: true,
            primaryAction: AppButton(
              label: texts.retry,
              onPressed: () => ref.read(brewMethodsProvider.notifier).load(),
            ),
          ),
        BrewMethodsStatus.ready => _list(state),
      },
    );
  }

  Widget _list(BrewMethodsState state) {
    final texts = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      children: [
        for (final group in state.grouped) ...[
          SectionTitle(
            group.slug == otherGroupSlug ? texts.svcGroupOther : group.name,
          ),
          for (final method in group.methods)
            AppRow(
              label: method.name,
              icon: AppIcons.method(method.iconKey),
              onTap: () => context.router.push(
                ChoosingRecipeRoute(
                  packId: widget.packId ?? 0,
                  method: method.slug,
                  methodName: method.name,
                ),
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.s6),
      ],
    );
  }
}
