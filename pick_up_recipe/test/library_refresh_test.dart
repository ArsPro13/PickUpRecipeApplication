// Списки обновляются сами — один способ на оба.
//
// Проверяется на уровне состояния, а не виджета: важно не то, что нарисовалось,
// а то, что нотифаер сходил за данными заново. Виджетный тест тут проверял бы
// `AutoTabsScaffold`, а сломается — подписка.

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/core/library_revision.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/src/features/brew_methods/application/brew_methods_state.dart';
import 'package:pick_up_recipe/src/features/brew_methods/data_sources/remote/brew_method_service.dart';
import 'package:pick_up_recipe/src/features/brew_methods/domain/brew_method.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipes_list_state.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Служба, которая не ходит в сеть, а считает, сколько раз её спросили.
class CountingRecipeService extends RecipeService {
  int calls = 0;

  /// Что «лежит на сервере». Меняется между запросами — так и проверяется,
  /// что список перечитали, а не показали старое.
  List<RecipeData> recipes = const [];

  @override
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
    calls++;
    return recipes;
  }
}

class EmptyMethodService extends BrewMethodService {
  @override
  Future<List<BrewMethod>> getMethods() async => const [];

  @override
  Future<List<BrewMethodGroup>> getGroups() async => const [];
}

RecipeData recipe({int id = 1, String date = '2026-09-05T10:00:00Z'}) => RecipeData(
      id: id,
      device: 'hario_v60',
      date: date,
      packId: 7,
      grinderId: 1,
      grindStep: '18',
      grindSubStep: null,
      water: 250,
      time: 150,
      temperature: 93,
      load: 15,
      title: '',
      notes: '',
      grindDescriptor: 'medium',
      agitationLevel: null,
      steps: const [],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CountingRecipeService recipes;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();

    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<ApiClient>(ApiClient(onAuthError: () async {}));

    recipes = CountingRecipeService();
    container = ProviderContainer(
      overrides: [
        recipeServiceProvider.overrideWithValue(recipes),
        brewMethodServiceProvider.overrideWithValue(EmptyMethodService()),
      ],
    );
    // Провайдер ленивый: пока его не прочитали, подписки на сигнал нет.
    container.read(recipesListProvider);
  });

  tearDown(() => container.dispose());

  group('обновление списков', () {
    test('сигнал заставляет список перечитать себя', () async {
      await container.read(recipesListProvider.notifier).load();
      expect(recipes.calls, 1);

      recipes.recipes = [recipe(id: 5)];
      LibraryRevision.bump();
      await Future<void>.delayed(Duration.zero);

      expect(recipes.calls, 2, reason: 'после сигнала список ходит за данными заново');
      expect(container.read(recipesListProvider).groups.single.latest.recipe.id, 5);
    });

    test('без сигнала список сам себя не перечитывает', () async {
      await container.read(recipesListProvider.notifier).load();
      await Future<void>.delayed(Duration.zero);

      expect(recipes.calls, 1, reason: 'обновление по сигналу, а не по таймеру');
    });

    test('каждый сигнал считается отдельно', () async {
      LibraryRevision.bump();
      await Future<void>.delayed(Duration.zero);
      LibraryRevision.bump();
      await Future<void>.delayed(Duration.zero);

      expect(recipes.calls, 2);
    });

    test('счётчик сигналов виден через провайдер', () async {
      final before = container.read(libraryRevisionProvider);
      LibraryRevision.bump();

      expect(container.read(libraryRevisionProvider), before + 1);
    });
  });
}
