import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/presentation/recipe_tags_widget.dart';

import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_tag_model.dart';

String convertDate(String date) {
  return '${date.substring(8, 10)}.${date.substring(5, 7)}.${date.substring(0, 4)}';
}

Widget getTags(RecipeData recipe) {
  List<RecipeTag> tags = [];

  tags.add(RecipeTag(
      icon: Icons.coffee_maker_outlined,
      name: recipe.device.toString(),
      color: Colors.orange));
  tags.add(RecipeTag(
      icon: Icons.scale_outlined,
      name: '${recipe.load.toString()} г',
      color: const Color.fromARGB(255, 154, 126, 101)));
  tags.add(RecipeTag(
      icon: Icons.water_drop_outlined,
      name: '${recipe.water.toString()} мл',
      color: Colors.blueAccent));
  tags.add(RecipeTag(
      icon: Icons.blur_on_sharp,
      name:
          '${recipe.grindStep.toString()}.${recipe.grindSubStep.toString()} click',
      color: const Color.fromARGB(255, 205, 166, 255)));

  return RecipeTagsWidget(tags: tags);
}

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
    return GestureDetector(
      onTap: () {
        context.router.push(BrewRoute(recipe: widget.recipe));
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 170,
        ),
        child: Container(
          margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 210,
                height: 250,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: Image.memory(
                      base64Decode(widget.recipe.pack.packImage),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Text(
                        widget.recipe.pack.packName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 21),
                      ),
                    ),
                    Text('Заварено ${convertDate(widget.recipe.date)}'),
                    getTags(widget.recipe),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
