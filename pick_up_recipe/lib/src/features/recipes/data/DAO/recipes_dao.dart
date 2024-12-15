import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';

abstract interface class RecipesDAO {
  Future<List<RecipeData>> fetchRecipes(
      {int? packId,
      int? grinderId,
      int? grindStep,
      int? grindSubStep,
      String? device,
      String? startDate,
      String? endDate,
      int? offset,
      int? limit,
      String? sortBy});

  List<RecipeData> getRecipes();

  Future<RecipeData?> generateRecipe(String device, int packId);
}
