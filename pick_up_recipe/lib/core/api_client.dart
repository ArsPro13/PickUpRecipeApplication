import 'dart:convert';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/config.dart';

class ApiClient {
  final String baseUrl = Config.baseUrl;

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = EncryptedSharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': accessToken,
    };
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    return response;
  }

  Future<http.Response> postRefresh(String endpoint) async {
    final prefs = EncryptedSharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': refreshToken ?? '',
    };

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode({}),
    );

    return response;
  }

  Future<http.Response> get(
      String endpoint, Map<String, String> queryParams) async {
    final headers = await _getAuthHeaders();

    final uri =
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: headers,
    );

    return response;
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getAuthHeaders();

    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getAuthHeaders();

    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    return response;
  }

  Future<http.Response> patchImage(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await _getAuthHeaders();

    final response = await http.patch(
      Uri.parse('${Config.packImageBaseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return response;
  }

  Future<http.Response> patch(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await _getAuthHeaders();

    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return response;
  }

  Future<http.Response> getPossibleValues(
      String endpoint, Map<String, String> queryParams) async {
    final headers = await _getAuthHeaders();

    final uri = Uri.parse('${Config.packImageBaseUrl}$endpoint')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: headers,
    );

    return response;
  }
}
