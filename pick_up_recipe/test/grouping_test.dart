// Группировка списков — единственная нетривиальная логика двух экранов,
// и её можно проверить без сети.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/brew_methods/application/brew_methods_state.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/step_type_model.dart';
import 'package:pick_up_recipe/src/features/brew_methods/domain/brew_method.dart';
import 'package:pick_up_recipe/src/features/codes/application/coffee_state.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipes_list_state.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';

BrewMethod method(String slug, {int? groupId, int sortOrder = 0}) {
  return BrewMethod(
    id: slug.hashCode,
    slug: slug,
    name: slug,
    iconKey: slug,
    groupId: groupId,
    sortOrder: sortOrder,
  );
}

void main() {
  group('методы заваривания', () {
    const groups = [
      BrewMethodGroup(id: 1, slug: 'pour_over', name: 'Пуровер', iconKey: 'v60', sortOrder: 1),
      BrewMethodGroup(id: 2, slug: 'immersion', name: 'Иммерсия', iconKey: 'fp', sortOrder: 2),
      BrewMethodGroup(id: 3, slug: 'pressure', name: 'Давление', iconKey: 'es', sortOrder: 3),
    ];

    test('порядок групп — из справочника, а не из порядка методов', () {
      final result = groupMethods(
        [
          method('espresso', groupId: 3),
          method('hario_v60', groupId: 1),
          method('french_press', groupId: 2),
        ],
        groups,
      );

      expect(result.map((g) => g.name), ['Пуровер', 'Иммерсия', 'Давление']);
    });

    test('внутри группы порядок — по sort_order', () {
      final result = groupMethods(
        [
          method('chemex', groupId: 1, sortOrder: 2),
          method('hario_v60', groupId: 1, sortOrder: 1),
        ],
        groups,
      );

      expect(result.single.methods.map((m) => m.slug), ['hario_v60', 'chemex']);
    });

    test('пустая группа не показывается', () {
      final result = groupMethods([method('hario_v60', groupId: 1)], groups);

      expect(result, hasLength(1));
      expect(result.single.name, 'Пуровер');
    });

    // Спрятать метод молча — худшее, что можно сделать с экраном выбора:
    // человек будет искать свой прибор и не найдёт.
    test('метод без группы не теряется', () {
      final result = groupMethods(
        [method('hario_v60', groupId: 1), method('самовар')],
        groups,
      );

      // Имени с сервера у этой группы нет — она собирается здесь, и слово
      // для заголовка подставляет экран. Домену остаётся метка.
      expect(result.last.slug, otherGroupSlug);
      expect(result.last.name, isEmpty);
      expect(result.last.methods.single.slug, 'самовар');
    });

    test('метод, ссылающийся на несуществующую группу, тоже не теряется', () {
      final result = groupMethods([method('phin', groupId: 99)], groups);

      expect(result.single.slug, otherGroupSlug);
    });

    test('пустой справочник даёт пустой список, а не падение', () {
      expect(groupMethods(const [], const []), isEmpty);
    });
  });

  group('история завариваний', () {
    RecipeData recipe(int packId, String device, String date) => RecipeData(
          id: '$packId$device$date'.hashCode,
          device: device,
          date: date,
          packId: packId,
          grinderId: 1,
          grindStep: '26',
          grindSubStep: null,
          water: 250,
          time: 150,
          temperature: 93,
          load: 15,
          title: '',
          notes: '',
          grindDescriptor: '',
          agitationLevel: null,
          steps: const [],
        );

    test('свежая группа стоит первой, свежая версия — сверху стопки', () {
      final result = groupRecipes([
        recipe(1, 'hario_v60', '2026-07-20T08:00:00Z'),
        recipe(2, 'chemex', '2026-08-01T08:00:00Z'),
        recipe(1, 'hario_v60', '2026-07-28T08:00:00Z'),
      ]);

      expect(result.first.method, 'chemex');
      expect(result.last.latest.date, '2026-07-28T08:00:00Z');
      expect(result.last.depth, 1);
    });

    test('значок и имя прибора берутся из справочника', () {
      final result = groupRecipes(
        [recipe(1, 'hario_v60', '2026-08-01T08:00:00Z')],
        methodNames: {'hario_v60': 'Hario V60'},
        methodIcons: {'hario_v60': 'hario-v60'},
      );

      expect(result.single.methodName, 'Hario V60');
      expect(result.single.methodIconKey, 'hario-v60');
    });

    test('без справочника вместо имени идёт slug, а не пустота', () {
      final result = groupRecipes([recipe(1, 'hario_v60', '2026-08-01T08:00:00Z')]);

      expect(result.single.methodName, 'hario_v60');
      expect(result.single.methodIconKey, 'hario_v60');
    });

    test('метки пачки — приборы из её истории, каждый по разу', () {
      final groups = groupRecipes(
        [
          recipe(1, 'hario_v60', '2026-08-01T08:00:00Z'),
          recipe(1, 'hario_v60', '2026-07-20T08:00:00Z'),
          recipe(1, 'chemex', '2026-07-25T08:00:00Z'),
          recipe(2, 'aeropress', '2026-07-25T08:00:00Z'),
        ],
        methodNames: {
          'hario_v60': 'Hario V60',
          'chemex': 'Chemex',
          'aeropress': 'AeroPress',
        },
      );

      // Метка знает и название, и slug: по slug она красится в цвет семьи.
      expect(
        methodsOfPack(groups, 1).map((it) => it.name).toList(),
        ['Hario V60', 'Chemex'],
      );
      expect(methodsOfPack(groups, 1).map((it) => it.slug).toList(), ['hario_v60', 'chemex']);
      expect(methodsOfPack(groups, 2).map((it) => it.name).toList(), ['AeroPress']);
      expect(methodsOfPack(groups, 3), isEmpty);
    });
  });

  group('экран кофе: чем заварить', () {
    const groups = [
      BrewMethodGroup(id: 1, slug: 'pour_over', name: 'Пуровер', iconKey: 'v60', sortOrder: 1),
    ];

    RecipeData packRecipe(String device) => RecipeData(
          id: device.hashCode,
          device: device,
          date: '2026-09-01T08:00:00Z',
          packId: 44,
          grinderId: 1,
          grindStep: '26',
          grindSubStep: null,
          water: 250,
          time: 150,
          temperature: 93,
          load: 15,
          title: '',
          notes: '',
          grindDescriptor: '',
          agitationLevel: null,
          steps: const [],
        );

    test('приборы с рецептом обжарщика стоят в начале группы', () {
      // В справочнике orea тридцатая: без подъёма её белая строка тонет
      // между двумя десятками прозрачных, и листать до неё надо руками.
      final grouped = groupMethods([
        method('hario_v60', groupId: 1, sortOrder: 1),
        method('chemex', groupId: 1, sortOrder: 2),
        method('origami', groupId: 1, sortOrder: 3),
        method('orea', groupId: 1, sortOrder: 30),
      ], groups);

      final (result, _) = buildCoffeeMethods(grouped, [packRecipe('orea')]);

      expect(result.single.methods.first.slug, 'orea');
      expect(result.single.methods.first.hasRecipe, isTrue);
    });

    test('порядок справочника внутри половин сохраняется', () {
      final grouped = groupMethods([
        method('hario_v60', groupId: 1, sortOrder: 1),
        method('chemex', groupId: 1, sortOrder: 2),
        method('origami', groupId: 1, sortOrder: 3),
        method('orea', groupId: 1, sortOrder: 30),
      ], groups);

      final (result, _) = buildCoffeeMethods(
        grouped,
        [packRecipe('orea'), packRecipe('chemex')],
      );

      // Наверху — с рецептами, между собой в порядке справочника;
      // ниже — остальные, тоже в своём порядке.
      expect(
        result.single.methods.map((m) => m.slug).toList(),
        ['chemex', 'orea', 'hario_v60', 'origami'],
      );
    });

    test('без рецептов порядок остаётся справочным', () {
      final grouped = groupMethods([
        method('hario_v60', groupId: 1, sortOrder: 1),
        method('chemex', groupId: 1, sortOrder: 2),
      ], groups);

      final (result, _) = buildCoffeeMethods(grouped, const []);

      expect(result.single.methods.map((m) => m.slug).toList(),
          ['hario_v60', 'chemex']);
    });
  });

}
