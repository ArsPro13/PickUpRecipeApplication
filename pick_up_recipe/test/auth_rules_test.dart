// Правила формы входа должны совпадать с серверными до знака (вопрос 8):
// форма, пропускающая то, что сервер отвергнет, оставляет человека с ошибкой
// без объяснения.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/src/features/authentication/domain/auth_rules.dart';

void main() {
  group('пароль', () {
    // authsvc.ValidatePassword требует ровно одного: не меньше шести символов.
    // На макете стояло второе правило «есть цифра или знак» — это было
    // предположение, а не факт, и его в форме быть не должно.
    test('порог совпадает с серверным', () {
      expect(AuthRules.minPasswordLength, 6);
    });

    test('короткий отвергается', () {
      expect(AuthRules.passwordError('qwer'), isNotNull);
      expect(AuthRules.passwordError('12345'), isNotNull);
    });

    test('шесть символов достаточно', () {
      expect(AuthRules.passwordError('qwerty'), isNull);
      expect(AuthRules.passwordError('123456'), isNull);
    });

    test('пароль без цифр и знаков принимается — сервер их не требует', () {
      expect(AuthRules.passwordError('пароль'), isNull);
    });

    test('считаются символы, а не байты', () {
      // Шесть кириллических букв — это двенадцать байт, но шесть символов,
      // и сервер считает именно руны.
      expect(AuthRules.passwordError('абвгде'), isNull);
      expect(AuthRules.passwordError('абвгд'), isNotNull);
    });

    test('пустой пароль объясняется отдельно', () {
      expect(AuthRules.passwordError(''), contains('Введите'));
    });
  });

  group('повтор пароля', () {
    test('несовпадение ловится', () {
      expect(AuthRules.repeatError('qwerty', 'qwerti'), isNotNull);
    });

    test('совпадение проходит', () {
      expect(AuthRules.repeatError('qwerty', 'qwerty'), isNull);
    });
  });

  group('почта', () {
    test('обычные адреса проходят', () {
      for (final email in ['a@a.ru', 'user.name@example.co.uk', 'x+tag@mail.ru']) {
        expect(AuthRules.emailError(email), isNull, reason: email);
      }
    });

    test('без собаки, без домена и с пробелом отвергаются', () {
      for (final email in ['user', 'user@', '@mail.ru', 'user@mail', 'a b@mail.ru']) {
        expect(AuthRules.emailError(email), isNotNull, reason: email);
      }
    });

    test('две собаки отвергаются', () {
      expect(AuthRules.emailError('a@b@c.ru'), isNotNull);
    });
  });

  group('код из письма', () {
    test('шесть цифр', () {
      expect(AuthRules.codeError('123456'), isNull);
    });

    test('другая длина и буквы отвергаются', () {
      expect(AuthRules.codeError('12345'), isNotNull);
      expect(AuthRules.codeError('1234567'), isNotNull);
      expect(AuthRules.codeError('12345a'), isNotNull);
    });
  });

  group('разбор ответа сервера', () {
    // encoding: utf8 обязателен — http.Response по умолчанию latin1,
    // и кириллица в теле роняет сам конструктор ответа.
    AuthFailure failureOf(int status, [String body = '']) => AuthFailure.fromResponse(
          http.Response(body, status, headers: const {'content-type': 'application/json'}),
          action: 'войти',
        );

    // Раньше в форму падал e.toString(), то есть человек видел
    // «Exception: Failed to login user».
    test('коды разбираются в понятный текст', () {
      expect(failureOf(401).message, contains('Неверная почта'));
      expect(failureOf(404).message, contains('нет'));
      expect(failureOf(409).message, contains('занята'));
      expect(failureOf(429).message, contains('минуту'));
      expect(failureOf(503).message, contains('Сервер не отвечает'));
    });

    test('неподтверждённая почта — не ошибка формы, а путь на экран кода', () {
      final failure = failureOf(403);

      expect(failure.emailNotVerified, isTrue);
      expect(failureOf(401).emailNotVerified, isFalse);
    });

    test('английская техническая строка бэкенда не показывается человеку', () {
      final failure = failureOf(400, '{"message":"Failed to login user"}');

      expect(failure.message, isNot(contains('Failed')));
    });

    test('осмысленное сообщение сервера показывается как есть', () {
      final failure = failureOf(400, '{"message":"Почта уже подтверждена"}');

      expect(failure.message, 'Почта уже подтверждена');
    });

    test('битое тело не роняет разбор', () {
      expect(failureOf(400, 'not json at all').message, isNotEmpty);
      expect(failureOf(400, '[]').message, isNotEmpty);
    });

    test('нет связи — отдельная ошибка с другим советом', () {
      expect(AuthFailure.offline.message, contains('интернет'));
      expect(AuthFailure.offline.statusCode, isNull);
    });
  });
}
