import 'dart:math';

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';

import '../domain/models/recipe_data_model.dart';
import '../domain/models/recipe_tag_model.dart';

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
    bool hasFinished = (widget.sec >= widget.step.stop);
    bool isRunning = (widget.sec <= widget.step.stop &&
        widget.sec > widget.step.start);

    double progress = (widget.sec - widget.step.start) /
        (widget.step.stop - widget.step.start);
    progress = min(1, max(0, progress));

    return Container(
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .colorScheme
            .onBackground,
        borderRadius: BorderRadius.circular(15),
        border: isRunning ? Border.all(
          color: Theme
              .of(context)
              .colorScheme
              .primary,
          width: 3,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: isRunning ? Theme
                .of(context)
                .colorScheme
                .primary
                .withOpacity(0.2) : Colors.grey.withOpacity(0.5),
            spreadRadius: 3,
            blurRadius: 4,
            offset: const Offset(0, 4), // changes position of shadow
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
                Text('Этап: ${widget.step.instruction}'),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('Количество воды: ${widget.step.water} мл'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                      'Длительность: ${widget.step.stop -
                          widget.step.start} сек.'),
                ),
              ],
            ),
            Container(
              width: 160,
              height: 160,
              child: CircularPercentIndicator(
                radius: 80,
                percent: progress,
                lineWidth: hasFinished ? 10 : 8,
                center: Text(
                    '${(progress * (widget.step.stop - widget.step.start) * 10)
                        .round() / 10} сек.'),
                progressColor: (
                    hasFinished
                        ? Theme
                        .of(context)
                        .colorScheme
                        .outline
                        : Theme
                        .of(context)
                        .colorScheme
                        .primary),
                backgroundColor: const Color.fromARGB(255, 210, 210, 210),
              ),

            ),
          ],
        ),
      ),
    );
  }
}