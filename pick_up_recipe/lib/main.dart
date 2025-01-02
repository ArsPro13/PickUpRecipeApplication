import 'package:auto_route/auto_route.dart';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/authentication/provider/authentication_state_notifier.dart';
import 'package:pick_up_recipe/src/themes/dark_theme.dart';
import 'package:pick_up_recipe/src/themes/light_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EncryptedSharedPreferences.initialize(prefsKey);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final getIt = GetIt.instance;

  void setupGetIt(WidgetRef ref) {
    if (!getIt.isRegistered<ApiClient>()) {
      getIt.registerLazySingleton(
        () => ApiClient(
          onAuthError: () async {
            final authProvider =
                ref.read(authenticationStateNotifierProvider.notifier);
            await authProvider.refresh();
          },
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    setupGetIt(ref);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
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
        return Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            key: ValueKey<int>(tabsRouter.activeIndex),
            currentIndex: tabsRouter.activeIndex,
            onTap: tabsRouter.setActiveIndex,
            type: BottomNavigationBarType.fixed,
            elevation: 10,
            enableFeedback: false,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            iconSize: 28,
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
          ),
        );
      },
    );
  }
}
