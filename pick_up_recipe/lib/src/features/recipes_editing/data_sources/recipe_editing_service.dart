import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';

class RecipeEditingService {
  final RecipeService _recipeService;

  RecipeEditingService(this._recipeService);

  Future<void> updateRecipe(RecipeData recipe) async {
    try {
      await _recipeService.updateRecipe(recipe.packId, recipe.toJson());
    } catch (e) {
      throw Exception('Failed to update recipe: $e');
    }
  }
}