import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/enums.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipe_choosing_state.dart';
import 'package:pick_up_recipe/src/features/recipes/data/DAO/recipes_dao.dart';

class RecipeChoosingStateNotifier extends StateNotifier<RecipeChoosingState> {
  RecipeChoosingStateNotifier() : super(const RecipeChoosingState());

  GetIt getIt = GetIt.instance;

  void clearRecipes() {
    state = state.copyWith(recipes: null, brewingMethod: null);
  }

  Future<void> fetchRecipes(int? packId, int? grinderId, int? grindStep, int? grindSubStep, String? device, String? startDate, String? endDate, int? offset, int? limit, String? sortBy) async {
    final RecipesDAO dao = getIt.get<RecipesDAO>();
    state = state.copyWith(isLoading: true);
    final recipes = await dao.fetchRecipes(packId: packId, grinderId: grinderId, grindStep: grindStep, grindSubStep: grindSubStep, device: device, startDate: startDate, endDate: endDate, offset: offset, limit: limit, sortBy: sortBy);
    state = state.copyWith(recipes: recipes, isLoading: false);
  }

  void setBrewingMethod(BrewingMethods? method) {
    state = state.copyWith(brewingMethod: method);
  }

  void onGenerateTapped() {
    state = state.copyWith();
  }
}
