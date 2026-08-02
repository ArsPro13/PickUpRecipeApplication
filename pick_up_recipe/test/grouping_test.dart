// Группировка списков — единственная нетривиальная логика двух экранов,
// и её можно проверить без сети.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/brew_methods/application/brew_methods_state.dart';
import 'package:pick_up_recipe/src/features/brew_methods/domain/brew_method.dart';

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

      expect(result.last.name, 'Прочие');
      expect(result.last.methods.single.slug, 'самовар');
    });

    test('метод, ссылающийся на несуществующую группу, тоже не теряется', () {
      final result = groupMethods([method('phin', groupId: 99)], groups);

      expect(result.single.name, 'Прочие');
    });

    test('пустой справочник даёт пустой список, а не падение', () {
      expect(groupMethods(const [], const []), isEmpty);
    });
  });
}
