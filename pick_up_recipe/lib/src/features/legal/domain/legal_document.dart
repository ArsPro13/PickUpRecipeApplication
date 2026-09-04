/// Правовой документ: заголовок, версия и текст.
class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.version,
    required this.body,
  });

  final String title;

  /// Версия в формате ГГГГ-ММ-ДД. Она уходит на сервер вместе с регистрацией
  /// и хранится рядом с аккаунтом: без неё «пользователь согласился» не
  /// отвечает на единственный важный вопрос — с чем именно.
  final String version;

  final String body;
}

/// Что за документ показываем. Оферты в списке нет: платежей в сервисе нет,
/// а оферта без предмета оплаты — бумага ни о чём.
enum LegalKind {
  userAgreement('/legal/user-agreement', 'Пользовательское соглашение'),
  privacy('/legal/privacy', 'Политика обработки данных'),
  consent('/legal/consent', 'Согласие на обработку данных');

  const LegalKind(this.path, this.title);

  final String path;
  final String title;
}
