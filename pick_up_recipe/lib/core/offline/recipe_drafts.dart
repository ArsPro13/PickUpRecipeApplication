// Изменённые, но не сохранённые рецепты.
//
// Рядом с `LocalRecipes` и по той же причине: и там, и здесь лежат версии,
// которых на сервере нет. Разница в том, что версия из `LocalRecipes` уже
// уехала бы, будь связь, а эта — не уедет никогда, потому что человек не
// нажимал «Сохранить».
//
// Терялись два случая, и оба обидные: рецепт поправили и заварили, не сохранив;
// рецепт поправили, начали заваривать и бросили на втором шаге. В обоих человек
// сделал работу — подобрал помол, сдвинул температуру, — и наутро её нет вовсе,
// потому что кнопку он не нажал. Список теперь показывает такую версию с
// пометкой: она не «сохранена», но и не выброшена.
//
// Черновик заводится в момент входа на экран заваривания и опознаётся не по
// идентификатору, а по отпечатку — набору тех же полей, что уходят на сервер.
// Отсюда сразу два нужных свойства: повторный вход в тот же рецепт не плодит
// второй черновик, а сохранённая версия сама вытесняет свой черновик — их
// отпечатки совпадают.
//
// Хранится только на телефоне. Колонки под это в базе нет, серверных миграций
// не делаем: переустановка приложения черновики сотрёт, и обещать иное нельзя.

import 'dart:convert';

import 'package:encrypt_shared_preferences/provider.dart';

import '../../src/features/recipes/domain/models/recipe_data_model.dart';

/// Отпечаток рецепта: всё, что его описывает, кроме идентификаторов и даты.
///
/// Ни id, ни дата рецепт не описывают: одна и та же правка, доехав до сервера,
/// получает и новый идентификатор, и новое время — а рецептом остаётся тем же.
/// Идентификаторы шагов выбрасываются по той же причине: их проставляет база.
///
/// Не описывают его и два поля, которые сервер считает вместе со списком:
/// «у чашки есть оценка» и «когда заваривали последний раз». Это история
/// рецепта, а не рецепт. Пока они входили в отпечаток, одна и та же версия до
/// оценки и после неё выглядела двумя разными рецептами.
///
/// Отдельной чистой функцией, чтобы проверялось тестом: на равенстве отпечатков
/// держится и то, что черновик один, и то, что сохранённая версия его гасит, и
/// то, что повтор рецепта находит уже сохранённую версию, а не заводит вторую.
String recipeFingerprint(RecipeData recipe) {
  final map = jsonDecode(jsonEncode(recipe)) as Map<String, dynamic>;

  map.remove('id');
  map.remove('date');
  map.remove('has_estimation');
  map.remove('last_brewed_at');
  for (final step in (map['steps'] as List<dynamic>? ?? const [])) {
    (step as Map<String, dynamic>).remove('id');
  }

  return jsonEncode(map);
}

abstract final class RecipeDrafts {
  static const String _key = 'recipe_drafts_v1';

  /// Сколько черновиков держим. Свежие вытесняют старые.
  ///
  /// Предел нужен потому, что черновик заводится на каждом входе в заваривание:
  /// без него список рос бы всю жизнь телефона. Двадцати хватает с запасом —
  /// совпавшие с сохранённым уходят сами.
  static const int limit = 20;

  static EncryptedSharedPreferences get _prefs =>
      EncryptedSharedPreferences.getInstance();

  /// Все черновики, свежие первыми.
  ///
  /// Черновики без пачки отбрасываются при чтении. Раньше экран заваривания
  /// запоминал и справочный рецепт метода — он общий, пачки у него нет, — и в
  /// «Рецептах» появлялась карточка «не сохранён» без кофе и с датой
  /// справочника. Сохранить её было нельзя и стереть нечем: ни одна
  /// сохранённая версия с ней не совпадала. Такие записи остались на
  /// телефонах, и показывать их больше незачем — справочный рецепт со стартом
  /// заваривания ложится своей копией под пачку.
  static List<RecipeData> all() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          RecipeData.fromJson(item as Map<String, dynamic>),
      ].where((draft) => draft.packId != 0).toList();
    } catch (_) {
      // Битый список — то же, что пустой: чинить его не из чего.
      return const [];
    }
  }

  /// Отпечатки всех черновиков. По ним список ставит пометку.
  static Set<String> keys() =>
      {for (final draft in all()) recipeFingerprint(draft)};

  /// Запоминает рецепт, по которому начали заваривать.
  ///
  /// Тот же рецепт второй раз не заводит второго черновика: запись одна на
  /// отпечаток, и повторный вход только поднимает её наверх.
  ///
  /// Справочный рецепт метода (без пачки) не запоминается: черновик нужен
  /// правке, которую человек сделал и не сохранил, а здесь править было
  /// нечего — см. [all].
  static Future<void> remember(RecipeData recipe) async {
    if (recipe.packId == 0) return;

    final key = recipeFingerprint(recipe);
    final kept = all().where((it) => recipeFingerprint(it) != key).toList();

    await _save([recipe, ...kept].take(limit).toList());
  }

  /// Забывает черновики, которые совпали с уже сохранённым.
  ///
  /// Зовётся при каждом чтении списка: как только правка доехала до сервера
  /// (или встала в очередь), её черновик перестаёт быть черновиком — иначе
  /// сохранённая версия ходила бы по списку с пометкой «не сохранён».
  static Future<void> forgetKnown(List<RecipeData> known) async {
    if (known.isEmpty) return;

    final saved = {for (final recipe in known) recipeFingerprint(recipe)};
    final kept =
        all().where((it) => !saved.contains(recipeFingerprint(it))).toList();
    if (kept.length == all().length) return;

    await _save(kept);
  }

  static Future<void> clear() => _prefs.remove(_key);

  static Future<void> _save(List<RecipeData> drafts) async {
    await _prefs.setString(
      _key,
      jsonEncode([for (final draft in drafts) draft.toJson()]),
    );
  }
}

/// Черновики, которых ещё нет ни на сервере, ни в очереди.
///
/// Чистая функция рядом с `withUnsentRecipes` и ради того же — теста без сети:
/// ошибка здесь выглядит как сохранённая версия с пометкой «не сохранён», то
/// есть как враньё на карточке.
List<RecipeData> unsavedDrafts(
  List<RecipeData> drafts,
  List<RecipeData> known, {
  int? packId,
  String? device,
}) {
  final saved = {for (final recipe in known) recipeFingerprint(recipe)};

  return drafts.where((draft) {
    if (packId != null && draft.packId != packId) return false;
    if (device != null && draft.device != device) return false;
    return !saved.contains(recipeFingerprint(draft));
  }).toList();
}
