import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/core/offline/offline_exception.dart';
import 'package:pick_up_recipe/src/features/authentication/data_sources/remote/auth_service.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/domain/models/pack_from_image_response_model.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_request_model.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_response_model.dart';

/// Что нашлось по коду с упаковки.
sealed class CodeResolution {
  const CodeResolution();
}

/// Кофе жив: код ведёт на пачку.
class CodeFound extends CodeResolution {
  const CodeFound({required this.packId, required this.packName, required this.roasterName});

  final int packId;
  final String packName;
  final String roasterName;
}

/// Код существует, но кофе снят с продажи. Пачка на полке никуда не делась,
/// и рецепты по ней остаются доступны (DECISIONS §2.3).
class CodeWithdrawn extends CodeResolution {
  const CodeWithdrawn({required this.packId, required this.packName, required this.roasterName});

  final int packId;
  final String packName;
  final String roasterName;
}

/// Такого кода нет.
class CodeNotFound extends CodeResolution {
  const CodeNotFound();
}

/// Кода не видели раньше, а сети нет.
///
/// Отдельный исход, а не «нет такого»: сказать «такого кофе не существует»,
/// не сумев спросить сервер, — прямая ложь. Код разбирает только сервер:
/// на телефоне нет ни таблицы кодов, ни права её иметь.
class CodeOffline extends CodeResolution {
  const CodeOffline();
}

class PackService {
  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  /// Что стоит за кодом с упаковки: пачка, снятая позиция или ничего.
  Future<CodeResolution> resolveCode(String code) async {
    final http.Response response;
    try {
      // Разобранный код кладётся в память: вернуться к своей пачке по коду
      // человек может и в лесу, а второй раз спрашивать сервер не о чем —
      // ответ по коду не меняется.
      response = await _apiClient.getCached(
        '/packs/by_code',
        {'code': code},
        cacheKey: 'code:$code',
      );
    } on OfflineException {
      return const CodeOffline();
    }

    if (response.statusCode == 404 || response.statusCode == 400) {
      return const CodeNotFound();
    }
    if (response.statusCode != 200 && response.statusCode != 403) {
      throw Exception('Код не проверился: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final packId = (data['pack_id'] as num?)?.toInt() ?? 0;
    final packName = data['pack_name'] as String? ?? '';
    final roasterName = data['roaster_name'] as String? ?? '';

    return response.statusCode == 403
        ? CodeWithdrawn(packId: packId, packName: packName, roasterName: roasterName)
        : CodeFound(packId: packId, packName: packName, roasterName: roasterName);
  }

  Future<List<PackData>?> getPacks({
    String? name,
    String? country,
    String? startDate,
    String? endDate,
    int? offset,
    int? limit,
    String? sortBy,
  }) async {
    try {
      final query = {
        'name': name ?? '',
        'country': country ?? '',
        'startDate': startDate ?? '',
        'endDate': endDate ?? '',
        'offset': offset?.toString() ?? '',
        'limit': limit?.toString() ?? '',
        'sortBy': sortBy ?? '',
      };

      final response = await _apiClient.getCached(
        '/packs/params',
        query,
        // Ключ по самому запросу: полка с поиском по стране и полка целиком —
        // разные ответы, и подменять один другим без сети нельзя.
        cacheKey: 'packs:${query.entries.map((e) => '${e.key}=${e.value}').join('&')}',
      );

      if (response.statusCode == 200) {
        final utf8Decoded = utf8.decode(response.bodyBytes);

        final data = jsonDecode(utf8Decoded);

        final List<PackData> packs = [];
        for (final pack in data ?? []) {
          final responseData = PackResponseBodyModel.fromJson(pack);
          packs.add(PackData.fromResponse(responseData));
        }

        return packs;
      } else if (response.statusCode == 401) {
        AuthService authService = AuthService();
        authService.refreshTokens();
      } else {
        throw Exception(
            'Failed to fetch packs: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      logger.e('Error fetching packs', error: e);
      rethrow;
    }
    return null;
  }

  Future<PackData?> getPackById(int id) async {
    try {
      final response = await _apiClient.getCached(
        '/packs',
        {'id': id.toString()},
        cacheKey: 'pack:$id',
      );

      if (response.statusCode == 200) {
        final utf8Decoded = utf8.decode(response.bodyBytes);

        final data = jsonDecode(utf8Decoded);

        final PackResponseBodyModel pack = PackResponseBodyModel.fromJson(data);

        return PackData.fromResponse(pack);
      } else if (response.statusCode == 401) {
        AuthService authService = AuthService();
        authService.refreshTokens();
      } else {
        throw Exception(
            'Failed to fetch pack: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      logger.e('Error fetching pack', error: e);
      rethrow;
    }
    return null;
  }

  Future<PackData> addPack(PackRequestModel packData) async {
    try {
      final response = await _apiClient.post('/packs', packData.toStringMap());

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to add pack: ${response.statusCode} ${response.reasonPhrase}');
      }

      logger.i('Pack added successfully.');

      final data = PackResponseBodyModel.fromJson(json.decode(response.body));

      return PackData.fromResponse(data);
    } catch (e) {
      logger.e('Error adding pack', error: e);
      rethrow;
    }
  }

  Future<void> updatePack(int packId, Map<String, dynamic> updatedData) async {
    try {
      final response = await _apiClient.put('/packs/$packId', updatedData);

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update pack: ${response.statusCode} ${response.reasonPhrase}');
      }

      logger.i('Pack updated successfully.');
    } catch (e) {
      logger.e('Error updating pack', error: e);
      rethrow;
    }
  }

  Future<void> deletePack(int packId) async {
    try {
      final response = await _apiClient.delete('/packs/$packId');

      if (response.statusCode != 204) {
        throw Exception(
            'Failed to delete pack: ${response.statusCode} ${response.reasonPhrase}');
      }

      logger.i('Pack deleted successfully.');
    } catch (e) {
      logger.e('Error deleting pack', error: e);
      rethrow;
    }
  }

  Future<PackFromImageResponseModel?> getPackByImage(String? image) async {
    if (image == null) {
      throw Exception(
          'Failed to fetch pack information by image: image is empty');
    }
    try {
      final response = await _apiClient.patchImage(
        '/recognize/images_base64?lang=rus',
        {
          'image1': image,
        },
      );

      if (response.statusCode == 200) {
        final utf8Decoded = utf8.decode(response.bodyBytes);

        final data = jsonDecode(utf8Decoded);

        final PackFromImageResponseModel packResponse =
            PackFromImageResponseModel.fromJson(data);

        return packResponse;
      } else if (response.statusCode == 401) {
        AuthService authService = AuthService();
        authService.refreshTokens();
      } else {
        throw Exception(
            'Failed to fetch pack information by image: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      logger.e('Error fetching pack', error: e);
      rethrow;
    }
    return null;
  }
}
