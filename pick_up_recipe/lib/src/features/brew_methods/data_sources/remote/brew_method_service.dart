import 'dart:convert';

import 'package:get_it/get_it.dart';

import '../../../../../core/api_client.dart';
import '../../domain/brew_method.dart';

/// Справочник методов заваривания. Только чтение: он засеян миграцией.
///
/// Оба запроса ходят через кэш: справочник меняется раз в релиз, а без него
/// не открывается ни страница кофе, ни список рецептов — то есть без сети не
/// работало бы ровно всё.
class BrewMethodService {
  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  Future<List<BrewMethod>> getMethods() async {
    final response = await _apiClient.getCached(
      '/brew_methods',
      const {},
      cacheKey: 'brew_methods',
    );
    if (response.statusCode != 200) {
      throw Exception('Не удалось получить методы: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>? ?? const [];
    return data.map((item) => BrewMethod.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<BrewMethodGroup>> getGroups() async {
    final response = await _apiClient.getCached(
      '/brew_methods/groups',
      const {},
      cacheKey: 'brew_method_groups',
    );
    if (response.statusCode != 200) {
      throw Exception('Не удалось получить группы методов: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>? ?? const [];
    return data.map((item) => BrewMethodGroup.fromJson(item as Map<String, dynamic>)).toList();
  }
}
