import 'dart:math';

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/presentation/recipe_icon_widget.dart';

import '../../themes/app_theme.dart';

// Widget getTags(RecipeData recipe) {
//   List<RecipeTag> tags = [];
//
//   tags.add(RecipeTag(icon: Icons.coffee_maker_outlined,
//       name: recipe.device.toString(),
//       color: Colors.orange));
//   tags.add(RecipeTag(icon: Icons.scale_outlined,
//       name: '${recipe.load.toString()} г',
//       color: const Color.fromARGB(255, 154, 126, 101)));
//   tags.add(RecipeTag(icon: Icons.water_drop_outlined,
//       name: '${recipe.water.toString()} мл',
//       color: Colors.blueAccent));
//   tags.add(RecipeTag(icon: Icons.blur_on_sharp,
//       name: '${recipe.grindStep.toString()}.${recipe.grindSubStep
//           .toString()} click',
//       color: const Color.fromARGB(255, 205, 166, 255)));
//
//   return RecipeTagsWidget(tags: tags);
// }

class RecipeStepAnimatedWidget extends StatefulWidget {
  const RecipeStepAnimatedWidget({
    super.key,
    required this.step,
    required this.sec,
  });

  final RecipeStep step;
  final double sec;

  @override
  State<RecipeStepAnimatedWidget> createState() =>
      _RecipeStepAnimatedWidgetState();
}

class _RecipeStepAnimatedWidgetState extends State<RecipeStepAnimatedWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppTheme>() ?? AppTheme.defaultThemeData;

    bool hasFinished = (widget.sec >= widget.step.stop);
    bool isRunning =
        (widget.sec <= widget.step.stop && widget.sec > widget.step.start);

    double progress = (widget.sec - widget.step.start) /
        (widget.step.stop - widget.step.start);
    progress = min(1, max(0, progress));

    return Container(
      decoration: BoxDecoration(
        color: theme.onBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: isRunning
            ? Border.all(
                color: Theme.of(context).colorScheme.secondary,
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isRunning
                ? theme.secondaryColor.withOpacity(0.5)
                : theme.secondaryColor.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 5,
            offset: const Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.step.instruction,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 30,),
                Row(
                  children: [
                    RecipeIconWidget(
                      value: '${widget.step.stop - widget.step.start} с',
                      icon: Icons.alarm,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    RecipeIconWidget(
                      value: '${widget.step.water} мл',
                      icon: Icons.water_drop_outlined,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              width: 160,
              height: 160,
              child: CircularPercentIndicator(
                radius: 80,
                percent: progress,
                lineWidth: hasFinished ? 10 : 8,
                center: Text(
                  '${(progress * (widget.step.stop - widget.step.start) * 10).round() / 10}',
                  style: const TextStyle(fontSize: 25),
                ),
                progressColor: (hasFinished
                    ? theme.outlineColor.withOpacity(0.3)
                    : theme.secondaryColor),
                backgroundColor: theme.backgroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
