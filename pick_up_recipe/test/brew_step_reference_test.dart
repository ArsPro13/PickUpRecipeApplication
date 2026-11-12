// Значок и подсказка шага на экране заваривания — из справочника типов.
//
// Справочник владелец правит в кабинете: названия, значки, описания шагов.
// До 9 ноября 2026 экран заваривания брал значок по самому типу шага, а
// описания у типа не было вовсе — правка в кабинете до экрана не доходила.
//
// Проверяются две функции, через которые она теперь доходит, и то, что без
// справочника (нет сети, старый сервер) экран остаётся прежним.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/brew_step.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/step_type_model.dart';
import 'package:pick_up_recipe/src/pages/brew_page.dart';
import 'package:pick_up_recipe/src/themes/app_icons.dart';

BrewStep _step(BrewStepType type, {String tip = ''}) => BrewStep(
      id: 's1',
      type: type,
      label: 'Шаг',
      duration: const Duration(seconds: 30),
      tip: tip,
    );

StepType _type(String slug, {String iconKey = '', String description = ''}) =>
    StepType(
      id: slug.hashCode,
      slug: slug,
      name: slug,
      shortName: slug,
      iconKey: iconKey,
      groupId: 1,
      description: description,
    );

void main() {
  group('значок шага', () {
    test('тот, что владелец выбрал типу в кабинете', () {
      final reference = StepTypeReference(types: [
        _type('stir', iconKey: 'ui-refresh'),
        _type('wait', iconKey: 'serve'),
      ]);

      expect(brewStepIcon(_step(BrewStepType.stir), reference),
          AppIcons.uiRefresh);
      expect(brewStepIcon(_step(BrewStepType.wait), reference),
          AppIcons.stepServe);
    });

    test('справочник не приехал — по самому типу шага, как раньше', () {
      expect(brewStepIcon(_step(BrewStepType.stir), null), AppIcons.stepStir);
      expect(brewStepIcon(_step(BrewStepType.openValve), null),
          AppIcons.stepOpenValve);
    });

    test('типа в справочнике нет или значок у него не задан — по типу шага',
        () {
      final reference = StepTypeReference(types: [_type('stir')]);

      expect(
          brewStepIcon(_step(BrewStepType.stir), reference), AppIcons.stepStir,
          reason: 'пустой ключ значка — не повод рисовать «свой шаг»');
      expect(
          brewStepIcon(_step(BrewStepType.pour), reference), AppIcons.stepPour);
    });

    test('ключ, которого нет в наборе этой сборки, — значок своего шага', () {
      // Кабинет может знать значок, который появился в более новой сборке.
      final reference =
          StepTypeReference(types: [_type('stir', iconKey: 'ui-teleport')]);

      expect(brewStepIcon(_step(BrewStepType.stir), reference),
          AppIcons.stepCustom);
    });
  });

  group('подсказка шага', () {
    final reference = StepTypeReference(types: [
      _type('wait', description: 'Дайте воде пройти сквозь кофе.'),
      _type('custom', description: 'Шаг, который вы назвали сами.'),
      _type('pour'),
    ]);

    test('своя подсказка рецепта главнее описания типа', () {
      expect(
        brewStepHint(
            _step(BrewStepType.wait, tip: 'Накрой крышкой.'), reference),
        'Накрой крышкой.',
      );
    });

    test('подсказки в рецепте нет — описание типа из справочника', () {
      expect(brewStepHint(_step(BrewStepType.wait), reference),
          'Дайте воде пройти сквозь кофе.');
    });

    test('у типа нет описания — подсказки нет', () {
      expect(brewStepHint(_step(BrewStepType.pour), reference), isEmpty);
      expect(brewStepHint(_step(BrewStepType.stir), reference), isEmpty,
          reason: 'типа нет в справочнике');
    });

    test('справочник не приехал — только своя подсказка', () {
      expect(brewStepHint(_step(BrewStepType.wait), null), isEmpty);
      expect(
          brewStepHint(_step(BrewStepType.wait, tip: 'Ждём.'), null), 'Ждём.');
    });

    test('свой шаг общим описанием не подписывается', () {
      // Что это за шаг, сказано в его названии: общее «шаг, который вы
      // назвали сами» под «Смахнуть пыль с фильтра» было бы невпопад. Так же
      // записаны шаги старых рецептов — тип у них пуст.
      expect(brewStepHint(_step(BrewStepType.custom), reference), isEmpty);
      expect(
          brewStepHint(_step(BrewStepType.fromWire('')), reference), isEmpty);
    });
  });
}
