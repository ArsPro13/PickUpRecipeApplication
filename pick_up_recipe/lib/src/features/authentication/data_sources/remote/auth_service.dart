import 'dart:convert';

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/core/logger.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = EncryptedSharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> authenticate(String email, String password) async {
    try {
      final response = await _apiClient.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('access_token') &&
            data.containsKey('refresh_token')) {
          await _saveTokens(data['access_token'], data['refresh_token']);
          logger.i('User authenticated and tokens saved.');
        } else {
          throw Exception('Invalid response format: tokens are missing');
        }
      } else {
        throw Exception(
          'Failed to login user',
        );
      }
    } catch (e) {
      logger.e('Authentication error', error: e);
      rethrow;
    }
  }

  Future<void> register(String email, String password) async {
    try {
      final response = await _apiClient.post('/auth/register', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception(
          'Failed to register user',
        );
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
      } else if (response.statusCode == 500) {
        logger.w('Wrong code');
        throw Exception('Wrong confirmation code. Try again');
      } else {
        throw Exception(
            'Failed to register: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      logger.e('Registration error', error: e);
      rethrow;
    }
  }

  Future<void> refreshTokens() async {
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
        throw Exception(
            'Failed to refresh tokens: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      logger.e('Token refresh error', error: e);
      rethrow;
    }
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
