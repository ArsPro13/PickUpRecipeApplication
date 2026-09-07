// Барабан длительности: крутится и отдаёт секунды.
//
// Проверяется то, ради чего барабан и заводили: поворот на одну позицию
// меняет значение ровно на единицу своего разряда. Барабан, который отдаёт
// минуты вместо секунд, портит рецепт молча — на вид он такой же.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/general_widgets/duration_wheel_sheet.dart';
import 'package:pick_up_recipe/src/pages/recipe_builder_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';

Widget _wheels(int seconds, void Function(int) onChanged) {
  return MaterialApp(
    theme: lightTheme,
    home: Scaffold(
      body: DurationWheels(seconds: seconds, onChanged: onChanged),
    ),
  );
}

/// Крутит барабан на [items] позиций вперёд.
///
/// Тащим ровно на высоту строки и без «броска»: одно движение пальца не даёт
/// скорости, и барабан встаёт на соседнее число, а не улетает по инерции.
Future<void> _spin(WidgetTester tester, int wheel, int items) async {
  await tester.drag(
    find.byType(ListWheelScrollView).at(wheel),
    Offset(0, -AppSizes.tapTarget * items),
    touchSlopY: 0,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('барабан минут и секунд', () {
    testWidgets('поворот секунд меняет секунды', (tester) async {
      var picked = 0;
      await tester.pumpWidget(_wheels(35, (value) => picked = value));

      await _spin(tester, 1, 5);

      expect(picked, 40);
    });

    testWidgets('поворот минут добавляет ровно минуту', (tester) async {
      var picked = 0;
      await tester.pumpWidget(_wheels(35, (value) => picked = value));

      await _spin(tester, 0, 1);

      expect(picked, 95);
    });

    testWidgets('барабан открывается на том, что было в рецепте', (tester) async {
      var picked = 0;
      await tester.pumpWidget(_wheels(160, (value) => picked = value));

      // 2:40 — минуты на двойке, секунды на сорока. Ничего не крутили,
      // значит и сообщать нечего.
      expect(find.text('2'), findsWidgets);
      expect(find.text('40'), findsWidgets);
      expect(picked, 0);

      // А сдвинули на одну секунду назад — приехало 2:39, а не 0:39.
      await _spin(tester, 1, -1);
      expect(picked, 159);
    });

    testWidgets('выбранное ложится в шаг секундами, а не минутами', (tester) async {
      // Ошибка в единице не видна глазом: барабан выглядит так же, а шаг
      // на полторы минуты уезжает в рецепт полутора часами.
      final target = RecipeStep(
        seqNum: 1,
        instruction: 'Пролив',
        water: 100,
        time: 35,
        id: 0,
        stepType: 'pour',
        stepKey: '',
        tip: '',
        isOptional: false,
        untilUser: false,
        untilSign: '',
        warning: '',
      );

      await tester.pumpWidget(_wheels(target.time, (value) => target.time = value));
      await _spin(tester, 0, 1);

      expect(target.time, 95);
      expect(formatDuration(target.time), '1:35');
    });
  });
}
