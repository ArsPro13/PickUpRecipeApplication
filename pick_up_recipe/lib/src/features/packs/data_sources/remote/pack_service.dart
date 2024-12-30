import 'dart:convert';

import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/src/features/authentication/data_sources/remote/auth_service.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/domain/models/pack_from_image_response_model.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_request_model.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_response_model.dart';

class PackService {
  final ApiClient _apiClient = ApiClient();

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
      final response = await _apiClient.get(
        '/packs/params',
        {
          'name': name ?? '',
          'country': country ?? '',
          'startDate': startDate ?? '',
          'endDate': endDate ?? '',
          'offset': offset?.toString() ?? '',
          'limit': limit?.toString() ?? '',
          'sortBy': sortBy ?? '',
        },
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
      final response = await _apiClient.get(
        '/packs',
        {
          'id': id.toString(),
        },
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
