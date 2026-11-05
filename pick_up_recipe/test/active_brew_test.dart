// Запись об идущем заваривании: то, на чём держится «ушёл с экрана — таймер
// идёт».
//
// Проверяется тестом, а не руками, по той же причине, что и черновик оценки:
// ошибка здесь не ломает экран, а молча теряет отсчёт — и заметить это можно
// только у чайника, с водой в воронке и без таймера.

import 'dart:convert';

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/recipes/application/active_brew.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/brew_engine.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/brew_step.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

RecipeStep step(int seqNum, {int time = 30, String type = 'pour'}) =>
    RecipeStep(
      seqNum: seqNum,
      instruction: 'Шаг $seqNum',
      water: type == 'pour' ? 60 : 0,
      time: time,
      id: seqNum,
      stepType: type,
      stepKey: '',
      tip: '',
      isOptional: false,
      untilUser: false,
      untilSign: '',
      warning: '',
    );

RecipeData recipe({
  int id = 42,
  String device = 'hario_v60',
  int water = 250,
  List<RecipeStep>? steps,
  bool rated = false,
  String date = '2026-11-05T10:00:00Z',
}) =>
    RecipeData(
      hasEstimation: rated,
      id: id,
      device: device,
      date: date,
      packId: 7,
      grinderId: 1,
      grindStep: '18',
      grindSubStep: null,
      water: water,
      time: 90,
      temperature: 93,
      load: 15,
      title: 'Харио V60',
      notes: '',
      grindDescriptor: 'medium',
      agitationLevel: null,
      steps: steps ?? [step(1), step(2), step(3)],
    );

/// Колд брю: залить и двенадцать часов в холодильнике.
RecipeData coldBrew() => recipe(
      id: 77,
      device: 'cold_brew',
      water: 600,
      steps: [step(1, time: 90), step(2, time: 43200, type: 'wait')],
    );

PackData pack() => PackData(
      packId: 7,
      userId: '1',
      packDate: '2026-11-01T10:00:00Z',
      packName: 'Бразилия Можиана',
      packDescriptors: const [],
      packCountry: 'Бразилия',
      packProcessingMethod: const [],
      packImage: '',
      packVariety: 'бурбон',
      packScaScore: 84,
      isActive: true,
      roasterName: 'Tasty',
    );

