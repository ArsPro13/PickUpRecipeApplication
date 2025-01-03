import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:pick_up_recipe/src/features/packs/presentation/active_packs_widget.dart';
import 'package:pick_up_recipe/src/features/recipes/presentation/latest_recipes_widget.dart';
import 'package:pick_up_recipe/src/general_widgets/buttons/app_button.dart';

@RoutePage()
class MainPage extends StatelessWidget {
  const MainPage({super.key});

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
          const SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: 10,
            ),
            sliver: LatestRecipesWidget(
                // limit: 10,
                ),
          ),
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
                  Center(
                    child: AppButton(
                      onTap: () {
                        final tabsRouter = AutoTabsRouter.of(context);
                        tabsRouter.setActiveIndex(1);
                      },
                      centerWidget: const Icon(Icons.add),
                      buttonStyle: AppButtonStyle.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 20),
            sliver: ActivePacksWidget(),
          ),
        ],
      ),
    );
  }
}
