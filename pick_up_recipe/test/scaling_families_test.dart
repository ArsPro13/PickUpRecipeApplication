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
    // Концентрат с доливкой — для обычного аэропресса; рядом подсказка,
    // что в AeroPress XL то же войдёт целиком.
    expect(scaled.warnings.map((warning) => warning.kind),
        [ScaleWarningKind.bypass, ScaleWarningKind.wholeIn]);
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

  // Владелец 04.11.2026: «исследуй, в каких методах заваривания существуют
  // более большие размеры девайсов, потому что, например, в моке вполне
  // нормально увеличить объём в два раза, потому что существуют более
  // большие кофеварки».
  group('кофеварка побольше вместо второго захода', () {
    for (final slug in ['moka', 'neapolitan']) {
      test('$slug — барабан по размерам кофеварки, рецепт на нём', () {
        final profile = ScalingProfile.builtIn(slug)!;
        final recipe = base[slug]!;
        final sizes = potSizes(recipe, profile);

        expect(profile.family, ScalingFamily.pot);
        expect(profile.sizeUnit, ScalingSizeUnit.cups);
        expect(sizes.length, greaterThanOrEqualTo(3));
        expect(sizes.map((size) => size.value), contains(recipe.water),
            reason: 'размер рецепта стоит на барабане ровно его водой');
        expect(scaleWheelValues(recipe, profile),
            [for (final size in sizes) size.value]);
      });

      test('$slug побольше — одна варка, «нужна кофеварка на N»', () {
        final profile = ScalingProfile.builtIn(slug)!;
        final recipe = base[slug]!;
        final own = profile.potOwnSize(recipe.water.toDouble());
        final bigger = potSizes(recipe, profile)
            .firstWhere((size) => size.value > recipe.water);
        final scaled = scale(slug, bigger.value);
        final k = bigger.value / recipe.water;

        expect(scaled.runs, 1, reason: 'не «1/2 · …», а одна варка');
        expect(labels(scaled.recipe), labels(recipe));
        expect(scaled.dose, greaterThan(recipe.load));
        expect(scaled.potSize, bigger.key);
        expect(
          scaled.warnings.first,
          ScaleWarning(ScaleWarningKind.potSize,
              size: own,
              biggerSize: bigger.key,
              sizeUnit: ScalingSizeUnit.cups),
        );

        // Нагрев до первых струек дольше, но медленнее воды: у кофеварки
        // побольше и дно шире.
        final heat0 = recipe.steps.firstWhere((s) => s.stepType == 'wait');
        final heat =
            scaled.recipe.steps.firstWhere((s) => s.stepKey == heat0.stepKey);
        expect(heat.time, greaterThan(heat0.time));
        expect(heat.time, lessThan(heat0.time * k));
      });
    }

    test('мока ×2 — кофеварка на 6 чашек: 306 мл, кофе по корзине', () {
      // Bialetti: 3 чашки — 150 мл и 17 г, 6 — 300 мл и 30 г. Корзина растёт
      // медленнее бойлера, поэтому кофе не 36 г, а 18 × 30 / 17.
      final scaled = scale('moka', 306);

      expect(scaled.water, 306);
      expect(scaled.potSize, '6');
      expect(scaled.dose, 31.8);
      expect(scaled.runs, 1);
      final heat = scaled.recipe.steps[2];
      expect(heat.instruction, 'Греть до первых струек');
      expect(heat.time, 255, reason: '180 с × √2');
    });

    test('мока на 4 и 18 чашек — корзина достроена по соседям', () {
      final moka = ScalingProfile.builtIn('moka')!;
      expect(moka.basketFor('4'), closeTo(23.3, 0.3));
      expect(moka.basketFor('18'), closeTo(66, 1));
    });

    test('Brikka: размеров два — меньше одной варкой, больше 4 чашек заходы',
        () {
      final brikka = ScalingProfile.builtIn('brikka')!;
      final recipe = base['brikka']!;
      expect(brikka.potOwnSize(recipe.water.toDouble()), '4',
          reason: '150 мл в мерку 2 чашек (120) не входят');
      expect(scaleWheelValues(recipe, brikka), [100, 150, 300, 450, 600]);

      final smaller = scale('brikka', 100);
      expect(smaller.potSize, '2');
      expect(smaller.dose, 9, reason: '18 г × 15 / 30');

      final twice = scale('brikka', 300);
      expect(twice.runs, 2, reason: 'кофеварки больше 4 чашек нет');
      expect(twice.potSize, isEmpty);
      expect(labels(twice.recipe).first, startsWith('1/2 · '));
    });
  });

  group('ещё заход, но есть прибор, куда войдёт за раз', () {
    test('фин ×2 — подсказка про Phin 12 oz, ×3 — про 24 oz', () {
      expect(
          scale('phin', 280).warnings.single,
          const ScaleWarning(ScaleWarningKind.wholeIn,
              biggerSize: 'Phin 12 oz'));
      expect(scale('phin', 420).warnings.single.biggerSize, 'Phin 24 oz');
      expect(scale('phin', 280).runs, 2,
          reason: 'у кого его нет — фин за фином');
    });

    test('Nanopresso ×2 — с Barista Kit одним шотом, ×3 не входит и в кит', () {
      final water = base['nanopresso']!.water;
      expect(scale('nanopresso', water * 2).warnings.single.biggerSize,
          'Nanopresso + Barista Kit');
      expect(scale('nanopresso', water * 3).warnings, isEmpty);
    });

    test('Staresso ×2 — SP-300', () {
      final water = base['staresso']!.water;
      expect(scale('staresso', water * 2).warnings.single.biggerSize,
          'Staresso SP-300');
    });
  });

  group('размер побольше вместо «лучше в два захода»', () {
    test('френч-пресс: рецепт на 480 мл — пресс 0,5 л; ×2 — 1 л, ×3 — 1,5 л',
        () {
      expect(
          recipeSize(
              base['french_press']!, ScalingProfile.builtIn('french_press')!),
          '0.5');
      expect(
        scale('french_press', 960).warnings,
        contains(const ScaleWarning(ScaleWarningKind.biggerSize,
            size: '0.5', biggerSize: '1.0', sizeUnit: ScalingSizeUnit.litres)),
      );
      expect(
        scale('french_press', 1440).warnings,
        contains(const ScaleWarning(ScaleWarningKind.biggerSize,
            size: '0.5', biggerSize: '1.5', sizeUnit: ScalingSizeUnit.litres)),
      );
    });

    test('турка ×2 — турки продают по объёму: 200 мл → 400 мл', () {
      expect(
        scale('cezve', 200).warnings,
        contains(const ScaleWarning(ScaleWarningKind.biggerSize,
            size: '200',
            biggerSize: '400',
            sizeUnit: ScalingSizeUnit.millilitres)),
      );
    });

    test('Clever ×1,5 — в L войдёт, ×2 — уже два захода', () {
      expect(
        scale('clever', 420).warnings,
        contains(const ScaleWarning(ScaleWarningKind.biggerSize,
            size: 'S', biggerSize: 'L')),
      );
      expect(scale('clever', 560).warnings.map((w) => w.kind),
          contains(ScaleWarningKind.overCapacity));
    });

    test('Switch 400 мл — в 03 войдёт', () {
      final scaled = scale('hario_switch', 400);
      expect(
        scaled.warnings,
        contains(const ScaleWarning(ScaleWarningKind.biggerSize,
            size: '02', biggerSize: '03')),
      );
    });

    test('сифон 550 мл — TCA-5', () {
      final scaled = scale('siphon', 550);
      expect(
        scaled.warnings,
        contains(const ScaleWarning(ScaleWarningKind.biggerSize,
            size: 'TCA-3', biggerSize: 'TCA-5')),
      );
    });

    test('аэропресс ×2 — концентрат в обычный, а в XL войдёт целиком', () {
      final scaled = scale('aeropress', 420);
      expect(scaled.bypassWater, greaterThan(0));
      expect(scaled.warnings.map((w) => w.kind),
          contains(ScaleWarningKind.wholeIn));
      expect(
          scaled.warnings
              .firstWhere((w) => w.kind == ScaleWarningKind.wholeIn)
              .biggerSize,
          'AeroPress XL');
    });

    test('эспрессо — больше прибора нет, остаётся ещё шот', () {
      expect(ScalingProfile.builtIn('espresso')!.family, ScalingFamily.repeat);
      expect(scale('espresso', 72).warnings, isEmpty);
    });
  });
}
