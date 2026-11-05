// Заваривание, которое идёт, пока человек на другом экране.
//
// До 6 ноября 2026 заваривание жило в состоянии своего экрана: ушли с экрана —
// отсчёт пропал. Стрелка «назад» хотя бы спрашивала «Прервать заваривание?»,
// а вкладка нижней панели уводила молча. Владелец: «пользователь может выйти
// из текущего рецепта, соответственно он не должен остановиться» — и рецепт
// при этом должен стоять на экране «Рецепты», чтобы к нему было куда вернуться.
//
// Движок считает время по настенным часам и умеет подняться из сохранённых
// меток (brew_engine.dart, `restoreFrom`). Здесь эти метки лежат вместе с
// рецептом — в защищённых настройках, по образцу `RatingDrafts`: запись
// переживает и уход с экрана, и приложение, убитое системой посреди колд брю.
//
// Записей может быть несколько, а не одна. Колд брю настаивается двенадцать
// часов, и утренняя воронка не должна стирать его отсчёт; спросить «прервать
// то, что идёт?» перед каждой чашкой было бы хуже, чем просто дать идти обоим.
//
// ── Долгий шаг без присмотра ────────────────────────────────────────────────
//
// С долгого шага — настаивания, нагрева — экран сам зовёт уйти. Но за ним
// идут шаги, которые делают руками: открыть клапан, опустить поршень, снять
// корку. Если часы отыграют их, пока человека нет, он вернётся к «готово» и
// вопросу «начать заново?» — за то, что послушался подсказки.
//
// Поэтому заваривание, с которого ушли на долгом шаге, дальше его конца без
// человека не идёт: настаивание доигрывает до нуля и ждёт. Вернулся — отсчёт
// продолжается со следующего шага, с паузы, по слову «Продолжить». Шаг при
// этом длился дольше, чем в рецепте, — ровно на столько, на сколько человек
// задержался; это правда, и прятать её незачем.

import 'dart:convert';

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/offline/recipe_drafts.dart' show recipeFingerprint;
import '../../packs/domain/models/pack_model.dart';
import '../domain/brew_engine.dart';
import '../domain/brew_step.dart';
import '../domain/models/recipe_data_model.dart';

/// По чему идущее заваривание узнаёт свой рецепт.
///
/// Отпечаток, а не идентификатор: у правки, которую заварили не сохранив,
/// идентификатор тот же, что у версии, от которой её вели, — и по нему экран
/// исходного рецепта подхватил бы чужой отсчёт. Признак «оценён» из отпечатка
/// убран: он приезжает со списком и к самому рецепту не относится.
///
/// Пачка — часть ключа. Справочный рецепт метода один на все пачки, и без
/// неё вчерашнее недоигранное заваривание одного кофе подхватил бы экран
/// другого.
String activeBrewKey(RecipeData recipe, [PackData? pack]) {
  final map = jsonDecode(recipeFingerprint(recipe)) as Map<String, dynamic>
    ..remove('has_estimation');

  return '${pack?.packId ?? recipe.packId}|${jsonEncode(map)}';
}

/// Одно идущее заваривание.
class ActiveBrew {
  const ActiveBrew({
    required this.recipe,
    required this.pack,
    required this.engine,
    RecipeData? brewed,
    this.scaledWater,
    this.savedVersionId,
    this.leftAt,
    this.heldStep,
  }) : _brewed = brewed;

  /// Рецепт, с которым открыли экран заваривания. Целиком, а не номером: с
  /// плашки надо открыть тот же экран, и без сети сходить за рецептом некуда.
  final RecipeData recipe;
  final PackData? pack;

  /// Метки движка — то, что отдал `BrewEngine.toPersistableState`.
  final Map<String, dynamic> engine;

  final RecipeData? _brewed;

  /// Что заваривают на самом деле: [recipe] или он же, пересчитанный на
  /// другой объём. Шаги движка собираются из него.
  RecipeData get brewed => _brewed ?? recipe;

