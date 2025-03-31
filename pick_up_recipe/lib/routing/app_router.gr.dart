// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element
  _$AppRouter({super.navigatorKey});

  @override
  final Map<String, PageFactory> pagesMap = {
    AuthenticationRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const AuthenticationPage(),
      );
    },
    BrewRoute.name: (routeData) {
      final args = routeData.argsAs<BrewRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: BrewPage(
          key: args.key,
          recipe: args.recipe,
          pack: args.pack,
        ),
      );
    },
    ChoosingRecipeRoute.name: (routeData) {
      final args = routeData.argsAs<ChoosingRecipeRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: ChoosingRecipePage(
          key: args.key,
          packId: args.packId,
        ),
      );
    },
    MainRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const MainPage(),
      );
    },
    RecognitionCameraRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const RecognitionCameraPage(),
      );
    },
    RootRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const RootScreen(),
      );
    },
  };
}

/// generated route for
/// [AuthenticationPage]
class AuthenticationRoute extends PageRouteInfo<void> {
  const AuthenticationRoute({List<PageRouteInfo>? children})
      : super(
          AuthenticationRoute.name,
          initialChildren: children,
        );

  static const String name = 'AuthenticationRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [BrewPage]
class BrewRoute extends PageRouteInfo<BrewRouteArgs> {
  BrewRoute({
    Key? key,
    required RecipeData recipe,
    required PackData? pack,
    List<PageRouteInfo>? children,
  }) : super(
          BrewRoute.name,
          args: BrewRouteArgs(
            key: key,
            recipe: recipe,
            pack: pack,
          ),
          initialChildren: children,
        );

  static const String name = 'BrewRoute';

  static const PageInfo<BrewRouteArgs> page = PageInfo<BrewRouteArgs>(name);
}

class BrewRouteArgs {
  const BrewRouteArgs({
    this.key,
    required this.recipe,
    required this.pack,
  });

  final Key? key;

  final RecipeData recipe;

  final PackData? pack;

  @override
  String toString() {
    return 'BrewRouteArgs{key: $key, recipe: $recipe, pack: $pack}';
  }
}

/// generated route for
/// [ChoosingRecipePage]
class ChoosingRecipeRoute extends PageRouteInfo<ChoosingRecipeRouteArgs> {
  ChoosingRecipeRoute({
    Key? key,
    required int packId,
    List<PageRouteInfo>? children,
  }) : super(
          ChoosingRecipeRoute.name,
          args: ChoosingRecipeRouteArgs(
            key: key,
            packId: packId,
          ),
          initialChildren: children,
        );

  static const String name = 'ChoosingRecipeRoute';

  static const PageInfo<ChoosingRecipeRouteArgs> page =
      PageInfo<ChoosingRecipeRouteArgs>(name);
}

class ChoosingRecipeRouteArgs {
  const ChoosingRecipeRouteArgs({
    this.key,
    required this.packId,
  });

  final Key? key;

  final int packId;

  @override
  String toString() {
    return 'ChoosingRecipeRouteArgs{key: $key, packId: $packId}';
  }
}

/// generated route for
/// [MainPage]
class MainRoute extends PageRouteInfo<void> {
  const MainRoute({List<PageRouteInfo>? children})
      : super(
          MainRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [RecognitionCameraPage]
class RecognitionCameraRoute extends PageRouteInfo<void> {
  const RecognitionCameraRoute({List<PageRouteInfo>? children})
      : super(
          RecognitionCameraRoute.name,
          initialChildren: children,
        );

  static const String name = 'RecognitionCameraRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [RootScreen]
class RootRoute extends PageRouteInfo<void> {
  const RootRoute({List<PageRouteInfo>? children})
      : super(
          RootRoute.name,
          initialChildren: children,
        );

  static const String name = 'RootRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}
