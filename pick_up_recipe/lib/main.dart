import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/src/features/packs/data/DAO/active_packs_dao.dart';
import 'package:pick_up_recipe/src/features/packs/data/DAO/mocked_active_packs_dao.dart';
import 'package:pick_up_recipe/src/features/recipes/data/DAO/latest_recipes_dao.dart';
import 'package:pick_up_recipe/src/features/recipes/data/DAO/mocked_latest_recipes_dao_instance.dart';
import 'package:pick_up_recipe/src/pages/main_page.dart';
import 'package:pick_up_recipe/src/themes/dark_theme.dart';
import 'package:pick_up_recipe/src/themes/light_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final getIt = GetIt.instance;
  int _selectedIndex = 0;

  void setupGetIt() {
    getIt.registerSingleton<LatestRecipesDAO>(MockedLatestRecipesDAOInstance());
    getIt.registerSingleton<ActivePacksDAO>(MockedActivePacksDAOInstance());
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    setupGetIt();
  }

  final List<Widget> pages = <Widget>[
    const MainPage(),
    const Center(child: Text('bbb')),
    const Center(child: Text('ccc')),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      home: Builder(builder: (context) {
        return Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.coffee),
                label: 'Main',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.coffee_maker),
                label: 'Second',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Third',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            onTap: _onItemTapped,
          ),
          body: pages[_selectedIndex],
        );
      }),
    );
  }
}
