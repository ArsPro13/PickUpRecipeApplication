import 'dart:convert';

import 'package:get_it/get_it.dart';

import '../../../../../core/api_client.dart';
import '../../domain/models/step_type_model.dart';

/// Справочник типов шагов. Только чтение: он засеян миграцией.
class StepTypeService {
  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  Future<StepTypeReference> getReference() async {
    final response = await _apiClient.get('/reference/step_types', const {});
    if (response.statusCode != 200) {
      throw Exception('Не удалось получить типы шагов: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;
    if (data == null) return const StepTypeReference();
    return StepTypeReference.fromJson(data);
  }
}
