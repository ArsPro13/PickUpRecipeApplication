// Выгрузка примеров пересчёта для отчёта исследования.
//
// Не проверка, а инструмент: числа в PDF обязаны совпадать с тем, что
// показывает приложение, поэтому их считает этот же движок. Запускается
// только с переменной окружения, обычный `flutter test` его пропускает:
//
//   SCALING_EXAMPLES_OUT=/путь/examples.json flutter test test/tool/
//
// Для каждого прибора — базовый рецепт и пересчёт на ×2 и ×3 (у заходов и
// порций — 2 и 3 штуки), с шагами, дозой, временем и предупреждениями.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/scaling/recipe_scaler.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/scaling/scaling_profile.dart';

import '../scaling_all_methods_test.dart' show loadBaseMethods, nearestOnWheel;

Map<String, Object?> _recipeJson(RecipeData recipe) => {
      'water': recipe.water,
      'dose': recipe.load,
      'time': recipe.time,
      'temperature': recipe.temperature,
      'steps': [
        for (final step in recipe.steps)
          {
            'type': step.stepType,
            'label': step.instruction,
            'water': step.water,
            'time': step.time,
          },
      ],
    };

void main() {
  final out = Platform.environment['SCALING_EXAMPLES_OUT'];

  test('выгрузка примеров для отчёта', () {
    final result = <String, Object?>{};
    for (final method in loadBaseMethods()) {
      final profile = ScalingProfile.builtIn(method.slug)!;
      final wheel = scaleWheelValues(method.recipe, profile);
      final examples = <String, Object?>{};
      for (final factor in [2.0, 3.0]) {
        final water = nearestOnWheel(wheel, method.recipe.water * factor);
        final scaled = scaleRecipe(
          base: method.recipe,
          water: water,
          profile: profile,
          labels: const ScaleLabels(
              splitWait: 'Ждём, пока уйдёт',
              dilute: 'Долейте горячую воду',
              diluteCold: 'Долейте холодную воду'),
        );
        examples['x${factor.round()}'] = {
          'water': scaled.water,
          'dose': scaled.dose,
          'runs': scaled.runs,
          'bypass': scaled.bypassWater,
          'total': scaled.totalSeconds,
          'grind_ratio': scaled.grindRatio,
          'bed_ratio': scaled.bedDepthRatio,
          'cup': scaled.cupMl,
          'warnings': [
            for (final warning in scaled.warnings)
              {
                'kind': warning.kind.name,
                'parts': warning.parts,
                'grams': warning.grams,
                'water': warning.water,
                'chamber': warning.chamber,
                'size': warning.size,
                'bigger': warning.biggerSize,
              },
          ],
          'recipe': _recipeJson(scaled.recipe),
        };
      }
      result[method.slug] = {
        'name': method.name,
        'family': profile.family.name,
        'unit': profile.unit.name,
        'water_meaning': method.waterMeaning,
        'wheel': {'from': wheel.first, 'to': wheel.last, 'count': wheel.length},
        'capacity': profile.capacityMl,
        'default_size': profile.defaultSize,
        'chamber': profile.chamberMl,
        'max_units': profile.maxUnits,
        'base': _recipeJson(method.recipe),
        ...examples,
      };
    }
    File(out!)
        .writeAsStringSync(const JsonEncoder.withIndent(' ').convert(result));
  }, skip: out == null ? 'только для отчёта: SCALING_EXAMPLES_OUT' : false);
}
