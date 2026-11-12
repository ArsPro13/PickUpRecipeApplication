// Когда по какому рецепту заваривали — на этом телефоне.
//
// Дату последнего заваривания ведёт сервер: приложение записывает старт
// (`POST /recipe/brew`), а список рецептов приезжает уже с ней. Но карточка
// должна сдвинуться сразу — человек нажал «Смолол, начинаем» и через три
// минуты смотрит на «Рецепты», — и должна сдвинуться без сети: заваривают
// там, где её нет. Поэтому время старта сперва ложится сюда, а к серверу едет
// следом или ждёт связи в очереди.
//
// Запись здесь — не замена серверной, а её опережение. Когда список приходит
// с сервера, берётся более поздняя из двух дат: своя не пропадёт, если запрос
// не дошёл, и не перебьёт заваривание с другого телефона.
//
// Тот же журнал выручает, пока сервер старый и про заваривания не знает
// вовсе: дата на карточке всё равно сдвигается — на этом телефоне.
//
// Хранится только последний старт на рецепт: счёт завариваний ведёт сервер.

import 'dart:convert';

import 'package:encrypt_shared_preferences/provider.dart';

import '../../src/features/recipes/domain/models/recipe_data_model.dart';
import 'outbox.dart';

abstract final class BrewLog {
  static const String _key = 'brew_log_v1';

  /// Сколько рецептов помним. Свежие вытесняют старые.
  ///
  /// Предел нужен потому, что запись заводится на каждом старте: без него
  /// журнал рос бы всю жизнь телефона. Трёхсот хватает с большим запасом —
  /// то, что вытеснено, к этому времени давно приехало с сервера.
  static const int limit = 300;

  static EncryptedSharedPreferences get _prefs =>
      EncryptedSharedPreferences.getInstance();

  static Map<String, String> _read() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};

    try {
      return {
        for (final entry in (jsonDecode(raw) as Map<String, dynamic>).entries)
          if (entry.value is String) entry.key: entry.value as String,
      };
    } catch (_) {
      // Битый журнал — то же, что пустой: даты приедут с сервера.
      return {};
    }
  }

  /// По рецепту [recipeId] начали заваривать в момент [at].
  ///
  /// Номер может быть и местным, отрицательным: версия, сделанная без сети,
  /// ещё не получила серверного. Когда получит — запись найдётся по нему
  /// (см. [lastFor]).
  static Future<void> mark(int recipeId, DateTime at) async {
    if (recipeId == 0) return;

    final log = _read();
    final moment = at.toUtc().toIso8601String();
    final known = log['$recipeId'];
    // Часы телефона могли перевести назад — более позднюю запись не трогаем.
    if (known != null && compareMoments(known, moment) >= 0) return;
    log['$recipeId'] = moment;

    await _prefs.setString(_key, jsonEncode(_trimmed(log)));
  }

  /// Когда по рецепту заваривали последний раз. null — на этом телефоне не
  /// заваривали (или запись уже вытеснена).
  ///
  /// Ищется и по местным номерам, которые с тех пор стали этим серверным:
  /// версию заварили без сети под номером −1005, наутро она уехала и стала
  /// 412-й — заваривание всё равно её.
  static String? lastFor(int recipeId) {
    if (recipeId == 0) return null;

    String? last;
    for (final entry in _read().entries) {
      final id = int.tryParse(entry.key);
      if (id == null) continue;
      if (id != recipeId && Outbox.resolve(id) != recipeId) continue;
      if (last == null || compareMoments(entry.value, last) > 0) {
        last = entry.value;
      }
    }
    return last;
  }

  /// Дописывает рецептам дату заваривания с этого телефона — там, где она
  /// позже серверной.
  ///
  /// Меняет сами рецепты: это свежеразобранный ответ сервера (или местные
  /// версии), которым ещё никто не пользуется.
  static void applyTo(Iterable<RecipeData> recipes) {
    final log = _read();
    if (log.isEmpty) return;

    // Номер рецепта → последний старт, с учётом местных номеров.
    final byId = <int, String>{};
    for (final entry in log.entries) {
      final id = int.tryParse(entry.key);
      if (id == null) continue;
      for (final target in {id, Outbox.resolve(id)}) {
        final known = byId[target];
        if (known == null || compareMoments(entry.value, known) > 0) {
          byId[target] = entry.value;
        }
      }
    }

    for (final recipe in recipes) {
      final local = byId[recipe.id];
      if (local == null) continue;

      final fromServer = recipe.lastBrewedAt;
      if (fromServer == null ||
          fromServer.isEmpty ||
          compareMoments(local, fromServer) > 0) {
        recipe.lastBrewedAt = local;
      }
    }
  }

  /// Выход из аккаунта: чужие заваривания следующему человеку не нужны.
  static Future<void> clear() => _prefs.remove(_key);

  /// Оставляет [limit] самых свежих записей.
  static Map<String, String> _trimmed(Map<String, String> log) {
    if (log.length <= limit) return log;

    final entries = log.entries.toList()
      ..sort((a, b) => compareMoments(b.value, a.value));
    return {for (final entry in entries.take(limit)) entry.key: entry.value};
  }
}
