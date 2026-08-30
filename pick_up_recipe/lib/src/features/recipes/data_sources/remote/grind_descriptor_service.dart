import 'dart:convert';

import 'package:get_it/get_it.dart';

import '../../../../../core/api_client.dart';
import '../../domain/models/grind_descriptor_model.dart';

/// Справочник крупности помола. Только чтение: он засеян миграцией.
class GrindDescriptorService {
  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  Future<List<GrindDescriptor>> getDescriptors() async {
    final response = await _apiClient.getCached(
      '/reference/grind_descriptors',
      const {},
      cacheKey: 'grind_descriptors',
    );
    if (response.statusCode != 200) {
      throw Exception('Не удалось получить крупность помола: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>? ?? const [];
    return data
        .map((item) => GrindDescriptor.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