/// Запись о заваривании, начатом [ago] назад.
ActiveBrew started(
  RecipeData recipe, {
  Duration ago = Duration.zero,
  Duration? left,
  RecipeData? brewed,
  int? scaledWater,
}) {
  final now = DateTime.now();
  final engine = BrewEngine(
    steps: brewStepsOf(brewed ?? recipe),
    clock: () => now.subtract(ago),
  )..start();

  return ActiveBrew(
    recipe: recipe,
    pack: pack(),
    brewed: brewed,
    scaledWater: scaledWater,
    engine: engine.toPersistableState(),
    leftAt: left == null ? null : now.subtract(left),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();
    ActiveBrews.load();
  });

  group('по чему заваривание узнаёт свой рецепт', () {
    test('тот же рецепт с другим номером и датой — то же заваривание', () {
      // Рецепт перечитали со списка: сервер мог отдать его с другой датой.
      expect(
        activeBrewKey(recipe(id: 1, date: '2026-11-05T10:00:00Z')),
        activeBrewKey(recipe(id: 2, date: '2026-11-06T08:00:00Z')),
      );
    });

    test('оценка рецепта его не меняет', () {
      // «Оценён» приезжает со списком и к самому рецепту не относится.
      expect(activeBrewKey(recipe(rated: true)), activeBrewKey(recipe()));
    });

    test('правка без сохранения — уже другое заваривание', () {
      // Номер у неё тот же, что у версии, от которой её вели: по номеру
      // экран исходного рецепта подхватил бы чужой отсчёт.
      expect(
        activeBrewKey(recipe(water: 300)),
        isNot(activeBrewKey(recipe(water: 250))),
      );
    });

    test('справочный рецепт по другой пачке — другое заваривание', () async {
      // Рецепт метода один на все пачки (пачка 0). Без пачки в ключе
      // вчерашнее недоигранное заваривание одного кофе подхватил бы экран
      // другого.
      final base = recipe()..packId = 0;
      final other = pack()..packId = 8;

      expect(activeBrewKey(base, pack()), isNot(activeBrewKey(base, other)));

      await ActiveBrews.put(started(base));
      expect(ActiveBrews.find(base, pack()), isNotNull);
      expect(ActiveBrews.find(base, other), isNull);
    });
  });

  group('запись', () {
    test('находится по рецепту и поднимает движок с того же места', () async {
      await ActiveBrews.put(
          started(recipe(), ago: const Duration(seconds: 40)));

      final found = ActiveBrews.find(recipe(), pack());
      expect(found, isNotNull);

      final snapshot = found!.toEngine()!.snapshot();
      expect(snapshot.status, BrewStatus.running);
      expect(snapshot.stepIndex, 1, reason: 'сорок секунд — это второй пролив');
    });

    test('переживает перезапуск приложения', () async {
      await ActiveBrews.put(started(
        recipe(),
        ago: const Duration(seconds: 40),
        left: const Duration(seconds: 5),
      ));

      // Приложение убито и запущено заново: в памяти пусто, читаем настройки.
      ActiveBrews.current.value = const [];
      ActiveBrews.load();

      final found = ActiveBrews.find(recipe(), pack());
      expect(found, isNotNull);
      expect(found!.pack?.packName, 'Бразилия Можиана');
      expect(found.leftAt, isNotNull);
      expect(found.toEngine()!.snapshot().stepIndex, 1);
    });

    test('пересчитанный рецепт возвращается пересчитанным', () async {
      final doubled = recipe(water: 500, steps: [
        step(1, time: 45),
        step(2, time: 45),
        step(3, time: 45),
      ]);
      await ActiveBrews.put(started(
        recipe(),
        ago: const Duration(seconds: 40),
        brewed: doubled,
        scaledWater: 500,
      ));
      await ActiveBrews.markSavedVersion(activeBrewKey(recipe(), pack()), 901);

      ActiveBrews.current.value = const [];
      ActiveBrews.load();

      final found = ActiveBrews.find(recipe(), pack())!;
      expect(found.scaledWater, 500);
      expect(found.savedVersionId, 901,
          reason: 'оценка уйдёт версии, сохранённой при старте');
      expect(found.brewed.water, 500);
      expect(found.toEngine()!.snapshot().stepIndex, 0,
          reason: 'шаги — пересчитанного рецепта: сорок секунд из сорока пяти');
    });

    test('та же запись обновляется, а не множится', () async {
      await ActiveBrews.put(started(recipe()));
      await ActiveBrews.put(started(recipe(), ago: const Duration(seconds: 5)));

      expect(ActiveBrews.current.value, hasLength(1));
    });

    test('два заваривания идут рядом, свежее — первым', () async {
      await ActiveBrews.put(started(coldBrew(), ago: const Duration(hours: 3)));
      await ActiveBrews.put(started(recipe()));

      expect(
        ActiveBrews.current.value.map((it) => it.recipe.device).toList(),
        ['hario_v60', 'cold_brew'],
        reason: 'воронка не стирает колд брю, который настаивается с ночи',
      );
    });

    test('remove стирает только своё', () async {
      await ActiveBrews.put(started(coldBrew()));
      await ActiveBrews.put(started(recipe()));

      await ActiveBrews.remove(activeBrewKey(recipe(), pack()));

      expect(ActiveBrews.find(recipe(), pack()), isNull);
      expect(ActiveBrews.find(coldBrew(), pack()), isNotNull);
    });

    test('отметка «ушли» без записи ничего не заводит', () async {
      await ActiveBrews.markLeft(
          activeBrewKey(recipe(), pack()), DateTime.now());

      expect(ActiveBrews.current.value, isEmpty,
          reason: 'с экрана уходят и после оценки, и не начав заваривать');
    });

    test('clear стирает всё — выход из аккаунта', () async {
      await ActiveBrews.put(started(recipe()));

      await ActiveBrews.clear();
      ActiveBrews.load();

      expect(ActiveBrews.current.value, isEmpty);
    });

    test('битая запись равна отсутствующей', () async {
      await EncryptedSharedPreferences.getInstance()
          .setString('active_brews_v1', '{не json');

      ActiveBrews.load();

      expect(ActiveBrews.current.value, isEmpty);
    });

    test('запись без момента старта не поднимается', () {
      final broken = ActiveBrew(recipe: recipe(), pack: null, engine: const {});

      expect(broken.toEngine(), isNull);
      expect(ActiveBrews.isStale(broken, DateTime.now()), isTrue);
    });

    test('запись целиком проходит через JSON', () {
      final original = started(
        recipe(),
        ago: const Duration(seconds: 12),
        left: const Duration(seconds: 3),
        scaledWater: 500,
        brewed: recipe(water: 500),
      ).withSavedVersion(55);

      final copy = ActiveBrew.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(copy.key, original.key);
      expect(copy.brewed.water, 500);
      expect(copy.scaledWater, 500);
      expect(copy.savedVersionId, 55);
      expect(copy.leftAt!.isAtSameMomentAs(original.leftAt!), isTrue);
      expect(copy.engine, original.engine);
    });
  });

  // С долгого шага экран сам зовёт уйти. Если за ним часы отыграют шаги,
  // которые делают руками, человек вернётся к «готово» и вопросу «начать
  // заново?» — за то, что послушался подсказки.
  group('долгий шаг без присмотра', () {
    /// Френч-пресс: залить, четыре минуты настаивания, снять корку, поршень.
    RecipeData frenchPress() => recipe(
          id: 91,
          device: 'french_press',
          steps: [
            step(1, time: 30),
            step(2, time: 240, type: 'wait'),
            step(3, time: 20, type: 'stir'),
            step(4, time: 20, type: 'press'),
          ],
        );

    /// Запись о заваривании френч-пресса: начали [ago] назад, с экрана ушли
    /// [left] назад.
    Future<ActiveBrew> leftBrew({
      required Duration ago,
      required Duration left,
      RecipeData? of,
    }) async {
      final brew = started(of ?? frenchPress(), ago: ago);
      await ActiveBrews.put(brew);
      await ActiveBrews.markLeft(brew.key, DateTime.now().subtract(left));

      return ActiveBrews.find(of ?? frenchPress(), pack())!;
    }

    test('ушли на настаивании — оно доигрывает и ждёт человека', () async {
      // Начали десять минут назад, ушли на второй минуте настаивания.
      final brew = await leftBrew(
        ago: const Duration(minutes: 10),
        left: const Duration(minutes: 8, seconds: 30),
      );

      expect(brew.heldStep, 1);
      final snapshot = brew.toEngine()!.snapshot();
      expect(snapshot.status, BrewStatus.awaitingUser,
          reason: 'без человека корку никто не снял — отыгрывать её нельзя');
      expect(snapshot.stepIndex, 1);
    });

    test('пока настаивание идёт, оно просто идёт', () async {
      final brew = await leftBrew(
        ago: const Duration(minutes: 2),
        left: const Duration(seconds: 30),
      );

      expect(brew.heldStep, 1);
      final snapshot = brew.toEngine()!.snapshot();
      expect(snapshot.status, BrewStatus.running);
      expect(snapshot.stepIndex, 1);
      expect(snapshot.remainingInStep.inSeconds, closeTo(150, 2));
    });

    test('вернулись после настаивания — следующий шаг, с паузы', () async {
      final brew = await leftBrew(
        ago: const Duration(minutes: 10),
        left: const Duration(minutes: 8, seconds: 30),
      );

      final snapshot = brew.comeBack()!.snapshot();

      expect(snapshot.stepIndex, 2, reason: 'корку снимают сейчас, с начала');
      expect(snapshot.status, BrewStatus.paused,
          reason: 'начать шаг человек должен сам, а не в миг открытия экрана');
      expect(snapshot.elapsedInStep, Duration.zero,
          reason: 'шаг на паузе в самом начале — на экране его полные 0:20');
    });

    test('вернулись во время настаивания — тот же отсчёт', () async {
      final brew = await leftBrew(
        ago: const Duration(minutes: 2),
        left: const Duration(seconds: 30),
      );

      final snapshot = brew.comeBack()!.snapshot();

      expect(snapshot.status, BrewStatus.running);
      expect(snapshot.stepIndex, 1);
      expect(snapshot.remainingInStep.inSeconds, closeTo(150, 2));
    });

    test('ушли с пролива — заваривание никого не ждёт', () async {
      // Сколько воды уже в воронке, часы не знают: тут спрашивает экран.
      final brew = await leftBrew(
        ago: const Duration(minutes: 10),
        left: const Duration(minutes: 9, seconds: 50),
      );

      expect(brew.heldStep, isNull);
      expect(brew.toEngine()!.snapshot().status, BrewStatus.finished);
    });

    test('долгий последний шаг просто кончается', () async {
      // За ним ничего не делают руками — ждать некого.
      final brew = await leftBrew(
        of: coldBrew(),
        ago: const Duration(hours: 13),
        left: const Duration(hours: 12, minutes: 50),
      );

      expect(brew.heldStep, isNull);
      expect(brew.toEngine()!.snapshot().status, BrewStatus.finished);
    });

    test('шаг «пока не скажете сделал» ждёт сам и не подтверждается за нас',
        () async {
      // Турка: греть до подъёма пены — три минуты ориентира и слово «сделал».
      final cezve = recipe(id: 92, device: 'cezve', steps: [
        step(1, time: 20),
        RecipeStep(
          seqNum: 2,
          instruction: 'Греть до подъёма пены',
          water: 0,
          time: 180,
          id: 2,
          stepType: 'wait',
          stepKey: '',
          tip: '',
          isOptional: false,
          untilUser: true,
          untilSign: '',
          warning: '',
        ),
        step(3, time: 20, type: 'serve'),
      ]);
      final brew = await leftBrew(
        of: cezve,
        ago: const Duration(minutes: 10),
        left: const Duration(minutes: 9),
      );

      expect(brew.heldStep, isNull);
      final snapshot = brew.comeBack()!.snapshot();
      expect(snapshot.status, BrewStatus.awaitingUser,
          reason: 'пену видел только человек — «сделал» скажет он сам');
      expect(snapshot.stepIndex, 1);
    });

    test('ожидание переживает перезапуск приложения', () async {
      await leftBrew(
        ago: const Duration(minutes: 10),
        left: const Duration(minutes: 8, seconds: 30),
      );

      ActiveBrews.current.value = const [];
      ActiveBrews.load();

      final brew = ActiveBrews.find(frenchPress(), pack())!;
      expect(brew.heldStep, 1);
      expect(brew.toEngine()!.snapshot().status, BrewStatus.awaitingUser);
    });
  });

  group('срок годности', () {
    final now = DateTime(2026, 11, 6, 9);

    ActiveBrew at(RecipeData recipe, DateTime startedAt, {DateTime? leftAt}) =>
        ActiveBrew(
          recipe: recipe,
          pack: null,
          engine:
              (BrewEngine(steps: brewStepsOf(recipe), clock: () => startedAt)
                    ..start())
                  .toPersistableState(),
          leftAt: leftAt,
        );

    test('вчерашняя воронка, к которой не вернулись, протухла', () {
      final abandoned = at(
        recipe(),
        now.subtract(const Duration(hours: 30)),
        leftAt: now.subtract(const Duration(hours: 30)),
      );

      expect(ActiveBrews.isStale(abandoned, now), isTrue);
    });

    test('воронка, с которой ушли час назад, ещё жива', () {
      final recent = at(
        recipe(),
        now.subtract(const Duration(hours: 1)),
        leftAt: now.subtract(const Duration(hours: 1)),
      );

      expect(ActiveBrews.isStale(recent, now), isFalse);
    });

    test('колд брю живёт все свои двенадцать часов и сутки после', () {
      // Поставили вчера вечером и ушли: к утру он обязан быть на месте.
      final overnight = at(
        coldBrew(),
        now.subtract(const Duration(hours: 30)),
        leftAt: now.subtract(const Duration(hours: 30)),
      );
      expect(ActiveBrews.isStale(overnight, now), isFalse);

      final forgotten = at(
        coldBrew(),
        now.subtract(const Duration(hours: 40)),
        leftAt: now.subtract(const Duration(hours: 40)),
      );
      expect(ActiveBrews.isStale(forgotten, now), isTrue);
    });

    test('протухшее отбрасывается при чтении', () async {
      final started = DateTime.now().subtract(const Duration(days: 3));
      await EncryptedSharedPreferences.getInstance().setString(
        'active_brews_v1',
        jsonEncode([at(recipe(), started, leftAt: started).toJson()]),
      );

      ActiveBrews.load();

      expect(ActiveBrews.current.value, isEmpty);
    });
  });
}
