// Счёт того, что человек уже накопил.
//
// Считается из двух списков, которые приложение и так держит на руках, —
// истории рецептов и полки пачек. Своих ручек под статистику нет и не заводим:
// каждая цифра здесь обязана сойтись с тем, что видно на соседней вкладке, а
// сойтись она может только если посчитана из того же самого.
//
// Чего здесь принципиально нет: числа завариваний, средней оценки и «дней
// подряд». Таблица заварок на сервере есть, но в неё никто не пишет, и клиент
// про неё не знает; оценки лежат по запросу на рецепт и в список не приходят.
// Подпись, обещающая то, чего система не считает, хуже пустого экрана: пустой
// экран честен.
//
// Отдельной чистой функцией — как `groupRecipes` и по той же причине: цифры на
// экране проверяются тестом, а не пересчитыванием карточек глазами.

import '../../packs/domain/models/pack_model.dart';
import '../../recipes/application/state/recipes_list_state.dart';

/// Прибор, которым сделано больше всего рецептов.
typedef FavouriteDevice = ({String name, int recipes});

class ProfileStats {
  const ProfileStats({
    this.recipes = 0,
    this.versions = 0,
    this.packs = 0,
    this.countries = 0,
    this.varieties = 0,
    this.favourite,
    this.firstRecipeDate,
  });

  /// Рецептов — пар «кофе + прибор», то есть ровно столько, сколько стопок
  /// на вкладке «Рецепты».
  final int recipes;

  /// Версий всего: то же число, что складывается из подписей «N версии».
  final int versions;

  final int packs;

  /// Стран и сортов на полке. Считаются по непустым полям: у пачки, заведённой
  /// руками, их может не быть вовсе, и ноль там честнее выдуманного.
  final int countries;
  final int varieties;

  /// Прибор, под который рецептов больше всего. null — рецептов нет вовсе или
  /// ни один прибор не вышел вперёд.
  final FavouriteDevice? favourite;

  /// Дата самого раннего рецепта — как её отдал сервер.
  final String? firstRecipeDate;

  /// Считать нечего: ни пачек, ни рецептов.
  bool get isEmpty => recipes == 0 && packs == 0;
}

/// Складывает статистику из того, что уже показано на других вкладках.
ProfileStats buildProfileStats(List<RecipeGroup> groups, List<PackData> packs) {
  var versions = 0;
  final byDevice = <String, int>{};
  String? earliest;

  for (final group in groups) {
    versions += group.versions.length;

    // По рецептам, а не по версиям: пять правок одного рецепта — это про
    // упрямство, а не про любимый прибор.
    byDevice[group.methodName] = (byDevice[group.methodName] ?? 0) + 1;

    for (final version in group.versions) {
      if (version.date.isEmpty) continue;
      if (earliest == null || version.date.compareTo(earliest) < 0) {
        earliest = version.date;
      }
    }
  }

  FavouriteDevice? favourite;
  for (final entry in byDevice.entries) {
    // Строго больше: при ничьей любимого нет. Назвать одного из двух равных
    // значило бы выдумать предпочтение, которого человек не высказывал.
    if (favourite == null || entry.value > favourite.recipes) {
      favourite = (name: entry.key, recipes: entry.value);
    }
  }
  if (favourite != null &&
      byDevice.values.where((count) => count == favourite!.recipes).length > 1) {
    favourite = null;
  }

  return ProfileStats(
    recipes: groups.length,
    versions: versions,
    packs: packs.length,
    countries: packs.map((pack) => pack.packCountry).where((it) => it.isNotEmpty).toSet().length,
    varieties: packs.map((pack) => pack.packVariety).where((it) => it.isNotEmpty).toSet().length,
    favourite: favourite,
    firstRecipeDate: earliest,
  );
}

/// «7 рецептов» — число со словом в нужном падеже.
///
/// Числительные здесь такие же, как в подписи стопки версий: «1 рецепт»,
/// «2 рецепта», «5 рецептов». Без этого экран говорит «2 рецептов».
String countWord(int count, String one, String few, String many) {
  if (count % 10 == 1 && count % 100 != 11) return one;
  if ([2, 3, 4].contains(count % 10) && !(count % 100 >= 12 && count % 100 <= 14)) {
    return few;
  }
  return many;
}
