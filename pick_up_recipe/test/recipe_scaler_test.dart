// Тесты пересчёта рецепта на другой объём воды.
//
// Три слоя проверок.
//
// 1. Эталоны витрины: 52 случая, число в число (recipe_scaler_golden.dart).
//    Владелец выбирал интерфейс по витрине, и экран обязан показать те же
//    числа, что он там видел.
// 2. Числа из PDF исследования (prototype/data.json): V60 ×2 и ×3, край шкалы
//    C40, френч-пресс и Clever — у витрины иммерсии и клапана нет.
// 3. Свойства, которые держатся на любом объёме: 250 мл — тот же рецепт,
//    вода шагов сходится с выбранной, доза держит соотношение, помол с
//    объёмом крупнеет.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/models/grinder_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/scaling/recipe_scaler.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/scaling/scaling_profile.dart';

import 'recipe_scaler_golden.dart';

RecipeStep _step(
  int seq,
  String type,
  String label, {
  int water = 0,
  required int time,
  String tip = '',
}) =>
    RecipeStep(
      seqNum: seq,
      instruction: label,
      water: water,
      time: time,
      id: seq,
      stepType: type,
      stepKey: 's$seq',
      tip: tip,
      isOptional: false,
      untilUser: false,
      untilSign: '',
      warning: '',
    );

RecipeData _recipe({
  required String device,
  required double load,
  required int water,
  double? temperature = 92,
  required List<RecipeStep> steps,
}) =>
    RecipeData(
      id: 77,
      device: device,
      date: '2026-11-01',
      packId: 1,
      grinderId: 11,
      grindStep: '27',
      grindSubStep: null,
      water: water,
      time: steps.fold(0, (sum, step) => sum + step.time),
      temperature: temperature,
      load: load,
      title: 'Бразилия Можиана',
      notes: '',
      grindDescriptor: 'medium',
      agitationLevel: null,
      steps: steps,
    );

/// Демо-рецепт стенда: «Бразилия Можиана» на V60, 15 г на 250 мл.
RecipeData moziana() => _recipe(
      device: 'hario_v60',
      load: 15,
      water: 250,
      steps: [
        _step(1, 'bloom', 'Предсмачивание',
            water: 45, time: 30, tip: 'Смочите весь кофе'),
        _step(2, 'pour', 'Первый пролив', water: 105, time: 35),
        _step(3, 'wait', 'Пауза', time: 10),
        _step(4, 'pour', 'Второй пролив', water: 100, time: 35),
        _step(5, 'wait', 'Ждём пролива', time: 50),
      ],
    );

List<GrinderMode> _modes(List<(String, double)> table) => [
      for (final (mode, microns) in table)
        GrinderMode(mode: mode, microns: microns),
    ];

/// Шкалы из grinders.db — те же, что на витрине.
final List<GrinderMode> c40 = _modes([
  ('11', 554), ('12', 568), ('13', 583), ('14', 606), ('15', 629), //
  ('16', 662), ('17', 695), ('18', 738), ('19', 780), ('20', 820),
  ('21', 859), ('22', 910), ('23', 961), ('24', 1008), ('25', 1054),
  ('26', 1119), ('27', 1184), ('28', 1211), ('29', 1237), ('30', 1268),
  ('31', 1299),
]);

final List<GrinderMode> jx = _modes([
  ('42', 563), ('43', 571), ('44', 579), ('45', 586), ('46', 594), //
  ('47', 602), ('48', 616), ('49', 630), ('50', 643), ('51', 657),
  ('52', 671), ('53', 684), ('54', 697), ('55', 709), ('56', 722),
  ('57', 735), ('58', 757), ('59', 778), ('60', 800), ('61', 821),
  ('62', 843), ('63', 859), ('64', 874), ('65', 890), ('66', 906),
  ('67', 922), ('68', 944), ('69', 966), ('70', 988), ('71', 1010),
  ('72', 1032), ('73', 1047), ('74', 1061), ('75', 1076), ('76', 1090),
  ('77', 1105), ('78', 1121), ('79', 1137), ('80', 1154), ('81', 1170),
  ('82', 1186),
]);

final ScalingProfile v60 = ScalingProfile.builtIn('hario_v60')!;

/// Пересчёт «Можианы» так, как его зовёт экран: со шкалой кофемолки
/// человека и делением, на котором стоит рецепт.
ScaledRecipe scaleMoziana(int water, {String grinder = 'jx', String? size}) {
  final onC40 = grinder == 'c40';
  return scaleRecipe(
    base: moziana(),
    water: water,
    profile: v60,
    scale: onC40 ? c40 : jx,
    baseClick: onC40 ? '27' : '60',
    grinderId: 99,
    size: size,
    labels: const ScaleLabels(splitWait: 'Ждём, пока уйдёт'),
  );
}

