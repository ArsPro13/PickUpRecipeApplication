import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/enums.dart';
import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipe_choosing_state.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/presentation/latest_recipes_widget.dart';
import 'package:pick_up_recipe/src/general_widgets/buttons/app_button.dart';
import 'package:pick_up_recipe/src/general_widgets/dropdown/custom_dropdown.dart';

@RoutePage()
class ChoosingRecipePage extends ConsumerStatefulWidget {
  const ChoosingRecipePage({super.key, required this.packId});

  final int packId;

  @override
  ConsumerState<ChoosingRecipePage> createState() => _ChoosingRecipePageState();
}

class _ChoosingRecipePageState extends ConsumerState<ChoosingRecipePage> {
  final brewingMethods =
      BrewingMethods.values.map((e) => e.getTitle()).toList();
  final getIt = GetIt.instance;
  int sliverListKeyValue = 0;

  @override
  void initState() {
    super.initState();
    Future(
      () => ref
          .read(recipeChoosingNotifierProvider.notifier)
          .setBrewingMethod(BrewingMethods.all),
    );
  }

  void _onSelectBrewingMethod(String method) {
    logger.i('Selected brewing method: ${method.toBrewingMethod()}');
    ref
        .read(recipeChoosingNotifierProvider.notifier)
        .setBrewingMethod(method.toBrewingMethod());
  }

  void _onGenerateTap() async {
    final method = ref.read(recipeChoosingNotifierProvider).brewingMethod;

    final recipeService = RecipeService();
    final generatedRecipe = await recipeService.generateRecipe(
        method?.getName() ?? '', widget.packId);

    logger.i('Generated new recipe for: ${generatedRecipe?.device}');

    if (mounted) {
      setState(() {
        ++sliverListKeyValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeChoosingNotifierProvider);
    final method = state.brewingMethod;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.router.maybePop();
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: CustomDropdown(
                placeholder: 'Choose brewing method',
                items: brewingMethods,
                onSelect: _onSelectBrewingMethod,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 20),
              sliver: SliverToBoxAdapter(
                child: AppButton(
                  onTap: _onGenerateTap,
                  isActive: method != BrewingMethods.all,
                  centerWidget: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (method != BrewingMethods.all)
                          const Text(
                            'Generate',
                            style: TextStyle(fontSize: 24),
                          ),
                        method != BrewingMethods.all
                            ? Text(
                                'recipe for ${method?.getTitle()}',
                                style: const TextStyle(fontSize: 14),
                              )
                            : const Text(
                                'Choose brewing method to generate',
                                style: TextStyle(fontSize: 18),
                              ),
                      ],
                    ),
                  ),
                  buttonStyle: AppButtonStyle.secondary,
                ),
              ),
            ),
            LatestRecipesWidget(
              packId: widget.packId,
              key: ValueKey(sliverListKeyValue),
            )
          ],
        ),
      ),
    );
  }
}
