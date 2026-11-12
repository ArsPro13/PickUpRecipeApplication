// Повтор рецепта не рождает новую карточку, а дата последнего заваривания
// меняется.
//
// Так владелец сформулировал правило 9 ноября 2026, и до этого оно не
// выполнялось ни в одну сторону:
//
//   * «Заварить снова» на своей карточке не сохраняло ничего — и дата на
//     карточке оставалась датой, когда рецепт когда-то сохранили;
//   * заваривание по справочному рецепту метода при каждом старте сохраняло
//     ещё одну его копию под пачку — стопка показывала «2 версии», «3 версии»
//     с одними и теми же числами;
//   * открытый экран справочного рецепта оставлял в списке карточку «не
//     сохранён» без кофе, которую нечем было ни сохранить, ни стереть.
//
// Здесь проверяется всё, на чём исправление держится и что не видно глазами:
// отпечаток рецепта, местный журнал заварок, порядок и склейка версий, отметка
// о заваривании и её дорога через очередь, поиск уже сохранённой версии.

import 'dart:convert';

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/core/library_revision.dart';
import 'package:pick_up_recipe/core/offline/brew_log.dart';
import 'package:pick_up_recipe/core/offline/network_status.dart';
import 'package:pick_up_recipe/core/offline/offline_exception.dart';
import 'package:pick_up_recipe/core/offline/outbox.dart';
import 'package:pick_up_recipe/core/offline/recipe_drafts.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/src/features/recipes/application/last_brew_cache.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipes_list_state.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Клиент, который не ходит в сеть: отвечает тем, что ему сказали, и
/// записывает, о чём его просили.
class _Api extends ApiClient {
  _Api() : super(onAuthError: _nothing);

  static Future<void> _nothing() async {}

  final Map<String, http.Response Function(Map<String, dynamic> body)> replies =
      {};
  final Map<String, http.Response Function()> getReplies = {};

  /// Что правда ушло на сервер — по порядку.
  final List<(String, Map<String, dynamic>)> calls = [];

  bool offline = false;

  List<Map<String, dynamic>> sent(String endpoint) => [
        for (final call in calls)
          if (call.$1 == endpoint) call.$2,
      ];

  @override
  Future<http.Response> get(String endpoint, Map<String, String> query) async {
    if (offline) throw const OfflineException();
    calls.add((endpoint, query));

    final reply = getReplies[endpoint];
    return reply == null ? http.Response('[]', 200) : reply();
  }

  @override
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    if (offline) throw const OfflineException();
    calls.add((endpoint, body));

    final reply = replies[endpoint];
    return reply == null ? http.Response('{}', 200) : reply(body);
  }
}

RecipeStep _step(int seq, String type, String label,
        {int water = 0, required int time, int id = 0}) =>
    RecipeStep(
      seqNum: seq,
      instruction: label,
      water: water,
      time: time,
      id: id,
      stepType: type,
      stepKey: 's$seq',
      tip: '',
      isOptional: false,
      untilUser: false,
      untilSign: '',
      warning: '',
    );

/// Копия справочного рецепта Clever под пачку — как её сохраняет приложение.
RecipeData clever({
  int id = 170,
  int packId = 11,
  String date = '2026-11-05T23:30:00Z',
  String? lastBrewedAt,
  bool rated = false,
  int water = 280,
}) =>
    RecipeData(
      id: id,
      device: 'clever',
      date: date,
      packId: packId,
      grinderId: 0,
      grindStep: '',
      grindSubStep: null,
      water: water,
      time: 210,
      temperature: 93,
      load: 18,
      title: 'Базовый рецепт: Clever Dripper',
      notes: '',
      grindDescriptor: 'medium',
      agitationLevel: null,
      hasEstimation: rated,
      lastBrewedAt: lastBrewedAt,
      steps: [
        _step(0, 'pour', 'Залить воду', water: water, time: 40, id: id * 10),
        _step(1, 'wait', 'Настаивание', time: 170, id: id * 10 + 1),
      ],
    );

