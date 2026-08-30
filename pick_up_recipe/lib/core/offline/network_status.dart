// Знает ли приложение сеть прямо сейчас.
//
// Отдельного опроса «есть ли интернет» нет намеренно: единственный честный
// признак доступности сервера — ответил ли он на настоящий запрос. Пинг до
// роутера не значит ничего: в кофейне вайфай раздаёт страницу входа, а до
// бэкенда не пускает.
//
// Поэтому статус ставят сами запросы: ответ — онлайн, OfflineException —
// офлайн. Плюс редкая проба, пока висим офлайн, — чтобы полоска сама погасла,
// когда сеть вернулась, а человек ничего не нажимал.

import 'dart:async';

import 'package:flutter/foundation.dart';

abstract final class NetworkStatus {
  /// true, пока последний запрос дошёл до сервера. Слушается полоской вверху.
  static final ValueNotifier<bool> online = ValueNotifier<bool>(true);

  /// Когда сеть вернулась. Подписан досыл очереди.
  static final List<VoidCallback> _onBack = [];

  /// Чем щупаем сеть, пока висим офлайн. Ставится при запуске — ядро не знает
  /// ни про ApiClient, ни про ручки.
  static Future<void> Function()? probe;

  static const Duration _probeEvery = Duration(seconds: 15);
  static Timer? _timer;

  static void whenBack(VoidCallback callback) => _onBack.add(callback);

  static void markOnline() {
    _timer?.cancel();
    _timer = null;

    if (online.value) return;
    online.value = true;
    for (final callback in [..._onBack]) {
      callback();
    }
  }

  static void markOffline() {
    if (online.value) online.value = false;
    _startProbing();
  }

  /// Пока сети нет — редкая проба, чтобы заметить возвращение самим.
  static void _startProbing() {
    if (_timer != null || probe == null) return;

    _timer = Timer.periodic(_probeEvery, (_) async {
      if (online.value) {
        _timer?.cancel();
        _timer = null;
        return;
      }
      try {
        await probe!();
      } catch (_) {
        // Проба и есть проверка: неудача означает «всё ещё нет сети».
      }
    });
  }

  /// Для тестов: вернуть в исходное.
  @visibleForTesting
  static void reset() {
    _timer?.cancel();
    _timer = null;
    _onBack.clear();
    online.value = true;
  }
}
