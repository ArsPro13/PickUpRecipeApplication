// Правила формы входа должны совпадать с серверными до знака (вопрос 8):
// форма, пропускающая то, что сервер отвергнет, оставляет человека с ошибкой
// без объяснения.
//
// Правило отвечает кодом, а не фразой, поэтому и спрашивается здесь код: тест
// проверяет, ЧТО не так с полем, а не то, какими словами это сказано. Слова
// живут в локалях и меняются без спроса у теста.

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
      expect(AuthRules.passwordProblem('qwer'), PasswordProblem.tooShort);
      expect(AuthRules.passwordProblem('12345'), PasswordProblem.tooShort);
    });

    test('шесть символов достаточно', () {
      expect(AuthRules.passwordProblem('qwerty'), isNull);
      expect(AuthRules.passwordProblem('123456'), isNull);
    });

    test('пароль без цифр и знаков принимается — сервер их не требует', () {
      expect(AuthRules.passwordProblem('пароль'), isNull);
    });

    test('считаются символы, а не байты', () {
      // Шесть кириллических букв — это двенадцать байт, но шесть символов,
      // и сервер считает именно руны.
      expect(AuthRules.passwordProblem('абвгде'), isNull);
      expect(AuthRules.passwordProblem('абвгд'), PasswordProblem.tooShort);
    });

    test('пустой пароль объясняется отдельно', () {
      // Пустое поле и короткий пароль — разные беды: в первом случае человеку
      // нечего исправлять, ему надо начать набирать.
      expect(AuthRules.passwordProblem(''), PasswordProblem.empty);
    });
  });

  group('повтор пароля', () {
    test('несовпадение ловится', () {
      expect(AuthRules.repeatProblem('qwerty', 'qwerti'), RepeatProblem.mismatch);
    });

    test('пустой повтор — не то же самое, что несовпадение', () {
      expect(AuthRules.repeatProblem('qwerty', ''), RepeatProblem.empty);
    });

    test('совпадение проходит', () {
      expect(AuthRules.repeatProblem('qwerty', 'qwerty'), isNull);
    });
  });

  group('почта', () {
    test('обычные адреса проходят', () {
      for (final email in ['a@a.ru', 'user.name@example.co.uk', 'x+tag@mail.ru']) {
        expect(AuthRules.emailProblem(email), isNull, reason: email);
      }
    });

    test('без собаки, без домена и с пробелом отвергаются', () {
      // Каждый случай со своим объяснением: «адрес неверный» не говорит, что
      // именно править.
      expect(AuthRules.emailProblem('user'), EmailProblem.atSign);
      expect(AuthRules.emailProblem('@mail.ru'), EmailProblem.atSign);
      expect(AuthRules.emailProblem('user@'), EmailProblem.domain);
      expect(AuthRules.emailProblem('user@mail'), EmailProblem.domain);
      expect(AuthRules.emailProblem('a b@mail.ru'), EmailProblem.spaces);
    });

    test('пустое поле объясняется отдельно', () {
      expect(AuthRules.emailProblem(''), EmailProblem.empty);
      expect(AuthRules.emailProblem('   '), EmailProblem.empty);
    });

    test('две собаки отвергаются', () {
      expect(AuthRules.emailProblem('a@b@c.ru'), EmailProblem.atSign);
    });
  });

  group('код из письма', () {
    test('шесть цифр', () {
      expect(AuthRules.codeProblem('123456'), isNull);
    });

    test('другая длина и буквы отвергаются', () {
      expect(AuthRules.codeProblem('12345'), CodeProblem.length);
      expect(AuthRules.codeProblem('1234567'), CodeProblem.length);
      expect(AuthRules.codeProblem('12345a'), CodeProblem.notDigits);
    });

    test('пустое поле объясняется отдельно', () {
      expect(AuthRules.codeProblem(''), CodeProblem.empty);
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