/// Тот же рецепт таким, каким его отдаёт сервер в списке.
Map<String, dynamic> serverJson(RecipeData recipe) => {
      'id': recipe.id,
      'pack_id': recipe.packId,
      'grinder_id': recipe.grinderId,
      'grind_step': recipe.grindStep,
      'water': recipe.water,
      'load': recipe.load,
      'time': recipe.time,
      'date': recipe.date,
      'device': recipe.device,
      'title': recipe.title,
      'notes': recipe.notes,
      'temperature': recipe.temperature,
      'grind_descriptor': recipe.grindDescriptor,
      'agitation_level': recipe.agitationLevel,
      'has_estimation': recipe.hasEstimation,
      if (recipe.lastBrewedAt != null) 'last_brewed_at': recipe.lastBrewedAt,
      'steps': [
        for (final step in recipe.steps)
          {
            'id': step.id,
            'recipe_id': recipe.id,
            'seq_num': step.seqNum,
            'instruction': step.instruction,
            'time': step.time,
            'water': step.water,
            'step_type': step.stepType,
            'step_key': step.stepKey,
            'tip': step.tip,
            'is_optional': step.isOptional,
            'until_user': step.untilUser,
            'until_sign': step.untilSign,
            'warning': step.warning,
          },
      ],
    };

