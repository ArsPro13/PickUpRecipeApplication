import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/core/enums.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipe_choosing_state_notifier.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';

class RecipeChoosingState {
  final List<RecipeData>? recipes;
  final BrewingMethods? brewingMethod;
  final bool isLoading;

  const RecipeChoosingState({
    this.recipes,
    this.brewingMethod,
    this.isLoading = false,
  });

  RecipeChoosingState copyWith({List<RecipeData>? recipes, BrewingMethods? brewingMethod, bool? isLoading}) {
    return RecipeChoosingState(
      recipes: recipes ?? this.recipes,
      brewingMethod: brewingMethod ?? this.brewingMethod,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<Object?> get props => [recipes];
}

final recipeChoosingNotifierProvider =
    StateNotifierProvider<RecipeChoosingStateNotifier, RecipeChoosingState>(
  (ref) => RecipeChoosingStateNotifier(),
);
