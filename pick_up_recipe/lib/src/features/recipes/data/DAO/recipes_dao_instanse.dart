
import 'package:pick_up_recipe/src/features/recipes/data/DAO/recipes_dao.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';


class RecipesDAOInstance implements RecipesDAO {
  List<RecipeData> latestRecipes = [];
  final RecipeService _recipeService = RecipeService();

  @override
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
      String? sortBy}) async {

    latestRecipes = await _recipeService.getByParams(
          packId: packId,
          grinderId: grinderId,
          grindStep: grindStep,
          grindSubStep: grindSubStep,
          device: device,
          startDate: startDate,
          endDate: endDate,
          offset: offset,
          limit: limit,
          sortBy: sortBy,
        ) ?? [];

    return latestRecipes;
  }

  @override
  List<RecipeData> getRecipes() {
    return latestRecipes;
  }

  @override
  Future<RecipeData?> generateRecipe(String device, int packId) async {
    final recipe = await _recipeService.generateRecipe(device, packId);
    return recipe;
  }
}
