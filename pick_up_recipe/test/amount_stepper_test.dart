// Счётчик граммов: кнопки, границы и ускорение при зажатии.
//
// Всё здесь про то, чего не видно на скриншоте: одно нажатие должно давать
// ровно один грамм, зажатие — разгоняться, а край диапазона — держать. Ошибка
// в любом из трёх портит не вид, а рецепт.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/general_widgets/amount_stepper.dart';
import 'package:pick_up_recipe/src/general_widgets/app_icon.dart';
import 'package:pick_up_recipe/src/themes/app_icons.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';

/// Счётчик вместе с тем, кто хранит значение: без родителя, который принимает
/// изменение и возвращает его обратно, проверялась бы половина связки.
class _Host extends StatefulWidget {
  const _Host({required this.initial, this.min = 0, this.max = 9999});

  final int initial;
  final int min;
  final int max;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: Center(
          child: AmountStepper(
            value: value,
            min: widget.min,
            max: widget.max,
            suffix: 'г',
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      ),
    );
  }
}

Finder _button(String icon) => find.ancestor(
      of: find.byWidgetPredicate((widget) => widget is AppIcon && widget.asset == icon),
      matching: find.byType(InkWell),
    );

int _value(WidgetTester tester) => tester.state<_HostState>(find.byType(_Host)).value;

void main() {
  group('множитель зажатия', () {
    test('пока держат недолго — по одному, дальше крупнее', () {
      expect(holdFactor(Duration.zero), 1);
      expect(holdFactor(AppDuration.slow), 1);
      expect(holdFactor(AppDuration.ambient - AppDuration.instant), 1);
    });

    test('после вдоха шаг растёт, после двух — ещё раз', () {
      final middle = holdFactor(AppDuration.ambient);
      final fastest = holdFactor(AppDuration.ambient * 2);

      expect(middle, greaterThan(1));
      expect(fastest, greaterThan(middle));
    });
  });

  group('счётчик', () {
    testWidgets('плюс прибавляет грамм, минус убавляет', (tester) async {
      await tester.pumpWidget(const _Host(initial: 100));

      await tester.tap(_button(AppIcons.uiPlus));
      await tester.pump();
      expect(_value(tester), 101);

      await tester.tap(_button(AppIcons.uiMinus));
      await tester.pump();
      expect(_value(tester), 100);
    });

    testWidgets('одно нажатие — ровно один грамм, а не два', (tester) async {
      // Прибавка сделана на нажатии, а автоповтор начинается с задержкой:
      // без паузы обычный тап давал бы сразу два, и попасть в ровное число
      // стало бы нельзя.
      await tester.pumpWidget(const _Host(initial: 100));

      await tester.tap(_button(AppIcons.uiPlus));
      await tester.pump(AppDuration.fast);

      expect(_value(tester), 101);
    });

    testWidgets('на краю диапазона счётчик стоит', (tester) async {
      await tester.pumpWidget(const _Host(initial: 0, min: 0, max: 5));

      await tester.tap(_button(AppIcons.uiMinus));
      await tester.pump();
      expect(_value(tester), 0);

      for (var i = 0; i < 8; i++) {
        await tester.tap(_button(AppIcons.uiPlus));
        await tester.pump();
      }
      expect(_value(tester), 5);
    });

    testWidgets('зажатие разгоняется, а не идёт по грамму до утра', (tester) async {
      await tester.pumpWidget(const _Host(initial: 0, max: 9999));

      final gesture = await tester.startGesture(tester.getCenter(_button(AppIcons.uiPlus)));
      await tester.pump();

      await tester.pump(AppDuration.ambient);
      final firstBreath = _value(tester);

      await tester.pump(AppDuration.ambient);
      final secondBreath = _value(tester) - firstBreath;

      await gesture.up();
      await tester.pump();

      // Автоповтор пошёл…
      expect(firstBreath, greaterThan(1));
      // …и за вторую пригоршню времени набрал заметно больше, чем за первую.
      expect(secondBreath, greaterThan(firstBreath * 3));
    });

    testWidgets('отпустили — счётчик остановился', (tester) async {
      await tester.pumpWidget(const _Host(initial: 0));

      final gesture = await tester.startGesture(tester.getCenter(_button(AppIcons.uiPlus)));
      await tester.pump(AppDuration.ambient);
      await gesture.up();
      await tester.pump();

      final stopped = _value(tester);
      await tester.pump(AppDuration.ambient);

      expect(_value(tester), stopped);
    });

    testWidgets('число вводится руками: двести пятьдесят не набирают кнопками', (tester) async {
      await tester.pumpWidget(const _Host(initial: 100));

      await tester.tap(find.text('100 г'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '250');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(_value(tester), 250);
      expect(find.text('250 г'), findsOneWidget);
    });

    testWidgets('набранное доезжает до шага рецепта', (tester) async {
      // Конструктор связывает счётчик с водой шага ровно так же: значение
      // ложится в рецепт сразу, без «Готово» и без второго экрана.
      final target = RecipeStep(
        seqNum: 1,
        instruction: 'Пролив',
        water: 100,
        time: 30,
        id: 0,
        stepType: 'pour',
        stepKey: '',
        tip: '',
        isOptional: false,
        untilUser: false,
        untilSign: '',
        warning: '',
      );

      await tester.pumpWidget(MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AmountStepper(
              value: target.water,
              suffix: 'г',
              onChanged: (next) => setState(() => target.water = next),
            ),
          ),
        ),
      ));

      await tester.tap(_button(AppIcons.uiPlus));
      await tester.pump();
      await tester.tap(_button(AppIcons.uiPlus));
      await tester.pump();

      expect(target.water, 102);
    });

    testWidgets('счётчик умещается в строку карточки шага на 360 точках', (tester) async {
      await tester.pumpWidget(const _Host(initial: 250));

      // На узком экране строке шага достаётся 296 точек: 360 без полей
      // экрана (20 и 20) и карточки (12 и 12). Значку с подписью «Вода»
      // нужна примерно сотня — значит счётчику остаётся меньше двухсот,
      // иначе подпись переедет на вторую строку.
      expect(tester.getSize(find.byType(AmountStepper)).width, lessThan(200));
    });

    testWidgets('пустое поле не превращается в ноль граммов', (tester) async {
      // Очистить поле легко случайно, а ноль воды в проливе — потерянный
      // рецепт: прежнее значение должно остаться.
      await tester.pumpWidget(const _Host(initial: 100));

      await tester.tap(find.text('100 г'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(_value(tester), 100);
    });
  });
}
