import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final String baseUrl = Config.baseUrl;

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    // final refreshToken = prefs.getString('refresh_token');

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

  Future<http.Response> get(String endpoint, Map<String, String> body) async {
    final headers = await _getAuthHeaders()..addAll(body);

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
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
}
