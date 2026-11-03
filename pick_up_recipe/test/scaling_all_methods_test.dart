// Пересчёт на больший объём — у каждого из 71 прибора справочника.
//
// Владелец: «чтобы у меня везде была поддержка увеличения объёма». Здесь это
// и проверяется — не на паре примеров, а на базовом рецепте каждого метода
// (test/fixtures/base_recipes.json — выгрузка базовых рецептов из миграций):
// у прибора есть профиль, барабан стоит на воде рецепта, а пересчёт на ×2 и
// ×3 даёт рецепт, который можно заварить, — вода шагов сходится, время не
// отрицательное, заходы кратны рецепту.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/scaling/recipe_scaler.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/scaling/scaling_profile.dart';

class BaseMethod {
  BaseMethod(this.slug, this.name, this.waterMeaning, this.recipe);

  final String slug;
  final String name;
  final String waterMeaning;
  final RecipeData recipe;
}

List<BaseMethod> loadBaseMethods() {
  final raw =
      jsonDecode(File('test/fixtures/base_recipes.json').readAsStringSync())
          as List<dynamic>;
  return [
    for (final item in raw.cast<Map<String, dynamic>>())
      BaseMethod(
        item['slug'] as String,
        item['name'] as String,
        item['water_meaning'] as String,
        _recipeOf(
            item['slug'] as String, item['recipe'] as Map<String, dynamic>),
      ),
  ];
}

RecipeData _recipeOf(String slug, Map<String, dynamic> json) {
  final steps = (json['steps'] as List<dynamic>).cast<Map<String, dynamic>>();
  return RecipeData(
    id: 1,
    device: slug,
    date: '2026-11-03',
    packId: 0,
    grinderId: 0,
    grindStep: '',
    grindSubStep: null,
    water: json['water'] as int,
    time: json['time'] as int,
    temperature: (json['temperature'] as num?)?.toDouble(),
    load: (json['load'] as num).toDouble(),
    title: '',
    notes: '',
    grindDescriptor: json['grind_descriptor'] as String,
    agitationLevel: null,
    steps: [
      for (var i = 0; i < steps.length; i++)
        RecipeStep(
          seqNum: i + 1,
          instruction: steps[i]['label'] as String,
          water: steps[i]['water'] as int,
          time: steps[i]['time'] as int,
          id: i + 1,
          stepType: steps[i]['type'] as String,
          stepKey: 's${i + 1}',
          tip: '',
          isOptional: false,
          untilUser: steps[i]['until_user'] as bool,
          untilSign: '',
          warning: '',
        ),
    ],
  );
}

const _waterKinds = {'bloom', 'pour', 'add_ice', 'dilute'};

int waterOfSteps(RecipeData recipe) => recipe.steps
    .where((step) => _waterKinds.contains(step.stepType))
    .fold(0, (sum, step) => sum + step.water);

/// Деление барабана, ближайшее к k-кратной воде рецепта.
int nearestOnWheel(List<int> wheel, double target) =>
    wheel.reduce((best, value) =>
        (value - target).abs() < (best - target).abs() ? value : best);

const labels = ScaleLabels(
    splitWait: 'Ждём', dilute: 'Долейте', diluteCold: 'Долейте холодную');

void main() {
  final methods = loadBaseMethods();

  test('в справочнике 71 метод, у каждого базовый рецепт', () {
    expect(methods, hasLength(71));
  });

  for (final method in methods) {
    group('${method.slug} — ${method.name}', () {
      final profile = ScalingProfile.builtIn(method.slug);

      test('есть профиль, рецепт пересчитывается', () {
        expect(profile, isNotNull, reason: 'нет профиля пересчёта');
        expect(canScaleRecipe(method.recipe, profile), isTrue);
      });

      if (profile == null) return;
      final wheel = scaleWheelValues(method.recipe, profile);

      test('барабан стоит на воде рецепта и растёт', () {
        expect(wheel, contains(method.recipe.water));
        expect(wheel.last, greaterThan(method.recipe.water),
            reason: 'объём должен расти: ${wheel.last}');
        for (var i = 1; i < wheel.length; i++) {
          expect(wheel[i], greaterThan(wheel[i - 1]));
        }
        if (profile.countsUnits) {
          for (final value in wheel) {
            expect(value % method.recipe.water, 0,
                reason: 'у заходов — кратные рецепту');
          }
        }
      });

      test('та же вода — тот же рецепт', () {
        final same = scaleRecipe(
            base: method.recipe,
            water: method.recipe.water,
            profile: profile,
            labels: labels);
        expect(same.isOriginal, isTrue);
        expect(
            same.recipe.toJson().toString(), method.recipe.toJson().toString());
      });

      for (final factor in [2.0, 3.0]) {
        test('×${factor.round()}: можно заварить', () {
          final water = nearestOnWheel(wheel, method.recipe.water * factor);
          final scaled = scaleRecipe(
              base: method.recipe,
              water: water,
              profile: profile,
              labels: labels);
          final recipe = scaled.recipe;

          expect(scaled.water, water);
          expect(recipe.water, water);
          expect(waterOfSteps(recipe), water,
              reason: 'вода шагов сходится с выбранной');
          expect(recipe.steps.every((step) => step.time >= 0), isTrue);
          expect(recipe.time,
              recipe.steps.fold<int>(0, (sum, step) => sum + step.time));
          expect(scaled.dose, greaterThan(method.recipe.load * 0.99),
              reason: 'кофе больше, чем в рецепте');
          expect(scaled.runs, greaterThanOrEqualTo(1));

          final k = water / method.recipe.water;
          switch (profile.family) {
            case ScalingFamily.repeat:
            case ScalingFamily.parallel:
              expect(scaled.runs, (k).round());
              expect(scaled.dose, closeTo(method.recipe.load * k, 0.01));
            case ScalingFamily.concentrate:
              // Концентрат крепче — кофе чуть больше пропорции, не меньше.
              expect(scaled.dose,
                  greaterThanOrEqualTo(method.recipe.load * k - 0.05));
            default:
              expect(scaled.dose, closeTo(method.recipe.load * k, 0.051));
          }
          if (profile.family == ScalingFamily.repeat) {
            expect(
                recipe.steps.length, method.recipe.steps.length * scaled.runs);
          }
          if (profile.family == ScalingFamily.percolation) {
            expect(scaled.totalSeconds,
                greaterThanOrEqualTo(method.recipe.time - 5),
                reason: 'больше воды — не быстрее');
          }
          final keys = recipe.steps.map((step) => step.stepKey).toList();
          expect(keys.toSet().length, keys.length,
              reason: 'ключи шагов разные — плеер различает шаги по ним');
        });
      }
    });
  }
}