  /// На сколько воды рецепт пересчитали. null — заваривают как есть.
  final int? scaledWater;

  /// Рецепт, сохранённый со стартом заваривания: пересчитанный — новой
  /// версией, справочный — своей копией под эту пачку. Ему уйдёт оценка, и
  /// он же стоит карточкой на «Рецептах». null — сохранять было нечего (свой
  /// рецепт заварили как есть) или сохранить не успели.
  final int? savedVersionId;

  /// С какого момента человек не видит экран заваривания: ушёл с него или
  /// свернул приложение. null — экран открыт.
  final DateTime? leftAt;

  /// Долгий шаг, на котором человек ушёл: дальше его конца заваривание без
  /// присмотра не идёт. null — уходили не с долгого шага (или не уходили).
  final int? heldStep;

  String get key => activeBrewKey(recipe, pack);

  /// Движок в том состоянии, в каком его оставили: по нему плашка считает,
  /// что с завариванием сейчас. null — запись побита.
  ///
  /// Шаг [heldStep] в нём кончается как шаг «пока не скажете сделал»: время
  /// его доигрывает, а следующий без человека не начинается. Механика та же,
  /// что у настоящих таких шагов, — движку о присмотре знать незачем.
  BrewEngine? toEngine({DateTime Function()? clock}) {
    final steps = brewStepsOf(brewed);
    final hold = heldStep;
    if (hold != null && hold >= 0 && hold < steps.length) {
      steps[hold] = _waitingForPerson(steps[hold]);
    }

    final restored = BrewEngine(steps: steps, clock: clock);
    return restored.restoreFrom(engine) ? restored : null;
  }

  /// Движок на момент, когда человек снова смотрит на экран заваривания.
  ///
  /// Если долгий шаг успел кончиться без него, заваривание стоит в конце
  /// этого шага. Возвращение и есть слово «сделал»: простой уходит в
  /// ожидание, а следующий шаг встаёт на паузу — начать его человек должен
  /// сам, когда возьмётся за воронку, а не в ту секунду, когда открыл экран.
  ///
  /// Отдаётся обычный движок, без ожидания на [heldStep]: экран открыт, и
  /// присматривать за шагами снова есть кому. null — запись побита.
  BrewEngine? comeBack({DateTime Function()? clock}) {
    // «Сделал» и пауза — в один и тот же момент. Между двумя обращениями к
    // часам проходят микросекунды, и следующий шаг встал бы на паузу уже
    // начатым: на экране 0:19 вместо его 0:20.
    final now = (clock ?? DateTime.now)();
    final held = toEngine(clock: () => now);
    if (held == null) return null;

    final snapshot = held.snapshot();
    if (snapshot.isAwaitingUser && snapshot.stepIndex == heldStep) {
      held
        ..confirmCurrentStep()
        ..pause();
    }

    final plain = BrewEngine(steps: brewStepsOf(brewed), clock: clock);
    return plain.restoreFrom(held.toPersistableState()) ? plain : null;
  }

  /// Та же запись, с экрана которой ушли в [moment].
  ///
  /// Здесь же решается, ждать ли человека: если в этот момент шёл долгий
  /// шаг, дальше его конца заваривание без присмотра не пойдёт. Последний
  /// шаг не в счёт — за ним ничего не делают руками, заваривание просто
  /// кончается; не в счёт и шаг, который и так ждёт слова «сделал».
  ActiveBrew leftAtMoment(DateTime moment) {
    int? hold;

    final plain = BrewEngine(steps: brewStepsOf(brewed));
    if (plain.restoreFrom(engine)) {
      final snapshot = plain.snapshotAt(moment);
      final index = snapshot.stepIndex;
      if (snapshot.isRunning &&
          index < plain.steps.length - 1 &&
          isLongWait(plain.steps[index]) &&
          !plain.steps[index].waitsForTap) {
        hold = index;
      }
    }

    return ActiveBrew(
      recipe: recipe,
      pack: pack,
      engine: engine,
      brewed: _brewed,
      scaledWater: scaledWater,
      savedVersionId: savedVersionId,
      leftAt: moment,
      heldStep: hold,
    );
  }

