import 'dart:convert';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/config.dart';

class ApiClient {
  final String baseUrl = Config.baseUrl;
  final Future<void> Function() onAuthError;
  ApiClient({required this.onAuthError});

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = EncryptedSharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': accessToken,
    };
  }

  Future<http.Response> _handleRequest(
      Future<http.Response> Function() request) async {
    var response = await request();

    // Access-токен живёт 15 минут, и первый запрос после паузы почти всегда
    // ловит 401. Одного «обновить и повторить» достаточно; без повтора каждый
    // экран, загружающийся единожды, встречал утро пустым.
    if (response.statusCode == 401) {
      await onAuthError();
      response = await request();
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

    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': refreshToken ?? '',
      },
      body: jsonEncode({}),
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
