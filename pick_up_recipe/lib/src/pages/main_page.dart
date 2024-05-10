import 'package:flutter/material.dart';
import 'package:pick_up_recipe/src/features/recipes/presentation/latest_recipes_widget.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        LatestRecipesWidget(),
      ],
    );
  }

}