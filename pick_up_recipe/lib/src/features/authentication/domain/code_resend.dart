// Повторная отправка кода из письма: отсчёт до следующей попытки и разбор
// ответа сервера.
//
// Вынесено из экрана по той же причине, что и auth_rules.dart: это
// единственная часть сценария «письмо не пришло», которую можно проверить
// тестом без запуска приложения. Домен отвечает, ЧТО произошло, а фразы для
// человека подставляет экран: исходов пять, и каждый требует своего совета.

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Чем кончилась просьба прислать код ещё раз.
enum ResendStatus {
  /// Письмо принято к отправке.
  sent,

  /// Сервер держит паузу между письмами и это письмо не принял.
  tooOften,

  /// Письмо не ушло со стороны сервера. Человеку тут править нечего, и
  /// показывать ему общую «ошибку» — значит отправить искать её у себя.
  mailDown,

  /// Сервер отверг сам запрос: не тот адрес, не то состояние аккаунта.
  rejected,

  /// До сервера не дошли.
  offline,
}

/// Разобранный ответ на повторную отправку.
class ResendOutcome {
  const ResendOutcome(this.status, {this.retryAfter});

  final ResendStatus status;

  /// Сколько ждать до следующей попытки. Заполнено только у [ResendStatus.tooOften]:
  /// человеку нужен срок, а не слово «часто».
  final Duration? retryAfter;

  /// Разбирает ответ ручки отправки письма.
  ///
  /// Пятисотка здесь значит ровно одно — письмо не ушло: обработчик
  /// `sendRegisterVerification` отвечает 500 только тогда, когда отправка не
  /// удалась. Поэтому она и разбирается как поломка почты, а не как «сервер
  /// прилёг»: совет человеку в этих случаях разный.
  factory ResendOutcome.fromResponse(http.Response response) {
    final code = response.statusCode;

    if (code == 200) return const ResendOutcome(ResendStatus.sent);

    if (code == 429) {
      return ResendOutcome(
        ResendStatus.tooOften,
        // Сервер молчит о сроке — берём его же ограничение: мидлвар
        // OncePerMinute пропускает одно письмо в минуту.
        retryAfter: _retryAfter(response) ?? ResendCooldown.serverPause,
      );
    }

    if (_saysMailUnavailable(response) || code >= 500) {
      return const ResendOutcome(ResendStatus.mailDown);
    }

    return const ResendOutcome(ResendStatus.rejected);
  }

  /// Сколько сервер просит подождать. null — не сказал.
  ///
  /// Смотрим в двух местах: заголовок `Retry-After` — то, что по правилам
  /// HTTP шлют вместе с 429, и поле в теле — то, что удобнее отдать
  /// приложению. Секунды, не дата: дату сервер не шлёт, и разбирать её
  /// незачем.
  static Duration? _retryAfter(http.Response response) {
    final header = int.tryParse(response.headers['retry-after']?.trim() ?? '');
    if (header != null && header > 0) return Duration(seconds: header);

    final body = _body(response);
    final field = body?['retry_after'] ?? body?['retry_after_seconds'];
    final seconds = field is num ? field.round() : int.tryParse('$field');
    if (seconds != null && seconds > 0) return Duration(seconds: seconds);

    return null;
  }

  /// Сказал ли сервер прямо, что почта не работает.
  ///
  /// Признак поломки почты бэкенд заводит отдельной задачей; когда он
  /// появится в теле ответа, разбирать его будет уже некому — вот он.
  static bool _saysMailUnavailable(http.Response response) {
    final body = _body(response);
    if (body == null) return false;

    final marker = '${body['code'] ?? body['error'] ?? ''}'.toLowerCase();

    return marker.contains('mail_unavailable') || marker.contains('mail_down');
  }

  static Map<String, dynamic>? _body(http.Response response) {
    if (response.body.isEmpty) return null;

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}

/// Отсчёт до следующей попытки.
///
/// Считается от момента готовности, а не тиканьем счётчика вниз: экран уходит
/// в фон вместе с приложением, свёрнутым в карман, и возвращается с числом,
/// которое давно неправда. Момент не врёт — сколько бы приложение ни спало.
class ResendCooldown {
  /// Отсчёта нет: письмо ещё не отправляли.
  const ResendCooldown.idle() : readyAt = null;

  const ResendCooldown.until(this.readyAt);

  /// Письмо ушло в [moment] — следующее можно через [pause].
  ResendCooldown.sentAt(DateTime moment, {Duration pause = serverPause})
      : readyAt = moment.add(pause);

  /// Пауза между письмами на сервере: мидлвар OncePerMinute на
  /// `/mail/send_verify_email` пропускает один запрос в минуту. Обещать
  /// раньше — значит обещать отказ.
  static const Duration serverPause = Duration(seconds: 60);

  /// Когда можно отправлять. null — прямо сейчас.
  final DateTime? readyAt;

  /// Сколько осталось ждать. Ноль — ждать нечего.
  Duration left(DateTime now) {
    final until = readyAt;
    if (until == null) return Duration.zero;

    final left = until.difference(now);

    return left.isNegative ? Duration.zero : left;
  }

  bool ready(DateTime now) => left(now) == Duration.zero;

  /// м:сс — как на таймере заваривания, чтобы формат времени был один на всё.
  static String format(Duration left) {
    final seconds = left.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '${left.inMinutes}:$seconds';
  }
}
