// Офлайн: очередь отправки, кэш ответов и свои неотправленные версии.
//
// Это самая опасная часть приложения из тех, что не видно глазами. Ошибка
// здесь выглядит не как сломанный экран, а как молча потерянная оценка —
// человек уверен, что сохранил, и узнаёт правду через неделю. Поэтому
// проверяется тестом всё: порядок отправки, подмена локального
// идентификатора на серверный и то, что происходит с оценкой, чей рецепт
// сервер отверг.

import 'dart:ui' show Locale;

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/core/offline/local_recipes.dart';
import 'package:pick_up_recipe/core/offline/network_status.dart';
import 'package:pick_up_recipe/core/offline/offline_cache.dart';
import 'package:pick_up_recipe/core/offline/offline_exception.dart';
import 'package:pick_up_recipe/core/offline/outbox.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/features/authentication/data_sources/remote/auth_service.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/general_widgets/offline_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Клиент, который не ходит в сеть: отвечает тем, что ему сказали, и
/// записывает, о чём его просили.
class FakeApiClient extends ApiClient {
  FakeApiClient() : super(onAuthError: _nothing);

  static Future<void> _nothing() async {}

  /// Что отвечать на POST по адресу. Функция, а не значение: ответ бывает
  /// разным на первый и второй вызов.
  final Map<String, http.Response Function(Map<String, dynamic> body)> replies = {};

  /// Что правда ушло на сервер — по порядку.
  final List<(String, Map<String, dynamic>)> calls = [];

  /// Сеть «пропала»: любой запрос отваливается, как в лесу.
  bool offline = false;

  /// Что отвечать на обновление токенов.
  http.Response Function()? refreshReply;

  @override
  Future<http.Response> postRefresh(String endpoint) async {
    if (offline) throw const OfflineException();
    calls.add((endpoint, const {}));

    final reply = refreshReply;
    return reply == null ? http.Response('{}', 200) : reply();
  }

  /// Что отвечать на GET по адресу.
  final Map<String, http.Response Function()> getReplies = {};

  @override
  Future<http.Response> get(String endpoint, Map<String, String> query) async {
    if (offline) throw const OfflineException();
    calls.add((endpoint, query));

    final reply = getReplies[endpoint];
    return reply == null ? http.Response('[]', 200) : reply();
  }

  @override
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    // Записываем только то, что правда ушло: попытка без сети до сервера
    // не долетает, и считать её отправкой значит проверять не то.
    if (offline) throw const OfflineException();
    calls.add((endpoint, body));

    final reply = replies[endpoint];
    if (reply == null) return http.Response('{}', 200);
    return reply(body);
  }
}

