// Параметры рецепта на экране заваривания: доза, помол, вода, температура.
//
// Их показывают два места сразу — постоянная строка под шапкой и рамка до
// старта, — и расходиться им нельзя. Плюс здесь единственное место, где легко
// соврать молча: подписать щелчки чужой кофемолки именем основной.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/pages/brew_page.dart';

RecipeData recipe({
  double load = 15,
  int water = 250,
  double? temperature = 93,
  String grindStep = '26',
  String grindDescriptor = 'средне-тонкий',
  int grinderId = 12,
}) {
  return RecipeData(
    id: 1,
    device: 'hario_v60',
    date: '2026-08-09T08:00:00Z',
    packId: 3,
    grinderId: grinderId,
    grindStep: grindStep,
    grindSubStep: null,
    water: water,
    time: 150,
    temperature: temperature,
    load: load,
    title: '',
    notes: '',
    grindDescriptor: grindDescriptor,
    agitationLevel: null,
    steps: const [],
  );
}

void main() {
  group('строка параметров', () {
    test('все четыре числа на месте', () {
      final params = BrewParams.of(recipe());

      expect(params.dose, '15 г');
      expect(params.grind, '26 щ.');
      expect(params.water, '250 мл');
      expect(params.temperature, '93 °C');
      expect(params.isEmpty, isFalse);
    });

    test('чего рецепт не знает, того и не показывает', () {
      final params = BrewParams.of(
        recipe(temperature: null, grindStep: '', grindDescriptor: ''),
      );

      expect(params.temperature, isNull);
      expect(params.grind, isNull);
      expect(params.dose, '15 г');
      expect(params.water, '250 мл');
    });

    test('исторический рецепт без чисел не рисует строку вовсе', () {
      final params = BrewParams.of(
        recipe(load: 0, water: 0, temperature: null, grindStep: '', grindDescriptor: ''),
      );

      expect(params.isEmpty, isTrue);
      expect(params.hasPrep, isFalse);
    });

    test('целые числа идут без хвоста, дробные с запятой', () {
      expect(BrewParams.of(recipe(load: 15)).dose, '15 г');
      expect(BrewParams.of(recipe(load: 15.5)).dose, '15,5 г');
      expect(BrewParams.of(recipe(temperature: 92.5)).temperature, '92,5 °C');
      expect(BrewParams.of(recipe(temperature: 93.0)).temperature, '93 °C');
    });
  });

  group('рамка до старта', () {
    test('со своей кофемолкой щелчки объясняет подпись', () {
      final params = BrewParams.of(recipe(), grinderName: 'Comandante');

      expect(params.prepValue, '15 г · 26');
      expect(params.prepHint, 'щелчков Comandante · средне-тонкий');
    });

    test('без имени кофемолки число объясняет себя само', () {
      // Иначе под крупным «15 г · 26» осталась бы пустота, и что такое 26 —
      // непонятно: граммы, градусы, секунды.
      final params = BrewParams.of(recipe());

      expect(params.prepValue, '15 г · 26 щ.');
      expect(params.prepHint, 'средне-тонкий');
    });

    test('чужая кофемолка не подписывается именем основной', () {
      // Помол в щелчках другой мельницы — не то же число. Имя сюда приходит
      // только когда оно совпало с grinder_id рецепта; проверяет это экран,
      // а разбор обязан принять null и промолчать.
      final params = BrewParams.of(recipe(), grinderName: null);

      expect(params.prepHint, isNot(contains('щелчков')));
    });

    test('пустое имя кофемолки равно отсутствию имени', () {
      final params = BrewParams.of(recipe(), grinderName: '   ');

      expect(params.prepValue, '15 г · 26 щ.');
      expect(params.prepHint, 'средне-тонкий');
    });

    test('без дескриптора остаётся одна кофемолка', () {
      final params = BrewParams.of(
        recipe(grindDescriptor: ''),
        grinderName: 'Comandante',
      );

      expect(params.prepHint, 'щелчков Comandante');
    });

    test('без помола молоть нечего — остаётся одна доза', () {
      final params = BrewParams.of(recipe(grindStep: '', grindDescriptor: ''));

      expect(params.prepValue, '15 г');
      expect(params.prepHint, isNull);
      expect(params.hasPrep, isTrue);
    });

    test('крупность помола приходит словом из справочника', () {
      // В рецепте лежит slug: без справочника в подписи оказывалось
      // английское `medium_fine` посреди русского экрана.
      final params = BrewParams.of(
        recipe(grindDescriptor: 'medium_fine'),
        grinderName: 'Comandante',
        descriptorName: 'средне-тонкий',
      );

      expect(params.prepHint, 'щелчков Comandante · средне-тонкий');
    });

    test('без справочника остаётся slug, а не пустота', () {
      final params = BrewParams.of(recipe(grindDescriptor: 'medium_fine'));

      expect(params.prepHint, 'medium_fine');
    });

    test('без дозы и помола подготовки нет, рамка остаётся таймером', () {
      final params = BrewParams.of(recipe(load: 0, grindStep: ''));

      expect(params.hasPrep, isFalse);
      expect(params.prepValue, isNull);
    });
  });
}
