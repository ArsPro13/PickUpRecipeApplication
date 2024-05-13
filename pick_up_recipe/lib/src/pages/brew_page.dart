import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
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
    List<Widget> stepsList = [];
    for (var i = 0; i < steps.length; ++i) {
      stepsList.add(
        RecipeStepAnimatedWidget(
          step: widget.recipe.steps[i],
          sec: getDuration(widget.recipe) * _anim.value,
        ),
      );
    }
    return SliverList.builder(
      itemCount: stepsList.length,
      itemBuilder: (BuildContext context, int index) {
        return stepsList[index];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        // padding: const EdgeInsets.only(top: 80),
        slivers: [
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              minHeight: 50,
              maxHeight: 70,
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 30,
                    ),
                    tooltip: 'Return to the main page',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    'Device: ${widget.recipe.device}',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                Text(
                  'Coffee: ${widget.recipe.pack.packName}',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          SliverPadding(
            sliver: SliverToBoxAdapter(
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
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          stepsWidgetsColumn(widget.recipe.steps),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => max(maxHeight, minHeight);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
