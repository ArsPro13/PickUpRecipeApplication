import 'dart:convert';

import 'package:get_it/get_it.dart';

import '../../../../../core/api_client.dart';
import '../../../../../core/offline/offline_exception.dart';
import '../../../../../core/offline/outbox.dart';
import '../../domain/models/step_type_model.dart';
import '../../domain/models/user_step_type_model.dart';

/// Типы шагов: встроенный справочник и свои заготовки.
class StepTypeService {
  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  Future<StepTypeReference> getReference() async {
    final response = await _apiClient.getCached(
      '/reference/step_types',
      const {},
      cacheKey: 'step_types',
    );
    if (response.statusCode != 200) {
      throw Exception('Не удалось получить типы шагов: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;
    if (data == null) return const StepTypeReference();
    return StepTypeReference.fromJson(data);
  }

  /// Свои заготовки под метод — пятая группа листа выбора.
  Future<List<UserStepType>> getUserStepTypes(int brewMethodId) async {
    final response = await _apiClient.getCached(
      '/user/step_types',
      {'brew_method_id': brewMethodId.toString()},
      cacheKey: 'user_step_types:$brewMethodId',
    );
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
    final payload = {
      'brew_method_id': brewMethodId,
      'label': label,
      'icon': icon,
      'ends_with': endsWith.wire,
      'has_water': hasWater,
      if (warning.isNotEmpty) 'warning': warning,
    };

    try {
      final response = await _apiClient.post('/user/step_types', payload);
      if (response.statusCode != 200) {
        throw Exception('Тип не сохранился: ${response.statusCode}');
      }

      return UserStepType.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } on OfflineException {
      // Без сети заготовка встаёт в очередь и сразу возвращается такой, какой
      // её завели: в рецепт она кладётся подписью, а не идентификатором, —
      // значит, шаг соберётся и без ответа сервера.
      await Outbox.enqueueUserStepType(payload);

      return UserStepType(
        id: await Outbox.nextLocalRecipeId(),
        brewMethodId: brewMethodId,
        label: label,
        icon: icon,
        endsWith: endsWith,
        hasWater: hasWater,
        warning: warning,
      );
    }
  }
}
