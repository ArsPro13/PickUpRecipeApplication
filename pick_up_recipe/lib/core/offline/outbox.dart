// Очередь того, что человек сделал без сети.
//
// Оценка чашки и правка рецепта не могут ждать связи: заваривают там, где её
// нет, и это нормальный, а не исключительный случай. Поэтому обе операции
// кладутся сюда и уезжают, когда сеть вернётся.
//
// Порядок строгий и очередь одна на всё. Правка рецепта и оценка этой правки
// связаны: пока сервер не завёл версию, оценивать нечего. Отправлять их
// параллельно значило бы гадать, что успело раньше.
//
// Локальные идентификаторы отрицательные. Рецепт, сделанный без сети, получает
// id вроде -1001; когда версия уезжает, сервер отвечает настоящим id, и всё,
// что ещё стоит в очереди с локальным, переписывается на него.

import 'dart:convert';

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../api_client.dart';
import '../logger.dart';
import 'local_recipes.dart';
import 'offline_exception.dart';

enum OutboxKind {
  /// POST /recipe/evolve — новая версия рецепта.
  evolve,

  /// POST /recipe/estimation — оценка чашки.
  estimation,

  /// POST /user/step_types — свой тип шага.
  userStepType;

  static OutboxKind byName(String name) =>
      OutboxKind.values.firstWhere((kind) => kind.name == name, orElse: () => evolve);
}

class OutboxEntry {
  const OutboxEntry({
    required this.seq,
    required this.kind,
    required this.payload,
    this.localId = 0,
    this.queuedAt = '',
    this.attempts = 0,
  });

  final int seq;
  final OutboxKind kind;
  final Map<String, dynamic> payload;

  /// Для evolve — локальный id, под которым версия живёт до отправки.
  final int localId;

  final String queuedAt;

  /// Сколько раз пробовали отправить и получили отказ сервера.
  ///
  /// Пять попыток — и дело выбрасывается. Без предела одно испорченное дело
  /// держит всю очередь: за ним стоят оценки, которые уехали бы без проблем.
  final int attempts;

  OutboxEntry retried() => OutboxEntry(
        seq: seq,
        kind: kind,
        payload: payload,
        localId: localId,
        queuedAt: queuedAt,
        attempts: attempts + 1,
      );

  Map<String, dynamic> toJson() => {
        'seq': seq,
        'kind': kind.name,
        'payload': payload,
        'local_id': localId,
        'at': queuedAt,
        'attempts': attempts,
      };

  factory OutboxEntry.fromJson(Map<String, dynamic> json) => OutboxEntry(
        seq: (json['seq'] as num?)?.toInt() ?? 0,
        kind: OutboxKind.byName(json['kind'] as String? ?? 'evolve'),
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
        localId: (json['local_id'] as num?)?.toInt() ?? 0,
        queuedAt: json['at'] as String? ?? '',
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      );
}

/// Чем закончился досыл.
class OutboxReport {
  const OutboxReport({this.sent = 0, this.dropped = 0, this.left = 0});

  /// Сколько уехало.
  final int sent;

  /// Сколько сервер отверг навсегда — их выбросили, чтобы очередь не встала.
  final int dropped;

  /// Сколько осталось ждать сети.
  final int left;

  bool get isEmpty => sent == 0 && dropped == 0;
}

/// Сервер отказал так, что повторять бессмысленно.
class _Rejected implements Exception {
  const _Rejected(this.status, this.body);

  final int status;
  final String body;
}

abstract final class Outbox {
  static const String _queueKey = 'offline_outbox_v1';
  static const String _mapKey = 'offline_outbox_map_v1';
  static const String _headKey = 'offline_outbox_head_v1';
  static const String _seqKey = 'offline_outbox_seq_v1';

  /// Сколько раз пробуем отправить дело, прежде чем признать его безнадёжным.
  static const int _maxAttempts = 5;

  /// Сколько дел ждёт отправки. Смотрит полоска вверху экрана.
  static final ValueNotifier<int> pending = ValueNotifier<int>(0);

  static bool _flushing = false;

  static EncryptedSharedPreferences get _prefs =>
      EncryptedSharedPreferences.getInstance();

  /// Поднимает счётчик из хранилища. Зовётся один раз при старте.
  static void init() {
    pending.value = _queue().length;
  }

  // ── Очередь ──────────────────────────────────────────────────────────────

  static List<OutboxEntry> _queue() {
    final raw = _prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list) OutboxEntry.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveQueue(List<OutboxEntry> queue) async {
    await _prefs.setString(
      _queueKey,
      jsonEncode([for (final entry in queue) entry.toJson()]),
    );
    pending.value = queue.length;
  }

  static Future<int> _nextSeq() async {
    final next = (_prefs.getInt(_seqKey) ?? 0) + 1;
    await _prefs.setInt(_seqKey, next);
    return next;
  }

  // ── Локальные идентификаторы ─────────────────────────────────────────────

