import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/src/features/authentication/data_sources/remote/auth_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_response_model.dart';

class RecipeService {
  final getIt = GetIt.instance;
  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  Future<RecipeData?> generateRecipe(String device, int packId) async {
    try {
      final response = await _apiClient.post(
        '/recipe/generate',
        {
          "device": device,
          "pack_id": packId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = RecipeResponseModel.fromJson(data);
        return RecipeData.fromResponse(responseData);
      } else if (response.statusCode == 401) {
        AuthService authService = AuthService();
        authService.refreshTokens();
      } else {
        throw Exception(
            'Failed to generate recipe: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      logger.e('Error generating recipe', error: e);
      rethrow;
    }
    return null;
  }

  Future<List<RecipeData>?> getByParams({
    int? packId,
    int? grinderId,
    int? grindStep,
    int? grindSubStep,
    String? device,
    String? startDate,
    String? endDate,
    int? offset,
    int? limit,
    String? sortBy,
  }) async {
    try {
      final response = await _apiClient.get(
        '/recipe/params',
        {
          if (packId != null) 'pack_id': packId.toString(),
          if (grinderId != null) 'grinder_id': grinderId.toString(),
          if (grindStep != null) 'grind_step': grindStep.toString(),
          if (grindSubStep != null) 'grind_sub_step': grindSubStep.toString(),
          if (device != null) 'device': device,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (offset != null) 'offset': offset.toString(),
          if (limit != null) 'limit': limit.toString(),
          if (sortBy != null) 'sort_by': sortBy,
        },
      );

      if (response.statusCode == 200) {
        final utf8Decoded = utf8.decode(response.bodyBytes);

        final List<dynamic>? data = jsonDecode(utf8Decoded);

        final List<RecipeData> recipes = [];

        for (final recipe in data ?? []) {
          final recipeResponseData = RecipeResponseModel.fromJson(recipe);

          recipes.add(RecipeData.fromResponse(recipeResponseData));
        }
        return recipes;
      } else if (response.statusCode == 401) {
        AuthService authService = AuthService();
        authService.refreshTokens();
      } else {
        throw Exception(
            'Failed to fetch recipes: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      logger.e('Error fetching recipes', error: e);
      rethrow;
    }
    return null;
  }
}
