// Сценарий «письмо с кодом не приходит».
//
// Экран подтверждения почты — единственное место, где человек застревает
// молча: письмо не дошло, а перед ним пустые ячейки. Всё, что он может
// сделать, — попросить письмо ещё раз, и ответы на эту просьбу должны
// различаться: «ушло», «рано», «почта не работает» и «нет связи» требуют
// четырёх разных советов, а не одной красной строки.
//
// Проверяются настоящие классы, а не их подделки: отсчёт считает сам
// ResendCooldown, ответы разбирает сам ResendOutcome, а сервис ходит через
// подставной клиент — тот же приём, что в offline_test.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/core/offline/offline_exception.dart';
import 'package:pick_up_recipe/src/features/authentication/data_sources/remote/auth_service.dart';
import 'package:pick_up_recipe/src/features/authentication/domain/code_resend.dart';

/// Клиент, который не ходит в сеть: отвечает тем, что ему сказали, и
/// запоминает, о чём его просили.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(onAuthError: _nothing);

  static Future<void> _nothing() async {}

  /// Что правда ушло на сервер.
  final List<(String, Map<String, dynamic>)> calls = [];

  http.Response reply = http.Response('', 200);

  /// Сеть «пропала»: запрос отваливается, как в лесу.
  bool offline = false;

  @override
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    if (offline) throw const OfflineException();
    calls.add((endpoint, body));

    return reply;
  }
}

/// Ответ сервера с заголовками: тело по умолчанию пустое — так отвечает
/// бэкенд, когда сказать ему нечего.
http.Response _response(int status, {String body = '', Map<String, String> headers = const {}}) {
  return http.Response(body, status, headers: {
    'content-type': 'application/json',
    ...headers,
  });
}

