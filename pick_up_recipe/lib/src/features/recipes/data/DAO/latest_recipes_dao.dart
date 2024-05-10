import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';

abstract interface class LatestRecipesDAO {
  Future<List<RecipeData>> fetchRecipes();
  List<RecipeData> getRecipes();
}