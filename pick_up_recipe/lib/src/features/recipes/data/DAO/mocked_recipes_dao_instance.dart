import 'dart:convert';

import 'package:pick_up_recipe/src/features/recipes/data/DAO/recipes_dao.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';

import 'package:pick_up_recipe/src/mocked_recipes.dart';

class MockedLatestRecipesDAOInstance implements RecipesDAO {
  List<RecipeData> latestRecipes = [];

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
    final data1 = json.decode(mockedJson1);
    final data2 = json.decode(mockedJson2);
    final data3 = json.decode(mockedJson3);

    List<RecipeData> newRecipes = [];

    newRecipes.add(RecipeData.fromJson(data1));
    newRecipes.add(RecipeData.fromJson(data2));
    newRecipes.add(RecipeData.fromJson(data3));

    latestRecipes = newRecipes;

    return latestRecipes;
  }

  @override
  List<RecipeData> getRecipes() {
    return latestRecipes;
  }

  @override
  Future<RecipeData> generateRecipe(String device, int packId) {
    throw UnimplementedError();
  }
}
