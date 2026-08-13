// Кэш последнего открытого рецепта — ответ C5: офлайн показывается он.
//
// Ровно один рецепт и ровно 30 дней: это не офлайн-режим, а страховка на
// случай «стою у чайника, сети нет». Свежее заваривание почти всегда
// повторяет вчерашнее, и его-то мы и умеем показать без сети.
//
// Очереди отправки оценок здесь нет — это отдельная работа, и обещать её
// экран офлайна не должен.

import 'dart:convert';

import 'package:encrypt_shared_preferences/provider.dart';

import '../../packs/domain/models/pack_model.dart';
import '../domain/models/recipe_data_model.dart';

class CachedBrew {
  const CachedBrew({required this.recipe, required this.pack, required this.savedAt});

  final RecipeData recipe;
  final PackData? pack;
  final DateTime savedAt;
}

abstract final class LastBrewCache {
  static const _key = 'last_brew_cache_v1';
  static const _lifetime = Duration(days: 30);

  /// Запоминает рецепт, по которому начали заваривать.
  static Future<void> save(RecipeData recipe, PackData? pack) async {
    final prefs = EncryptedSharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'saved_at': DateTime.now().toIso8601String(),
        'recipe': recipe.toJson(),
        if (pack != null) 'pack': pack.toJson(),
      }),
    );
  }

  /// Последний рецепт, если он ещё не протух. null — показывать нечего.
  static Future<CachedBrew?> load() async {
    final prefs = EncryptedSharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(data['saved_at'] as String? ?? '');
      if (savedAt == null || DateTime.now().difference(savedAt) > _lifetime) {
        return null;
      }

      return CachedBrew(
        recipe: RecipeData.fromJson(data['recipe'] as Map<String, dynamic>),
        pack: data['pack'] == null
            ? null
            : PackData.fromJson(data['pack'] as Map<String, dynamic>),
        savedAt: savedAt,
      );
    } catch (_) {
      // Битый кэш — то же, что отсутствующий: чинить его не из чего.
      return null;
    }
  }
}
