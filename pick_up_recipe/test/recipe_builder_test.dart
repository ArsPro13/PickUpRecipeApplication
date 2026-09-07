// Конструктор рецепта: разбор чисел, тело запроса на сохранение и отбор
// типов шагов по методу.
//
// Всё, что здесь проверяется, стоит рецепта, если ошибётся: «0:35» разобранное
// как 35 минут, потерянное при отправке поле или лист, показывающий отжим у
// V60. Виджеты вокруг этого проверяются глазами, а это — тестом.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/step_type_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/user_step_type_model.dart';
import 'package:pick_up_recipe/src/pages/recipe_builder_page.dart';
import 'package:pick_up_recipe/src/themes/app_icons.dart';

StepType type(String slug, {required int groupId, int sortOrder = 0}) {
  return StepType(
    id: slug.hashCode,
    slug: slug,
    name: slug,
    shortName: '',
    iconKey: 'step-$slug',
    groupId: groupId,
    sortOrder: sortOrder,
  );
}

RecipeStep step({
  int seqNum = 1,
  String instruction = 'Пролив',
  int water = 100,
  int time = 30,
  String stepType = 'pour',
  String tip = '',
  bool untilUser = false,
  String untilSign = '',
}) {
  return RecipeStep(
    seqNum: seqNum,
    instruction: instruction,
    water: water,
    time: time,
    id: 0,
    stepType: stepType,
    stepKey: '',
    tip: tip,
    isOptional: false,
    untilUser: untilUser,
    untilSign: untilSign,
    warning: '',
  );
}

/// Рецепт с произвольным набором шагов. Нужен там, где проверяется итог по
/// воде: он и есть то, что расходится с общей водой рецепта.
RecipeData recipeWith(List<RecipeStep> steps, {int water = 250}) => RecipeData(
      id: 7,
      device: 'v60',
      date: '2026-08-09T10:00:00Z',
      packId: 3,
      grinderId: 12,
      grindStep: '68',
      grindSubStep: null,
      water: water,
      time: 160,
      temperature: 95,
      load: 15,
      title: '',
      notes: '',
      grindDescriptor: '',
      agitationLevel: null,
      steps: steps,
    );

