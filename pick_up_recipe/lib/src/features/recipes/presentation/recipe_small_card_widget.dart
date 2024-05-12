import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';

String convertDate(String date) {
  return '${date.substring(11, 19)} ${date.substring(0, 10)}';
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
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
          width: .5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.memory(
                base64Decode(widget.recipe.pack.packImage),
                height: 70,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.recipe.pack.packName,
                  style: const TextStyle(fontSize: 24),
                ),
                Text(convertDate(widget.recipe.date)),
                Text('Made on ${widget.recipe.device}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
