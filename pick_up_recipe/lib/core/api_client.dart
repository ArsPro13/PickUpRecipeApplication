import 'dart:async';
import 'dart:convert';

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/config.dart';
import 'package:pick_up_recipe/core/offline/net_errors.dart';
import 'package:pick_up_recipe/core/offline/network_status.dart';
import 'package:pick_up_recipe/core/offline/offline_cache.dart';
import 'package:pick_up_recipe/core/offline/offline_exception.dart';

class ApiClient {
  final String baseUrl = Config.baseUrl;
  final Future<void> Function() onAuthError;
  ApiClient({required this.onAuthError});

  /// Сколько ждём ответа, прежде чем считать, что сети нет.
  ///
  /// Предел нужен именно ради офлайна: без сети сокет иногда не отваливается,
  /// а молчит, и экран остаётся в крутилке навсегда. Двенадцать секунд — с
  /// запасом на медленный мобильный интернет и заметно меньше, чем терпение
  /// человека, стоящего над воронкой.
  static const Duration _timeout = Duration(seconds: 12);

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = EncryptedSharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': accessToken,
    };
  }

  /// Один поход в сеть: ответ — значит связь есть, обрыв — значит офлайн.
  ///
  /// Различать эти два случая обязан именно этот метод, и только он: выше по
  /// коду «сервер отказал» и «сервера не слышно» выглядят одинаково, а вести
  /// себя должны противоположно — первое показывают человеку, на второе
  /// достают сохранённое.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      NetworkStatus.markOnline();
      return response;
    } catch (error) {
      // ClientException — то, чем обрыв приезжает в веб-сборке (там нет ни
      // сокетов, ни dart:io); SocketException и родня — то же самое на
      // телефоне; TimeoutException — сеть, которая молчит, не отваливаясь.
      if (error is http.ClientException ||
          error is TimeoutException ||
          isPlatformNetworkError(error)) {
        NetworkStatus.markOffline();
        throw OfflineException(error);
      }
      rethrow;
    }
  }

  Future<http.Response> _handleRequest(
      Future<http.Response> Function() request) async {
    var response = await _send(request);

    // Access-токен живёт 15 минут, и первый запрос после паузы почти всегда
    // ловит 401. Одного «обновить и повторить» достаточно; без повтора каждый
    // экран, загружающийся единожды, встречал утро пустым.
    if (response.statusCode == 401) {
      await onAuthError();
      response = await _send(request);
    }

    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    return await _handleRequest(() async {
      final headers = await _getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      return response;
    });
  }

  /// Обновление пары токенов.
  ///
  /// Мимо _handleRequest намеренно: тот на 401 зовёт onAuthError, а onAuthError
  /// зовёт обновление токенов. Пропусти этот запрос через общий обработчик — и
  /// протухшая сессия уходит в бесконечный цикл: 401 → обновить → 401 → …
  /// Приложение при этом молотит сервер запросами, а человек видит пустой экран.
  Future<http.Response> postRefresh(String endpoint) async {
    final prefs = EncryptedSharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    return _send(
      () => http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': refreshToken ?? '',
        },
        body: jsonEncode({}),
      ),
    );
  }

  Future<http.Response> get(
      String endpoint, Map<String, String> queryParams) async {
    return await _handleRequest(() async {
      final headers = await _getAuthHeaders();

      final uri =
          Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: headers,
      );

      return response;
    });
  }

  /// GET, который переживает отсутствие сети.
  ///
  /// Удачный ответ кладётся в память телефона; когда сети нет, оттуда же и
  /// достаётся — тем же телом, что пришло бы от сервера. Разбирает его дальше
  /// тот же код, что и живой ответ: офлайн не может разойтись с онлайном в
  /// мелочах, потому что различия просто негде появиться.
  ///
  /// Кэша нет и сети нет — исключение уходит наверх: соврать тут нечем.
  Future<http.Response> getCached(
    String endpoint,
    Map<String, String> queryParams, {
    required String cacheKey,
  }) async {
    try {
      final response = await get(endpoint, queryParams);
      if (response.statusCode == 200) {
        await OfflineCache.put(cacheKey, utf8.decode(response.bodyBytes));
      }
      return response;
    } on OfflineException {
      final cached = OfflineCache.body(cacheKey);
      if (cached == null) rethrow;

      return http.Response(
        cached,
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    }
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    return await _handleRequest(() async {
      final headers = await _getAuthHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      return response;
    });
  }

  Future<http.Response> delete(String endpoint) async {
    return await _handleRequest(() async {
      final headers = await _getAuthHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return response;
    });
  }

  Future<http.Response> patchImage(
      String endpoint, Map<String, dynamic> body) async {
    return await _handleRequest(() async {
      final headers = await _getAuthHeaders();

      final response = await http.patch(
        Uri.parse('${Config.packImageBaseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return response;
    });
  }

  Future<http.Response> patch(
      String endpoint, Map<String, dynamic> body) async {
    return await _handleRequest(() async {
      final headers = await _getAuthHeaders();

      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return response;
    });
  }

  Future<http.Response> getPossibleValues(
      String endpoint, Map<String, String> queryParams) async {
    return await _handleRequest(() async {
      final headers = await _getAuthHeaders();

      final uri = Uri.parse('${Config.packImageBaseUrl}$endpoint')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: headers,
      );

      return response;
    });
  }
}
