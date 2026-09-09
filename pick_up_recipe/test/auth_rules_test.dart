// Правила формы входа должны совпадать с серверными до знака (вопрос 8):
// форма, пропускающая то, что сервер отвергнет, оставляет человека с ошибкой
// без объяснения.
//
// Правило отвечает кодом, а не фразой, поэтому и спрашивается здесь код: тест
// проверяет, ЧТО не так с полем, а не то, какими словами это сказано. Слова
// живут в локалях и меняются без спроса у теста.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/features/authentication/domain/auth_rules.dart';
import 'package:pick_up_recipe/src/pages/auth_rule_texts.dart';

void main() {
  late AppLocalizations ru;
  late AppLocalizations en;

  setUpAll(() async {
    ru = await AppLocalizations.delegate.load(const Locale('ru'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

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
          action: AuthAction.login,
        );

    // Раньше в форму падал e.toString(), то есть человек видел
    // «Exception: Failed to login user».
    test('коды разбираются в причину, а не в общий отказ', () {
      expect(failureOf(400).reason, AuthReason.badFields);
      expect(failureOf(401).reason, AuthReason.wrongCredentials);
      expect(failureOf(404).reason, AuthReason.unknownEmail);
      expect(failureOf(409).reason, AuthReason.emailTaken);
      expect(failureOf(429).reason, AuthReason.tooOften);
      expect(failureOf(503).reason, AuthReason.serverDown);
      expect(failureOf(418).reason, AuthReason.actionFailed);
    });

    test('неподтверждённая почта — не ошибка формы, а путь на экран кода', () {
      final failure = failureOf(403);

      expect(failure.emailNotVerified, isTrue);
      expect(failureOf(401).emailNotVerified, isFalse);
    });

    test('английская техническая строка бэкенда не показывается человеку', () {
      final failure = failureOf(400, '{"message":"Failed to login user"}');

      expect(failure.text(ru), isNot(contains('Failed')));
      expect(failure.text(en), isNot(contains('Failed')));
    });

    test('осмысленное сообщение сервера показывается как есть', () {
      final failure = failureOf(400, '{"message":"Почта уже подтверждена"}');

      // Строка пришла с сервера: переводить её нечем, и на английском экране
      // она остаётся такой, какой её прислали.
      expect(failure.text(ru), 'Почта уже подтверждена');
      expect(failure.text(en), 'Почта уже подтверждена');
    });

    test('объяснение пятисотки важнее общей фразы про сервер', () {
      // 503 «отправка писем не настроена» говорит человеку, что дело не в нём.
      // «Сервер не отвечает» отправило бы его проверять связь.
      final failure = failureOf(503, '{"message":"отправка писем не настроена, попробуйте позже"}');

      expect(failure.text(ru), 'отправка писем не настроена, попробуйте позже');
    });

    test('битое тело не роняет разбор', () {
      expect(failureOf(400, 'not json at all').text(ru), isNotEmpty);
      expect(failureOf(400, '[]').text(ru), isNotEmpty);
    });

    test('нет связи — отдельная ошибка с другим советом', () {
      expect(AuthFailure.offline.reason, AuthReason.offline);
      expect(AuthFailure.offline.text(ru), contains('интернет'));
      expect(AuthFailure.offline.statusCode, isNull);
    });
  });

  // Перевод не должен молча подменить смысл: до вынесения строк в словарь
  // каждый ответ сервера давал ровно эту фразу, и по-русски она обязана
  // остаться той же — иначе «перевели» превращается в «переписали».
  group('тексты ошибок входа на русском не изменились', () {
    AuthFailure failureOf(int status) => AuthFailure.fromResponse(
          http.Response('', status, headers: const {'content-type': 'application/json'}),
          action: AuthAction.login,
        );

    test('разбор по коду ответа', () {
      expect(failureOf(400).text(ru), 'Проверьте почту и пароль');
      expect(failureOf(401).text(ru), 'Неверная почта или пароль');
      expect(failureOf(403).text(ru), 'Почта не подтверждена');
      expect(failureOf(404).text(ru), 'Такой почты у нас нет');
      expect(failureOf(409).text(ru), 'Эта почта уже занята');
      expect(failureOf(429).text(ru), 'Слишком часто. Подождите минуту');
      expect(failureOf(503).text(ru), 'Сервер не отвечает. Попробуйте ещё раз');
    });

    test('отдельные случаи, разобранные не по коду ответа', () {
      expect(
        const AuthFailure(AuthReason.wrongCode).text(ru),
        'Код не подошёл. Проверьте письмо ещё раз',
      );
      expect(
        const AuthFailure(AuthReason.noTokens).text(ru),
        'Сервер ответил без токенов',
      );
      expect(AuthFailure.offline.text(ru), 'Нет связи. Проверьте интернет');
    });

    test('«Не удалось <действие>» собрано целой фразой на каждое действие', () {
      String failed(AuthAction action) => AuthFailure.fromResponse(
            http.Response('', 418, headers: const {'content-type': 'application/json'}),
            action: action,
          ).text(ru);

      expect(failed(AuthAction.login), 'Не удалось войти');
      expect(failed(AuthAction.sendLetter), 'Не удалось отправить письмо');
      expect(failed(AuthAction.changePassword), 'Не удалось сменить пароль');
      expect(failed(AuthAction.register), 'Не удалось зарегистрироваться');
      expect(failed(AuthAction.verifyEmail), 'Не удалось подтвердить почту');
    });
  });

  group('на английском телефоне в ошибках входа нет кириллицы', () {
    final cyrillic = RegExp('[а-яёА-ЯЁ]');

    test('каждая причина отказа', () {
      for (final reason in AuthReason.values) {
        final failure = AuthFailure(reason);
        expect(
          cyrillic.hasMatch(failure.text(en)),
          isFalse,
          reason: '$reason: ${failure.text(en)}',
        );
      }
    });

    test('каждое действие в «Не удалось …»', () {
      for (final action in AuthAction.values) {
        final failure = AuthFailure(AuthReason.actionFailed, action: action);
        expect(
          cyrillic.hasMatch(failure.text(en)),
          isFalse,
          reason: '$action: ${failure.text(en)}',
        );
      }
    });

    test('правила полей формы тоже', () {
      final rules = <String>[
        for (final problem in EmailProblem.values) problem.text(en),
        for (final problem in PasswordProblem.values) problem.text(en),
        for (final problem in RepeatProblem.values) problem.text(en),
        for (final problem in CodeProblem.values) problem.text(en),
      ];

      for (final line in rules) {
        expect(cyrillic.hasMatch(line), isFalse, reason: line);
      }
    });
  });
}
