import 'dart:convert';

import 'package:get_it/get_it.dart';

import '../../../../../core/api_client.dart';
import '../../domain/models/step_type_model.dart';
import '../../domain/models/user_step_type_model.dart';

/// Типы шагов: встроенный справочник и свои заготовки.
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

  /// Свои заготовки под метод — пятая группа листа выбора.
  Future<List<UserStepType>> getUserStepTypes(int brewMethodId) async {
    final response = await _apiClient.get('/user/step_types', {
      'brew_method_id': brewMethodId.toString(),
    });
    if (response.statusCode != 200) {
      throw Exception('Свои типы не пришли: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>?;
    return [
      for (final item in data ?? const [])
        UserStepType.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// Заводит свой тип шага. Возвращает созданное — с id и умолчаниями базы.
  Future<UserStepType> createUserStepType({
    required int brewMethodId,
    required String label,
    required String icon,
    required StepEndsWith endsWith,
    bool hasWater = false,
    String warning = '',
  }) async {
    final response = await _apiClient.post('/user/step_types', {
      'brew_method_id': brewMethodId,
      'label': label,
      'icon': icon,
      'ends_with': endsWith.wire,
      'has_water': hasWater,
      if (warning.isNotEmpty) 'warning': warning,
    });
    if (response.statusCode != 200) {
      throw Exception('Тип не сохранился: ${response.statusCode}');
    }

    return UserStepType.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }
}
