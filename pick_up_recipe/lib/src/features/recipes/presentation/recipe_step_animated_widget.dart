import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';

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
    bool has_finished = (widget.sec >= widget.step.stop);

    double progress = (widget.sec - widget.step.start) /
        (widget.step.stop - widget.step.start);
    progress = min(1, max(0, progress));

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text('Этап: ${widget.step.instruction}'),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('Количество воды: ${widget.step.water} мл'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                      'Длительность: ${widget.step.stop - widget.step.start} сек.'),
                ),
              ],
            ),
            Container(
              width: 120,
              height: 120,
                child: CircularPercentIndicator(
                  radius: 60,
                  // value: progress,
                  // strokeWidth: 10,
                  percent: progress,
                  lineWidth: has_finished ? 10 : 8,
                  center: Text('${(progress * (widget.step.stop - widget.step.start) * 10).round() / 10} сек.'),
                  progressColor: (
                      has_finished
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(context).colorScheme.primary),
                  backgroundColor: const Color.fromARGB(255, 210, 210, 210),
                  // semanticsLabel: 'Progress indicator',
                ),

            ),
          ],
        ),
      ),
    );
  }
}
