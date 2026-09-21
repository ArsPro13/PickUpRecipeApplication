// Справочники, которые правятся в кабинете владельца, а не миграцией.
//
// Их два вида: палитра категорий (чем красить теги) и словари подсказок
// (что предлагать в полях формы). Оба читаются с кешем: они меняются раз в
// месяц, а нужны на каждом экране ввода — ходить за ними по сети каждый раз
// значит показывать пустое поле тому, кто в дороге.

import 'dart:convert';

import 'package:get_it/get_it.dart';

import '../../../../../core/api_client.dart';
import '../../domain/flavor_descriptor_entry.dart';
import '../../domain/flavor_palette.dart';
import '../../domain/reference_term.dart';

class ReferenceService {
  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  /// Палитра категорий. Пустой список — законный ответ: приложение знает
  /// палитру наизусть и рисует встроенной.
  Future<List<FlavorCategory>> getFlavorCategories() async {
    final response = await _apiClient.getCached(
      '/reference/flavor_categories',
      const {},
      cacheKey: 'flavor_categories',
    );
    if (response.statusCode != 200) {
      throw Exception('Не удалось получить палитру: ${response.statusCode}');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>? ?? const [];
    return data
        .map((item) => FlavorCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Словарь дескрипторов целиком: слово, категория, ступень.
  ///
  /// Из него получаются и цвет, и подсказки в поле — список один, потому
  /// что слова одни. Ответ сервера бывает двух видов, списком и объектом с
  /// полем `descriptors`: ручка отдаёт справочник вместе с группами.
  Future<List<FlavorDescriptorEntry>> getDescriptors() async {
    final response = await _apiClient.getCached(
      '/reference/flavor_descriptors',
      const {},
      cacheKey: 'flavor_descriptors',
    );
    if (response.statusCode != 200) {
      throw Exception('Не удалось получить дескрипторы: ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final list = decoded is Map<String, dynamic>
        ? (decoded['descriptors'] as List<dynamic>? ?? const [])
        : (decoded as List<dynamic>? ?? const []);

    return [
      for (final item in list)
        if (item is Map<String, dynamic>) FlavorDescriptorEntry.fromJson(item),
    ];
  }

  /// Подсказки одного вида: `country`, `region`, `processing`, `variety`.
  Future<List<ReferenceTerm>> getTerms(String kind) async {
    final response = await _apiClient.getCached(
      '/reference/terms',
      {'kind': kind},
      cacheKey: 'reference_terms_$kind',
    );
    if (response.statusCode != 200) {
      throw Exception('Не удалось получить подсказки $kind: ${response.statusCode}');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>? ?? const [];
    return data
        .map((item) => ReferenceTerm.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
