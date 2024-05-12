import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
        child: Column(
          children: [
            Text('Этап: ${widget.step.instruction}'),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Количество воды: ${widget.step.water} мл'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Длительность: ${widget.step.stop - widget.step.start} сек.'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Прошло: ${(progress * (widget.step.stop - widget.step.start)).round()} сек.'),
            ),
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 0),
              width: 350,
              height: 15,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: LinearProgressIndicator(
                  value: progress,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  backgroundColor: const Color.fromARGB(255, 210, 210, 210),
                  semanticsLabel: 'Progress indicator',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
