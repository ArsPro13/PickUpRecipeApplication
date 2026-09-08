// Экран оценки на английском телефоне.
//
// Телефон владельца говорит по-английски, и весь экран «Как получилось» ехал
// на нём по-русски: карта вкуса, звёзды, шесть ползунков и обе кнопки внизу.
// Проверяется поэтому не отдельная подпись, а весь экран целиком: кириллица
// на нём — это забытая строка, в какой бы части он ни стояла.
//
// Отдельно проверяется развилка: фраза «Заметно горько, чуть слабо» на экране
// обязана говорить на языке телефона, а в запросе к серверу — всегда
// по-русски. Комментарий к оценке читают люди в кабинете обжарщика, и язык
// телефона на это поле не влияет.

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
import 'package:pick_up_recipe/src/features/recipes/application/rating_draft.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/taste_map.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Клиент, который запоминает отправленное и ничего не спрашивает у сети.
class _EstimationApiClient extends ApiClient {
  _EstimationApiClient() : super(onAuthError: _nothing);

  static Future<void> _nothing() async {}

  /// Тела отправленных запросов по адресам.
  final Map<String, Map<String, dynamic>> sent = {};

  @override
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    sent[endpoint] = body;
    return http.Response('{}', 200);
  }

  /// Сессия обновляется молча: гвард уже пустил по сохранённому токену.
  @override
  Future<http.Response> postRefresh(String endpoint) async => http.Response(
        jsonEncode({'access_token': 'access', 'refresh_token': 'refresh'}),
        200,
      );
}

/// Приложение из одного экрана оценки.
///
/// Настоящий роутер, а не подделка: шапка экрана спрашивает у него, есть ли
/// куда возвращаться, и без него экран не собирается вовсе.
class _RatingApp extends ConsumerStatefulWidget {
  const _RatingApp({required this.recipe, required this.locale});

  final RecipeData recipe;
  final Locale locale;

  @override
  ConsumerState<_RatingApp> createState() => _RatingAppState();
}

class _RatingAppState extends ConsumerState<_RatingApp> {
  late final AppRouter _router = AppRouter(ref);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: lightTheme,
      // Язык задан прямо, а не взят у машины с тестом: проверяется как раз
      // английский телефон владельца.
      locale: widget.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router.config(
        deepLinkBuilder: (_) => DeepLink([RatingRoute(recipe: widget.recipe)]),
      ),
    );
  }
}

RecipeData _recipe() => RecipeData(
      id: 42,
      device: 'hario_v60',
      date: '2026-09-05T10:00:00Z',
      packId: 7,
      grinderId: 1,
      grindStep: '18',
      grindSubStep: null,
      water: 250,
      time: 150,
      temperature: 93,
      load: 15,
      title: '',
      notes: '',
      grindDescriptor: 'medium',
      agitationLevel: null,
      steps: const [],
    );

/// Всё, что экран показывает словами: подписи, подсказки и то, что читает
/// голосовой помощник.
Iterable<String> _shownText(WidgetTester tester) sync* {
  for (final widget in tester.allWidgets) {
    if (widget is Text && widget.data != null) yield widget.data!;
    if (widget is Tooltip && widget.message != null) yield widget.message!;
    if (widget is Semantics && widget.properties.label != null) {
      yield widget.properties.label!;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final cyrillic = RegExp(r'[А-Яа-яЁё]');

  late _EstimationApiClient api;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    final prefs = EncryptedSharedPreferences.getInstance();
    await prefs.clear();

    // Гвард пускает дальше по сохранённой сессии — без неё он увёл бы на вход.
    await prefs.setString('access_token', 'access');
    await prefs.setString('refresh_token', 'refresh');

    RatingDrafts.current.value = null;

    await GetIt.instance.reset();
    api = _EstimationApiClient();
    GetIt.instance.registerSingleton<ApiClient>(api);
  });

  /// Открывает экран оценки с уже сказанным «заметно горько, чуть слабо»:
  /// пустая карта не показывает ни фразы, ни кнопки поправки.
  Future<void> pumpRating(WidgetTester tester, Locale locale) async {
    // Окно с запасом: шрифт в тестах не тот, что на телефоне, и мерить по
    // нему тесноту экрана нечестно. Здесь проверяются слова, а не вёрстка.
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await RatingDrafts.save(RatingDraft(
      recipe: _recipe(),
      pack: null,
      point: const TastePoint(0.6, -0.3),
      stars: 4,
      axes: const {'acidity': 7},
      savedAt: DateTime.now(),
    ));

    await tester.pumpWidget(
      ProviderScope(child: _RatingApp(recipe: _recipe(), locale: locale)),
    );
    await tester.pumpAndSettle();
  }

  group('экран оценки', () {
    testWidgets('на английском телефоне русских слов на экране не остаётся', (tester) async {
      await pumpRating(tester, const Locale('en'));

      for (final line in _shownText(tester)) {
        expect(
          cyrillic.hasMatch(line),
          isFalse,
          reason: 'по-русски посреди английского экрана: «$line»',
        );
      }

      // Кириллицы нет и у пустого экрана, поэтому отдельно — что слова на
      // месте: шапка, фраза под картой, обе части необязательного разбора
      // и главная кнопка внизу.
      expect(find.text('How did it turn out'), findsOneWidget);
      expect(find.text('Noticeably bitter, slightly weak'), findsOneWidget);
      expect(find.text('Break it down by axis'), findsOneWidget);
      expect(find.text('Aroma'), findsOneWidget);
      expect(find.text('Adjust the recipe'), findsOneWidget);
    });

    testWidgets('карта вкуса читается голосовым помощником на языке экрана', (tester) async {
      await pumpRating(tester, const Locale('en'));

      expect(
        find.bySemanticsLabel('Taste map. Noticeably bitter, slightly weak'),
        findsOneWidget,
      );
    });

    testWidgets('комментарий к оценке уезжает на сервер по-русски', (tester) async {
      await pumpRating(tester, const Locale('en'));

      // На экране фраза английская — и ровно та же жалоба уходит на сервер
      // по-русски: перевод не должен просочиться в тело запроса.
      expect(find.text('Noticeably bitter, slightly weak'), findsOneWidget);

      await tester.tap(find.text('Just save the rating'));
      await tester.pumpAndSettle();

      expect(
        api.sent['/recipe/estimation']?['comment'],
        'Заметно горько, чуть слабо',
        reason: 'комментарий читают в кабинете обжарщика, и он русский',
      );
    });

    testWidgets('на русском телефоне экран остался русским', (tester) async {
      await pumpRating(tester, const Locale('ru'));

      expect(find.text('Как получилось'), findsOneWidget);
      expect(find.text('Заметно горько, чуть слабо'), findsOneWidget);
      expect(find.text('Разобрать по осям'), findsOneWidget);
      expect(find.text('Поправить рецепт'), findsOneWidget);
    });
  });
}