http.Response Function() listOf(List<RecipeData> recipes) =>
    () => http.Response(
          jsonEncode([for (final recipe in recipes) serverJson(recipe)]),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Api api;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();

    NetworkStatus.reset();
    Outbox.init();

    api = _Api();
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<ApiClient>(api);
  });

  group('отпечаток рецепта', () {
    test('оценка и заваривание рецепт другим не делают', () {
      // Это история рецепта, а не рецепт: одна и та же версия до оценки и
      // после неё обязана остаться той же версией.
      final fresh = clever();
      final used = clever(rated: true, lastBrewedAt: '2026-11-09T07:10:00Z');

      expect(recipeFingerprint(used), recipeFingerprint(fresh));
    });

    test('номер и дата — тоже не рецепт: вчерашняя копия и сегодняшняя равны',
        () {
      expect(
        recipeFingerprint(clever(id: 171, date: '2026-11-09T13:23:00Z')),
        recipeFingerprint(clever()),
      );
    });

    test('другая вода — другой рецепт', () {
      expect(recipeFingerprint(clever(water: 420)),
          isNot(recipeFingerprint(clever())));
    });
  });

  group('черновик справочного рецепта', () {
    test('открытый справочный рецепт карточкой «не сохранён» не становится',
        () async {
      // Пачки у справочного рецепта нет: это общий рецепт метода.
      await LastBrewCache.save(clever(id: 7, packId: 0), null);

      expect(RecipeDrafts.all(), isEmpty);
    });

    test('свой несохранённый рецепт по-прежнему запоминается', () async {
      await LastBrewCache.save(clever(water: 300), null);

      expect(RecipeDrafts.all(), hasLength(1));
    });

    test('оставшиеся от прежних сборок черновики без пачки не показываются',
        () async {
      // Так хранилище выглядит на телефоне, обновлённом с 1.0.7: внутри
      // лежит справочный рецепт, который запомнил прежний экран заваривания.
      await EncryptedSharedPreferences.getInstance().setString(
        'recipe_drafts_v1',
        jsonEncode([
          clever(id: 7, packId: 0).toJson(),
          clever(water: 300).toJson(),
        ]),
      );

      final drafts = RecipeDrafts.all();
      expect(drafts, hasLength(1));
      expect(drafts.single.packId, 11);

      // И в список рецептов такой черновик не подмешивается.
      final groups = groupRecipes(withUnsentRecipes(
        const [],
        const [],
        drafts: RecipeDrafts.all(),
      ));
      expect(groups.map((group) => group.packId), [11]);
    });
  });

  group('когда рецептом пользовались', () {
    test('не заваривали — это когда сохранили', () {
      expect(clever().usedAt, '2026-11-05T23:30:00Z');
    });

    test('заваривали — это когда заваривали', () {
      expect(clever(lastBrewedAt: '2026-11-09T07:10:00Z').usedAt,
          '2026-11-09T07:10:00Z');
    });

    test('заваривание раньше сохранения дату не отматывает', () {
      // Так не бывает на одном телефоне, но бывает при переведённых часах.
      expect(clever(lastBrewedAt: '2026-11-01T07:10:00Z').usedAt,
          '2026-11-05T23:30:00Z');
    });

    test('моменты сравниваются временем, а не буквами', () {
      // Буквами «…:05Z» больше, чем «…:05.300Z»: точка стоит раньше «Z».
      expect(compareMoments('2026-11-09T07:10:05Z', '2026-11-09T07:10:05.300Z'),
          lessThan(0));
      expect(
          compareMoments('2026-11-09T10:10:05+03:00', '2026-11-09T07:10:05Z'),
          0);
    });
  });

  group('стопка версий', () {
    test('одинаковые версии — одна карточка', () {
      // Три заваривания по справочному рецепту на 1.0.7 — три копии в базе.
      final groups = groupRecipes([
        clever(id: 170, date: '2026-11-05T23:30:00Z'),
        clever(id: 171, date: '2026-11-07T08:00:00Z', rated: true),
        clever(id: 172, date: '2026-11-09T13:23:00Z'),
      ]);

      final versions = groups.single.versions;
      expect(versions, hasLength(1), reason: 'это один рецепт, а не три');

      final card = versions.single;
      expect(card.recipe.id, 172, reason: 'заваривают снова с той, что свежее');
      expect(card.usedAt, '2026-11-09T13:23:00Z');
      expect(card.rated, isTrue,
          reason: 'оценка, поставленная вчерашней копии, — оценка этого же '
              'рецепта, и «Не оценено» на карточке было бы неправдой');
      expect(card.date, '2026-11-05T23:30:00Z',
          reason: 'рецепт появился, когда сохранили первую копию');
    });

    test('ни одна из одинаковых не оценена — карточка «не оценена»', () {
      final groups = groupRecipes([
        clever(id: 170, date: '2026-11-05T23:30:00Z'),
        clever(id: 171, date: '2026-11-07T08:00:00Z'),
      ]);

      expect(groups.single.versions.single.rated, isFalse);
    });

    test('разные версии остаются разными карточками', () {
      final groups = groupRecipes([
        clever(id: 170),
        clever(id: 175, date: '2026-11-08T08:00:00Z', water: 420),
      ]);

      expect(groups.single.versions, hasLength(2));
    });

    test('повтор прошлой версии поднимает её наверх стопки', () {
      // 420 мл сохранили позже, а вчера снова заварили исходные 280.
      final groups = groupRecipes([
        clever(id: 175, date: '2026-11-08T08:00:00Z', water: 420),
        clever(id: 170, lastBrewedAt: '2026-11-09T07:10:00Z'),
      ]);

      final versions = groups.single.versions;
      expect(versions.map((version) => version.recipe.id), [170, 175]);
      expect(groups.single.latest.usedAt, '2026-11-09T07:10:00Z');
    });

    test('стопка, по которой заваривали последней, стоит в списке первой', () {
      final groups = groupRecipes([
        clever(id: 200, packId: 12, date: '2026-11-08T08:00:00Z'),
        clever(id: 170, packId: 11, lastBrewedAt: '2026-11-09T07:10:00Z'),
      ]);

      expect(groups.map((group) => group.packId), [11, 12]);
    });
  });

  group('журнал заварок на телефоне', () {
    final morning = DateTime.utc(2026, 11, 9, 7, 10);

    test('запоминает последний старт', () async {
      await BrewLog.mark(170, morning);
      await BrewLog.mark(170, morning.add(const Duration(hours: 5)));

      expect(BrewLog.lastFor(170), '2026-11-09T12:10:00.000Z');
      expect(BrewLog.lastFor(999), isNull);
    });

    test('переведённые назад часы свежую запись не затирают', () async {
      await BrewLog.mark(170, morning);
      await BrewLog.mark(170, morning.subtract(const Duration(days: 3)));

      expect(BrewLog.lastFor(170), '2026-11-09T07:10:00.000Z');
    });

    test('дописывает дату рецепту, пока сервер о заваривании не знает',
        () async {
      await BrewLog.mark(170, morning);

      final recipes = [clever(), clever(id: 300)];
      BrewLog.applyTo(recipes);

      expect(recipes.first.lastBrewedAt, '2026-11-09T07:10:00.000Z');
      expect(recipes.last.lastBrewedAt, isNull,
          reason: 'по этому рецепту на телефоне не заваривали');
    });

    test('более позднюю дату с сервера не перебивает', () async {
      // Вечером заварили с другого телефона — сервер знает больше.
      await BrewLog.mark(170, morning);

      final recipe = clever(lastBrewedAt: '2026-11-09T18:00:00Z');
      BrewLog.applyTo([recipe]);

      expect(recipe.lastBrewedAt, '2026-11-09T18:00:00Z');
    });

    test('заваривание версии, сделанной без сети, находит её серверный номер',
        () async {
      // Версию сохранили в лесу под местным номером и тут же заварили.
      api.offline = true;
      final localId = await RecipeService().evolveRecipe(clever(water: 420));
      expect(localId, isNegative);
      await BrewLog.mark(localId, morning);

      // Наутро версия уехала и стала 412-й.
      api.offline = false;
      api.replies['/recipe/evolve'] = (_) => http.Response('{"id": 412}', 200);
      await Outbox.flush();

      expect(BrewLog.lastFor(412), '2026-11-09T07:10:00.000Z');

      final recipe = clever(id: 412, water: 420);
      BrewLog.applyTo([recipe]);
      expect(recipe.lastBrewedAt, '2026-11-09T07:10:00.000Z');
    });

    test('журнал не растёт без конца', () async {
      for (var id = 1; id <= BrewLog.limit + 20; id++) {
        await BrewLog.mark(id, morning.add(Duration(minutes: id)));
      }

      expect(BrewLog.lastFor(1), isNull, reason: 'самое старое вытеснено');
      expect(BrewLog.lastFor(BrewLog.limit + 20), isNotNull);
    });

    test('выход из аккаунта стирает журнал', () async {
      await BrewLog.mark(170, morning);
      await BrewLog.clear();

      expect(BrewLog.lastFor(170), isNull);
    });
  });

  group('отметка о заваривании', () {
    final started = DateTime.utc(2026, 11, 9, 7, 10);

    test('уходит на сервер и сразу видна на телефоне', () async {
      final before = LibraryRevision.revision.value;

      await RecipeService().recordBrew(170, startedAt: started);

      final sent = api.sent('/recipe/brew').single;
      expect(sent['recipe_id'], 170);
      expect(sent['started_at'], '2026-11-09T07:10:00.000Z');
      expect(BrewLog.lastFor(170), '2026-11-09T07:10:00.000Z');
      expect(LibraryRevision.revision.value, greaterThan(before),
          reason: 'списки должны перечитать себя и показать новую дату');
      expect(Outbox.pending.value, 0);
    });

    test('без сети встаёт в очередь и уезжает потом', () async {
      api.offline = true;
      await RecipeService().recordBrew(170, startedAt: started);

      expect(Outbox.pending.value, 1);
      expect(BrewLog.lastFor(170), isNotNull,
          reason: 'дата на карточке сдвигается и без сети');

      api.offline = false;
      final report = await Outbox.flush();

      expect(report.sent, 1);
      final sent = api.sent('/recipe/brew').single;
      expect(sent['recipe_id'], 170);
      expect(sent['started_at'], '2026-11-09T07:10:00.000Z',
          reason: 'время — когда нажали кнопку, а не когда дозвонились');
    });

    test('у версии, сделанной без сети, едет следом за ней и под её номером',
        () async {
      api.offline = true;
      final service = RecipeService();
      final localId = await service.evolveRecipe(clever(water: 420));
      await service.recordBrew(localId, startedAt: started);
      expect(Outbox.pending.value, 2);

      api.offline = false;
      api.replies['/recipe/evolve'] = (_) => http.Response('{"id": 412}', 200);
      await Outbox.flush();

      expect(
          api.calls
              .map((call) => call.$1)
              .where((path) => path.startsWith('/recipe/'))
              .toList(),
          ['/recipe/evolve', '/recipe/brew'],
          reason: 'сперва версия, потом заваривание по ней');
      expect(api.sent('/recipe/brew').single['recipe_id'], 412);
    });

    test('отвергнутая сервером версия уносит с собой и свою отметку', () async {
      api.offline = true;
      final service = RecipeService();
      final localId = await service.evolveRecipe(clever(water: 420));
      await service.recordBrew(localId, startedAt: started);

      api.offline = false;
      api.replies['/recipe/evolve'] = (_) => http.Response('forbidden', 403);
      final report = await Outbox.flush();

      expect(report.dropped, 2);
      expect(api.sent('/recipe/brew'), isEmpty,
          reason: 'версия не завелась — отмечать заваривание не на чем');
      expect(Outbox.pending.value, 0);
    });

    test('старый сервер ручки не знает — заваривание это не трогает', () async {
      api.replies['/recipe/brew'] = (_) => http.Response('Not Found', 404);

      await RecipeService().recordBrew(170, startedAt: started);

      expect(BrewLog.lastFor(170), isNotNull,
          reason: 'дату на этом телефоне держит журнал');
      expect(Outbox.pending.value, 0, reason: 'повторять такой запрос незачем');
    });

    test('отметка из очереди, которую старый сервер отверг, очередь не держит',
        () async {
      api.offline = true;
      final service = RecipeService();
      await service.recordBrew(170, startedAt: started);
      await service.postEstimation(recipeId: 170, overall: 8);

      api.offline = false;
      api.replies['/recipe/brew'] = (_) => http.Response('Not Found', 404);
      final report = await Outbox.flush();

      expect(report.dropped, 1);
      expect(report.sent, 1, reason: 'оценка за отметкой обязана уехать');
      expect(api.sent('/recipe/estimation'), hasLength(1));
    });
  });

  group('сохранить завариваемое — или найти уже сохранённое', () {
    test('такая же копия уже лежит — берётся она, новая не заводится',
        () async {
      api.getReplies['/recipe/params'] = listOf(
          [clever(id: 170, rated: true, lastBrewedAt: '2026-11-06T08:00:00Z')]);

      // Что приложение собирается сохранить со стартом: справочный рецепт
      // под пачку, с номером справочного и без номеров шагов.
      final version = clever(id: 7, date: '2026-09-21T19:36:00Z');
      for (final step in version.steps) {
        step.id = 0;
      }

      final id = await RecipeService().saveBrewedVersion(version);

      expect(id, 170);
      expect(api.sent('/recipe/evolve'), isEmpty);

      final query = api.sent('/recipe/params').single;
      expect(query['pack_id'], '11');
      expect(query['device'], 'clever');
      expect(query['all_versions'], 'true',
          reason: 'та же версия может быть и прошлой в цепочке');
    });

    test('из нескольких одинаковых берётся последняя', () async {
      api.getReplies['/recipe/params'] = listOf([
        clever(id: 171, date: '2026-11-09T13:23:00Z'),
        clever(id: 170),
      ]);

      expect(await RecipeService().saveBrewedVersion(clever(id: 7)), 171);
    });

    test('такой версии нет — сохраняется новая', () async {
      api.getReplies['/recipe/params'] = listOf([clever(id: 170)]);
      api.replies['/recipe/evolve'] = (_) => http.Response('{"id": 501}', 200);

      final id =
          await RecipeService().saveBrewedVersion(clever(id: 170, water: 420));

      expect(id, 501);
      expect(api.sent('/recipe/evolve').single['water'], 420);
    });

    test('несохранённый черновик за сохранённую версию не принимается',
        () async {
      // Правку заварили, не сохранив: она лежит в черновиках и подмешивается
      // к списку, но сохранённой от этого не становится.
      await RecipeDrafts.remember(clever(id: 170, water: 420));
      api.getReplies['/recipe/params'] = listOf([clever(id: 170)]);
      api.replies['/recipe/evolve'] = (_) => http.Response('{"id": 501}', 200);

      final same =
          await RecipeService().findSameVersion(clever(id: 170, water: 420));

      expect(same, isNull);
    });

    test('список не открылся — версия всё равно сохраняется', () async {
      // Вторую такую же в этом случае не заведёт сам сервер.
      api.getReplies['/recipe/params'] = () => http.Response('boom', 500);
      api.replies['/recipe/evolve'] = (_) => http.Response('{"id": 501}', 200);

      expect(await RecipeService().saveBrewedVersion(clever(id: 7)), 501);
    });

    test('справочный рецепт без пачки сохранить не к чему', () async {
      expect(await RecipeService().findSameVersion(clever(id: 7, packId: 0)),
          isNull);
      expect(api.calls, isEmpty);
    });
  });
}
