import 'package:flutter/cupertino.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';

class RecipeSmallCardWidget extends StatefulWidget {
  const RecipeSmallCardWidget({
    super.key,
    required this.recipe,
  });

  final RecipeData recipe;

  @override
  State<RecipeSmallCardWidget> createState() => RecipeSmallCardWidgetState();
}

class RecipeSmallCardWidgetState extends State<RecipeSmallCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Center(
              child: Text(''),
            ),
          ],
        ),
      ],
    );
  }
}
