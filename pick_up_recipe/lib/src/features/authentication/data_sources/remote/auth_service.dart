import 'dart:convert';

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/core/offline/offline_exception.dart';
import 'package:pick_up_recipe/src/features/authentication/domain/auth_rules.dart';
import 'package:pick_up_recipe/src/features/authentication/domain/code_resend.dart';

class AuthService {
  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = EncryptedSharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> authenticate(String email, String password) async {
    final response = await _apiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (response.statusCode != 200) {
      throw AuthFailure.fromResponse(response, action: 'войти');
    }

    final data = jsonDecode(response.body);
    if (!data.containsKey('access_token') || !data.containsKey('refresh_token')) {
      throw const AuthFailure('Сервер ответил без токенов');
    }

    await _saveTokens(data['access_token'], data['refresh_token']);
    logger.i('User authenticated and tokens saved.');
  }

  /// Повторная отправка кода подтверждения.
  ///
  /// Без неё человек, у которого письмо не дошло, оказывался в тупике:
  /// ручка на бэкенде была, а клиент её не звал.
  ///
  /// Возвращает разобранный исход, а не бросает исключение: «слишком часто»,
  /// «почта не работает» и «адрес не тот» — не одна ошибка на троих, а три
  /// разных совета человеку, и различать их по тексту исключения нельзя.
  ///
  /// Отдельной ручки повтора нет и не нужно: письмо шлёт та же
  /// `/mail/send_verify_email`, которая считает частоту по адресу получателя
  /// и отвечает сроком до следующей попытки — и при отказе, и при успехе.
  Future<ResendOutcome> resendVerificationCode(String email) async {
    try {
      final response = await _apiClient.post('/mail/send_verify_email', {'email': email});

      return ResendOutcome.fromResponse(response);
    } on OfflineException {
      return const ResendOutcome(ResendStatus.offline);
    }
  }

  /// Письмо для сброса пароля.
  ///
  /// Ответ одинаковый и на известный, и на неизвестный адрес (ответ 39):
  /// иначе форма превращается в проверялку, зарегистрирован ли человек.
  Future<void> requestPasswordReset(String email) async {
    final response = await _apiClient.post('/auth/forgot_password', {'email': email});

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw AuthFailure.fromResponse(response, action: 'отправить письмо');
    }
  }

  /// Сброс пароля по коду из письма.
  Future<void> resetPassword(String email, String code, String newPassword) async {
    final response = await _apiClient.post('/auth/reset_password', {
      'email': email,
      'code': code,
      'password': newPassword,
    });

    if (response.statusCode != 200) {
      throw AuthFailure.fromResponse(response, action: 'сменить пароль');
    }
  }

  /// Регистрация.
  ///
  /// [legalConsentVersion] — редакция правовых документов, с которой человек
  /// согласился отметкой в форме. Сервер отвечает 422, если её нет или она
  /// не совпадает с опубликованной: согласие без указания, с ЧЕМ именно
  /// человек согласился, не доказывает ничего.
  Future<void> register(
    String email,
    String password,
    String legalConsentVersion,
  ) async {
    try {
      final response = await _apiClient.post('/auth/register', {
        'email': email,
        'password': password,
        'legal_consent_version': legalConsentVersion,
      });

      if (response.statusCode != 200) {
        throw AuthFailure.fromResponse(response, action: 'зарегистрироваться');
      }
    } catch (e) {
      logger.e('Registration error', error: e);
      rethrow;
    }
  }

  Future<void> verifyMail(String email, String code) async {
    try {
      final response = await _apiClient.post('/mail/verify_email', {
        'code': code,
        'email': email,
      });

      if (response.statusCode == 200) {
        return;
      }

      // Бэкенд отвечает 500 на неверный код: разбирать его как «сервер лёг»
      // было бы неправдой, и человек не понял бы, что надо просто перенабрать.
      if (response.statusCode == 500) {
        logger.w('Wrong code');
        throw const AuthFailure('Код не подошёл. Проверьте письмо ещё раз');
      }

      throw AuthFailure.fromResponse(response, action: 'подтвердить почту');
    } catch (e) {
      logger.e('Registration error', error: e);
      rethrow;
    }
  }

  /// Обновление токенов, которое не спорит само с собой.
  ///
  /// Сервер помнит только последний выданный refresh (он лежит в
  /// `users.refresh_token`), и два параллельных обновления кончаются тем, что
  /// второе приходит с уже отданным токеном и получает 401 — а это для
  /// приложения «сессии нет», то есть человека выбрасывает на экран входа
  /// посреди работы.
  ///
  /// Параллельные 401 — обычное дело: экран поднимает три запроса сразу, и
  /// каждый зовёт обновление. Поэтому поход за токенами один на всех: кто
  /// пришёл вторым, ждёт того же ответа.
  static Future<void>? _refreshing;

  Future<void> refreshTokens() {
    return _refreshing ??= _refreshTokens().whenComplete(() => _refreshing = null);
  }

  Future<void> _refreshTokens() async {
    try {
      final response = await _apiClient.postRefresh('/auth/refresh');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('access_token') &&
            data.containsKey('refresh_token')) {
          await _saveTokens(data['access_token'], data['refresh_token']);

          logger.i('Tokens refreshed and saved.');
        } else {
          throw Exception('Invalid response format: tokens are missing');
        }
      } else {
        // Сервер отверг refresh — он мёртв: у сервера лежит только последний
        // выданный, и этот им уже не является. Держать его на телефоне значит
        // при каждом запуске считать сессию своей и показывать пустые экраны
        // вместо экрана входа.
        if (response.statusCode == 401 || response.statusCode == 403) {
          await logout();
        }

        throw Exception(
            'Failed to refresh tokens: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      logger.e('Token refresh error', error: e);
      rethrow;
    }
  }

  /// Лежит ли на телефоне сессия, которой можно пользоваться без сети.
  ///
  /// Нужна ровно для офлайна: подтвердить токен у сервера нельзя, но и
  /// выбрасывать человека на экран входа за то, что на кухне нет вайфая,
  /// нельзя тем более — он остался бы без всего, что уже сохранено.
  bool hasStoredSession() {
    final prefs = EncryptedSharedPreferences.getInstance();
    final refresh = prefs.getString('refresh_token');
    return refresh != null && refresh.isNotEmpty;
  }

  Future<String?> getAccessToken() async {
    final prefs = EncryptedSharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> getRefreshToken() async {
    final prefs = EncryptedSharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<void> logout() async {
    final prefs = EncryptedSharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    logger.i('User logged out and tokens removed.');
  }
}
