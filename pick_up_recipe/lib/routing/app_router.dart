import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../src/features/authentication/guards/authentication_guard.dart';
import '../src/features/recipes/domain/models/recipe_data_model.dart';
import '../src/pages/authentication_page.dart';
import '../src/pages/brew_page.dart';
import '../src/pages/main_page.dart';
import '../src/pages/settings_page.dart';

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
          // guards: [AuthGuard(ref)],
          children: [
            AutoRoute(
              page: MainRoute.page,
              initial: true,
            ),
            AutoRoute(
              page: BrewRoute.page,
            ),
          ],
        ),
        AutoRoute(
          page: BrewRoute.page,
          // guards: [AuthGuard(ref)],
        ),
        AutoRoute(
          page: AuthenticationRoute.page,
        ),
        AutoRoute(
          page: SettingsRoute.page,
        ),
      ];
}