/// Шаги одной строкой, как в эталонах: «bloom:90/40 pour:210/45 …».
String stepsLine(RecipeData recipe) => recipe.steps
    .map((step) =>
        '${step.stepType}${step.stepKey.startsWith('scale-wait-') ? '+' : ''}'
        ':${step.water}/${step.time}')
    .join(' ');

int splitOf(ScaledRecipe scaled) => scaled.warnings
    .where((warning) => warning.kind == ScaleWarningKind.split)
    .fold(0, (_, warning) => warning.parts);

int waterOfSteps(RecipeData recipe) => recipe.steps
    .where((step) =>
        const {'bloom', 'pour', 'add_ice', 'dilute'}.contains(step.stepType))
    .fold(0, (sum, step) => sum + step.water);

void main() {
  group('эталоны витрины', () {
    for (final line in showcaseGolden) {
      final parts = line.split(' | ');
      final head = parts[0].split(' ');
      final water = int.parse(head[0]);
      final grinder = head[1];
      final size = head[2];
      final fields = parts[1].split(' ');
      String field(String name) => fields[fields.indexOf(name) + 1];

      test('$water мл, $grinder, V60-$size', () {
        final scaled = scaleMoziana(water, grinder: grinder, size: size);

        expect(scaled.dose, double.parse(field('dose')), reason: 'доза');
        expect(scaled.grindStep, field('grind'), reason: 'деление');
        expect(scaled.recipe.temperature, double.parse(field('temp')),
            reason: 'температура');
        expect(scaled.totalSeconds, int.parse(field('total')),
            reason: 'всё время');
        expect(scaled.recipe.time, scaled.totalSeconds);
        expect(scaled.cupMl, int.parse(field('cup')), reason: 'в чашке');
        expect(splitOf(scaled), int.parse(field('split')),
            reason: 'на сколько частей пролив');
        expect(stepsLine(scaled.recipe), parts[2], reason: 'шаги');
      });
    }
  });

  group('числа из PDF исследования', () {
    test('V60 ×2 на JX: 30 г, 60 → 64 клика, 3:10', () {
      final scaled = scaleMoziana(500);

      expect(scaled.dose, 30);
      expect(scaled.baseGrindStep, '60');
      expect(scaled.grindStep, '64');
      expect(scaled.totalSeconds, 190);
      expect(stepsLine(scaled.recipe),
          'bloom:90/40 pour:210/45 wait:0/10 pour:200/45 wait:0/50');
      expect(scaled.warnings, isEmpty);
    });

    test('V60 ×3 в V60-03 на JX: 45 г, 67 кликов, 3:35', () {
      final scaled = scaleMoziana(750, size: '03');

      expect(scaled.dose, 45);
      expect(scaled.grindStep, '67');
      expect(scaled.totalSeconds, 215);
      expect(scaled.warnings,
          [const ScaleWarning(ScaleWarningKind.deepBed, grams: 30)]);
    });

    test('C40 ×3: шкала кончается на 31 — вода на 3 °C холоднее', () {
      final scaled = scaleMoziana(750, grinder: 'c40', size: '03');

      expect(scaled.grindStep, '31');
      expect(scaled.recipe.temperature, 89);
      expect(
        scaled.warnings,
        contains(const ScaleWarning(ScaleWarningKind.grinderEdgeCoarse,
            click: '31', tempDrop: 3)),
      );
    });

    test('C40 ×2 со шкалой сервера: пауза 10 → 15 с, 3:15, как в прототипе',
        () {
      // Шкала, как её отдаёт grinder_translator: деления «27.0» и микроны без
      // округления. На витрине микроны округлены до целых, и этот случай
      // лежит ровно на границе: пауза 12,6 с там округлялась к 10, здесь — к
      // 15. Прототип на Python (data.json, 02-2-C40) считает по точным
      // числам и тоже даёт 15 с и 195 с.
      final server = _modes([
        ('11.0', 553.7468532676305), ('12.0', 568.4292990776869), //
        ('13.0', 583.1117448877433), ('14.0', 605.8415404870311),
        ('15.0', 628.5713360863189), ('16.0', 661.8746304361916),
        ('17.0', 695.1779247860643), ('18.0', 737.7450446122884),
        ('19.0', 780.3121644385125), ('20.0', 819.5094887308663),
        ('21.0', 858.7068130232202), ('22.0', 909.9864727399665),
        ('23.0', 961.2661324567129), ('24.0', 1007.6555970951765),
        ('25.0', 1054.0450617336403), ('26.0', 1118.8780583629064),
        ('27.0', 1183.7110549921726), ('28.0', 1210.577994959193),
        ('29.0', 1237.444934926213), ('30.0', 1268.4552154685766),
        ('31.0', 1299.4654960109403),
      ]);

      final scaled = scaleRecipe(
        base: moziana(),
        water: 500,
        profile: v60,
        scale: server,
        baseClick: '27',
        grinderId: 11,
      );

      expect(scaled.grindStep, '31.0');
      expect(scaled.totalSeconds, 195);
      expect(stepsLine(scaled.recipe),
          'bloom:90/40 pour:210/45 wait:0/15 pour:200/45 wait:0/50');
    });

    test('френч-пресс ×2: настаивание 240 → 235 с, помол прежний', () {
      final press = _recipe(
        device: 'french_press',
        load: 30,
        water: 500,
        temperature: 94,
        steps: [
          _step(1, 'pour', 'Залить воду', water: 500, time: 20),
          _step(2, 'wait', 'Настаивание', time: 240),
          _step(3, 'stir', 'Снять корку', time: 15),
          _step(4, 'press', 'Опустить поршень', time: 20),
          _step(5, 'serve', 'Разлить', time: 10),
        ],
      );

      final scaled = scaleRecipe(
        base: press,
        water: 1000,
        profile: ScalingProfile.builtIn('french_press')!,
        scale: c40,
        baseClick: '27',
        grinderId: 99,
      );

      expect(scaled.dose, 60);
      expect(stepsLine(scaled.recipe),
          'pour:1000/40 wait:0/235 stir:0/15 press:0/20 serve:0/10');
      expect(scaled.totalSeconds, 320);
      expect(scaled.grindStep, isNull, reason: 'иммерсия помол не трогает');
      expect(scaled.recipe.grinderId, 11);
      expect(scaled.recipe.grindStep, '27');
      // Литр воды с 60 г кофе в литровый пресс входит: номинал Bodum — это
      // вода по 125 мл на чашку с запасом 2,5 см до верха (исследование v3).
      // Рецепт на 500 мл — это пресс на 0,5 л, и пересчёт называет размер,
      // где литр поместится (исследование размеров 04.11).
      expect(scaled.warnings, [
        const ScaleWarning(ScaleWarningKind.biggerSize,
            size: '0.5', biggerSize: '1.0', sizeUnit: ScalingSizeUnit.litres),
      ]);

      final over = scaleRecipe(
        base: press,
        water: 1100,
        profile: ScalingProfile.builtIn('french_press')!,
      );
      // 1,1 л в литровый пресс уже не войдёт, но пресс на 1,5 л продаётся:
      // называем его, а не советуем два захода (владелец 04.11: «исследуй, в
      // каких методах существуют более большие размеры девайсов»).
      expect(over.warnings, [
        const ScaleWarning(ScaleWarningKind.biggerSize,
            size: '0.5', biggerSize: '1.5', sizeUnit: ScalingSizeUnit.litres),
      ]);

      // Больше самого большого пресса — тогда уже два захода.
      final huge = scaleRecipe(
        base: press,
        water: 1600,
        profile: ScalingProfile.builtIn('french_press')!,
      );
      expect(huge.warnings.map((warning) => warning.kind),
          [ScaleWarningKind.overCapacity]);
    });

    test('Clever ×2: настаивание 110 с, слив 80 с', () {
      final clever = _recipe(
        device: 'clever',
        load: 18,
        water: 280,
        temperature: 93,
        steps: [
          _step(1, 'close_valve', 'Закрыть клапан', time: 5),
          _step(2, 'pour', 'Залить воду', water: 280, time: 30),
          _step(3, 'wait', 'Настаивание', time: 120),
          _step(4, 'stir', 'Размешать', time: 10),
          _step(5, 'open_valve', 'Поставить на чашку', time: 5),
          _step(6, 'wait', 'Слив', time: 60),
        ],
      );

      final scaled = scaleRecipe(
        base: clever,
        water: 560,
        profile: ScalingProfile.builtIn('clever')!,
      );

      expect(scaled.dose, 36);
      expect(
        stepsLine(scaled.recipe),
        'close_valve:0/5 pour:560/60 wait:0/110 stir:0/10 open_valve:0/5 '
        'wait:0/80',
      );
      expect(scaled.totalSeconds, 270);
      expect(scaled.bedDepthRatio, closeTo(1.3568, 0.0005));
    });
  });

  group('свойства', () {
    test('та же вода — тот же рецепт, до секунды', () {
      final base = moziana()..steps[1].time = 33;
      final scaled = scaleRecipe(
        base: base,
        water: 250,
        profile: v60,
        scale: jx,
        baseClick: '60',
        grinderId: 99,
      );

      expect(scaled.isOriginal, isTrue);
      expect(scaled.warnings, isEmpty);
      expect(scaled.grindStep, '60');
      expect(scaled.recipe.toJson().toString(), base.toJson().toString());
      expect(identical(scaled.recipe, base), isFalse,
          reason: 'копия, а не тот же объект');
    });

    test('исходный рецепт не меняется', () {
      final base = moziana();
      final before = base.toJson().toString();

      scaleRecipe(
        base: base,
        water: 750,
        profile: v60,
        scale: c40,
        baseClick: '27',
        grinderId: 99,
      );

      expect(base.toJson().toString(), before);
    });

    test('вода шагов сходится с выбранной на всём барабане', () {
      for (final grinder in ['c40', 'jx', '']) {
        for (final size in ['02', '03']) {
          for (var water = kScaleMinWater;
              water <= kScaleMaxWater;
              water += kScaleWaterStep) {
            final scaled = grinder.isEmpty
                ? scaleRecipe(
                    base: moziana(), water: water, profile: v60, size: size)
                : scaleMoziana(water, grinder: grinder, size: size);

            expect(waterOfSteps(scaled.recipe), water,
                reason: '$water мл, $grinder, $size');
            expect(scaled.recipe.water, water);
            expect(
              scaled.recipe.steps.every((step) => step.time >= 0),
              isTrue,
            );
          }
        }
      }
    });

    test('доза держит соотношение до десятой грамма', () {
      for (var water = kScaleMinWater;
          water <= kScaleMaxWater;
          water += kScaleWaterStep) {
        final scaled = scaleMoziana(water);

        expect(scaled.dose, closeTo(15 * water / 250, 0.05 + 1e-9));
        expect(scaled.recipe.load, scaled.dose);
      }
    });

    test('с объёмом помол крупнеет, а время растёт', () {
      double? ratio;
      int? clicks;
      for (var water = kScaleMinWater;
          water <= kScaleMaxWater;
          water += kScaleWaterStep) {
        // Без шкалы — точное отношение, без округления до клика.
        final exact = scaleRecipe(base: moziana(), water: water, profile: v60);
        if (ratio != null) {
          expect(exact.grindRatio, greaterThanOrEqualTo(ratio),
              reason: '$water мл');
        }
        ratio = exact.grindRatio;

        final onJx = int.parse(scaleMoziana(water).grindStep!);
        if (clicks != null) {
          expect(onJx, greaterThanOrEqualTo(clicks), reason: '$water мл');
        }
        clicks = onJx;
      }

      final totals = [
        for (final water in [125, 250, 375, 500, 625, 750])
          scaleMoziana(water, size: '03').totalSeconds,
      ];
      for (var i = 1; i < totals.length; i++) {
        expect(totals[i], greaterThanOrEqualTo(totals[i - 1]),
            reason: totals.join(' '));
      }
    });

    test('время шагов — по 5 с, нетронутые шаги — как в рецепте', () {
      final press = _recipe(
        device: 'french_press',
        load: 30,
        water: 500,
        steps: [
          _step(1, 'pour', 'Залить воду', water: 500, time: 20),
          _step(2, 'wait', 'Настаивание', time: 240),
          _step(3, 'stir', 'Снять корку', time: 3),
        ],
      );

      final scaled = scaleRecipe(
        base: press,
        water: 750,
        profile: ScalingProfile.builtIn('french_press')!,
      );

      expect(scaled.recipe.steps[2].time, 3);
      expect(scaled.recipe.steps[1].time % 5, 0);
    });
  });

  group('пролив частями', () {
    test('750 мл в V60-02: каждый пролив в 2 части, в 03 войдёт', () {
      final scaled = scaleMoziana(750, size: '02');

      expect(
        scaled.warnings,
        contains(const ScaleWarning(ScaleWarningKind.split,
            parts: 2, size: '02', biggerSize: '03')),
      );

      final labels = scaled.recipe.steps.map((step) => step.instruction);
      expect(labels, [
        'Предсмачивание',
        'Первый пролив · 1/2',
        'Ждём, пока уйдёт',
        'Первый пролив · 2/2',
        'Пауза',
        'Второй пролив · 1/2',
        'Ждём, пока уйдёт',
        'Второй пролив · 2/2',
        'Ждём пролива',
      ]);

      final keys = scaled.recipe.steps.map((step) => step.stepKey).toList();
      expect(keys.toSet().length, keys.length, reason: 'ключи шагов разные');
      expect(scaled.recipe.steps.first.tip, 'Смочите весь кофе');
    });

    test('1000 мл в V60-03 помещается — частей нет', () {
      expect(splitOf(scaleMoziana(1000, size: '03')), 0);
    });
  });

  group('предупреждения', () {
    test('меньше 8 г — слой тонкий', () {
      expect(scaleMoziana(120).warnings,
          [const ScaleWarning(ScaleWarningKind.tooThin, grams: 8)]);
    });

    test('больше 30 г в V60 — глубже, чем советуют', () {
      expect(
        scaleMoziana(550, size: '03').warnings,
        [const ScaleWarning(ScaleWarningKind.deepBed, grams: 30)],
      );
    });

    test('больше 50 г — два захода по половине', () {
      expect(
        scaleMoziana(1000, size: '03').warnings,
        contains(const ScaleWarning(ScaleWarningKind.tooDeep,
            grams: 50, halfWater: 500)),
      );
    });
  });

  group('что пересчитывается', () {
    test('у каждой семьи свои приборы', () {
      final families = {
        'hario_v60': ScalingFamily.percolation,
        'batch_brewer': ScalingFamily.percolation,
        'clever': ScalingFamily.valve,
        'gina': ScalingFamily.valve,
        'french_press': ScalingFamily.immersion,
        'cezve': ScalingFamily.heated,
        'siphon': ScalingFamily.heated,
        'aeropress': ScalingFamily.concentrate,
        'espresso': ScalingFamily.repeat,
        // Мока — кофеварка побольше, а не второй заход (владелец 04.11).
        'moka': ScalingFamily.pot,
        'neapolitan': ScalingFamily.pot,
        'drip_bag': ScalingFamily.parallel,
        'cupping': ScalingFamily.parallel,
        'cold_brew': ScalingFamily.coldSteep,
        'cold_drip': ScalingFamily.coldDrip,
      };
      families.forEach((slug, family) {
        expect(ScalingProfile.builtIn(slug)?.family, family, reason: slug);
      });
    });

    test('прибора нет в таблице — не пересчитывается', () {
      for (final slug in ['cold', 'unknown_device', '']) {
        expect(ScalingProfile.builtIn(slug), isNull, reason: slug);
      }
    });

    test('рецепт без пролива с водой и временем не пересчитывается', () {
      expect(canScaleRecipe(moziana(), v60), isTrue);
      expect(canScaleRecipe(moziana(), null), isFalse);

      final historical = moziana();
      for (final step in historical.steps) {
        step.stepType = '';
      }
      expect(canScaleRecipe(historical, v60), isFalse);

      expect(canScaleRecipe(moziana()..load = 0, v60), isFalse);
    });

    test('без шкалы кофемолки помол — только во сколько раз', () {
      final scaled = scaleRecipe(base: moziana(), water: 500, profile: v60);

      expect(scaled.grindStep, isNull);
      expect(scaled.grindRatio, closeTo(1.089, 0.001));
      expect(scaled.recipe.grinderId, 11, reason: 'кофемолка рецепта');
      expect(scaled.recipe.grindStep, '27');
    });

    test('новое деление записано в рецепт с кофемолкой человека', () {
      final scaled = scaleMoziana(500);

      expect(scaled.recipe.grinderId, 99);
      expect(scaled.recipe.grindStep, '64');
      expect(scaled.recipe.grindSubStep, isNull);
    });

    test('деление рецепта находится и с хвостом «.0»', () {
      final scale = [
        for (final mode in jx)
          GrinderMode(mode: '${mode.mode}.0', microns: mode.microns),
      ];

      final scaled = scaleRecipe(
        base: moziana(),
        water: 500,
        profile: v60,
        scale: scale,
        baseClick: '60',
        grinderId: 99,
      );

      expect(scaled.grindStep, '64.0');
    });

    test('профиль из справочника методов', () {
      final profile = ScalingProfile.fromJson({
        'family': 'percolation',
        'geometry': {'r_bottom_mm': 29, 'half_angle_deg': 21.8},
        'sizes_ml': {'155': 300, '185': 485},
        'default_size': '185',
        'soft_dose_g': 30,
      })!;

      expect(profile.family, ScalingFamily.percolation);
      expect(profile.capacityFor(null), 485);
      expect(profile.capacityFor('155'), 300);
      expect(profile.softDoseGrams, 30);
      expect(profile.grindExponent, 2.5);
      expect(ScalingProfile.fromJson({'family': 'bypass'}), isNull);
    });
  });
}
