// Правила формы входа и разбор ответов сервера.
//
// Вынесено из виджетов отдельным файлом по двум причинам. Во-первых, правила
// обязаны совпадать с серверными до знака (вопрос 8): форма, пропускающая то,
// что сервер отвергнет, оставляет человека с ошибкой без объяснения.
// Во-вторых, это единственная часть экранов входа, которую можно проверить
// тестом без запуска приложения.

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Проверки полей входа и регистрации.
abstract final class AuthRules {
  /// Наименьшая длина пароля.
  ///
  /// Ровно то, что проверяет `authsvc.ValidatePassword`: не меньше шести
  /// символов, и больше ничего. Второе правило «есть цифра или знак» стояло
  /// на макете как предположение — сервер его не требует, и требовать его
  /// в форме значило бы врать про причину отказа.
  static const int minPasswordLength = 6;

  /// Что не так с почтой. null — всё в порядке.
  ///
  /// Сервер разбирает адрес через `mail.ParseAddress`, то есть требует
  /// синтаксически корректный адрес и не проверяет существование ящика.
  static String? emailError(String email) {
    final value = email.trim();
    if (value.isEmpty) return 'Введите почту';

    final at = value.indexOf('@');
    if (at <= 0 || at != value.lastIndexOf('@')) return 'В адресе должна быть одна собака';

    final domain = value.substring(at + 1);
    if (!domain.contains('.') || domain.startsWith('.') || domain.endsWith('.')) {
      return 'После собаки должен быть домен: example.ru';
    }
    if (value.contains(' ')) return 'В адресе не бывает пробелов';

    return null;
  }

  /// Что не так с паролем. null — всё в порядке.
  static String? passwordError(String password) {
    if (password.isEmpty) return 'Введите пароль';
    if (password.runes.length < minPasswordLength) {
      return 'Не короче $minPasswordLength символов';
    }
    return null;
  }

  /// Совпадают ли пароль и его повтор.
  ///
  /// Поле повтора оставлено, хотя рядом есть показ пароля (ответ 38): оно
  /// лишнее, но привычное, и убирать его отдельным решением незачем.
  static String? repeatError(String password, String repeat) {
    if (repeat.isEmpty) return 'Повторите пароль';
    if (password != repeat) return 'Пароли не совпадают';
    return null;
  }

  /// Что не так с кодом из письма. null — всё в порядке.
  static String? codeError(String code) {
    final value = code.trim();
    if (value.isEmpty) return 'Введите код из письма';
    if (value.length != 6) return 'В коде шесть цифр';
    if (int.tryParse(value) == null) return 'Код состоит только из цифр';
    return null;
  }
}

/// Ошибка запроса к серверу, разобранная по коду ответа.
///
/// До этого в форму падал `e.toString()` — то есть человек видел
/// `Exception: Failed to login user`. Разбор по коду даёт вместо этого текст,
/// по которому понятно, что делать дальше.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.statusCode, this.emailNotVerified = false});

  final String message;
  final int? statusCode;

  /// Почта не подтверждена: экран входа должен не ругаться, а увести на код.
  final bool emailNotVerified;

  @override
  String toString() => message;

  /// Разбирает ответ сервера в понятную человеку ошибку.
  ///
  /// Действие в родительном падеже — «войти», «зарегистрироваться»: оно
  /// подставляется в текст ошибки там, где сервер не сказал ничего внятного.
  static AuthFailure fromResponse(http.Response response, {required String action}) {
    final detail = _messageOf(response);

    return switch (response.statusCode) {
      400 => AuthFailure(
          detail ?? 'Проверьте почту и пароль',
          statusCode: 400,
        ),
      401 => const AuthFailure('Неверная почта или пароль', statusCode: 401),
      403 => AuthFailure(
          detail ?? 'Почта не подтверждена',
          statusCode: 403,
          emailNotVerified: true,
        ),
      404 => const AuthFailure('Такой почты у нас нет', statusCode: 404),
      409 => const AuthFailure('Эта почта уже занята', statusCode: 409),
      // Ограничение частоты стоит на всех почтовых ручках: без него отправкой
      // писем можно засыпать чужой ящик.
      429 => const AuthFailure('Слишком часто. Подождите минуту', statusCode: 429),
      >= 500 => AuthFailure(
          'Сервер не отвечает. Попробуйте ещё раз',
          statusCode: response.statusCode,
        ),
      _ => AuthFailure(detail ?? 'Не удалось $action', statusCode: response.statusCode),
    };
  }

  /// Сеть недоступна. Отдельно от кодов ответа: тут не «сервер сказал», а
  /// «до сервера не дошли», и совет другой.
  static const AuthFailure offline = AuthFailure('Нет связи. Проверьте интернет');

  /// Достаёт текст ошибки из тела ответа, если он там есть и осмысленный.
  static String? _messageOf(http.Response response) {
    if (response.body.isEmpty) return null;

    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) return null;

      final message = data['message'] ?? data['error'];
      if (message is! String || message.isEmpty) return null;

      // Английские технические строки бэкенда человеку не показываем:
      // «Failed to login user» — это не объяснение.
      if (RegExp(r'^[A-Za-z0-9 _\-.:]+$').hasMatch(message)) return null;

      return message;
    } on FormatException {
      return null;
    }
  }
}
