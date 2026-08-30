import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../brew_methods/application/brew_methods_state.dart';
import '../../brew_methods/data_sources/remote/brew_method_service.dart';
import '../../packs/data_sources/remote/pack_service.dart';
import '../../packs/domain/models/pack_model.dart';
import '../../recipes/data_sources/remote/recipe_service.dart';
import '../../recipes/domain/models/recipe_data_model.dart';
import '../domain/pack_code.dart';

enum CoffeeStatus { loading, ready, notFound, withdrawn, failed }

/// Метод заваривания в списке страницы кофе.
class CoffeeMethod {
  const CoffeeMethod({
    required this.slug,
    required this.name,
    required this.iconKey,
    required this.hasRecipe,
  });

  final String slug;
  final String name;
  final String iconKey;

  /// Есть ли под этот прибор рецепт для этого зерна. Метод без рецепта не
  /// прячется и не блокируется — он просто тише: рецепт можно собрать самому.
  final bool hasRecipe;
}

class CoffeeMethodGroup {
  const CoffeeMethodGroup({required this.name, required this.methods});

  final String name;
  final List<CoffeeMethod> methods;
}

class CoffeeState {
  const CoffeeState({
    this.status = CoffeeStatus.loading,
    this.pack,
    this.groups = const [],
    this.lastBrewed,
    this.error,
    this.withdrawn = false,
    this.withdrawnName = '',
    this.withdrawnRoaster = '',
  });

  final CoffeeStatus status;
  final PackData? pack;

  /// Все методы по группам справочника.
  final List<CoffeeMethodGroup> groups;

  /// Чем заваривали это зерно в последний раз — для быстрого старта.
  final ({CoffeeMethod method, String date})? lastBrewed;

  final String? error;

  /// Кофе снят с продажи, но пачка открылась (она уже на полке): экран
  /// показывает её как обычно, добавив плашку. Это не то же самое, что
  /// status == withdrawn — тот случай для чужой пачки, которую не открыть.
  final bool withdrawn;

  /// Имя и обжарщик снятой позиции — для экрана, где пачки нет.
  final String withdrawnName;
  final String withdrawnRoaster;
}

/// Открывает страницу кофе по коду с упаковки или по своей пачке.
///
/// Код проверяется локально до похода на сервер: контрольный символ ловит
/// опечатку ручного ввода, и незачем ради этого ждать ответа сети.
class CoffeeStateNotifier extends StateNotifier<CoffeeState> {
  CoffeeStateNotifier(this._packs, this._methods, this._recipes) : super(const CoffeeState());

  final PackService _packs;
  final BrewMethodService _methods;
  final RecipeService _recipes;

  Future<void> open({String? code, int? packId}) async {
    state = const CoffeeState();

    var withdrawn = false;
    var withdrawnName = '';
    var withdrawnRoaster = '';

    var targetPackId = packId;

    try {
      if (code != null && code.isNotEmpty) {
        // Код разбирает сервер: три исхода — пачка, «снят с продажи», ничего.
        switch (await _packs.resolveCode(code)) {
          case CodeFound(packId: final found):
            targetPackId = found;
          case CodeNotFound():
            state = const CoffeeState(status: CoffeeStatus.notFound);
            return;
          case CodeWithdrawn(packId: final found, :final packName, :final roasterName):
            withdrawn = true;
            withdrawnName = packName;
            withdrawnRoaster = roasterName;
            targetPackId = found;
          case CodeOffline():
            // Код разбирает сервер, и другого способа нет. Сказать «такого
            // кода не существует», не сумев спросить, — соврать; поэтому
            // экран показывает офлайн, а не «не найдено».
            state = const CoffeeState(
              status: CoffeeStatus.failed,
              error: 'Код проверяет сервер — без сети его не разобрать',
            );
            return;
        }
      }

      if (targetPackId == null) {
        state = const CoffeeState(status: CoffeeStatus.notFound);
        return;
      }

      final pack = await _packs.getPackById(targetPackId);
      if (pack == null) {
        state = const CoffeeState(status: CoffeeStatus.notFound);
        return;
      }

      // Пачка обязательна, список методов — нет: без него экран покажет
      // зерно и скажет, что способы не открылись, вместо того чтобы упасть.
      final (groups, last) = await _loadMethods(targetPackId);

      state = CoffeeState(
        status: CoffeeStatus.ready,
        pack: pack,
        groups: groups,
        lastBrewed: last,
        withdrawn: withdrawn,
      );
    } catch (error) {
      // Снятая позиция с чужой пачкой не открывается по правам — но это не
      // ошибка сети: показываем «снят с продажи» с тем, что о нём известно.
      if (withdrawn) {
        state = CoffeeState(
          status: CoffeeStatus.withdrawn,
          withdrawn: true,
          withdrawnName: withdrawnName,
          withdrawnRoaster: withdrawnRoaster,
        );
        return;
      }
      state = CoffeeState(status: CoffeeStatus.failed, error: error.toString());
    }
  }

  Future<(List<CoffeeMethodGroup>, ({CoffeeMethod method, String date})?)> _loadMethods(
    int packId,
  ) async {
    try {
      final methods = await _methods.getMethods();
      final groups = await _methods.getGroups();
      final recipes = await _recipes.getByParams(packId: packId) ?? const <RecipeData>[];

      return buildCoffeeMethods(groupMethods(methods, groups), recipes);
    } catch (_) {
      return (const <CoffeeMethodGroup>[], null);
    }
  }

  /// Разбирает код до похода на сервер.
  static bool isCodeUsable(String code) => PackCode.isValid(code);
}

/// Раскладывает справочник методов и рецепты зерна в то, что рисует экран.
///
/// Отдельной функцией, а не внутри нотифаера: это единственная нетривиальная
/// логика страницы, и проверять её тестом без сети дешевле, чем через виджет.
(List<CoffeeMethodGroup>, ({CoffeeMethod method, String date})?) buildCoffeeMethods(
  List<GroupedMethods> grouped,
  List<RecipeData> recipes,
) {
  final withRecipe = {for (final recipe in recipes) recipe.device};

  final groups = [
    for (final group in grouped)
      CoffeeMethodGroup(
        name: group.name,
        methods: [
          for (final method in group.methods)
            CoffeeMethod(
              slug: method.slug,
              name: method.name,
              iconKey: method.iconKey,
              hasRecipe: withRecipe.contains(method.slug),
            ),
        ],
      ),
  ];

  if (recipes.isEmpty) return (groups, null);

  // Быстрый старт — по свежему рецепту, а не по частоте: человек возвращается
  // к тому, чем заваривал вчера, а не к тому, чем заваривал чаще всего.
  final latest = [...recipes]..sort((a, b) => b.date.compareTo(a.date));
  final method = groups
      .expand((group) => group.methods)
      .where((candidate) => candidate.slug == latest.first.device)
      .firstOrNull;

  return (groups, method == null ? null : (method: method, date: latest.first.date));
}

final packServiceProvider = Provider<PackService>((ref) => PackService());

final coffeeRecipeServiceProvider = Provider<RecipeService>((ref) => RecipeService());

final coffeeStateProvider = StateNotifierProvider<CoffeeStateNotifier, CoffeeState>(
  (ref) => CoffeeStateNotifier(
    ref.watch(packServiceProvider),
    ref.watch(brewMethodServiceProvider),
    ref.watch(coffeeRecipeServiceProvider),
  ),
);