RecipeData recipe({int id = 1, int packId = 7, String device = 'hario_v60'}) {
  return RecipeData(
    id: id,
    device: device,
    date: '2026-08-30T10:00:00Z',
    packId: packId,
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
    // Шаги обязательно настоящие: рецепт без шагов не ловит ошибок копии,
    // а копия рецепта — самое хрупкое место офлайна.
    steps: [
      RecipeStep(
        seqNum: 1,
        instruction: 'Предсмачивание',
        water: 45,
        time: 30,
        id: 1,
        stepType: 'bloom',
        stepKey: '',
        tip: 'Лей от центра',
        isOptional: false,
        untilUser: false,
        untilSign: '',
        warning: '',
      ),
      RecipeStep(
        seqNum: 2,
        instruction: 'Первый пролив',
        water: 105,
        time: 30,
        id: 2,
        stepType: 'pour',
        stepKey: '',
        tip: '',
        isOptional: false,
        untilUser: false,
        untilSign: '',
        warning: '',
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiClient api;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();

    NetworkStatus.reset();
    Outbox.init();

    api = FakeApiClient();
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<ApiClient>(api);
  });

  group('очередь отправки', () {
    test('без сети правка получает отрицательный id и живёт на телефоне', () async {
      api.offline = true;

      final saved = await RecipeService().evolveRecipe(recipe(id: 42));

      expect(saved, lessThan(0), reason: 'локальный id не должен путаться с серверным');
      expect(Outbox.pending.value, 1);
      expect(LocalRecipes.all().map((it) => it.id), [saved]);
    });

    test('сохранённая без сети версия остаётся рецептом, а не обломком', () async {
      api.offline = true;

      final localId = await RecipeService().evolveRecipe(recipe(id: 42));

      final saved = LocalRecipes.all().single;
      expect(saved.id, localId);
      expect(saved.steps.map((step) => step.instruction),
          ['Предсмачивание', 'Первый пролив']);
      expect(saved.steps.first.water, 45);
      expect(saved.temperature, 93);
      expect(saved.device, 'hario_v60');
    });

    test('оценка встаёт в очередь, а не пропадает', () async {
      api.offline = true;

      await RecipeService().postEstimation(recipeId: 5, overall: 8);

      expect(Outbox.pending.value, 1);
    });

    test('досыл подменяет локальный id рецепта на серверный', () async {
      api.offline = true;

      final service = RecipeService();
      final localId = await service.evolveRecipe(recipe(id: 42));
      await service.postEstimation(recipeId: localId, overall: 8);

      expect(Outbox.pending.value, 2);

      api.offline = false;
      api.replies['/recipe/evolve'] = (_) => http.Response('{"id": 777}', 200);

      final report = await Outbox.flush();

      expect(report.sent, 2);
      expect(Outbox.pending.value, 0);

      final estimation = api.calls.firstWhere((call) => call.$1 == '/recipe/estimation');
      expect(estimation.$2['recipe_id'], 777,
          reason: 'оценка должна уехать на версию, которую завёл сервер');

      expect(LocalRecipes.all(), isEmpty, reason: 'уехавшая версия живёт уже на сервере');
    });

    test('порядок сохраняется: сперва версия, потом оценка', () async {
      api.offline = true;

      final service = RecipeService();
      final localId = await service.evolveRecipe(recipe(id: 42));
      await service.postEstimation(recipeId: localId, overall: 8);

      api.offline = false;
      api.replies['/recipe/evolve'] = (_) => http.Response('{"id": 777}', 200);
      await Outbox.flush();

      expect(api.calls.map((call) => call.$1).where((path) => path != '/recipe/evolve').length, 1);
      expect(api.calls.first.$1, '/recipe/evolve');
    });

    test('отвергнутая сервером версия уносит с собой свою оценку', () async {
      api.offline = true;

      final service = RecipeService();
      final localId = await service.evolveRecipe(recipe(id: 42));
      await service.postEstimation(recipeId: localId, overall: 8);

      api.offline = false;
      api.replies['/recipe/evolve'] = (_) => http.Response(
            '{"message":"no such recipe"}',
            404,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );

      final report = await Outbox.flush();

      expect(report.sent, 0);
      expect(report.dropped, 2, reason: 'оценку некуда вешать, если версии нет');
      expect(Outbox.pending.value, 0);
      expect(LocalRecipes.all(), isEmpty);
    });

    test('вторая правка того же рецепта продолжает свою цепочку', () async {
      api.offline = true;

      final service = RecipeService();
      await service.evolveRecipe(recipe(id: 125));
      await service.evolveRecipe(recipe(id: 125));

      api.offline = false;
      var next = 200;
      api.replies['/recipe/evolve'] = (_) => http.Response('{"id": ${next++}}', 200);

      final report = await Outbox.flush();

      expect(report.sent, 2);

      final evolves = api.calls.where((call) => call.$1 == '/recipe/evolve').toList();
      expect(evolves.first.$2['id'], 125);
      expect(evolves.last.$2['id'], 200,
          reason: 'вторая правка встаёт следом за первой, а не спорит с ней');
    });

    test('устаревшая правка встаёт следом за тем, что уже на сервере', () async {
      api.offline = true;
      await RecipeService().evolveRecipe(recipe(id: 125, packId: 7));

      api.offline = false;
      // Сервер: «эту версию уже правили» — и отдаёт голову цепочки.
      var conflicted = false;
      api.replies['/recipe/evolve'] = (body) {
        if (!conflicted && body['id'] == 125) {
          conflicted = true;
          return http.Response(
            '{"message":"not the latest"}',
            409,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{"id": 300}', 200);
      };
      api.getReplies['/recipe/params'] = () => http.Response(
            '[{"id": 154, "date": "2026-08-31T00:00:00Z"}]',
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );

      final report = await Outbox.flush();

      expect(report.sent, 1, reason: 'правку человека нельзя терять из-за того, что рецепт ушёл вперёд');
      expect(report.dropped, 0);

      final evolves = api.calls.where((call) => call.$1 == '/recipe/evolve').toList();
      expect(evolves.length, 2, reason: 'вторая попытка — уже от головы цепочки');
      expect(evolves.last.$2['id'], 154);
    });

    test('безнадёжное дело выбрасывается после пяти попыток', () async {
      api.offline = true;
      await RecipeService().postEstimation(recipeId: 5, overall: 8);

      api.offline = false;
      api.replies['/recipe/estimation'] = (_) => http.Response('{}', 500);

      for (var attempt = 1; attempt <= 4; attempt++) {
        await Outbox.flush();
        expect(Outbox.pending.value, 1, reason: 'попытка $attempt ещё не последняя');
      }

      final last = await Outbox.flush();

      expect(last.dropped, 1);
      expect(Outbox.pending.value, 0, reason: 'иначе одно дело держит всю очередь');
    });

    test('ошибка сервера очередь не съедает — попробуем позже', () async {
      api.offline = true;
      await RecipeService().postEstimation(recipeId: 5, overall: 8);

      api.offline = false;
      api.replies['/recipe/estimation'] = (_) => http.Response('{}', 500);

      final report = await Outbox.flush();

      expect(report.sent, 0);
      expect(report.dropped, 0);
      expect(Outbox.pending.value, 1);
    });

    test('пропавшая посреди досыла сеть оставляет остаток в очереди', () async {
      api.offline = true;

      final service = RecipeService();
      await service.postEstimation(recipeId: 5, overall: 8);
      await service.postEstimation(recipeId: 6, overall: 9);

      expect(Outbox.pending.value, 2);

      final report = await Outbox.flush();

      expect(report.sent, 0);
      expect(Outbox.pending.value, 2);
    });
  });

  group('кэш ответов', () {
    test('удачный ответ сохраняется и достаётся без сети', () async {
      await OfflineCache.put('packs', '[{"id":1}]');

      expect(OfflineCache.body('packs'), '[{"id":1}]');
      expect(OfflineCache.savedAt('packs'), isNotNull);
    });

    test('выход из аккаунта стирает чужое', () async {
      await OfflineCache.put('packs', '[{"id":1}]');
      await OfflineCache.clearAll();

      expect(OfflineCache.body('packs'), isNull);
    });
  });

  group('свои неотправленные версии', () {
    final unsent = [recipe(id: -1001, packId: 7, device: 'hario_v60')];

    test('подмешиваются к списку сервера и стоят первыми', () {
      final merged = withUnsentRecipes([recipe(id: 5)], unsent);

      expect(merged.map((it) => it.id), [-1001, 5]);
    });

    test('чужая пачка не показывается', () {
      final merged = withUnsentRecipes([recipe(id: 5)], unsent, packId: 8);

      expect(merged.map((it) => it.id), [5]);
    });

    test('чужой прибор не показывается', () {
      final merged = withUnsentRecipes([recipe(id: 5)], unsent, device: 'chemex');

      expect(merged.map((it) => it.id), [5]);
    });
  });

  group('оценка без чисел', () {
    test('пустые оси не уезжают вовсе — ноль значил бы «отвратительно»', () async {
      await RecipeService().postEstimation(recipeId: 5, comment: 'горчит');

      final call = api.calls.single;
      expect(call.$1, '/recipe/estimation');
      expect(call.$2.containsKey('overall'), isFalse);
      expect(call.$2.containsKey('aroma'), isFalse);
      expect(call.$2['comment'], 'горчит');
    });

    test('поставленные звёзды уезжают по шкале 0…10', () async {
      await RecipeService().postEstimation(recipeId: 5, overall: 8);

      expect(api.calls.single.$2['overall'], 8);
    });
  });

  group('полоска связи', () {
    // Строки уехали в lib/l10n/app_ru.arb, поэтому берём их через ту же
    // локаль, что увидит человек с русским телефоном.
    final ru = lookupAppLocalizations(const Locale('ru'));

    test('онлайн и пусто — молчит', () {
      expect(offlineBarText(ru, online: true, waiting: 0), isEmpty);
    });

    test('офлайн без очереди — объясняет, откуда данные', () {
      expect(
        offlineBarText(ru, online: false, waiting: 0),
        'Нет сети. Показываем сохранённое',
      );
    });

    test('счёт по-русски', () {
      expect(offlineBarText(ru, online: false, waiting: 1), contains('1 дело уедет'));
      expect(offlineBarText(ru, online: false, waiting: 2), contains('2 дела уедут'));
      expect(offlineBarText(ru, online: false, waiting: 5), contains('5 дел уедут'));
      expect(offlineBarText(ru, online: false, waiting: 11), contains('11 дел уедут'));
      expect(offlineBarText(ru, online: false, waiting: 21), contains('21 дело уедет'));
    });

    test('английская локаль считает по своим правилам', () {
      final en = lookupAppLocalizations(const Locale('en'));

      expect(offlineBarText(en, online: false, waiting: 1), contains('1 item'));
      expect(offlineBarText(en, online: false, waiting: 5), contains('5 items'));
    });
  });

  group('обновление токенов', () {
    test('параллельные 401 обновляют токены один раз', () async {
      var refreshes = 0;
      api.refreshReply = () {
        refreshes++;
        return http.Response(
          '{"access_token":"a","refresh_token":"r"}',
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      };

      final service = AuthService();
      await Future.wait([
        service.refreshTokens(),
        service.refreshTokens(),
        service.refreshTokens(),
      ]);

      expect(refreshes, 1,
          reason: 'сервер помнит только последний refresh — второй запрос'
              ' с тем же токеном означал бы выход из аккаунта');
    });

    test('следующее обновление ходит заново', () async {
      var refreshes = 0;
      api.refreshReply = () {
        refreshes++;
        return http.Response(
          '{"access_token":"a","refresh_token":"r"}',
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      };

      final service = AuthService();
      await service.refreshTokens();
      await service.refreshTokens();

      expect(refreshes, 2);
    });
  });

  group('состояние сети', () {
    test('возвращение сети будит досыл', () {
      var woken = 0;
      NetworkStatus.whenBack(() => woken++);

      NetworkStatus.markOffline();
      expect(NetworkStatus.online.value, isFalse);

      NetworkStatus.markOnline();
      expect(NetworkStatus.online.value, isTrue);
      expect(woken, 1);
    });

    test('повторный успех не будит второй раз', () {
      var woken = 0;
      NetworkStatus.whenBack(() => woken++);

      NetworkStatus.markOffline();
      NetworkStatus.markOnline();
      NetworkStatus.markOnline();

      expect(woken, 1);
    });
  });
}
