// Как масштабируется каждая семья приборов — на базовых рецептах справочника.
//
// scaling_all_methods_test.dart проверяет, что пересчёт у всех 71 прибора
// даёт рецепт, который можно заварить. Здесь — что он значит по смыслу:
// у турки дольше греется, у колд брю часы те же, аэропресс доливает, эспрессо
// повторяет шот, дрип-пакеты заливаются по очереди и ждут вместе.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/scaling/recipe_scaler.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/scaling/scaling_profile.dart';

import 'scaling_all_methods_test.dart' show loadBaseMethods;

const _labels = ScaleLabels(
  splitWait: 'Ждём, пока уйдёт',
  dilute: 'Долейте горячую воду',
  diluteCold: 'Долейте холодную воду',
);

void main() {
  final base = {
    for (final method in loadBaseMethods()) method.slug: method.recipe,
  };

  ScaledRecipe scale(String slug, int water) => scaleRecipe(
        base: base[slug]!,
        water: water,
        profile: ScalingProfile.builtIn(slug)!,
        labels: _labels,
      );

  List<String> labels(RecipeData recipe) =>
      [for (final step in recipe.steps) step.instruction];

  test('эспрессо ×2 — тот же шот ещё раз, номер захода впереди', () {
    final scaled = scale('espresso', 72);

    expect(scaled.runs, 2);
    expect(scaled.dose, 36);
    expect(scaled.dosePerRun, 18);
    expect(labels(scaled.recipe), [
      '1/2 · Смолоть в корзину',
      '1/2 · Разровнять и утрамбовать',
      '1/2 · Пролив',
      '1/2 · Подавать',
      '2/2 · Смолоть в корзину',
      '2/2 · Разровнять и утрамбовать',
      '2/2 · Пролив',
      '2/2 · Подавать',
    ]);
    expect([for (final step in scaled.recipe.steps) step.water],
        [0, 0, 36, 0, 0, 0, 36, 0]);
  });

  test('аэропресс ×2 — концентрат в камере и доливка горячей', () {
    final scaled = scale('aeropress', 420);

    expect(scaled.runs, 1);
    expect(scaled.bypassWater, greaterThan(100));
    expect(scaled.warnings.single.kind, ScaleWarningKind.bypass);
    final steps = scaled.recipe.steps;
    final press = steps.indexWhere((step) => step.stepType == 'press');
    expect(steps[press + 1].stepType, 'dilute',
        reason: 'доливают после отжима, не до');
    expect(steps[press + 1].instruction, 'Долейте горячую воду');
    expect(steps[press + 1].water, scaled.bypassWater);
    // В камере — вода и кофе не больше её объёма.
    final chamber = steps.first.water + 0.8 * scaled.dose;
    expect(chamber, lessThanOrEqualTo(280));
  });

  test('аэропресс со льдом доливают холодной', () {
    final scaled = scaleRecipe(
      base: copyRecipe(base['aeropress']!)..temperature = 20,
      water: 420,
      profile: ScalingProfile.builtIn('cold_aero')!,
      labels: _labels,
    );
    expect(
      scaled.recipe.steps
          .where((step) => step.stepType == 'dilute')
          .single
          .instruction,
      'Долейте холодную воду',
    );
  });

  test('Gina ×2 — вода стоит в воронке только при закрытом кране', () {
    // 440 мл в воронку на 300 не вошли бы, но второй пролив идёт при
    // открытом кране: разом в ней ≈140 мл.
    expect(scale('gina', 440).warnings, isEmpty);
    // У Clever кран закрыт всё время — 560 мл в L на 500 не войдут.
    expect(scale('clever', 560).warnings.map((warning) => warning.kind),
        [ScaleWarningKind.overCapacity]);
  });

  test('турка ×2 — до пенки греется вдвое дольше, остальное то же', () {
    final scaled = scale('cezve', 200);
    final heat = scaled.recipe.steps.firstWhere((step) => step.untilUser);
    expect(heat.time, 360);
    expect(
      [for (final step in scaled.recipe.steps.skip(3)) step.time],
      [for (final step in base['cezve']!.steps.skip(3)) step.time],
    );
  });

  test('колд брю ×2 — часы настаивания те же', () {
    final scaled = scale('cold_brew', 1200);
    final steep = scaled.recipe.steps.firstWhere((step) => step.time > 3600);
    expect(steep.time, 43200);
    expect(scaled.dose, 120);
  });

  test('колд дрип ×2 — капает вдвое дольше, колба меньше воды', () {
    final scaled = scale('cold_drip', 1080);
    expect(
        scaled.recipe.steps
            .map((step) => step.time)
            .reduce((a, b) => a > b ? a : b),
        34800);
    expect(scaled.warnings.single.kind, ScaleWarningKind.refill);
    expect(scaled.warnings.single.chamber, 720);
  });

  test('дрип-пакеты ×3 — заливают по очереди, ждут вместе', () {
    final scaled = scale('drip_bag', 450);
    expect(scaled.runs, 3);
    expect(labels(scaled.recipe),
        ['Предсмачивание ×3', 'Долить до полного ×3', 'Ждём пролива']);
    expect([for (final step in scaled.recipe.steps) step.time], [90, 120, 80]);
  });

  test('сифон ×1,5 — нагрев нижней колбы растёт, контакт тот же', () {
    final scaled = scale('siphon', 465);
    final steps = scaled.recipe.steps;
    expect(steps[1].time, 60, reason: 'подъём воды: 40 с × 1,5');
    expect(steps[3].time, 45, reason: 'экстракция наверху та же');
  });
}
