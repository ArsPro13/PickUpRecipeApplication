import 'dart:convert';

import 'package:get_it/get_it.dart';

import '../../../../../core/api_client.dart';
import '../../domain/brew_method.dart';

/// Справочник методов заваривания. Только чтение: он засеян миграцией.
class BrewMethodService {
  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  Future<List<BrewMethod>> getMethods() async {
    final response = await _apiClient.get('/brew_methods', const {});
    if (response.statusCode != 200) {
      throw Exception('Не удалось получить методы: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>? ?? const [];
    return data.map((item) => BrewMethod.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<BrewMethodGroup>> getGroups() async {
    final response = await _apiClient.get('/brew_methods/groups', const {});
    if (response.statusCode != 200) {
      throw Exception('Не удалось получить группы методов: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>? ?? const [];
    return data.map((item) => BrewMethodGroup.fromJson(item as Map<String, dynamic>)).toList();
  }
}
