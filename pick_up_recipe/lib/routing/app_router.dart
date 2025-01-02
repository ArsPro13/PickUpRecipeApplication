import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/pages/choosing_recipe_page.dart';
import 'package:pick_up_recipe/src/pages/recognition_camera_page.dart';

import 'package:pick_up_recipe/main.dart';
import 'package:pick_up_recipe/src/features/authentication/guards/authentication_guard.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/pages/authentication_page.dart';
import 'package:pick_up_recipe/src/pages/brew_page.dart';
import 'package:pick_up_recipe/src/pages/main_page.dart';

part './app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page|Screen,Route')
class AppRouter extends _$AppRouter {
  WidgetRef ref;

  AppRouter(this.ref) : super();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: RootRoute.page,
          initial: true,
          guards: [AuthGuard(ref)],
          children: [
            AutoRoute(
              page: MainRoute.page,
              initial: true,
              guards: [AuthGuard(ref)],
            ),
            AutoRoute(
              page: BrewRoute.page,
              guards: [AuthGuard(ref)],
            ),
            AutoRoute(
              page: RecognitionCameraRoute.page,
              guards: [AuthGuard(ref)],
            )
          ],
        ),
        AutoRoute(
          page: BrewRoute.page,
          guards: [AuthGuard(ref)],
        ),
        AutoRoute(
          page: ChoosingRecipeRoute.page,
          guards: [AuthGuard(ref)],
        ),
        AutoRoute(page: AuthenticationRoute.page),
      ];
}
