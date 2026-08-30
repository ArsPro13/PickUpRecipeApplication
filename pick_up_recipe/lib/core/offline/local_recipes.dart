// Версии рецептов, сделанные без сети.
//
// Пока правка не уехала на сервер, она существует только здесь — и должна
// вести себя как обычный рецепт: лежать в «Моих рецептах», открываться,
// завариваться. Иначе человек, поправивший помол в лесу, увидит, что его
// работа исчезла, и второй раз он её делать не станет.
//
// Хранится клиентская модель, а не тело ответа сервера: сервер этой версии
// ещё не видел, и подделывать его формат было бы враньём.

import 'dart:convert';

import 'package:encrypt_shared_preferences/provider.dart';

import '../../src/features/recipes/domain/models/recipe_data_model.dart';

abstract final class LocalRecipes {
  static const String _key = 'offline_local_recipes_v1';

  static EncryptedSharedPreferences get _prefs =>
      EncryptedSharedPreferences.getInstance();

  /// Всё, что ещё не уехало. Свежие первыми — как в списке.
  static List<RecipeData> all() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list) RecipeData.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      // Битый список — то же, что пустой: чинить его не из чего.
      return const [];
    }
  }

  static Future<void> add(RecipeData recipe) async {
    final kept = all().where((it) => it.id != recipe.id).toList();
    await _save([recipe, ...kept]);
  }

  /// Убирает версию, которая уехала на сервер и теперь живёт там.
  static Future<void> removeById(int localId) async {
    await _save(all().where((it) => it.id != localId).toList());
  }

  static Future<void> clear() => _prefs.remove(_key);

  static Future<void> _save(List<RecipeData> recipes) async {
    await _prefs.setString(
      _key,
      jsonEncode([for (final recipe in recipes) recipe.toJson()]),
    );
  }
}