  /// Следующий локальный id рецепта. Отрицательные, чтобы ни один экран не
  /// перепутал его с серверным и не отправил как настоящий.
  static Future<int> nextLocalRecipeId() async {
    final seq = await _nextSeq();
    return -1000 - seq;
  }

  static Map<String, int> _map() {
    final raw = _prefs.getString(_mapKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      return {
        for (final entry in (jsonDecode(raw) as Map<String, dynamic>).entries)
          entry.key: (entry.value as num).toInt(),
      };
    } catch (_) {
      return {};
    }
  }

  /// Серверный id вместо локального. Для обычного id возвращает его же.
  static int resolve(int id) => id >= 0 ? id : (_map()['$id'] ?? id);

  static Future<void> _remember(int localId, int serverId) async {
    final map = _map()..['$localId'] = serverId;
    await _prefs.setString(_mapKey, jsonEncode(map));
  }

  /// Голова своей цепочки: во что превратилась версия, от которой правили.
  ///
  /// Нужна для второй правки одного и того же рецепта без сети. Обе уходят от
  /// одной версии, но сервер второй раз откажет — «правится не последняя
  /// версия», и он прав. Правильный ответ не «потерять правку», а продолжить
  /// свою же цепочку: вторая правка встаёт следом за первой.
  static Map<String, int> _heads() {
    final raw = _prefs.getString(_headKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      return {
        for (final entry in (jsonDecode(raw) as Map<String, dynamic>).entries)
          entry.key: (entry.value as num).toInt(),
      };
    } catch (_) {
      return {};
    }
  }

  static Future<void> _rememberHead(int sourceId, int serverId) async {
    final heads = _heads()
      ..['$sourceId'] = serverId
      ..['$serverId'] = serverId;
    await _prefs.setString(_headKey, jsonEncode(heads));
  }

  // ── Постановка в очередь ─────────────────────────────────────────────────

  /// Ставит новую версию рецепта. Возвращает локальный id, под которым она
  /// будет жить до отправки.
  static Future<int> enqueueEvolve(Map<String, dynamic> payload) async {
    final localId = await nextLocalRecipeId();
    final queue = _queue()
      ..add(
        OutboxEntry(
          seq: await _nextSeq(),
          kind: OutboxKind.evolve,
          payload: payload,
          localId: localId,
          queuedAt: DateTime.now().toIso8601String(),
        ),
      );

    await _saveQueue(queue);
    return localId;
  }

  static Future<void> enqueueEstimation(Map<String, dynamic> payload) async {
    final queue = _queue()
      ..add(
        OutboxEntry(
          seq: await _nextSeq(),
          kind: OutboxKind.estimation,
          payload: payload,
          queuedAt: DateTime.now().toIso8601String(),
        ),
      );

    await _saveQueue(queue);
  }

  static Future<void> enqueueUserStepType(Map<String, dynamic> payload) async {
    final queue = _queue()
      ..add(
        OutboxEntry(
          seq: await _nextSeq(),
          kind: OutboxKind.userStepType,
          payload: payload,
          queuedAt: DateTime.now().toIso8601String(),
        ),
      );

    await _saveQueue(queue);
  }

  // ── Досыл ────────────────────────────────────────────────────────────────

  /// Отправляет очередь по порядку.
  ///
  /// Останавливается на первом же деле, которое не ушло из-за сети: следующие
  /// могут от него зависеть, и «перепрыгнуть и отправить остальное» — способ
  /// повесить оценку на несуществующий рецепт.
  static Future<OutboxReport> flush() async {
    if (_flushing) return const OutboxReport();

    var queue = _queue();
    if (queue.isEmpty) return const OutboxReport();

    _flushing = true;
    var sent = 0;
    var dropped = 0;

    try {
      while (queue.isNotEmpty) {
        final entry = queue.first;

        try {
          await _send(entry);
          sent++;
          queue = queue.sublist(1);
          await _saveQueue(queue);
        } on OfflineException {
          // Сеть пропала посреди досыла — остальное подождёт.
          break;
        } on _Rejected catch (rejection) {
          logger.e(
            'Дело из очереди отвергнуто сервером: '
            '${entry.kind.name} ${rejection.status} ${rejection.body}',
          );
          dropped++;
          queue = queue.sublist(1);

          // Оценка без своей версии рецепта не нужна никому: если версия не
          // завелась, вешать оценку не на что.
          if (entry.kind == OutboxKind.evolve && entry.localId != 0) {
            final before = queue.length;
            queue = queue
                .where(
                  (waiting) =>
                      waiting.kind != OutboxKind.estimation ||
                      (waiting.payload['recipe_id'] as num?)?.toInt() != entry.localId,
                )
                .toList();
            dropped += before - queue.length;
            await LocalRecipes.removeById(entry.localId);
          }

          await _saveQueue(queue);
        } catch (error) {
          // Сервер жив, но ответил чем-то непонятным. Повтор дешевле
          // потерянной оценки — но не бесконечный: пять отказов подряд, и
          // дело выбрасывается, иначе оно держит всю очередь за собой.
          logger.e('Досыл прерван', error: error);

          final tried = entry.retried();
          if (tried.attempts >= _maxAttempts) {
            dropped++;
            queue = queue.sublist(1);
            if (tried.kind == OutboxKind.evolve && tried.localId != 0) {
              await LocalRecipes.removeById(tried.localId);
            }
          } else {
            queue = [tried, ...queue.sublist(1)];
          }

          await _saveQueue(queue);
          break;
        }
      }
    } finally {
      _flushing = false;
    }

    return OutboxReport(sent: sent, dropped: dropped, left: queue.length);
  }