void main() {
  group('чем шаг заканчивается', () {
    test('шаг с таймером не ждёт человека, шаг с признаком — ждёт', () {
      expect(stepEndsByUser(step()), isFalse);
      expect(stepEndsByUser(step(stepType: 'custom', untilUser: true)), isTrue);
    });

    test('подпись берётся из того же перечисления, что и форма своего типа', () {
      expect(stepEnding(step()), StepEndsWith.timer);
      expect(stepEnding(step(stepType: 'custom', untilUser: true)), StepEndsWith.user);
      expect(
        stepEnding(step(stepType: 'custom', untilUser: true, untilSign: 'воронка пуста')),
        StepEndsWith.none,
      );

      // Дословно те же слова, что в сегментах формы: разъехавшись, они
      // рассказали бы про один и тот же шаг две разные истории.
      expect(stepEnding(step(stepType: 'custom', untilUser: true)).label, 'по кнопке');
    });

    test('признак без ожидания человека ничего не значит', () {
      // until_sign у шага по таймеру — мусор из старых рецептов: шаг всё
      // равно кончится по часам, и обещать признак нельзя.
      expect(stepEnding(step(untilSign: 'воронка пуста')), StepEndsWith.timer);
    });
  });

  group('какие шаги льют воду', () {
    test('вода — у тех же четырёх типов, что и в плеере', () {
      for (final slug in ['pour', 'bloom', 'add_ice', 'dilute']) {
        expect(stepTakesWater(step(stepType: slug)), isTrue, reason: slug);
      }
    });

    test('пауза, размешивание и свой шаг воду не льют', () {
      for (final slug in ['wait', 'stir', 'press', 'note', 'custom', '']) {
        expect(stepTakesWater(step(stepType: slug)), isFalse, reason: slug);
      }
    });

    test('чужая вода вычищается, своя остаётся', () {
      // На фото у своего шага стоят «2 г»: они пережили смену типа с пролива
      // и с тех пор врали в итоге, потому что в чашку не попадали.
      final recipe = recipeWith([
        step(water: 100),
        step(seqNum: 2, stepType: 'custom', water: 2, untilUser: true),
      ]);

      dropStrayWater(recipe);

      expect(recipe.steps.first.water, 100);
      expect(recipe.steps.last.water, 0);
    });

    test('итог по воде складывает только льющие шаги', () {
      final recipe = recipeWith([
        step(water: 100),
        step(seqNum: 2, stepType: 'bloom', water: 50),
        step(seqNum: 3, stepType: 'custom', water: 2, untilUser: true),
      ]);

      dropStrayWater(recipe);
      final sum = recipe.steps
          .where(stepTakesWater)
          .fold<int>(0, (total, item) => total + item.water);

      expect(sum, 150);
    });

    test('такой шаг уезжает на сервер без воды и с признаком ожидания', () {
      final recipe = recipeWith([
        step(seqNum: 1, stepType: 'custom', water: 2, time: 9, untilUser: true),
      ]);

      dropStrayWater(recipe);
      final steps = evolvePayload(recipe)['steps'] as List<dynamic>;

      expect((steps.single as Map)['water'], 0);
      expect((steps.single as Map)['until_user'], isTrue);
    });
  });

  group('подпись свёрнутой строки шага', () {
    test('у пролива — вода и время', () {
      expect(stepSummary(step(water: 100, time: 30)), '100 г · 0:30');
    });

    test('у паузы — только время', () {
      expect(stepSummary(step(stepType: 'wait', water: 0, time: 65)), '1:05');
    });

    test('у шага по кнопке вместо времени — чем он кончается', () {
      // Было «0:09»: девять секунд, которые никто не отсчитывал.
      expect(
        stepSummary(step(stepType: 'custom', water: 2, time: 9, untilUser: true)),
        'по кнопке',
      );
    });

    test('у шага по признаку — то же, но своими словами', () {
      expect(
        stepSummary(step(
          stepType: 'custom',
          water: 0,
          time: 9,
          untilUser: true,
          untilSign: 'воронка пуста',
        )),
        'по признаку',
      );
    });
  });

  group('показ чисел', () {
    test('целая доза идёт без хвоста', () {
      expect(formatDecimal(16), '16');
      expect(formatDecimal(16.0), '16');
    });

    test('дробное — с запятой, как принято по-русски', () {
      expect(formatDecimal(16.7), '16,7');
      expect(formatDecimal(15.25), '15,3');
    });

    test('длительность — м:сс, секунды всегда двумя знаками', () {
      expect(formatDuration(35), '0:35');
      expect(formatDuration(60), '1:00');
      expect(formatDuration(160), '2:40');
      expect(formatDuration(9), '0:09');
    });
  });

  group('разбор введённого', () {
    test('запятая и точка равноправны', () {
      expect(parseNumber('16,7'), 16.7);
      expect(parseNumber('16.7'), 16.7);
    });

    test('пустое и мусор не превращаются в ноль', () {
      expect(parseNumber(''), isNull);
      expect(parseNumber('  '), isNull);
      expect(parseNumber('абв'), isNull);
    });

    test('м:сс разбирается в секунды', () {
      expect(parseDuration('0:35'), 35);
      expect(parseDuration('2:40'), 160);
      expect(parseDuration('1:00'), 60);
    });

    test('число без двоеточия — это секунды', () {
      expect(parseDuration('45'), 45);
    });

    test('половинки вокруг двоеточия достраиваются нулём', () {
      expect(parseDuration('3:'), 180);
      expect(parseDuration(':20'), 20);
    });

    test('мусор не даёт нуля: значение должно остаться прежним', () {
      expect(parseDuration(''), isNull);
      expect(parseDuration('1:2:3'), isNull);
      expect(parseDuration('утро'), isNull);
    });
  });

  group('тело запроса на сохранение', () {
    RecipeData recipe() => RecipeData(
          id: 7,
          device: 'v60',
          date: '2026-08-09T10:00:00Z',
          packId: 3,
          grinderId: 12,
          grindStep: '68',
          grindSubStep: null,
          water: 250,
          time: 160,
          temperature: 95,
          load: 15,
          title: 'Мой V60',
          notes: '',
          grindDescriptor: 'medium_fine',
          agitationLevel: 2,
          steps: [step(), step(seqNum: 2, instruction: 'Пауза', water: 0, stepType: 'wait')],
        );

    test('поля едут именами бэкенда, а не клиентской модели', () {
      final payload = evolvePayload(recipe());

      // Ровно та тройка, на которой генератор молча расходится с сервером.
      expect(payload['pack_id'], 3);
      expect(payload['grind_descriptor'], 'medium_fine');
      expect(payload['agitation_level'], 2);

      expect(payload.containsKey('pack'), isFalse);
      expect(payload.containsKey('grindDescriptor'), isFalse);
      expect(payload.containsKey('agitationLevel'), isFalse);
    });

    test('пустые необязательные поля не отправляются вовсе', () {
      final without = recipe()
        ..title = ''
        ..notes = ''
        ..grindDescriptor = ''
        ..agitationLevel = null
        ..temperature = null;

      final payload = evolvePayload(without);

      expect(payload.containsKey('title'), isFalse);
      expect(payload.containsKey('grind_descriptor'), isFalse);
      expect(payload.containsKey('agitation_level'), isFalse);
      expect(payload.containsKey('temperature'), isFalse);

      // А обязательные — отправляются, даже если нулевые.
      expect(payload['water'], 250);
      expect(payload['load'], 15);
    });

    test('шаги едут списком с порядковыми номерами', () {
      final steps = evolvePayload(recipe())['steps'] as List<dynamic>;

      expect(steps, hasLength(2));
      expect((steps[0] as Map)['seq_num'], 1);
      expect((steps[0] as Map)['step_type'], 'pour');
      expect((steps[1] as Map)['seq_num'], 2);
      expect((steps[1] as Map)['water'], 0);
    });
  });

  group('значок типа шага', () {
    test('семантический ключ справочника переводится в имя файла спрайта', () {
      // Справочник отдаёт 'bloom', в спрайте лежит 'ico-step-bloom' — без
      // перевода все шаги рисовались одним запасным значком.
      expect(AppIcons.step('bloom'), AppIcons.stepBloom);
      expect(AppIcons.step('pour'), AppIcons.stepPour);
      expect(AppIcons.step('wait'), AppIcons.stepWait);
    });

    test('подчёркивания в ключе становятся дефисами', () {
      expect(AppIcons.step('open_valve'), AppIcons.stepOpenValve);
      expect(AppIcons.step('remove_filter'), AppIcons.stepRemoveFilter);
    });

    test('незнакомый и пустой ключ дают значок своего шага, а не пустоту', () {
      expect(AppIcons.step('нет такого'), AppIcons.stepCustom);
      expect(AppIcons.step(''), AppIcons.stepCustom);
      expect(AppIcons.step(null), AppIcons.stepCustom);
    });
  });

  group('рабочая копия рецепта', () {
    RecipeData source() => RecipeData(
          id: 7,
          device: 'v60',
          date: '2026-08-09T10:00:00Z',
          packId: 3,
          grinderId: 12,
          grindStep: '68',
          grindSubStep: null,
          water: 250,
          time: 160,
          temperature: 95,
          load: 15,
          title: '',
          notes: '',
          grindDescriptor: 'medium_fine',
          agitationLevel: 2,
          steps: [step(), step(seqNum: 2, instruction: 'Пауза', water: 0, stepType: 'wait')],
        );

    test('шаги копируются, а не падают приведением типа', () {
      // `fromJson(recipe.toJson())` роняет экран на первом же шаге: генератор
      // кладёт в 'steps' объекты, а разбор ждёт карты.
      final copy = copyRecipe(source());

      expect(copy.steps, hasLength(2));
      expect(copy.steps.first.instruction, 'Пролив');
      expect(copy.steps.last.stepType, 'wait');
    });

    test('правка копии не трогает исходный рецепт', () {
      final original = source();
      final copy = copyRecipe(original);

      copy.water = 300;
      copy.steps.first.time = 99;
      copy.steps.removeLast();

      expect(original.water, 250);
      expect(original.steps.first.time, 30);
      expect(original.steps, hasLength(2));
    });
  });

  group('типы шагов, разрешённые методу', () {
    const groups = [
      StepTypeGroup(id: 1, slug: 'water', name: 'Вода', sortOrder: 1),
      StepTypeGroup(id: 2, slug: 'action', name: 'Действие', sortOrder: 2),
      StepTypeGroup(id: 3, slug: 'service', name: 'Обслуживание', sortOrder: 3),
    ];

    final reference = StepTypeReference(
      groups: groups,
      types: [
        type('pour', groupId: 1, sortOrder: 1),
        type('bloom', groupId: 1, sortOrder: 2),
        type('stir', groupId: 2, sortOrder: 1),
        type('open_valve', groupId: 3, sortOrder: 1),
      ],
    );

    test('неразрешённые типы не показываются вовсе', () {
      final result = reference.allowedFor(['pour', 'bloom', 'stir']);

      final slugs = result.expand((group) => group.types).map((t) => t.slug);
      expect(slugs, ['pour', 'bloom', 'stir']);
      expect(slugs, isNot(contains('open_valve')));
    });

    test('группа без единого разрешённого типа не показывается', () {
      final result = reference.allowedFor(['pour', 'bloom']);

      expect(result.map((group) => group.name), ['Вода']);
    });

    test('порядок — из справочника: групп и типов внутри них', () {
      final result = reference.allowedFor(['stir', 'bloom', 'pour']);

      expect(result.map((group) => group.name), ['Вода', 'Действие']);
      expect(result.first.types.map((t) => t.slug), ['pour', 'bloom']);
    });

    test('метод, не сказавший ничего, получает весь справочник', () {
      final result = reference.allowedFor(const []);

      expect(result.expand((group) => group.types), hasLength(4));
    });

    test('тип из группы, которой нет в клиенте, не теряется', () {
      final ahead = StepTypeReference(
        groups: groups,
        types: [type('pour', groupId: 1), type('dilute', groupId: 99)],
      );

      final result = ahead.allowedFor(const []);

      expect(result.map((group) => group.name), ['Вода', 'Прочие']);
      expect(result.last.types.single.slug, 'dilute');
    });

    test('«своё» не встаёт в сетку рядом с проливом', () {
      final withCustom = StepTypeReference(
        groups: groups,
        types: [type('pour', groupId: 1), type('custom', groupId: 2)],
      );

      final slugs = withCustom
          .allowedFor(['pour', 'custom'])
          .expand((group) => group.types)
          .map((t) => t.slug);

      expect(slugs, ['pour']);
    });

    test('поиск по ключу находит тип и молчит о незнакомом', () {
      expect(reference.bySlug('bloom')?.name, 'bloom');
      expect(reference.bySlug('custom'), isNull);
    });
  });
}
