// Стопка версий на вкладке «Рецепты».
//
// Барабан живёт на контроллере анимации, и весь экран держится на том, что
// контроллер переживает стопку, которую никто не листал.

import 'package:auto_route/auto_route.dart';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/src/features/brew_methods/application/brew_methods_state.dart';
import 'package:pick_up_recipe/src/features/brew_methods/data_sources/remote/brew_method_service.dart';
import 'package:pick_up_recipe/src/features/brew_methods/domain/brew_method.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipes_list_state.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/pages/recipes_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Роутер, который никуда не ведёт, а записывает, куда его просили.
///
/// Проверять переход по появлению экрана конструктора нельзя: он поднял бы
/// половину приложения вместе с сетью, а вопрос тут не «нарисовался ли экран»,
/// а «какой рецепт на него уехал».
class _RecordingRouter extends RootStackRouter {
  final List<PageRouteInfo> pushed = [];

  @override
  List<AutoRoute> get routes => const [];

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    pushed.add(route);
    return null;
  }
}

/// История завариваний без сети: что положили, то и отдаёт.
class _StaticRecipeService extends RecipeService {
  _StaticRecipeService(this.stored);

  final List<RecipeData> stored;

  @override
  Future<List<RecipeData>?> getByParams({
    int? packId,
    int? grinderId,
    int? grindStep,
    int? grindSubStep,
    String? device,
    String? startDate,
    String? endDate,
    int? offset,
    int? limit,
    String? sortBy,
    bool allVersions = false,
  }) async {
    return stored;
  }
}

/// Справочник приборов пустой: имя метода экран возьмёт из slug.
class _EmptyMethodService extends BrewMethodService {
  @override
  Future<List<BrewMethod>> getMethods() async => const [];

  @override
  Future<List<BrewMethodGroup>> getGroups() async => const [];
}

/// Полка пачек пуста: карточке хватает рецепта, пачка ей только фото.
class _SilentApiClient extends ApiClient {
  _SilentApiClient() : super(onAuthError: _nothing);

  static Future<void> _nothing() async {}

  @override
  Future<http.Response> getCached(
    String endpoint,
    Map<String, String> queryParams, {
    required String cacheKey,
  }) async {
    return http.Response('[]', 200);
  }
}

RecipeData _recipe({required int id, required String date, required double load}) {
  return RecipeData(
    id: id,
    device: 'hario_v60',
    date: date,
    packId: 7,
    grinderId: 1,
    grindStep: '18',
    grindSubStep: null,
    water: 250,
    time: 150,
    temperature: 93,
    load: load,
    title: '',
    notes: '',
    grindDescriptor: '',
    agitationLevel: null,
    steps: const [],
  );
}

/// Одна стопка из трёх версий: под верхней карточкой видно ещё две.
final _versions = [
  _recipe(id: 301, date: '2026-09-09T10:00:00Z', load: 15),
  _recipe(id: 302, date: '2026-09-08T10:00:00Z', load: 16),
  _recipe(id: 303, date: '2026-09-07T10:00:00Z', load: 17),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();

    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<ApiClient>(_SilentApiClient());
  });

  Future<_RecordingRouter> pumpRecipes(WidgetTester tester) async {
    final router = _RecordingRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipeServiceProvider.overrideWithValue(_StaticRecipeService(_versions)),
          brewMethodServiceProvider.overrideWithValue(_EmptyMethodService()),
        ],
        child: MaterialApp(
          theme: lightTheme,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => MediaQuery(
              // Движение выключено: иначе первая стопка один раз за прогон
              // сама показывает жест, и тесты начинают зависеть от порядка.
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: StackRouterScope(
                controller: router,
                stateHash: 0,
                child: const RecipesPage(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  group('стопка версий', () {
    testWidgets('уход с экрана без свайпа не роняет стопку', (tester) async {
      await pumpRecipes(tester);

      // Стопку не листали и подсказку ей не показывали, так что контроллер
      // полёта никому не понадобился. Ленивый `late final` заводил бы его
      // прямо в `dispose` — на уже отсоединённом элементе, которому неоткуда
      // взять `TickerMode`, — и первый же уход с экрана падал в отладке.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
