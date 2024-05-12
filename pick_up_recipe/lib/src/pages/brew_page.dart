import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/presentation/recipe_step_animated_widget.dart';

int getDuration(RecipeData recipe) {
  return recipe.steps[recipe.steps.length - 1].stop;
}

class BrewPage extends StatefulWidget {
  const BrewPage({
    super.key,
    required this.recipe,
  });

  final RecipeData recipe;

  @override
  State<BrewPage> createState() => _BrewPageState();
}

class _BrewPageState extends State<BrewPage>
    with SingleTickerProviderStateMixin<BrewPage> {
  bool _is_animation_running = false;

  late final _controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: getDuration(widget.recipe)),
  )..addListener(_update);

  late final _anim = _controller.view;

  @override
  void dispose() {
    _controller.removeListener(_update);
    _controller.dispose();
    super.dispose();
  }

  void _update() => setState(() {});

  Widget stepsWidgetsColumn(List<RecipeStep> steps) {
    List<Widget> list = [];
    for(var i = 0; i < steps.length; ++i){
      list.add(RecipeStepAnimatedWidget(
        step:widget.recipe.steps[i],
        sec: getDuration(widget.recipe) * _anim.value,
      ),);
    }
    return Column(children: list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(top: 80),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.coffee_maker),
              Text(
                'Device: ${widget.recipe.device}',
                style: const TextStyle(fontSize: 20),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Coffee: ${widget.recipe.pack.packName}',
                style: const TextStyle(fontSize: 18),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_is_animation_running) {
                      _controller.stop();
                    } else {
                      _controller.forward();
                    }
                    setState(() {
                      _is_animation_running = !_is_animation_running;
                    });
                  },
                  child: Text(_is_animation_running
                      ? 'Stop brewing'
                      : 'Start brewing!'),
                ),
                const SizedBox(
                  width: 20,
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Icon(Icons.edit),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Прогресс: ${((getDuration(widget.recipe) * _anim.value * 10).round() / 10).toString()} сек.',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          stepsWidgetsColumn(widget.recipe.steps),
        ],
      ),
    );
  }
}
