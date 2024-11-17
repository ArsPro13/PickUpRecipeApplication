import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/data/DAO/mocked_pack_info_from_camera_instance.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/data/DAO/pack_info_dao.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/data/DAO/pack_info_dao_instance.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/data/DAO/pack_info_from_camera_dao.dart';
import 'package:pick_up_recipe/src/features/packs/data/DAO/active_packs_dao.dart';
import 'package:pick_up_recipe/src/features/packs/data/DAO/active_packs_dao_instance.dart';
import 'package:pick_up_recipe/src/features/recipes/data/DAO/latest_recipes_dao.dart';
import 'package:pick_up_recipe/src/features/recipes/data/DAO/mocked_latest_recipes_dao_instance.dart';
import 'package:pick_up_recipe/src/themes/dark_theme.dart';
import 'package:pick_up_recipe/src/themes/light_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

var logger = Logger();

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final getIt = GetIt.instance;

  void setupGetIt() {
    getIt.registerSingleton<LatestRecipesDAO>(MockedLatestRecipesDAOInstance());
    getIt.registerSingleton<ActivePacksDAO>(ActivePacksDAOImpl());
    getIt.registerSingleton<PackInfoFromCameraDAO>(
        MockedPackInfoFromCameraDAO());
    getIt.registerSingleton<PackInfoDAO>(PackInfoDAOInstance());
  }

  @override
  void initState() {
    super.initState();
    setupGetIt();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter(ref).config(),
      theme: lightTheme,
      darkTheme: darkTheme,
    );
  }
}

@RoutePage()
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final getIt = GetIt.instance;

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: const [
        MainRoute(),
        RecognitionCameraRoute(),
      ],
      bottomNavigationBuilder: (_, tabsRouter) {
        return BottomNavigationBar(
          currentIndex: tabsRouter.activeIndex,
          onTap: tabsRouter.setActiveIndex,
          items: const [
            BottomNavigationBarItem(
              label: 'Main',
              icon: Icon(Icons.coffee),
            ),
            BottomNavigationBarItem(
              label: 'Add pack',
              icon: Icon(Icons.add),
            ),
          ],
        );
      },
    );
  }
}