  static Future<void> _send(OutboxEntry entry) async {
    final api = GetIt.instance<ApiClient>();

    switch (entry.kind) {
      case OutboxKind.evolve:
        final payload = Map<String, dynamic>.from(entry.payload);

        final source = resolve((payload['id'] as num?)?.toInt() ?? 0);
        // Своя же предыдущая правка, если она уже уехала: вторая правка того
        // же рецепта продолжает цепочку, а не спорит с ней.
        final from = _heads()['$source'] ?? source;
        payload['id'] = from;

        var response = await api.post('/recipe/evolve', payload);

        // 409 — рецепт успел уйти вперёд: у него уже есть следующая версия.
        // Это не повод выбрасывать правку человека. Спрашиваем у сервера,
        // что теперь последнее в этой цепочке, и встаём следом за ним.
        if (response.statusCode == 409) {
          final head = await _serverHead(api, payload);
          if (head != null && head != payload['id']) {
            payload['id'] = head;
            response = await api.post('/recipe/evolve', payload);
          }
        }

        if (response.statusCode != 200) {
          throw _statusFailure(response.statusCode, response.body);
        }

        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final serverId = (data['id'] as num?)?.toInt();
        if (serverId != null) {
          await _rememberHead(source, serverId);
          if (from != source) await _rememberHead(from, serverId);

          if (entry.localId != 0) {
            await _remember(entry.localId, serverId);
            await LocalRecipes.removeById(entry.localId);
          }
        }

      case OutboxKind.estimation:
        final payload = Map<String, dynamic>.from(entry.payload);
        final recipeId = resolve((payload['recipe_id'] as num?)?.toInt() ?? 0);
        if (recipeId < 0) {
          // Версия так и не завелась — вешать оценку не на что.
          throw const _Rejected(0, 'рецепт не уехал');
        }
        payload['recipe_id'] = recipeId;

        final response = await api.post('/recipe/estimation', payload);
        if (response.statusCode != 200) {
          throw _statusFailure(response.statusCode, response.body);
        }

      case OutboxKind.userStepType:
        final response = await api.post('/user/step_types', entry.payload);
        if (response.statusCode != 200) {
          throw _statusFailure(response.statusCode, response.body);
        }
    }
  }

  /// Последняя версия цепочки по паре «пачка + прибор».
  ///
  /// Ручка без `all_versions` отдаёт по одной записи на цепочку — её голову.
  /// Голов у пары может быть несколько (рецепт обжарщика и своя ветка), и
  /// берётся свежая: правку продолжают от того, чем заваривали последним.
  ///
  /// null — спросить не вышло: тогда дело уходит по обычному пути ошибки.
  static Future<int?> _serverHead(ApiClient api, Map<String, dynamic> payload) async {
    final packId = (payload['pack_id'] as num?)?.toInt();
    final device = payload['device'] as String?;
    if (packId == null || device == null || device.isEmpty) return null;

    try {
      final response = await api.get('/recipe/params', {
        'pack_id': packId.toString(),
        'device': device,
      });
      if (response.statusCode != 200) return null;

      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>? ?? const [];

      int? best;
      var bestDate = '';
      for (final item in list) {
        final recipe = item as Map<String, dynamic>;
        final id = (recipe['id'] as num?)?.toInt();
        final date = recipe['date'] as String? ?? '';
        if (id == null) continue;
        if (best == null || date.compareTo(bestDate) > 0) {
          best = id;
          bestDate = date;
        }
      }

      return best;
    } catch (_) {
      // Не спросили — не страшно: ниже дело пойдёт обычным путём.
      return null;
    }
  }

  /// 4xx — сервер не передумает, дело выбрасывается. 5xx — попробуем позже.
  static Object _statusFailure(int status, String body) {
    if (status >= 400 && status < 500 && status != 429) {
      return _Rejected(status, body);
    }
    return Exception('Сервер ответил $status');
  }

  /// Стирает очередь — на выходе из аккаунта.
  static Future<void> clear() async {
    await _prefs.remove(_queueKey);
    await _prefs.remove(_mapKey);
    await _prefs.remove(_headKey);
    pending.value = 0;
  }
}
