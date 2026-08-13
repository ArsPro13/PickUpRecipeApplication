import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/authentication/provider/authentication_state_notifier.dart';
import 'package:pick_up_recipe/src/general_widgets/app_surface.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';

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
      // Текстура бумаги лежит под всем приложением, а не под каждым экраном:
      // Scaffold прозрачный, и фон рисуется здесь один раз.
      builder: (context, child) => PaperBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}
