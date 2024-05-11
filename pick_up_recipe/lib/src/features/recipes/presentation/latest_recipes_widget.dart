import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/src/features/recipes/data/DAO/latest_recipes_dao.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/presentation/recipe_small_card_widget.dart';

class LatestRecipesWidget extends StatefulWidget {
  const LatestRecipesWidget({super.key});

  @override
  State<LatestRecipesWidget> createState() => _LatestRecipesWidgetState();
}

class _LatestRecipesWidgetState extends State<LatestRecipesWidget> {
  bool loaded = false;
  List<RecipeData> latestRecipes = [];
  GetIt getIt = GetIt.instance;
  late final LatestRecipesDAO dao;

  @override
  void initState() {
    dao = getIt.get<LatestRecipesDAO>();
    loaded = false;
    super.initState();
    fetchRecipes(dao);
    print(dao);
  }

  Future<void> fetchRecipes(LatestRecipesDAO dao) async {
    setState(() {
      loaded = false;
    });
    latestRecipes = await dao.fetchRecipes();
    setState(() {
      loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      // padding: const EdgeInsets.only(top: 10),
      itemCount: latestRecipes.length,
      itemBuilder: (context, index) {
        return RecipeSmallCardWidget(recipe: latestRecipes[index]);
      },
    );
  }
}
