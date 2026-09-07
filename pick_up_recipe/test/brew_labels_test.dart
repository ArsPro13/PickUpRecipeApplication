// Надписи экрана заваривания, которые выбираются по шагу.
//
// Раньше их выбирал шаблон всего рецепта, и на шаге «пока не скажете сделал»
// вторая кнопка звалась «Пропустить» — то есть обещала выбросить шаг ровно
// там, где человек собирался его подтвердить.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/brew_step.dart';
import 'package:pick_up_recipe/src/pages/brew_page.dart';

BrewStep step({
  BrewStepType type = BrewStepType.pour,
  Duration duration = const Duration(seconds: 30),
  bool untilUser = false,
  String untilSign = '',
}) {
  return BrewStep(
    id: 's1',
    type: type,
    label: 'Шаг',
    duration: duration,
    untilUser: untilUser,
    untilSign: untilSign,
  );
}

void main() {
  group('надпись второй кнопки', () {
    test('на обычном шаге — «Пропустить»', () {
      expect(brewSkipLabel(step()), 'Пропустить');
    });

    test('на шаге по кнопке — «Пропустить», а не «Сделал»', () {
      // «Сделал» на этом шаге уже стоит на главной кнопке: две кнопки с
      // одинаковой надписью и разным исходом — худшее из возможного.
      expect(
        brewSkipLabel(step(untilUser: true, duration: Duration.zero)),
        'Пропустить',
      );
    });

    test('на шаге с признаком — «Случилось»', () {
      expect(brewSkipLabel(step(untilSign: 'пена поднялась')), 'Случилось');
    });

    test('на усилии руки — «Сделал»', () {
      expect(brewSkipLabel(step(type: BrewStepType.press)), 'Сделал');
      expect(brewSkipLabel(step(type: BrewStepType.invert)), 'Сделал');
      expect(brewSkipLabel(step(type: BrewStepType.flip)), 'Сделал');
    });

    test('шаг важнее шаблона: пролив в рецепте с отжимом остаётся пропуском', () {
      // Рецепт аэропресса целиком — «усилие», но шаг пролива в нём
      // кончается секундомером, и «Сделал» на нём врало бы.
      expect(brewSkipLabel(step(type: BrewStepType.pour)), 'Пропустить');
    });
  });
}
