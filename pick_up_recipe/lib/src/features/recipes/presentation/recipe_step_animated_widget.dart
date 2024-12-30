import 'dart:math';

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/presentation/recipe_icon_widget.dart';

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
    required this.start,
  });

  final RecipeStep step;
  final double sec;
  final int start;

  @override
  State<RecipeStepAnimatedWidget> createState() =>
      _RecipeStepAnimatedWidgetState();
}

class _RecipeStepAnimatedWidgetState extends State<RecipeStepAnimatedWidget> {
  @override
  Widget build(BuildContext context) {
    bool hasFinished = (widget.sec >= widget.step.time + widget.start);
    bool isRunning = (widget.sec <= widget.step.time + widget.start &&
        widget.sec > widget.start);

    double progress = (widget.sec - widget.start) / (widget.step.time);
    progress = min(1, max(0, progress));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
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
                ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)
                : Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.2),
            spreadRadius: 3,
            blurRadius: 5,
            offset: const Offset(0, 1), // changes position of shadow
          ),
        ],
      ),
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.step.instruction,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    RecipeIconWidget(
                      value: '${widget.step.time} с',
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
            const SizedBox(
              width: 20,
            ),
            Expanded(
              child: CircularPercentIndicator(
                radius: 80,
                percent: progress,
                lineWidth: hasFinished ? 10 : 8,
                center: Text(
                  '${(progress * (widget.step.time) * 10).round() / 10}',
                  style: const TextStyle(fontSize: 25),
                ),
                progressColor: (hasFinished
                    ? Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.secondary),
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
