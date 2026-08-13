// Шаблон экрана заваривания выбирается по вопросу «когда шаг закончился»,
// а не по группе прибора. Проверяем границы на двадцати методах базы:
// именно они разложены по шаблонам в design/night4/brew.js.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/brew_template.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';

RecipeData _recipe(String device, int time, List<String> stepTypes) {
  return RecipeData(
    id: 1,
    device: device,
    date: '',
    packId: 0,
    grinderId: 0,
    grindStep: '',
    grindSubStep: null,
    water: 250,
    time: time,
    temperature: 93,
    load: 15,
    title: '',
    notes: '',
    grindDescriptor: 'medium',
    agitationLevel: null,
    steps: [
      for (final (index, type) in stepTypes.indexed)
        RecipeStep(
          id: index,
          seqNum: index,
          instruction: type,
          water: 0,
          time: 30,
          stepType: type,
          stepKey: '',
          tip: '',
          isOptional: false,
          untilUser: false,
          untilSign: '',
          warning: '',
        ),
    ],
  );
}

void main() {
  group('resolveBrewTemplate', () {
    test('воронка — опорный пролив', () {
      expect(
        resolveBrewTemplate(_recipe('hario_v60', 165, ['bloom', 'pour', 'wait'])),
        BrewTemplate.pour,
      );
    });

    test('клапан главнее пролива: шаг живёт пять секунд, состояние — минуту', () {
      expect(
        resolveBrewTemplate(
          _recipe('hario_switch', 185, ['close_valve', 'bloom', 'pour', 'open_valve']),
        ),
        BrewTemplate.valve,
      );
    });

    test('отжим и переворот — усилие', () {
      expect(
        resolveBrewTemplate(_recipe('aeropress', 130, ['pour', 'stir', 'wait', 'press'])),
        BrewTemplate.press,
      );
      expect(
        resolveBrewTemplate(
          _recipe('aeropress_inverted', 135, ['invert', 'pour', 'flip', 'press']),
        ),
        BrewTemplate.press,
      );
    });

    test('давление без отжима — по признаку: мока и перколятор', () {
      expect(
        resolveBrewTemplate(
          _recipe('moka', 300, ['grind', 'pour', 'wait']),
          methodGroup: 'pressure',
        ),
        BrewTemplate.cue,
      );
    });

    test('турка — по признаку, хотя группа у неё иммерсия', () {
      expect(
        resolveBrewTemplate(
          _recipe('cezve', 275, ['pour', 'stir', 'wait']),
          methodGroup: 'immersion',
        ),
        BrewTemplate.cue,
      );
    });

    test('эспрессо-семейство — выстрел: вода это выход в чашке', () {
      expect(
        resolveBrewTemplate(
          _recipe('espresso', 67, ['grind', 'pour', 'serve']),
          waterMeaning: 'in_cup',
          methodGroup: 'pressure',
        ),
        BrewTemplate.shot,
      );
    });

    test('дольше часа — часы, что бы ни было в шагах', () {
      expect(
        resolveBrewTemplate(
          _recipe('cold_brew', 43410, ['pour', 'stir', 'wait', 'remove_filter']),
          methodGroup: 'cold',
        ),
        BrewTemplate.long,
      );
    });
  });
}
