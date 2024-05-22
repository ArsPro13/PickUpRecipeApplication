import 'dart:convert';

import 'package:pick_up_recipe/src/features/recipes/data/DAO/latest_recipes_dao.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';

import '../../../../mocked_recipes.dart';



class MockedLatestRecipesDAOInstance implements LatestRecipesDAO {
  List<RecipeData> latestRecipes = [];

  @override
  Future<List<RecipeData>> fetchRecipes() async {
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
}