import 'dart:math';
import 'dart:ui';

import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/presentation/recipe_step_animated_widget.dart';

import '../features/recipes/presentation/recipe_icon_widget.dart';

int getDuration(RecipeData recipe) {
  return recipe.steps[recipe.steps.length - 1].stop;
}

@RoutePage()
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
  bool _isAnimationRunning = false;

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
      body: Stack(
        children: [
          CustomScrollView(
            // padding: const EdgeInsets.only(top: 80),
            slivers: [
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  minHeight: 50,
                  maxHeight: 70,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        child: const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: SizedBox(
                              height: 35,
                              width: 35,
                              child: Icon(Icons.arrow_back, size: 30.0)),
                        ),
                        onTap: () {
                          context.router.maybePop();
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brewed on ${widget.recipe.device}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Рецепт для зерна ${widget.recipe.pack.packName}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, bottom: 5, top: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RecipeIconWidget(
                                  value:
                                      '${widget.recipe.temperature.toString()} °C',
                                  icon: Icons.thermostat_outlined,
                                  color: Colors.orange),
                              RecipeIconWidget(
                                  value: '${widget.recipe.load.toString()} г',
                                  icon: Icons.scale_outlined,
                                  color:
                                      const Color.fromARGB(255, 154, 126, 101)),
                              RecipeIconWidget(
                                  value: '${widget.recipe.water.toString()} мл',
                                  icon: Icons.water_drop_outlined,
                                  color: Colors.blueAccent),
                              RecipeIconWidget(
                                  value:
                                      '${widget.recipe.grindStep.toString()}.${widget.recipe.grindSubStep.toString()} click',
                                  icon: Icons.blur_on_sharp,
                                  color:
                                      const Color.fromARGB(255, 205, 166, 255)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              stepsWidgetsColumn(widget.recipe.steps)
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 50,
                    width: 70,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        shape:
                        MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.secondary,
                              width: 0.1,
                            ),
                          ),
                        ),
                      ),
                      onPressed: () {},
                      child: const Icon(Icons.edit_outlined),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    height: 50,
                    width: 170,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.secondary,
                              width: 0.1,
                            ),
                          ),
                        ),
                      ),
                      onPressed: () {
                        if (_isAnimationRunning) {
                          _controller.stop();
                        } else {
                          _controller.forward();
                        }
                        setState(() {
                          _isAnimationRunning = !_isAnimationRunning;
                        });
                      },
                      child: Text(_isAnimationRunning
                          ? 'Stop brewing'
                          : 'Start brewing!'),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
