// Незаконченная оценка чашки, пережившая выход из приложения.
//
// Оценку ставят через минуту после чашки и почти всегда отвлекаясь: закипел
// второй чайник, позвонили, приложение убили из списка задач. Всё, что человек
// успел натыкать — точка на карте вкуса, звёзды, тронутые оси, — жило только в
// состоянии виджета и пропадало вместе с ним. Второй раз ту же чашку уже не
// вспомнить: она выпита.
//
// Сделано по образцу `LastBrewCache`: одна запись в защищённых настройках,
// свой срок годности, битое значение равно отсутствующему. Черновик один, а не
// список: две недооценённые чашки одновременно — это не жизнь, а угол, и
// список пришлось бы где-то показывать целиком.
//
// Срок — семь дней. Соседний кэш заваривания живёт тридцать, но там речь про
// «повторить вчерашнее», а недельной давности впечатление от чашки человек уже
// не восстановит: показывать его как «продолжите» значит просить выдумать.

import 'dart:convert';

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/widgets.dart';

import '../../../../l10n/app_localizations.dart';
import '../../packs/domain/models/pack_model.dart';
import '../domain/models/recipe_data_model.dart';
import '../domain/taste_map.dart';

/// Что человек успел сказать про чашку.
class RatingDraft {
  const RatingDraft({
    required this.recipe,
    required this.pack,
    required this.point,
    required this.stars,
    required this.axes,
    required this.savedAt,
  });

  /// Рецепт и пачка целиком, а не их идентификаторы: с плашки надо открыть тот
  /// же экран оценки, и без сети сходить за рецептом будет некуда.
  final RecipeData recipe;
  final PackData? pack;

  final TastePoint point;

  /// Звёзды 1…5. Ноль — не ставили.
  final int stars;

  /// Только тронутые оси: нетронутая середина шкалы — это не оценка.
  final Map<String, double> axes;

  final DateTime savedAt;

  /// Пустой черновик хранить незачем — это просто открытый и закрытый экран.
  bool get isEmpty => point.isCenter && stars == 0 && axes.isEmpty;

  /// Подпись для плашки: что именно осталось недосказанным.
  ///
  /// Словарь приходит параметром: черновик поднимают из хранилища, где
  /// `BuildContext` взять неоткуда, а показывают его на экране со своим языком.
  String summaryFor(AppLocalizations texts) {
    final parts = [
      if (!point.isCenter) point.summaryFor(texts).toLowerCase(),
      if (stars > 0) texts.rateStarsOf(stars),
      if (axes.isNotEmpty) texts.rateAxesCount(axes.length),
    ];
    return parts.join(' · ');
  }

  /// Та же подпись по-русски — для вызова, у которого словаря под рукой нет.
  String get summary => summaryFor(lookupAppLocalizations(const Locale('ru')));

  Map<String, dynamic> toJson() => {
        'saved_at': savedAt.toIso8601String(),
        'recipe': recipe.toJson(),
        if (pack != null) 'pack': pack!.toJson(),
        'x': point.x,
        'y': point.y,
        'stars': stars,
        'axes': axes,
      };

  static RatingDraft fromJson(Map<String, dynamic> json) => RatingDraft(
        recipe: RecipeData.fromJson(json['recipe'] as Map<String, dynamic>),
        pack: json['pack'] == null
            ? null
            : PackData.fromJson(json['pack'] as Map<String, dynamic>),
        point: TastePoint(
          (json['x'] as num?)?.toDouble() ?? 0,
          (json['y'] as num?)?.toDouble() ?? 0,
        ),
        stars: (json['stars'] as num?)?.toInt() ?? 0,
        axes: {
          for (final entry in (json['axes'] as Map? ?? const {}).entries)
            entry.key as String: (entry.value as num).toDouble(),
        },
        savedAt: DateTime.tryParse(json['saved_at'] as String? ?? '') ?? DateTime(0),
      );
}

abstract final class RatingDrafts {
  static const String _key = 'rating_draft_v1';

  /// Сколько живёт незаконченная оценка.
  static const Duration lifetime = Duration(days: 7);

  /// Живой черновик — за ним смотрит плашка на вкладке «Пачки».
  ///
  /// `ValueNotifier`, как `Outbox.pending`: пишет черновик экран оценки, а
  /// показывает его совсем другая вкладка, и связывать их через ещё один
  /// провайдер значило бы завести второй источник правды.
  static final ValueNotifier<RatingDraft?> current = ValueNotifier<RatingDraft?>(null);

  static EncryptedSharedPreferences get _prefs =>
      EncryptedSharedPreferences.getInstance();

  /// Запоминает то, что человек успел сказать.
  ///
  /// Пустой черновик стирается, а не пишется: экран оценки открывают и просто
  /// закрывают чаще, чем заполняют, и плашка «продолжите» без единой цифры
  /// была бы напоминанием ни о чём.
  static Future<void> save(RatingDraft draft) async {
    if (draft.isEmpty) return clear();

    await _prefs.setString(_key, jsonEncode(draft.toJson()));
    current.value = draft;
  }

  /// Черновик, если он ещё не протух. null — продолжать нечего.
  static Future<RatingDraft?> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      current.value = null;
      return null;
    }

    try {
      final draft = RatingDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (DateTime.now().difference(draft.savedAt) > lifetime) {
        await clear();
        return null;
      }

      current.value = draft;
      return draft;
    } catch (_) {
      // Битый черновик — то же, что отсутствующий: чинить его не из чего.
      current.value = null;
      return null;
    }
  }

  /// Оценка уехала (или человек от неё отказался) — продолжать больше нечего.
  static Future<void> clear() async {
    await _prefs.remove(_key);
    current.value = null;
  }
}
