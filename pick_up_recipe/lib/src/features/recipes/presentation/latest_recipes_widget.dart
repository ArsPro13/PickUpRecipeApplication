import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/presentation/recipe_small_card_widget.dart';

class LatestRecipesWidget extends ConsumerStatefulWidget {
  const LatestRecipesWidget({
    super.key,
    this.packId,
    this.limit,
  });

  final int? packId;
  final int? limit;

  @override
  ConsumerState<LatestRecipesWidget> createState() =>
      _LatestRecipesWidgetState();
}

class _LatestRecipesWidgetState extends ConsumerState<LatestRecipesWidget> {
  bool loaded = false;
  List<RecipeData> latestRecipes = [];
  GetIt getIt = GetIt.instance;

  @override
  void initState() {
    loaded = false;
    super.initState();
    Future(() {
      fetchRecipes();
    });
  }

  Future<void> fetchRecipes() async {
    setState(() {
      loaded = false;
    });

    final recipeService = RecipeService();

    latestRecipes = await recipeService.getByParams(
          packId: widget.packId,
          limit: widget.limit,
        ) ??
        [];

    setState(() {
      loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reversedRecipes = latestRecipes.reversed.toList();
    return loaded
        ? SliverList.builder(
            itemCount: reversedRecipes.length,
            itemBuilder: (context, index) {
              return RecipeSmallCardWidget(recipe: reversedRecipes[index]);
            },
          )
        : SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 70),
              child: SpinKitWaveSpinner(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          );
  }
}
