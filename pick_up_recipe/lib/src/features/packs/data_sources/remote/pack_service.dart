import 'dart:convert';

import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/main.dart';
import 'package:pick_up_recipe/src/features/authentication/data_sources/remote/auth_service.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_request_model.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_response_model.dart';

class PackService {
  final ApiClient _apiClient = ApiClient();

  Future<List<PackResponseBodyModel>?> getPacks(
    String? name,
    String? country,
    String? startDate,
    String? endDate,
    int? offset,
    int? limit,
    String? sortBy,
  ) async {
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
        final List<dynamic>? data = jsonDecode(response.body);

        final List<PackResponseBodyModel> packs = [];
        for (final pack in data ?? []) {
          packs.add(PackResponseBodyModel.fromJson(pack));
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

  Future<PackData> addPack(PackRequestModel packData) async {
    try {
      // final response = await _apiClient.post('/packs', {
      //   "pack_country": "Kenya",
      //   "pack_date": "12-12-2012",
      //   "pack_descriptors": [
      //     "aaaaaaaazzzz"
      //   ],
      //   "pack_image": "akwlnigiorsngowi",
      //   "pack_name": "liqengwqn",
      //   "pack_processing_method": [
      //     "gpqn2og io2rgni2rg 2greion"
      //   ],
      //   "pack_sca_score": 90,
      //   "pack_variety": "kjgrwnirwlg"
      // });
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
}
