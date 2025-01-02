import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/src/features/authentication/data_sources/remote/auth_service.dart';

class PossibleValuesService {
  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  Future<List<String>?> getByEndpoint(String endpoint) async {
    try {
      final response = await _apiClient.getPossibleValues(
        '/possible_values/$endpoint',
        {},
      );

      if (response.statusCode == 200) {
        final utf8Decoded = utf8.decode(response.bodyBytes);
        final data = List<String>.from(jsonDecode(utf8Decoded));
        return data;
      } else if (response.statusCode == 401) {
        AuthService authService = AuthService();
        authService.refreshTokens();
      } else {
        throw Exception(
            'Failed to fetch possible countries: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      logger.e('Error fetching possible countries', error: e);
      rethrow;
    }
    return null;
  }
}
