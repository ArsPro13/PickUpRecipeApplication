import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:pick_up_recipe/src/features/packs/presentation/active_packs_widget.dart';
import 'package:pick_up_recipe/src/features/recipes/presentation/latest_recipes_widget.dart';

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 70),
              child: Text(
                'Latest Recipes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                ),
              ),
            ),
          ),
          const LatestRecipesWidget(),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Active packs',
                    style: TextStyle(fontSize: 30),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    onPressed: () {},
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
          const ActivePacksWidget(),
        ],
      ),
    );
  }
}
