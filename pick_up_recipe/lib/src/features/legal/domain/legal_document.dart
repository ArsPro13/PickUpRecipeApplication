/// Правовой документ: заголовок, версия и текст.
class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.version,
    required this.body,
  });

  /// Заголовок так, как его назвал сервер. Пустая строка — не назвал никак;
  /// шапка листа берётся не отсюда, а из перевода по виду документа.
  final String title;

  /// Версия в формате ГГГГ-ММ-ДД. Она уходит на сервер вместе с регистрацией
  /// и хранится рядом с аккаунтом: без неё «пользователь согласился» не
  /// отвечает на единственный важный вопрос — с чем именно.
  final String version;

  final String body;
}

/// Что за документ показываем. Оферты в списке нет: платежей в сервисе нет,
/// а оферта без предмета оплаты — бумага ни о чём.
///
/// Вид документа — код, а не заголовок: языка экрана домен не знает. Перевод
/// кода в заголовок живёт рядом с экраном, в legal_sheet.dart.
enum LegalKind {
  userAgreement('/legal/user-agreement'),
  privacy('/legal/privacy'),
  consent('/legal/consent');

  const LegalKind(this.path);

  final String path;
}
