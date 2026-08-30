// Когда досылать очередь.
//
// Три повода, и все три нужны: старт приложения (человек мог закрыть его в
// лесу и открыть дома), возвращение из фона (тот же случай, только короче),
// и возвращение сети (телефон в руках, вайфай перехватило само).
//
// Четвёртого — «дёргать каждые пять секунд» — нет намеренно: очередь пуста в
// девяноста девяти случаях из ста, а батарею тратит именно фон.

import 'package:flutter/material.dart';

import '../logger.dart';
import 'network_status.dart';
import 'outbox.dart';

/// Куда показать «отправлено»: ключ живёт в MaterialApp.
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

abstract final class OfflineSync {
  static bool _wired = false;

  /// Подписывает досыл на возвращение сети. Зовётся один раз при старте.
  static void wire() {
    if (_wired) return;
    _wired = true;

    Outbox.init();
    NetworkStatus.whenBack(() => unawaitedFlush());
  }

  /// Досылает очередь и, если что-то уехало, говорит об этом человеку.
  static Future<void> flush() async {
    final report = await Outbox.flush();
    if (report.isEmpty) return;

    logger.i('Досыл: отправлено ${report.sent}, отброшено ${report.dropped}');

    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(content: Text(_said(report))),
    );
  }

  static void unawaitedFlush() {
    // Ошибку глотаем сознательно: досыл — фоновое дело, и всплывшее из него
    // исключение прервало бы то, чем человек занят прямо сейчас.
    flush().catchError((Object error) => logger.e('Досыл упал', error: error));
  }
}

String _said(OutboxReport report) {
  if (report.dropped == 0) {
    return report.sent == 1
        ? 'Отправлено то, что ждало связи'
        : 'Отправлено, что ждало связи: ${report.sent}';
  }

  if (report.sent == 0) {
    return 'Сервер не принял отложенное (${report.dropped}) — оно устарело';
  }

  return 'Отправлено: ${report.sent}. Не принято сервером: ${report.dropped}';
}
