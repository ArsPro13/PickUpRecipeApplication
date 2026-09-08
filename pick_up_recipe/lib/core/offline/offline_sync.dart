// Когда досылать очередь.
//
// Три повода, и все три нужны: старт приложения (человек мог закрыть его в
// лесу и открыть дома), возвращение из фона (тот же случай, только короче),
// и возвращение сети (телефон в руках, вайфай перехватило само).
//
// Четвёртого — «дёргать каждые пять секунд» — нет намеренно: очередь пуста в
// девяноста девяти случаях из ста, а батарею тратит именно фон.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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

    // mounted проверяется отдельно от null: досыл начинается до первого кадра
    // и заканчивается когда угодно, а у снятого мессенджера контекст мёртв.
    final messenger = messengerKey.currentState;
    if (messenger == null || !messenger.mounted) return;

    // Локали берутся у самого мессенджера: он живёт внутри MaterialApp, то
    // есть под Localizations, — а своего экрана у досыла нет и быть не может,
    // он срабатывает в фоне.
    final texts = AppLocalizations.of(messenger.context);

    messenger.showSnackBar(
      SnackBar(content: Text(outboxReportText(texts, report))),
    );
  }

  static void unawaitedFlush() {
    // Ошибку глотаем сознательно: досыл — фоновое дело, и всплывшее из него
    // исключение прервало бы то, чем человек занят прямо сейчас.
    flush().catchError((Object error) => logger.e('Досыл упал', error: error));
  }
}

/// Что сказать человеку после досыла.
///
/// Отдельной функцией и не приватной — ради теста, как у полоски связи: исходов
/// три, и каждый должен говорить правду про свой, а не общее «что-то ушло».
///
/// «Одно дело» и «несколько дел» различает ICU внутри `svcSyncSent`, а не эта
/// функция: у каждого языка свои формы, и собранные руками работали бы ровно
/// для одного из них.
String outboxReportText(AppLocalizations texts, OutboxReport report) {
  if (report.dropped == 0) return texts.svcSyncSent(report.sent);
  if (report.sent == 0) return texts.svcSyncDropped(report.dropped);

  return texts.svcSyncMixed(report.sent, report.dropped);
}