void main() {
  group('отсчёт до следующего письма', () {
    final sent = DateTime(2026, 9, 7, 12);

    test('пауза совпадает с серверной', () {
      // Мидлвар OncePerMinute на /mail/send_verify_email: одно письмо в минуту.
      // Обещать раньше — значит обещать отказ.
      expect(ResendCooldown.serverPause, const Duration(seconds: 60));
    });

    test('сразу после письма повтор запрещён', () {
      final cooldown = ResendCooldown.sentAt(sent);

      expect(cooldown.ready(sent), isFalse);
      expect(cooldown.left(sent), ResendCooldown.serverPause);
    });

    test('минута прошла — повтор разрешён', () {
      final cooldown = ResendCooldown.sentAt(sent);

      expect(cooldown.ready(sent.add(const Duration(seconds: 59))), isFalse);
      expect(cooldown.ready(sent.add(const Duration(seconds: 60))), isTrue);
      expect(cooldown.ready(sent.add(const Duration(minutes: 5))), isTrue);
    });

    test('остаток считается от момента, а не тикает вниз', () {
      // Приложение свернули в карман на сорок секунд. Вернувшись, экран
      // обязан показать двадцать, а не ту же минуту, на которой его прервали.
      final cooldown = ResendCooldown.sentAt(sent);

      expect(cooldown.left(sent.add(const Duration(seconds: 40))), const Duration(seconds: 20));
    });

    test('остаток не уходит в минус', () {
      expect(ResendCooldown.sentAt(sent).left(sent.add(const Duration(hours: 1))), Duration.zero);
    });

    test('письма ещё не было — ждать нечего', () {
      const cooldown = ResendCooldown.idle();

      expect(cooldown.ready(sent), isTrue);
      expect(cooldown.left(sent), Duration.zero);
    });

    test('сервер попросил ждать дольше — ждём столько', () {
      final cooldown = ResendCooldown.sentAt(sent, pause: const Duration(seconds: 90));

      expect(cooldown.ready(sent.add(const Duration(seconds: 60))), isFalse);
      expect(cooldown.ready(sent.add(const Duration(seconds: 90))), isTrue);
    });

    test('м:сс — тот же формат времени, что на таймере заваривания', () {
      expect(ResendCooldown.format(const Duration(seconds: 60)), '1:00');
      expect(ResendCooldown.format(const Duration(seconds: 7)), '0:07');
      expect(ResendCooldown.format(Duration.zero), '0:00');
    });
  });

  group('ответ сервера на повторную отправку', () {
    test('200 — письмо ушло, и сервер сам называет срок следующего', () {
      // Тело ответа — CodeRequestResponse из controller/authhandler.go: срок
      // приходит и при успехе, чтобы кнопка не придумывала свою минуту рядом
      // с серверной.
      final outcome = ResendOutcome.fromResponse(_response(200, body: '{"retry_after":60}'));

      expect(outcome.status, ResendStatus.sent);
      expect(outcome.retryAfter, const Duration(seconds: 60));
    });

    test('200 без срока — письмо всё равно ушло', () {
      final outcome = ResendOutcome.fromResponse(_response(200));

      expect(outcome.status, ResendStatus.sent);
      expect(outcome.retryAfter, isNull, reason: 'сервер промолчал — отсчёт возьмёт своё значение');
    });

    test('ответы ручки разбираются ровно так, как она отвечает', () {
      // Оба тела списаны с обработчика: tooSoonForCode и mailFailureResponse.
      final tooOften = ResendOutcome.fromResponse(_response(
        429,
        body: '{"retry_after":42,"message":"код уже отправлен, следующий можно запросить позже"}',
        headers: {'retry-after': '42'},
      ));

      expect(tooOften.status, ResendStatus.tooOften);
      expect(tooOften.retryAfter, const Duration(seconds: 42));

      final disabled = ResendOutcome.fromResponse(_response(
        503,
        body: '{"message":"отправка писем не настроена, попробуйте позже"}',
      ));

      expect(disabled.status, ResendStatus.mailDown, reason: 'почта выключена — человек не виноват');
    });

    test('429 без срока — минута, ограничение сервера', () {
      // Echo отвечает на превышение английской технической строкой и без
      // Retry-After. Показывать её человеку нельзя, а срок ему нужен.
      final outcome = ResendOutcome.fromResponse(
        _response(429, body: '{"message":"rate limit exceeded"}'),
      );

      expect(outcome.status, ResendStatus.tooOften);
      expect(outcome.retryAfter, ResendCooldown.serverPause);
    });

    test('429 со сроком в заголовке — этот срок', () {
      final outcome = ResendOutcome.fromResponse(
        _response(429, headers: {'retry-after': '20'}),
      );

      expect(outcome.status, ResendStatus.tooOften);
      expect(outcome.retryAfter, const Duration(seconds: 20));
    });

    test('429 со сроком в теле — этот срок', () {
      expect(
        ResendOutcome.fromResponse(_response(429, body: '{"retry_after":15}')).retryAfter,
        const Duration(seconds: 15),
      );
      expect(
        ResendOutcome.fromResponse(_response(429, body: '{"retry_after_seconds":"25"}')).retryAfter,
        const Duration(seconds: 25),
      );
    });

    test('непонятный срок не роняет разбор', () {
      // Дата вместо секунд, битое тело, ноль — во всех случаях остаётся
      // серверное ограничение, а не отсутствие отсчёта.
      for (final response in [
        _response(429, headers: {'retry-after': 'Wed, 21 Oct 2026 07:28:00 GMT'}),
        _response(429, body: 'not json at all'),
        _response(429, body: '{"retry_after":0}'),
      ]) {
        final outcome = ResendOutcome.fromResponse(response);

        expect(outcome.status, ResendStatus.tooOften);
        expect(outcome.retryAfter, ResendCooldown.serverPause);
      }
    });

    test('500 на этой ручке значит, что письмо не ушло', () {
      // sendRegisterVerification отвечает 500 только тогда, когда отправка
      // не удалась, — значит это поломка почты, а не «сервер прилёг».
      expect(ResendOutcome.fromResponse(_response(500)).status, ResendStatus.mailDown);
      expect(ResendOutcome.fromResponse(_response(502)).status, ResendStatus.mailDown);
    });

    test('признак поломки почты в теле разбирается', () {
      expect(
        ResendOutcome.fromResponse(_response(503, body: '{"code":"mail_unavailable"}')).status,
        ResendStatus.mailDown,
      );
      expect(
        ResendOutcome.fromResponse(_response(400, body: '{"error":"MAIL_DOWN"}')).status,
        ResendStatus.mailDown,
      );
    });

    test('400 — сервер отверг запрос, а не почту', () {
      final outcome = ResendOutcome.fromResponse(
        _response(400, body: '{"message":"request validation failed"}'),
      );

      expect(outcome.status, ResendStatus.rejected);
    });
  });

  group('повторная отправка через сервис', () {
    late _FakeApiClient api;

    setUp(() async {
      api = _FakeApiClient();
      await GetIt.instance.reset();
      GetIt.instance.registerSingleton<ApiClient>(api);
    });

    test('уходит на почтовую ручку с тем же адресом', () async {
      api.reply = _response(200, body: '{"retry_after":60}');

      final outcome = await AuthService().resendVerificationCode('me@example.com');

      expect(outcome.status, ResendStatus.sent);
      expect(api.calls.single.$1, '/mail/send_verify_email');
      expect(api.calls.single.$2['email'], 'me@example.com');
    });

    test('«слишком часто» доходит до экрана сроком, а не общей ошибкой', () async {
      api.reply = _response(429, headers: {'retry-after': '30'});

      final outcome = await AuthService().resendVerificationCode('me@example.com');

      expect(outcome.status, ResendStatus.tooOften);
      expect(outcome.retryAfter, const Duration(seconds: 30));
    });

    test('неработающая почта доходит отдельным исходом', () async {
      api.reply = _response(500);

      final outcome = await AuthService().resendVerificationCode('me@example.com');

      expect(outcome.status, ResendStatus.mailDown);
    });

    test('нет связи — не поломка почты, и до сервера ничего не ушло', () async {
      api.offline = true;

      final outcome = await AuthService().resendVerificationCode('me@example.com');

      expect(outcome.status, ResendStatus.offline);
      expect(api.calls, isEmpty);
    });
  });
}
