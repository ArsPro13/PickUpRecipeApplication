import 'dart:convert';

import 'package:get_it/get_it.dart';

import '../../../../../core/api_client.dart';
import '../../../../../core/logger.dart';
import '../../domain/models/grinder_model.dart';

/// Кофемолки: справочник и набор пользователя.
///
/// Набор пользователя живёт на сервере, а не локально (ответ на вопрос 19):
/// переустановка приложения не должна стирать кофемолку — без неё в рецепте
/// нечего показать вместо щелчков.
///
/// Сообщения исключений и журнала в словарь не выносятся: на экран они не
/// попадают — экран кофемолки говорит своими словами и про сеть, и про отказ
/// сервера, — а читает их разработчик в логе. Язык лога от языка телефона
/// зависеть не должен.
class GrinderService {
  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  /// Весь справочник кофемолок.
  ///
  /// Сохраняется на телефон: без справочника экран выбора пуст, а щелчки в
  /// рецепте не во что перевести.
  Future<List<Grinder>> getAllGrinders() async {
    final response = await _apiClient.getCached(
      '/recipe/grinders',
      const {},
      cacheKey: 'grinders',
    );

    if (response.statusCode != 200) {
      throw Exception('Не удалось получить справочник кофемолок: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>? ?? const [];
    return data.map((item) => Grinder.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Кофемолки пользователя вместе с признаком основной.
  Future<List<UserGrinder>> getUserGrinders() async {
    final response = await _apiClient.getCached(
      '/auth/profile',
      const {},
      cacheKey: 'profile',
    );

    if (response.statusCode != 200) {
      throw Exception('Не удалось получить профиль: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final grinders = data['grinders'] as List<dynamic>? ?? const [];

    return grinders
        .map((item) => UserGrinder.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Заменяет набор кофемолок пользователя целиком.
  ///
  /// Целиком, а не по одной: экран отдаёт итоговый список, и считать разницу
  /// на клиенте значило бы повторять ту же работу дважды.
  Future<List<UserGrinder>> setUserGrinders(
    List<Grinder> grinders, {
    int? primaryGrinderId,
  }) async {
    final response = await _apiClient.put('/auth/profile', {
      'grinders': grinders.map((grinder) => {'id': grinder.id}).toList(),
      if (primaryGrinderId != null) 'primary_grinder_id': primaryGrinderId,
    });

    if (response.statusCode != 200) {
      logger.e('Не удалось сохранить кофемолки: ${response.statusCode} ${response.body}');
      throw Exception('Не удалось сохранить кофемолки: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final saved = data['grinders'] as List<dynamic>? ?? const [];

    return saved.map((item) => UserGrinder.fromJson(item as Map<String, dynamic>)).toList();
  }
}
