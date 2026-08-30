import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/core/offline/network_status.dart';
import 'package:pick_up_recipe/core/offline/offline_sync.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/authentication/provider/authentication_state.dart';
import 'package:pick_up_recipe/src/features/authentication/provider/authentication_state_notifier.dart';
import 'package:pick_up_recipe/src/general_widgets/offline_bar.dart';
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

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final getIt = GetIt.instance;

  /// Роутер живёт полем, а не создаётся в build: иначе каждая перерисовка
  /// заводила новый, и позвать его снаружи (например, чтобы увести на вход)
  /// было не у кого.
  late final AppRouter _router = AppRouter(ref);

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

    setupGetIt(ref);
    WidgetsBinding.instance.addObserver(this);

    // Чем щупаем сеть, пока висим офлайн: самый дешёвый справочник. Заодно
    // обновляет его копию на телефоне — то есть проба не пропадает зря.
    NetworkStatus.probe = () =>
        getIt<ApiClient>().getCached('/brew_methods/groups', const {}, cacheKey: 'brew_method_groups');

    OfflineSync.wire();

    // Приложение могли закрыть в лесу с непустой очередью — пробуем сразу.
    OfflineSync.unawaitedFlush();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Вернулись в приложение — самый частый момент, когда сеть уже появилась:
    // телефон достали из кармана там, где ловит.
    if (state == AppLifecycleState.resumed) {
      OfflineSync.unawaitedFlush();
    }
  }

  @override
  Widget build(BuildContext context) {
    setupGetIt(ref);

    // Сессия кончилась не по нашей воле — сервер отверг токены. Гвард к этому
    // моменту уже пропустил человека внутрь и второй раз не сработает: без
    // этого он остаётся на экране, который больше ничего не покажет.
    ref.listen(authenticationStateNotifierProvider, (previous, next) {
      if (previous?.status == AuthState.isAuthenticated &&
          next.status == AuthState.needsAuthentication) {
        _router.replaceAll([const AuthWelcomeRoute()]);
      }
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router.config(),
      scaffoldMessengerKey: messengerKey,
      theme: lightTheme,
      darkTheme: darkTheme,
      // Текстура бумаги лежит под всем приложением, а не под каждым экраном:
      // Scaffold прозрачный, и фон рисуется здесь один раз.
      //
      // Полоска связи — над всем сразу по той же причине: без сети меняется
      // поведение каждого экрана, а не одного.
      builder: (context, child) => PaperBackground(
        child: OfflineBar(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
