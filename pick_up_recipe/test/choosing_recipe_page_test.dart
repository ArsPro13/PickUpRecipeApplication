// Экран выбора рецепта: рецепты с прошлых пачек — стопками, как на вкладке.
//
// Раньше раздел «С прошлых пачек» стоял строками «зерно — 18 кликов · 2:15»,
// по одной на пачку. Просьба — видеть его так же, как вкладку «Рецепты», и
// так же листать вбок. Ломается это тихо тремя способами, и каждый закрыт
// тестом ниже: в раздел попадает не то (чужой прибор, своя пачка); на месте
// стопки стоит похожая копия без барабана; жест забирает прокрутка экрана,
// и карточка не листается.

import 'dart:convert';

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
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/brew_methods/application/brew_methods_state.dart';
import 'package:pick_up_recipe/src/features/brew_methods/data_sources/remote/brew_method_service.dart';
import 'package:pick_up_recipe/src/features/brew_methods/domain/brew_method.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipes_list_state.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/general_widgets/app_icon.dart';
import 'package:pick_up_recipe/src/general_widgets/recipe_deck.dart';
import 'package:pick_up_recipe/src/pages/choosing_recipe_page.dart';
import 'package:pick_up_recipe/src/themes/app_icons.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Роутер, который никуда не ведёт, а записывает, куда его просили.
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

/// Отдаёт пачки по идентификатору — ради имён в шапках стопок. Остальная сеть
/// отвечает пустотой: без кофемолки и справочника помола экран обходится.
class _PacksApiClient extends ApiClient {
  _PacksApiClient() : super(onAuthError: _nothing);

  static Future<void> _nothing() async {}

  static const _names = {1: 'Кения', 2: 'Эфиопия', 3: 'Колумбия'};

  @override
  Future<http.Response> getCached(
    String endpoint,
    Map<String, String> queryParams, {
    required String cacheKey,
  }) async {
    if (endpoint == '/auth/profile') return http.Response('{}', 200);

    final id = int.tryParse(queryParams['id'] ?? '');
    if (endpoint != '/packs' || id == null) return http.Response('[]', 200);

    return http.Response(
      jsonEncode({
        'id': id,
        'pack_country': '',
        'pack_date': '2026-09-01',
        'pack_descriptors': <String>[],
        'pack_image': '',
        'pack_name': _names[id],
        'pack_processing_method': <String>[],
        'pack_sca_score': 84,
        'pack_variety': '',
        'user_id': 1,
        'roaster_name': '',
      }),
      200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

/// История без сети: что положили, то и отдаёт — с теми же фильтрами пачки и
/// прибора, что у настоящего запроса.
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
    return [
      for (final recipe in stored)
        if ((packId == null || recipe.packId == packId) &&
            (device == null || recipe.device == device))
          recipe,
    ];
  }
}

/// Два прибора: имя V60 нужно шапке стопки, аэропресс — чтобы было что
/// не пустить в раздел.
class _MethodsService extends BrewMethodService {
  @override
  Future<List<BrewMethod>> getMethods() async => const [
        BrewMethod(
            id: 1,
            slug: 'hario_v60',
            name: 'Hario V60',
            iconKey: 'v60',
            groupId: 1),
        BrewMethod(
            id: 2,
            slug: 'aeropress',
            name: 'Аэропресс',
            iconKey: 'aeropress',
            groupId: 2),
      ];