  /// Та же запись, у которой завариваемый рецепт уже сохранён версией [id].
  ActiveBrew withSavedVersion(int id) => ActiveBrew(
        recipe: recipe,
        pack: pack,
        engine: engine,
        brewed: _brewed,
        scaledWater: scaledWater,
        savedVersionId: id,
        leftAt: leftAt,
        heldStep: heldStep,
      );

  /// Тот же шаг, но следующий за ним ждёт человека.
  static BrewStep _waitingForPerson(BrewStep step) => BrewStep(
        id: step.id,
        type: step.type,
        label: step.label,
        duration: step.duration,
        waterG: step.waterG,
        tip: step.tip,
        isOptional: step.isOptional,
        untilUser: true,
        untilSign: step.untilSign,
        warning: step.warning,
      );

  Map<String, dynamic> toJson() => {
        'recipe': recipe.toJson(),
        if (pack != null) 'pack': pack!.toJson(),
        if (_brewed != null) 'brewed': _brewed.toJson(),
        'engine': engine,
        if (scaledWater != null) 'scaled_water': scaledWater,
        if (savedVersionId != null) 'saved_version_id': savedVersionId,
        if (leftAt != null) 'left_at': leftAt!.toUtc().toIso8601String(),
        if (heldStep != null) 'held_step': heldStep,
      };

  static ActiveBrew fromJson(Map<String, dynamic> json) => ActiveBrew(
        recipe: RecipeData.fromJson(json['recipe'] as Map<String, dynamic>),
        pack: json['pack'] == null
            ? null
            : PackData.fromJson(json['pack'] as Map<String, dynamic>),
        brewed: json['brewed'] == null
            ? null
            : RecipeData.fromJson(json['brewed'] as Map<String, dynamic>),
        engine: Map<String, dynamic>.from(json['engine'] as Map),
        scaledWater: (json['scaled_water'] as num?)?.toInt(),
        savedVersionId: (json['saved_version_id'] as num?)?.toInt(),
        leftAt: DateTime.tryParse(json['left_at'] as String? ?? ''),
        heldStep: (json['held_step'] as num?)?.toInt(),
      );
}

abstract final class ActiveBrews {
  static const String _key = 'active_brews_v1';

  /// Сколько запись живёт после того, как заваривание должно было кончиться.
  ///
  /// Сутки: вчерашний недоигранный таймер уже никому не нужен, а плашка
  /// «идёт заваривание» без срока висела бы на главном экране вечно — шаг
  /// «пока не скажете сделал» сам не кончается никогда.
  static const Duration grace = Duration(hours: 24);

  /// Идущие заваривания — за ними смотрит плашка на «Рецептах» и «Пачках».
  ///
  /// `ValueNotifier`, как `RatingDrafts.current`: пишет запись экран
  /// заваривания, а показывает её совсем другая вкладка.
  static final ValueNotifier<List<ActiveBrew>> current =
      ValueNotifier<List<ActiveBrew>>(const []);

  static bool _loaded = false;

  static EncryptedSharedPreferences get _prefs =>
      EncryptedSharedPreferences.getInstance();

  /// Читает записи из настроек — после запуска приложения.
  ///
  /// Протухшие и побитые отбрасываются здесь же: запись, которую нельзя
  /// поднять, равна отсутствующей — чинить её не из чего.
  static void load() {
    _loaded = true;

    final stored = _read();
    final alive = _withoutStale(stored);
    current.value = alive;

    if (alive.length != stored.length) _write(alive);
  }

  /// Заваривание этого рецепта по этой пачке, если оно идёт.
  ///
  /// Рецепт узнаётся и по номеру версии, сохранённой со стартом. Пока идёт
  /// заваривание, эта версия уже стоит карточкой на «Рецептах», и нажатие на
  /// неё обязано привести к тому же таймеру, что и плашка, — а не открыть
  /// рецепт заново рядом с идущим.
  static ActiveBrew? find(RecipeData recipe, [PackData? pack]) {
    _ensureLoaded();

    final key = activeBrewKey(recipe, pack);
    for (final brew in current.value) {
      if (brew.key == key) return brew;
    }
    for (final brew in current.value) {
      if (recipe.id != 0 && brew.savedVersionId == recipe.id) return brew;
    }
    return null;
  }

