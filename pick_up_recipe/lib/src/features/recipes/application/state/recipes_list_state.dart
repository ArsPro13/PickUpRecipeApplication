import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../brew_methods/application/brew_methods_state.dart';
import '../../../brew_methods/data_sources/remote/brew_method_service.dart';
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
    required this.timeSec,
    required this.date,
    required this.recipe,
    this.temperatureC,
  });

  /// Сам рецепт: с карточки его можно заварить снова, не ходя за ним заново.
  final RecipeData recipe;

  final int packId;

  /// Slug метода: по нему открывается список рецептов под этот прибор.
  final String method;

  final String title;
  final String subtitle;
  final double doseG;
  final int waterG;

  /// Общее время рецепта. Стоит на краю стопки рядом с температурой —
  /// по этой паре версии и различают на глаз.
  final int timeSec;

  /// Дата как её отдал сервер. Нужна для сортировки и для подписи нижнего
  /// края стопки «ещё 6 версий, с 22 июля».
  final String date;

  final double? temperatureC;
}

/// Группа истории — пара «кофе + метод» (ответ Q23b).
///
/// Не цепочка prev_id/next_id: на экране это выглядит одинаково, но запросы
/// разные, и владелец выбрал пару. Версии внутри группы идут от свежей к старой.
class RecipeGroup {
  const RecipeGroup({
    required this.key,
    required this.title,
    required this.versions,
    required this.packId,
    required this.method,
    required this.methodName,
    required this.methodIconKey,
  });

  final String key;
  final String title;
  final List<RecipeVersion> versions;

  final int packId;

  /// Slug прибора и его человеческое имя: первое нужно для перехода,
  /// второе — для подписи и значка в кружке.
  final String method;
  final String methodName;
  final String methodIconKey;

  /// Свежая версия — та, что лежит сверху стопки.
  RecipeVersion get latest => versions.first;

  /// Сколько версий не поместилось на верхнюю карточку.
  int get depth => versions.length - 1;
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
  RecipesListNotifier(this._service, this._methods) : super(const RecipesListState());

  final RecipeService _service;
  final BrewMethodService _methods;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Всю цепочку целиком: толщина стопки на экране и есть число правок,
      // а по головам цепочек её не построить.
      final recipes =
          await _service.getByParams(allVersions: true) ?? const <RecipeData>[];

      // Справочник методов нужен только ради названий. Если он не открылся,
      // список рецептов всё равно показывается — просто с slug вместо имени:
      // это хуже, чем с именем, и несравнимо лучше пустого экрана.
      var names = const <String, String>{};
      var icons = const <String, String>{};
      try {
        final methods = await _methods.getMethods();
        names = {for (final method in methods) method.slug: method.name};
        icons = {for (final method in methods) method.slug: method.iconKey};
      } catch (_) {
        names = const {};
        icons = const {};
      }

      state = state.copyWith(
        groups: groupRecipes(recipes, methodNames: names, methodIcons: icons),
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }
}

/// Собирает рецепты в группы «кофе + метод».
///
/// Вынесено из нотифаера отдельной функцией, чтобы проверять группировку
/// тестом без сети: это единственная нетривиальная логика экрана.
///
/// [methodNames] переводит slug прибора в человеческое название. Без него в
/// карточке стоял бы `hario_v60` — именно так экран и выглядел, пока список
/// не отдавал ни названия рецепта, ни справочника методов.
List<RecipeGroup> groupRecipes(
  List<RecipeData> recipes, {
  Map<String, String> methodNames = const {},
  Map<String, String> methodIcons = const {},
}) {
  final byKey = <String, List<RecipeData>>{};

  for (final recipe in recipes) {
    byKey.putIfAbsent('${recipe.packId}/${recipe.device}', () => []).add(recipe);
  }

  final groups = <RecipeGroup>[];
  for (final entry in byKey.entries) {
    // Свежая версия первой: именно её показывает верхняя карточка стопки.
    final versions = [...entry.value]..sort((a, b) => b.date.compareTo(a.date));
    final method = versions.first.device;
    final methodName = methodNames[method] ?? method;

    groups.add(
      RecipeGroup(
        key: entry.key,
        title: versions.first.title.isNotEmpty ? versions.first.title : methodName,
        packId: versions.first.packId,
        method: method,
        methodName: methodName,
        methodIconKey: methodIcons[method] ?? method,
        versions: versions
            .map(
              (recipe) => RecipeVersion(
                packId: recipe.packId,
                method: recipe.device,
                title: recipe.title.isNotEmpty ? recipe.title : methodName,
                subtitle: formatRecipeDate(recipe.date),
                doseG: recipe.load,
                waterG: recipe.water,
                timeSec: recipe.time,
                date: recipe.date,
                recipe: recipe,
                temperatureC: recipe.temperature,
              ),
            )
            .toList(),
      ),
    );
  }

  // Свежие группы сверху: список читают с начала, а «так завариваю» —
  // это про последнее заваривание, а не про случайный порядок ключей.
  groups.sort((a, b) => b.latest.date.compareTo(a.latest.date));

  return groups;
}

/// Приборы, которыми эту пачку уже заваривали, в порядке свежести.
///
/// Метка на карточке пачки: остаток в граммах с макета снят — под него нет ни
/// исходного веса, ни расхода, — а методы берутся из той же истории и ничего
/// не требуют от схемы.
/// Возвращает и название, и slug: по slug метка узнаёт семью прибора и
/// красится в её цвет, а по названию подписывается.
List<({String name, String slug})> methodsOfPack(List<RecipeGroup> groups, int packId) {
  final found = <({String name, String slug})>[];
  for (final group in groups) {
    if (group.packId != packId) continue;
    if (found.any((item) => item.name == group.methodName)) continue;
    found.add((name: group.methodName, slug: group.method));
  }
  return found;
}

/// Дата рецепта человеческим языком: «28 июля».
///
/// Год добавляется, только когда он не нынешний: «28 июля 2025» в списке за
/// эту неделю — лишний шум, а без года запись двухлетней давности врёт.
String formatRecipeDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;

  const months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  final local = parsed.toLocal();
  final day = '${local.day} ${months[local.month - 1]}';
  return local.year == DateTime.now().year ? day : '$day ${local.year}';
}

final recipeServiceProvider = Provider<RecipeService>((ref) => RecipeService());

final recipesListProvider = StateNotifierProvider<RecipesListNotifier, RecipesListState>(
  (ref) => RecipesListNotifier(
    ref.watch(recipeServiceProvider),
    ref.watch(brewMethodServiceProvider),
  ),
);
