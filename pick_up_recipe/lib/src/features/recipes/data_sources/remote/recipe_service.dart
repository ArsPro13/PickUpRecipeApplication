import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/core/offline/local_recipes.dart';
import 'package:pick_up_recipe/core/offline/offline_exception.dart';
import 'package:pick_up_recipe/core/offline/outbox.dart';
import 'package:pick_up_recipe/src/features/authentication/data_sources/remote/auth_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/correction_model.dart';
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

  /// Справочный рецепт метода — с него начинается ветка «у обжарщика нет
  /// рецепта под ваш прибор». null — у метода нет базового рецепта.
  Future<RecipeData?> getBaseRecipe(String device) async {
    final response = await _apiClient.getCached(
      '/recipe/base',
      {'device': device},
      cacheKey: 'recipe_base:$device',
    );

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Базовый рецепт не пришёл: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return RecipeData.fromResponse(RecipeResponseModel.fromJson(data));
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
    bool allVersions = false,
  }) async {
    try {
      final query = {
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
        // Без этого список отдаёт по одному рецепту на цепочку правок, и
        // стопке версий на экране «Мои рецепты» взяться неоткуда.
        if (allVersions) 'all_versions': 'true',
      };

      final response = await _apiClient.getCached(
        '/recipe/params',
        query,
        cacheKey:
            'recipes:${query.entries.map((e) => '${e.key}=${e.value}').join('&')}',
      );

      if (response.statusCode == 200) {
        final utf8Decoded = utf8.decode(response.bodyBytes);

        final List<dynamic>? data = jsonDecode(utf8Decoded);

        final List<RecipeData> recipes = [];

        for (final recipe in data ?? []) {
          final recipeResponseData = RecipeResponseModel.fromJson(recipe);

          recipes.add(RecipeData.fromResponse(recipeResponseData));
        }

        return withUnsentRecipes(
          recipes,
          LocalRecipes.all(),
          packId: packId,
          device: device,
        );
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

  /// Сохраняет оценку чашки.
  ///
  /// Шкала в базе 0…10, а на экране пять звёзд — перевод делает вызывающий,
  /// потому что звёзды знает только он (открытый вопрос макета 05).
  ///
  /// Все семь осей необязательны и уезжают только те, что человек правда
  /// назвал. Пустая ось — это `null` в базе, а не ноль: ноль на шкале 0…10
  /// значит «отвратительно» и попал бы в среднюю по позиции у обжарщика.
  Future<void> postEstimation({
    required int recipeId,
    double? aroma,
    double? flavor,
    double? aftertaste,
    double? acidity,
    double? bitterness,
    double? sweetness,
    double? overall,
    String comment = '',
  }) async {
    final payload = {
      'recipe_id': recipeId,
      if (aroma != null) 'aroma': aroma,
      if (flavor != null) 'flavor': flavor,
      if (aftertaste != null) 'aftertaste': aftertaste,
      if (acidity != null) 'acidity': acidity,
      if (bitterness != null) 'bitterness': bitterness,
      if (sweetness != null) 'sweetness': sweetness,
      if (overall != null) 'overall': overall,
      'comment': comment,
      'date': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final response = await _apiClient.post('/recipe/estimation', payload);

      if (response.statusCode != 200) {
        throw Exception('Оценка не сохранилась: ${response.statusCode}');
      }
    } on OfflineException {
      // Оценку ставят сразу после чашки и ровно там, где заваривали, — то
      // есть чаще всего без сети. Потерять её значит потерять единственное,
      // ради чего человек вернулся к экрану.
      await Outbox.enqueueEstimation(payload);
    }
  }

  /// Просит поправку по жалобам. Ничего не меняет — только предлагает.
  Future<RecipeCorrection> suggestCorrection({
    required int recipeId,
    required List<String> complaints,
  }) async {
    final response = await _apiClient.post('/recipe/correction', {
      'recipe_id': recipeId,
      'complaints': complaints,
    });

    if (response.statusCode != 200) {
      throw Exception('Поправка не пришла: ${response.statusCode}');
    }

    return RecipeCorrection.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  /// Сохраняет правку как новую версию в цепочке `prev_id`/`next_id`.
  ///
  /// Не `PUT /recipe/` — тот переписал бы сохранённое. Рецепт обжарщика
  /// эталон и остаётся неприкосновенным, а своя правка всегда начинает
  /// следующую версию: на этом стоит вся история и стопка «ещё 6 версий».
  ///
  /// Возвращает идентификатор новой версии, а не рецепт целиком: ручка
  /// отдаёт `BaseRecipe`, то есть шапку **без шагов**, и собирать из неё
  /// `RecipeData` значило бы стереть шаги на экране сразу после сохранения.
  Future<int> evolveRecipe(RecipeData recipe) async {
    final payload = evolvePayload(recipe);

    try {
      final response = await _apiClient.post('/recipe/evolve', payload);

      if (response.statusCode != 200) {
        throw Exception('Рецепт не сохранился: ${response.statusCode}');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return (data['id'] as num?)?.toInt() ?? recipe.id;
    } on OfflineException {
      // Версия встаёт в очередь и получает отрицательный идентификатор.
      // До отправки она живёт на телефоне и ведёт себя как обычный рецепт:
      // открывается, заваривается, принимает оценку — та уедет следом.
      //
      // Копия делается до постановки в очередь: если она не соберётся,
      // человек увидит отказ — и в очереди не останется дела, про которое
      // ему сказали, что оно не сохранилось.
      final local = copyRecipe(recipe)
        ..date = DateTime.now().toUtc().toIso8601String();

      final localId = await Outbox.enqueueEvolve(payload);
      local.id = localId;
      await LocalRecipes.add(local);

      return localId;
    }
  }
}

/// Подмешивает к списку с сервера версии, которые ещё не уехали.
///
/// Вынесено функцией ради теста: без неё правка, сделанная в лесу, пропадала
/// бы из «Моих рецептов» до первой сети — то есть ровно тогда, когда человек
/// на неё смотрит.
List<RecipeData> withUnsentRecipes(
  List<RecipeData> fromServer,
  List<RecipeData> unsentAll, {
  int? packId,
  String? device,
}) {
  final unsent = unsentAll.where((recipe) {
    if (packId != null && recipe.packId != packId) return false;
    if (device != null && recipe.device != device) return false;
    return true;
  }).toList();

  if (unsent.isEmpty) return fromServer;

  // Свои неотправленные — сверху: они самые свежие по определению.
  return [...unsent, ...fromServer];
}

/// Тело запроса на сохранение версии.
///
/// Собирается руками, а не через `RecipeData.toJson()`: генератор пишет поля
/// именами клиентской модели — `pack`, `grindDescriptor`, `agitationLevel`, —
/// а бэкенд ждёт `pack_id`, `grind_descriptor`, `agitation_level`. Круговой
/// разбор от этого не страдает, потому что читает теми же именами, а вот
/// отправка молча теряла бы три поля.
///
/// Вынесено из класса, чтобы проверяться тестом без сети.
Map<String, dynamic> evolvePayload(RecipeData recipe) {
  return {
    'id': recipe.id,
    'pack_id': recipe.packId,
    // Дата версии — когда человек её сохранил, а не когда она доехала до
    // сервера: без сети правка лежит в очереди до утра, и подписать её
    // утренним временем значило бы соврать про вчерашнюю чашку.
    'date': DateTime.now().toUtc().toIso8601String(),
    'grinder_id': recipe.grinderId,
    'grind_step': recipe.grindStep,
    'water': recipe.water,
    'load': recipe.load,
    'time': recipe.time,
    'device': recipe.device,
    if (recipe.temperature != null) 'temperature': recipe.temperature,
    if (recipe.title.isNotEmpty) 'title': recipe.title,
    if (recipe.notes.isNotEmpty) 'notes': recipe.notes,
    if (recipe.grindDescriptor.isNotEmpty) 'grind_descriptor': recipe.grindDescriptor,
    if (recipe.agitationLevel != null) 'agitation_level': recipe.agitationLevel,
    'steps': [
      for (final step in recipe.steps)
        {
          'seq_num': step.seqNum,
          'instruction': step.instruction,
          'water': step.water,
          'time': step.time,
          if (step.stepType.isNotEmpty) 'step_type': step.stepType,
          if (step.stepKey.isNotEmpty) 'step_key': step.stepKey,
          if (step.tip.isNotEmpty) 'tip': step.tip,
          'is_optional': step.isOptional,
          'until_user': step.untilUser,
          if (step.untilSign.isNotEmpty) 'until_sign': step.untilSign,
          if (step.warning.isNotEmpty) 'warning': step.warning,
        },
    ],
  };
}
