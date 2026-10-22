// Карточка кофе: «Обжарщик обещает» — обещание обжарщика, а не наше.
//
// У пачки, заведённой руками, обжарщика нет: дескрипторы в неё вписал сам
// человек. Раньше блок показывался всегда, и на такой пачке в нём висел
// одинокий чип с обрывком слова — с этого владелец и начал разговор.
//
// Вторая группа — поиск прибора и прошлые рецепты зерна. Владелец попросил
// «поиск как в кофемолках» и, выбрав зерно, видеть прошлые рецепты «так же,
// как на вкладке с рецептами».

import 'dart:convert';

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
import 'package:pick_up_recipe/src/general_widgets/recipe_deck.dart';
import 'package:pick_up_recipe/src/pages/coffee_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Клиент, который отдаёт одну пачку и молчит обо всём остальном.
///
/// Справочник методов и рецепты страница переживает без сети сама: без них
/// она показывает зерно и строку «способы не загрузились».
class _OnePackApiClient extends ApiClient {
  _OnePackApiClient({required this.roasterName}) : super(onAuthError: _nothing);

  static Future<void> _nothing() async {}

  final String roasterName;

  @override
  Future<http.Response> getCached(
    String endpoint,
    Map<String, String> queryParams, {
    required String cacheKey,
  }) async {
    if (endpoint != '/packs') return http.Response('[]', 200);

    return http.Response(
      jsonEncode({
        'id': 1,
        'pack_country': 'Бразилия',
        'pack_date': '2026-09-01',
        'pack_descriptors': ['малиновый', 'карамель'],
        'pack_image': '',
        'pack_name': 'бразилия',
        'pack_processing_method': <String>[],
        'pack_sca_score': 84,
        'pack_variety': 'арабика',
        'user_id': 1,
        'roaster_name': roasterName,
      }),
      200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

/// Четыре прибора двумя группами — хватает, чтобы поиск было из чего вести.
class _MethodsService extends BrewMethodService {
  @override
  Future<List<BrewMethod>> getMethods() async => const [
        BrewMethod(
            id: 1,
            slug: 'aeropress',
            name: 'Аэропресс',
            iconKey: 'aeropress',
            groupId: 1),
        BrewMethod(
            id: 2,
            slug: 'french_press',
            name: 'Френч-пресс',
            iconKey: 'french-press',
            groupId: 1),
        BrewMethod(
            id: 3, slug: 'v60', name: 'Hario V60', iconKey: 'v60', groupId: 2),
        BrewMethod(
            id: 4,
            slug: 'chemex',
            name: 'Кемекс',
            iconKey: 'chemex',
            groupId: 2),
      ];

  @override
  Future<List<BrewMethodGroup>> getGroups() async => const [
        BrewMethodGroup(
            id: 1, slug: 'immersion', name: 'Иммерсия', iconKey: ''),
        BrewMethodGroup(id: 2, slug: 'pourover', name: 'Пуровер', iconKey: ''),
      ];
}

/// История: две версии аэропресса по этой пачке и одна — по чужой.
class _HistoryService extends RecipeService {
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
    final all = [
      _recipe(id: 11, packId: 1, date: '2026-10-20T08:15:00Z'),
      _recipe(id: 12, packId: 1, date: '2026-10-21T08:15:00Z'),
      _recipe(id: 21, packId: 2, date: '2026-10-19T08:15:00Z'),
    ];
    return packId == null
        ? all
        : all.where((recipe) => recipe.packId == packId).toList();
  }
}

RecipeData _recipe(
    {required int id, required int packId, required String date}) {
  return RecipeData(
    hasEstimation: true,
    id: id,
    device: 'aeropress',
    date: date,
    packId: packId,
    grinderId: 0,
    grindStep: '',
    grindSubStep: null,
    water: 220,
    time: 135,
    temperature: 88,
    load: 16,
    title: '',
    notes: '',
    grindDescriptor: '',
    agitationLevel: null,
    steps: const [],
  );
}

void main() {
  Future<void> pumpCard(WidgetTester tester,
      {required String roasterName}) async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<ApiClient>(
      _OnePackApiClient(roasterName: roasterName),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: lightTheme,
          // Подписи экран берёт из локали. Язык задан прямо: проверяются
          // русские слова, а не системный язык машины с тестом.
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CoffeePage(packId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('карточка кофе', () {
    testWidgets('у пачки, заведённой руками, обещаний обжарщика нет',
        (tester) async {
      await pumpCard(tester, roasterName: '');

      expect(find.text('бразилия'), findsWidgets);
      expect(find.text('Обжарщик обещает'), findsNothing);
      expect(find.text('малиновый'), findsNothing);
    });

    testWidgets('у пачки по коду обжарщика блок остаётся', (tester) async {
      await pumpCard(tester, roasterName: 'Tasty Coffee');

      expect(find.text('Обжарщик обещает'), findsOneWidget);
      expect(find.text('малиновый'), findsOneWidget);
    });
  });

  group('поиск прибора и прошлые рецепты', () {
    late AppLocalizations ru;

    setUpAll(() async {
      ru = await AppLocalizations.delegate.load(const Locale('ru'));
    });

    Future<void> pumpWithHistory(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await EncryptedSharedPreferences.initialize(prefsKey);
      await EncryptedSharedPreferences.getInstance().clear();

      await GetIt.instance.reset();
      GetIt.instance.registerSingleton<ApiClient>(
        _OnePackApiClient(roasterName: ''),
      );

      // Шире телефона: в тестах каждая буква — квадрат во весь кегль, и метки
      // карточки на телефонной ширине не помещаются, хотя на телефоне
      // помещаются. Ширина та же, что у тестов вкладки «Рецепты».
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            brewMethodServiceProvider.overrideWithValue(_MethodsService()),
            recipeServiceProvider.overrideWithValue(_HistoryService()),
          ],
          child: MaterialApp(
            theme: lightTheme,
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => MediaQuery(
                // Без движения: первая стопка иначе сама показывает жест.
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: const CoffeePage(packId: 1),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> search(WidgetTester tester, String query) async {
      await tester.enterText(find.byType(TextField), query);
      // Список ждёт паузу после последней буквы — как у кофемолок.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }

    testWidgets('прибор находится поиском, не открывая групп', (tester) async {
      await pumpWithHistory(tester);

      // Группы свёрнуты: приборов в них не видно.
      expect(find.text('Кемекс'), findsNothing);

      await search(tester, 'кем');
      expect(find.text('Кемекс'), findsOneWidget);
      expect(find.text('Hario V60'), findsNothing);

      // Нестрого, как у кофемолок: латиницей ищется кириллическое имя.
      await search(tester, 'kemex');
      expect(find.text('Кемекс'), findsOneWidget);
    });

    testWidgets('не нашлось — есть «Показать все»', (tester) async {
      await pumpWithHistory(tester);

      await search(tester, 'qqqqqq');
      expect(find.text(ru.coffeeMethodNotFound), findsOneWidget);

      await tester.tap(find.text(ru.grinderShowAll));
      await tester.pumpAndSettle();

      expect(find.text(ru.coffeeMethodNotFound), findsNothing);
      expect(find.text('Иммерсия'), findsOneWidget);
    });

    testWidgets('прошлые рецепты зерна стоят стопкой, как на вкладке',
        (tester) async {
      await pumpWithHistory(tester);

      expect(find.text(ru.chooseMine), findsOneWidget);
      // Одна стопка — только этого зерна: чужая пачка сюда не попала.
      expect(find.byType(RecipeDeck), findsOneWidget);
      expect(find.text(ru.recipesCurrent), findsOneWidget);
      expect(find.textContaining(ru.recipesVersionsCount(2)), findsOneWidget);
    });
  });
}
