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

  /// Сколько ждать до следующей попытки. Приходит и с отказом «слишком часто»,
  /// и с удачной отправкой: в первом случае человеку нужен срок вместо слова
  /// «часто», во втором — по нему заводится отсчёт на кнопке.
  final Duration? retryAfter;

  /// Разбирает ответ ручки отправки письма.
  ///
  /// Пятисотки здесь значат ровно одно — письмо не ушло: 503 отдаётся, когда
  /// почта выключена или не настроена, 500 — когда отправка не удалась по
  /// другой причине. Ни то, ни другое человек исправить не может, и совет ему
  /// нужен не тот, что при «сервер прилёг».
  factory ResendOutcome.fromResponse(http.Response response) {
    final code = response.statusCode;

    // Срок приходит и с удачным ответом: сервер сам говорит, когда примет
    // следующую просьбу, и придумывать свою минуту рядом с его минутой
    // значит рано или поздно с ней разойтись.
    if (code == 200) {
      return ResendOutcome(ResendStatus.sent, retryAfter: _retryAfter(response));
    }

    if (code == 429) {
      return ResendOutcome(
        ResendStatus.tooOften,
        // Сервер промолчал о сроке — берём его же ограничение: код с одного
        // адреса просят не чаще раза в минуту.
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
  /// Сейчас он говорит это кодом ответа, а не признаком в теле. Разбор
  /// оставлен на случай, когда признак появится: тело с ним приедет раньше,
  /// чем сюда дойдут руки.
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

  /// Пауза между письмами на сервере: `ResendInterval` в обработчике —
  /// не чаще раза в минуту на один адрес получателя. Обещать раньше —
  /// значит обещать отказ.
  ///
  /// Запасное значение: сервер присылает срок сам, и верить надо ему.
  /// Здешняя минута нужна там, где он промолчал.
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