  /// Запоминает заваривание — или обновляет запись о нём.
  ///
  /// Новая запись встаёт первой: на плашке сверху то, что начали позже.
  static Future<void> put(ActiveBrew brew) async {
    _ensureLoaded();

    final key = brew.key;
    final list = current.value;
    final at = list.indexWhere((it) => it.key == key);

    final next = at < 0
        ? [brew, ...list]
        : [
            for (var index = 0; index < list.length; index++)
              index == at ? brew : list[index],
          ];

    current.value = _withoutStale(next);
    await _write(current.value);
  }

  /// Заваривание кончилось: доиграно до оценки или прервано.
  static Future<void> remove(String key) async {
    _ensureLoaded();
    if (!current.value.any((it) => it.key == key)) return;

    current.value = [
      for (final brew in current.value)
        if (brew.key != key) brew,
    ];
    await _write(current.value);
  }

  /// Человек ушёл с экрана заваривания.
  ///
  /// Если записи нет, ничего не происходит: с экрана уходят и после оценки, и
  /// после «Прервать», когда запоминать уже нечего. Возвращение отмечать
  /// отдельно не нужно: экран, открытый снова, записывает заваривание заново
  /// — уже без отметки ухода.
  static Future<void> markLeft(String key, DateTime moment) async {
    final brew = _byKey(key);
    if (brew == null) return;

    await put(brew.leftAtMoment(moment));
  }

  /// Завариваемый рецепт сохранился версией — оценка уйдёт ей и после
  /// возврата к завариванию.
  static Future<void> markSavedVersion(String key, int id) async {
    final brew = _byKey(key);
    if (brew == null) return;

    await put(brew.withSavedVersion(id));
  }

  /// Выход из аккаунта: чужой таймер на главном экране хуже пустого.
  static Future<void> clear() async {
    _loaded = true;
    current.value = const [];
    await _prefs.remove(_key);
  }

  /// Протухла ли запись к моменту [now].
  ///
  /// Срок считается от ухода с экрана (а без него — от старта) и от полной
  /// длительности рецепта: колд брю на двенадцать часов обязан дожить до
  /// утра, а брошенная трёхминутная воронка — нет.
  ///
  /// Отдельной функцией ради теста: ошибка здесь стирает идущий колд брю.
  static bool isStale(ActiveBrew brew, DateTime now) {
    final engine = brew.toEngine();
    if (engine == null) return true;

    final startedAt =
        DateTime.tryParse(brew.engine['started_at'] as String? ?? '');
    final since = brew.leftAt ?? startedAt ?? now;

    return now.difference(since) > engine.totalDuration + grace;
  }

  static ActiveBrew? _byKey(String key) {
    _ensureLoaded();
    for (final brew in current.value) {
      if (brew.key == key) return brew;
    }
    return null;
  }

  /// Экран заваривания могут открыть раньше корневого — по ссылке с пачки.
  static void _ensureLoaded() {
    if (!_loaded) load();
  }

  static List<ActiveBrew> _withoutStale(List<ActiveBrew> brews) {
    final now = DateTime.now();
    return [
      for (final brew in brews)
        if (!isStale(brew, now)) brew,
    ];
  }

  static List<ActiveBrew> _read() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      return [
        for (final item in jsonDecode(raw) as List<dynamic>)
          ActiveBrew.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      // Битый список — то же, что пустой.
      return const [];
    }
  }

  static Future<void> _write(List<ActiveBrew> brews) async {
    if (brews.isEmpty) {
      await _prefs.remove(_key);
      return;
    }

    await _prefs.setString(
      _key,
      jsonEncode([for (final brew in brews) brew.toJson()]),
    );
  }
}
