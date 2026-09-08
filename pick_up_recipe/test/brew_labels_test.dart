// Надписи экрана заваривания, которые выбираются по шагу.
//
// Раньше их выбирал шаблон всего рецепта, и на шаге «пока не скажете сделал»
// вторая кнопка звалась «Пропустить» — то есть обещала выбросить шаг ровно
// там, где человек собирался его подтвердить.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
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
  // Надписи приходят из словаря: тот же выбор на английском экране даёт
  // «Skip» и «It happened».
  late AppLocalizations ru;

  setUpAll(() async {
    ru = await AppLocalizations.delegate.load(const Locale('ru'));
  });

  group('надпись второй кнопки', () {
    test('на обычном шаге — «Пропустить»', () {
      expect(brewSkipLabel(ru, step()), 'Пропустить');
    });

    test('на шаге по кнопке — «Пропустить», а не «Сделал»', () {
      // «Сделал» на этом шаге уже стоит на главной кнопке: две кнопки с
      // одинаковой надписью и разным исходом — худшее из возможного.
      expect(
        brewSkipLabel(ru, step(untilUser: true, duration: Duration.zero)),
        'Пропустить',
      );
    });

    test('на шаге с признаком — «Случилось»', () {
      expect(brewSkipLabel(ru, step(untilSign: 'пена поднялась')), 'Случилось');
    });

    test('на усилии руки — «Сделал»', () {
      expect(brewSkipLabel(ru, step(type: BrewStepType.press)), 'Сделал');
      expect(brewSkipLabel(ru, step(type: BrewStepType.invert)), 'Сделал');
      expect(brewSkipLabel(ru, step(type: BrewStepType.flip)), 'Сделал');
    });

    test('шаг важнее шаблона: пролив в рецепте с отжимом остаётся пропуском', () {
      // Рецепт аэропресса целиком — «усилие», но шаг пролива в нём
      // кончается секундомером, и «Сделал» на нём врало бы.
      expect(brewSkipLabel(ru, step(type: BrewStepType.pour)), 'Пропустить');
    });
  });

  group('метка на месте таймера', () {
    test('у шага по кнопке вместо «0:00» видно, чем он кончается', () {
      expect(
        brewStepEndNote(ru, step(untilUser: true, duration: Duration.zero)),
        'по кнопке',
      );
    });

    test('признак важнее кнопки: он и есть ответ «когда»', () {
      expect(
        brewStepEndNote(ru, step(
          untilUser: true,
          untilSign: 'воронка опустела',
          duration: Duration.zero,
        )),
        'по признаку',
      );
    });

    test('у шага со временем метки нет — там стоит время', () {
      expect(brewStepEndNote(ru, step()), isEmpty);
      expect(brewStepEndNote(ru, step(untilSign: 'пена поднялась')), isEmpty,
          reason: 'признак — ориентир, но таймер у шага настоящий');
    });
  });
}