  @override
  Future<List<BrewMethodGroup>> getGroups() async => const [
        BrewMethodGroup(id: 1, slug: 'pourover', name: 'Пуровер', iconKey: ''),
        BrewMethodGroup(
            id: 2, slug: 'immersion', name: 'Иммерсия', iconKey: ''),
      ];
}

RecipeData _recipe({
  required int id,
  required int packId,
  required String date,
  String device = 'hario_v60',
}) {
  return RecipeData(
    hasEstimation: true,
    id: id,
    device: device,
    date: date,
    packId: packId,
    grinderId: 0,
    grindStep: '',
    grindSubStep: null,
    water: 250,
    time: 150,
    temperature: 93,
    load: 15,
    title: '',
    notes: '',
    grindDescriptor: '',
    agitationLevel: null,
    steps: const [],
  );
}

/// Две прошлые пачки под V60 — у одной две версии, у другой одна, — и всё,
/// чему в разделе стоять нельзя: та же пачка аэропрессом и справочный рецепт,
/// заваренный без пачки.
final _history = [
  _recipe(id: 21, packId: 2, date: '2026-10-20T08:00:00Z'),
  _recipe(id: 22, packId: 2, date: '2026-10-10T08:00:00Z'),
  _recipe(id: 31, packId: 3, date: '2026-10-15T08:00:00Z'),
  _recipe(id: 23, packId: 2, date: '2026-10-25T08:00:00Z', device: 'aeropress'),
  _recipe(id: 1, packId: 0, date: '2026-10-26T08:00:00Z'),
];

/// Рецепт под само это зерно: с ним наверху экрана стоит «От обжарщика».
final _own = _recipe(id: 11, packId: 1, date: '2026-10-27T08:00:00Z');

final _playButtons = find.byWidgetPredicate(
  (widget) => widget is AppIcon && widget.asset == AppIcons.uiPlay,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations ru;

  setUpAll(() async {
    ru = await AppLocalizations.delegate.load(const Locale('ru'));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();

    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<ApiClient>(_PacksApiClient());
  });

  /// Экран зерна «Кения» под V60. [own] — рецепты под само это зерно.
  Future<_RecordingRouter> pumpChoosing(
    WidgetTester tester, {
    List<RecipeData> own = const [],
  }) async {
    // Выше телефона, чтобы обе стопки стояли на экране без прокрутки:
    // проверяется раздел, а не то, как до него долистать.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = _RecordingRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipeServiceProvider
              .overrideWithValue(_StaticRecipeService([...own, ..._history])),
          brewMethodServiceProvider.overrideWithValue(_MethodsService()),
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
                child: const ChoosingRecipePage(
                  packId: 1,
                  method: 'hario_v60',
                  methodName: 'Hario V60',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  List<RecipeDeck> decks(WidgetTester tester) =>
      tester.widgetList<RecipeDeck>(find.byType(RecipeDeck)).toList();

  group('с прошлых пачек', () {
    testWidgets('стоят стопками вкладки «Рецепты», по стопке на пачку',
        (tester) async {
      await pumpChoosing(tester);

      expect(find.text(ru.chooseOtherPacks), findsOneWidget);
      // Две пачки под этот прибор, свежая сверху. Аэропресс той же пачки и
      // справочный рецепт без пачки сюда не попали.
      expect(decks(tester).map((deck) => deck.group.packId).toList(), [2, 3]);
      expect(decks(tester).first.group.versions, hasLength(2),
          reason: 'стопка несёт все версии пачки, а не одну свежую');
      // Шапка стопки называет зерно: без него две карточки с одинаковыми
      // числами не различить.
      expect(find.text('Эфиопия · Hario V60'), findsOneWidget);
      expect(find.text('Колумбия · Hario V60'), findsOneWidget);
    });

    testWidgets('стопка листается вбок прямо на этом экране', (tester) async {
      final router = await pumpChoosing(tester);
      final first = find.byType(RecipeDeck).first;

      // Смахиваем верхнюю карточку: наверх поднимается прошлая версия.
      await tester.drag(
        find.descendant(of: first, matching: find.text(ru.recipesCurrent)),
        const Offset(-150, 0),
      );
      await tester.pumpAndSettle();

      expect(router.pushed, isEmpty,
          reason: 'смахивание листает стопку, а не открывает рецепт');
      expect(
        find.descendant(
            of: first, matching: find.text(ru.recipesVersionOf(2, 2))),
        findsOneWidget,
      );

      // Заварить можно ровно ту версию, что сейчас сверху.
      await tester.tap(find.descendant(of: first, matching: _playButtons).last);
      await tester.pumpAndSettle();

      final route = router.pushed.single;
      expect(route.routeName, BrewRoute.name);
      expect((route.args as BrewRouteArgs).recipe.id, 22);
    });

    testWidgets('без рецепта под это зерно главная — свежая стопка',
        (tester) async {
      await pumpChoosing(tester);

      expect(find.text(ru.chooseRoaster), findsNothing);
      expect(decks(tester).map((deck) => deck.hero).toList(), [true, false]);
    });

    testWidgets('рецепт под это зерно есть — главный он, а не стопка',
        (tester) async {
      await pumpChoosing(tester, own: [_own]);

      expect(find.text(ru.chooseRoaster), findsOneWidget);
      expect(decks(tester).map((deck) => deck.hero).toList(), [false, false]);
    });
  });
}
