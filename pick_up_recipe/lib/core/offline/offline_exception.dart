import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Запрос не дошёл до сервера: сети нет, адрес недоступен, ответа не дождались.
///
/// Отдельным типом, а не общим `Exception`, потому что весь офлайн держится на
/// различии «сервер отказал» и «сервера не было слышно». Первое — настоящая
/// ошибка, её показывают человеку; второе — обычное дело на кухне без вайфая,
/// и на него полагается достать сохранённое, а не ругаться красным.
class OfflineException implements Exception {
  const OfflineException([this.cause]);

  /// Что именно упало: SocketException, ClientException, TimeoutException.
  /// Хранится для лога — человеку это не показывают.
  final Object? cause;

  /// Текст для человека. Берётся из .arb, чтобы строка жила в одном месте с
  /// остальными, а не отдельной константой в ядре.
  ///
  /// Локаль здесь прибита к шаблонной: исключение летит из слоя данных, где
  /// BuildContext взять неоткуда, а языка системы оно не знает. Экран, дошедший
  /// до перевода, покажет [AppLocalizations.noNetwork] на своём языке —
  /// значение то же самое.
  @override
  String toString() => lookupAppLocalizations(const Locale('ru')).noNetwork;
}
