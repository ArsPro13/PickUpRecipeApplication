import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data_sources/remote/recipe_service.dart';
import '../../domain/models/recipe_data_model.dart';

/// Одна версия рецепта в списке истории.
class RecipeVersion {
  const RecipeVersion({
    required this.packId,
    required this.method,
    required this.title,
    required this.subtitle,
    required this.doseG,
    required this.waterG,
    this.temperatureC,
  });

  final int packId;

  /// Slug метода: по нему открывается список рецептов под этот прибор.
  final String method;

  final String title;
  final String subtitle;
  final double doseG;
  final int waterG;
  final double? temperatureC;
}

/// Группа истории — пара «кофе + метод» (ответ Q23b).
///
/// Не цепочка prev_id/next_id: на экране это выглядит одинаково, но запросы
/// разные, и владелец выбрал пару. Версии внутри группы идут от свежей к старой.
class RecipeGroup {
  const RecipeGroup({required this.key, required this.title, required this.versions});

  final String key;
  final String title;
  final List<RecipeVersion> versions;
}

class RecipesListState {
  const RecipesListState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  final List<RecipeGroup> groups;
  final bool isLoading;
  final String? error;

  RecipesListState copyWith({
    List<RecipeGroup>? groups,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RecipesListState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RecipesListNotifier extends StateNotifier<RecipesListState> {
  RecipesListNotifier(this._service) : super(const RecipesListState());

  final RecipeService _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final recipes = await _service.getByParams() ?? const <RecipeData>[];
      state = state.copyWith(groups: groupRecipes(recipes), isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }
}

/// Собирает рецепты в группы «кофе + метод».
///
/// Вынесено из нотифаера отдельной функцией, чтобы проверять группировку
/// тестом без сети: это единственная нетривиальная логика экрана.
List<RecipeGroup> groupRecipes(List<RecipeData> recipes) {
  final byKey = <String, List<RecipeData>>{};

  for (final recipe in recipes) {
    byKey.putIfAbsent('${recipe.packId}/${recipe.device}', () => []).add(recipe);
  }

  final groups = <RecipeGroup>[];
  for (final entry in byKey.entries) {
    // Свежая версия первой: именно её показывает свёрнутая карточка.
    final versions = [...entry.value]..sort((a, b) => b.date.compareTo(a.date));

    groups.add(
      RecipeGroup(
        key: entry.key,
        title: versions.first.device,
        versions: versions
            .map(
              (recipe) => RecipeVersion(
                packId: recipe.packId,
                method: recipe.device,
                title: recipe.device,
                subtitle: recipe.date,
                doseG: recipe.load,
                waterG: recipe.water,
                temperatureC: recipe.temperature.toDouble(),
              ),
            )
            .toList(),
      ),
    );
  }

  return groups;
}

final recipeServiceProvider = Provider<RecipeService>((ref) => RecipeService());

final recipesListProvider = StateNotifierProvider<RecipesListNotifier, RecipesListState>(
  (ref) => RecipesListNotifier(ref.watch(recipeServiceProvider)),
);
