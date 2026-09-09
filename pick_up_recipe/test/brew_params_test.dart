// Параметры рецепта на экране заваривания: доза, помол, вода, температура.
//
// Их показывают два места сразу — постоянная строка под шапкой и рамка до
// старта, — и расходиться им нельзя. Плюс здесь единственное место, где легко
// соврать молча: выдать деления чужой кофемолки за деления своей.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/grind_translation.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/models/grinder_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/grind_descriptor_model.dart';
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

/// Кусок настоящей шкалы Comandante C40: средняя крупность взята из базы
/// grinder_translator.
const Grinder comandante = Grinder(
  id: 12,
  name: 'Comandante C40',
  modes: [
    GrinderMode(mode: '13.0', microns: 583.1),
    GrinderMode(mode: '14.0', microns: 605.8),
    GrinderMode(mode: '20.0', microns: 819.5),
  ],
);

const List<GrindDescriptor> descriptors = [
  GrindDescriptor(slug: 'medium_fine', name: 'Средне-тонкий', microns: 600, sortOrder: 3),
];

GrindReading reading(
  RecipeData source, {
  Grinder? grinder,
  List<GrindDescriptor> reference = const [],
}) {
  return grindReading(
    descriptorSlug: source.grindDescriptor,
    reference: reference,
    recipeGrinderId: source.grinderId,
    recipeGrindStep: source.grindStep,
    grinder: grinder,
  );
}

void main() {
  // Единицы приходят из словаря: «250 мл» на английском экране — «250 ml».
  late AppLocalizations ru;

  setUpAll(() async {
    ru = await AppLocalizations.delegate.load(const Locale('ru'));
  });

  group('строка параметров', () {
    test('все четыре числа на месте', () {
      final source = recipe();
      final params = BrewParams.of(ru, source, grind: reading(source, grinder: comandante));

      expect(params.dose, '15 г');
      expect(params.grind, '26');
      expect(params.water, '250 мл');
      expect(params.temperature, '93 °C');
      expect(params.isEmpty, isFalse);
    });

    test('чего рецепт не знает, того и не показывает', () {
      final params = BrewParams.of(
        ru,
        recipe(temperature: null, grindStep: '', grindDescriptor: ''),
      );

      expect(params.temperature, isNull);
      expect(params.grind, isNull);
      expect(params.dose, '15 г');
      expect(params.water, '250 мл');
    });

    test('исторический рецепт без чисел не рисует строку вовсе', () {
      final params = BrewParams.of(
        ru,
        recipe(load: 0, water: 0, temperature: null, grindStep: '', grindDescriptor: ''),
      );

      expect(params.isEmpty, isTrue);
      expect(params.hasPrep, isFalse);
    });

    test('целые числа идут без хвоста, дробные с запятой', () {
      expect(BrewParams.of(ru, recipe(load: 15)).dose, '15 г');
      expect(BrewParams.of(ru, recipe(load: 15.5)).dose, '15,5 г');
      expect(BrewParams.of(ru, recipe(temperature: 92.5)).temperature, '92,5 °C');
      expect(BrewParams.of(ru, recipe(temperature: 93.0)).temperature, '93 °C');
    });
  });

  group('рамка до старта', () {
    test('со своей кофемолкой деления объясняет подпись', () {
      final source = recipe();
      final params = BrewParams.of(ru, source, grind: reading(source, grinder: comandante));

      expect(params.prepValue, '15 г · 26');
      expect(params.prepHint, 'делений Comandante C40 · средне-тонкий');
    });

    test('без кофемолки остаётся слово и приглашение её выбрать', () {
      // Прятать помол нельзя: до пункта 8 он только словом и показывался,
      // и это единственное, что у человека было.
      final params = BrewParams.of(ru, recipe());

      expect(params.prepValue, '15 г · средне-тонкий');
      expect(params.prepHint, 'выберите кофемолку — покажем деление');
    });

    test('чужие деления не выдаются за свои, а пересчитываются', () {
      // 26 щелчков другой мельницы — не то же число. Показывается деление
      // своей кофемолки, полученное через крупность, и помечается «примерно».
      final source = recipe(grinderId: 99, grindDescriptor: 'medium_fine');
      final params = BrewParams.of(
        ru,
        source,
        grind: reading(source, grinder: comandante, reference: descriptors),
      );

      expect(params.prepValue, '15 г · примерно 14');
      expect(params.prepValue, isNot(contains('26')));
      expect(params.prepHint, 'делений Comandante C40 · Средне-тонкий');
    });

    test('без дескриптора остаётся одна кофемолка', () {
      final source = recipe(grindDescriptor: '');
      final params = BrewParams.of(ru, source, grind: reading(source, grinder: comandante));

      expect(params.prepHint, 'делений Comandante C40');
    });

    test('без помола молоть нечего — остаётся одна доза', () {
      final params = BrewParams.of(ru, recipe(grindStep: '', grindDescriptor: ''));

      expect(params.prepValue, '15 г');
      expect(params.prepHint, isNull);
      expect(params.hasPrep, isTrue);
    });

    test('крупность помола приходит словом из справочника', () {
      // В рецепте лежит slug: без справочника в подписи оказывалось
      // английское `medium_fine` посреди русского экрана.
      final source = recipe(grindDescriptor: 'medium_fine');
      final params = BrewParams.of(
        ru,
        source,
        grind: reading(source, grinder: comandante, reference: descriptors),
      );

      expect(params.prepHint, 'делений Comandante C40 · Средне-тонкий');
    });

    test('без справочника остаётся slug, а не пустота', () {
      final params = BrewParams.of(ru, recipe(grindDescriptor: 'medium_fine'));

      expect(params.grind, 'medium_fine');
    });

    test('без дозы и помола подготовки нет, рамка остаётся таймером', () {
      final params = BrewParams.of(ru, recipe(load: 0, grindStep: '', grindDescriptor: ''));

      expect(params.hasPrep, isFalse);
      expect(params.prepValue, isNull);
    });
  });
}
