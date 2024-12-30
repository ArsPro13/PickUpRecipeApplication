import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_tag_model.dart';

class RecipeTagsWidget extends StatelessWidget {
  const RecipeTagsWidget({super.key, required this.tags});

  final List<RecipeTag> tags;

  @override
  Widget build(BuildContext context) {
    List<Widget> tagWidgets = [];
    for (int i = 0; i < tags.length; ++i) {
      tagWidgets.add(RecipeTagWidget(tag: tags[i]));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: tagWidgets,
      ),
    );
  }
}

class RecipeTagWidget extends StatelessWidget {
  const RecipeTagWidget({super.key, required this.tag});

  final RecipeTag tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: tag.color.withValues(alpha: 0.3),
      ),
      height: 35,
      width: 145,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 7, right: 4),
            child: Icon(
              tag.icon,
              size: 21,
            ),
          ),
          Text(tag.name),
        ],
      ),
    );
  }
}
