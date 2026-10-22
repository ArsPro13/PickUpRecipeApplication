// Экран 07 «Рецепты» — вторая вкладка.
//
// Группа — пара «кофе + метод» (ответ Q23b), а не цепочка prev_id/next_id: на
// экране это выглядит одинаково, но владелец выбрал пару. Каждая группа —
// стопка версий: её карточки, барабан и подписи живут в
// general_widgets/recipe_deck.dart, потому что та же стопка стоит и на
// странице зерна. Здесь — только список стопок и его пустые состояния.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../features/packs/application/state/active_packs_state.dart';
import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/application/state/recipes_list_state.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/recipe_deck.dart';
import '../themes/app_icons.dart';
import '../themes/app_tokens.dart';

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
    // Справочник виденных пачек, а не страница полки: заваривание могло быть
    // по пачке, которая лежит дальше прочитанных страниц. Недостающие
    // дочитываются точечно — см. _body.
    final packs = ref.watch(activePacksNotifierProvider).known;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).recipesTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(recipesListProvider.notifier).load(),
        child: _body(state, packs),
      ),
    );
  }

  Widget _body(RecipesListState state, Map<int, PackData> packs) {
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
            title: AppLocalizations.of(context).recipesFailed,
            // Не текст исключения: он всегда по-русски и человеку
            // говорит только код ответа. Причина уходит в журнал.
            description: AppLocalizations.of(context).svcLoadFailedNote,
            isError: true,
            primaryAction: AppButton(
              label: AppLocalizations.of(context).retry,
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
            title: AppLocalizations.of(context).recipesEmpty,
            description: AppLocalizations.of(context).recipesEmptyNote,
            primaryAction: AppButton(
              label: AppLocalizations.of(context).recipesToPacks,
              onPressed: () => AutoTabsRouter.of(context).setActiveIndex(0),
            ),
          ),
        ],
      );
    }

    // Пачки, о которых история знает, а полка ещё нет. Просим их один раз
    // за построение списка: ensurePacks сам отсеет уже известные, а запрос
    // на пачку кэширован.
    final missing = state.groups
        .map((group) => group.packId)
        .where((id) => !packs.containsKey(id))
        .toSet();
    if (missing.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(activePacksNotifierProvider.notifier).ensurePacks(missing);
      });
    }

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
        return RecipeDeck(
          group: group,
          pack: packs[group.packId],
          // Единственный главный элемент экрана — верхняя карточка первой
          // группы. Поднимать все значит не поднять ни одну.
          hero: index == 0,
          first: index == 0,
        );
      },
    );
  }
}
