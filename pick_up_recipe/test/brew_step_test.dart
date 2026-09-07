// Предикат «шаг ждёт человека» — один на экран заваривания и конструктор.
//
// Проверяется не формула, а обещание: на любой вариант завершения шага оба
// экрана получают один и тот же ответ. Пока это так, шаг, заведённый как «по
// кнопке», не промотается в плеере сам; разойдись условия — и заметит это
// только человек посреди пролива, а не тест.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/brew_step.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/user_step_type_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/step_ending.dart';

/// Шаг конструктора: те же данные, что придут с сервера.
RecipeStep _recipeStep({
  String stepType = 'pour',
  int time = 30,
  int water = 0,
  bool untilUser = false,
  String untilSign = '',
}) {
  return RecipeStep(
    seqNum: 1,
    instruction: 'Пролив',
    water: water,
    time: time,
    id: 1,
    stepType: stepType,
    stepKey: 's1',
    tip: '',
    isOptional: false,
    untilUser: untilUser,
    untilSign: untilSign,
    warning: '',
  );
}

/// Тот же шаг, каким его увидит плеер.
BrewStep _brewStep(RecipeStep step) {
  return BrewStep.fromResponse(
    seqNum: step.seqNum,
    instruction: step.instruction,
    timeSec: step.time,
    waterMl: step.water,
    stepType: step.stepType,
    stepKey: step.stepKey,
    untilUser: step.untilUser,
    untilSign: step.untilSign,
  );
}

void main() {
  group('чем заканчивается шаг', () {
    test('таймер — единственный вариант без человека', () {
      // Перебором по values, а не тремя строчками: новый вариант завершения
      // не проскочит мимо этого решения молча.
      for (final ending in StepEndsWith.values) {
        expect(
          ending.endsByHuman,
          ending != StepEndsWith.timer,
          reason: 'вариант «${ending.label}» ответил не то',
        );
        expect(ending.showsDuration, !ending.endsByHuman);
      }
    });

    test('признак — тоже человек', () {
      // «Пока воронка не опустеет» приложение не увидит: конец шага заметит
      // тот, кто на него смотрит.
      expect(StepEndsWith.none.endsByHuman, isTrue);
      expect(_recipeStep(untilSign: 'пока воронка не опустеет').endsByHuman, isTrue);
    });

    test('свой тип шага отвечает тем же', () {
      for (final ending in StepEndsWith.values) {
        final type = UserStepType(id: 1, brewMethodId: 2, label: 'Продуть', endsWith: ending);

        expect(type.endsByHuman, ending.endsByHuman);
        expect(type.showsDuration, ending.showsDuration);
      }

      // Вода у заготовки — отдельный признак: по умолчанию свой шаг её не
      // считает, для воды есть пролив.
      expect(
        const UserStepType(id: 1, brewMethodId: 2, label: 'Продуть').showsWater,
        isFalse,
      );
      expect(
        const UserStepType(id: 1, brewMethodId: 2, label: 'Долить', hasWater: true).showsWater,
        isTrue,
      );
    });
  });

  // Одинаково оба экрана отвечают про то, кто заканчивает шаг. Про длительность
  // и воду ответы расходятся намеренно: конструктор решает, есть ли смысл
  // вводить значение, плеер — есть ли смысл его показывать. Подробности в
  // step_ending.dart; проверки ролей — в группах ниже.
  group('кто заканчивает шаг — оба экрана отвечают одинаково', () {
    // Все четыре сочетания признаков завершения: ни одного, кнопка, признак,
    // и то и другое сразу — так рецепт приходит с сервера.
    final endings = [
      (untilUser: false, untilSign: ''),
      (untilUser: true, untilSign: ''),
      (untilUser: false, untilSign: 'пока не осядет пена'),
      (untilUser: true, untilSign: 'пока не осядет пена'),
    ];

    for (final ending in endings) {
      test('untilUser=${ending.untilUser}, признак=«${ending.untilSign}»', () {
        final step = _recipeStep(
          water: 60,
          untilUser: ending.untilUser,
          untilSign: ending.untilSign,
        );
        final played = _brewStep(step);

        expect(played.endsByHuman, step.endsByHuman);

        expect(step.endsByHuman, ending.untilUser || ending.untilSign.isNotEmpty);
      });
    }
  });

  group('длительность', () {
    test('у шага по таймеру показывается всегда', () {
      // В конструкторе поле нужно и у пустого шага: иначе время некуда ввести.
      expect(_recipeStep(time: 0).showsDuration, isTrue);
      expect(_recipeStep(time: 45).showsDuration, isTrue);
    });

    test('у шага, который ждёт человека, её нет и с заданным временем', () {
      // Ровно то, на что жаловался владелец: у шага «смахнуть пыль и нажать»
      // стояло 0:09. Значение из рецепта не девается никуда — просто не
      // показывается там, где ничего не решает.
      expect(_recipeStep(time: 0, untilUser: true).showsDuration, isFalse);
      expect(_recipeStep(time: 90, untilUser: true).showsDuration, isFalse);
      expect(_recipeStep(time: 90, untilSign: 'пока не осядет пена').showsDuration, isFalse);
    });
  });

  group('вода', () {
    test('её принимают ровно четыре типа', () {
      const withWater = {
        BrewStepType.bloom,
        BrewStepType.pour,
        BrewStepType.addIce,
        BrewStepType.dilute,
      };

      for (final type in BrewStepType.values) {
        expect(
          _recipeStep(stepType: type.wireName).showsWater,
          withWater.contains(type),
          reason: 'тип ${type.wireName} ответил про воду не то',
        );
      }
    });

    test('у своего шага воды нет', () {
      expect(_recipeStep(stepType: 'custom').showsWater, isFalse);
      expect(_brewStep(_recipeStep(stepType: 'custom')).showsWater, isFalse);
    });

    test('исторический шаг: воду решает тип, а не проставленное значение', () {
      // У рецептов до формата v1 тип пустой, то есть «свой шаг», и плеер воду
      // такому шагу обнуляет. Показать граммы в конструкторе значило бы
      // обещать пролив, которого не будет.
      expect(_recipeStep(stepType: '', water: 40).showsWater, isFalse);
      expect(_recipeStep(stepType: 'pour', water: 0).showsWater, isTrue);
    });
  });
}
