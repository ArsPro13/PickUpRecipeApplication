// Выбор окончания шага: три вещи, которые сломались у сегментов.
//
// Экран узкий по определению — 360 точек это половина живых телефонов, — и
// именно на нём «по признаку» переносилось с разрывом слова, выбранный
// вариант ничем не отличался от остальных, а надпись съезжала от галочки.
// Каждая из трёх бед проверяется отдельно: они независимы и чинятся по-разному.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/user_step_type_model.dart';
import 'package:pick_up_recipe/src/general_widgets/step_ending_choice.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';

/// Ширина узкого телефона. Форма живёт в полях экрана по 20 точек, но здесь
/// важна именно ширина устройства — от неё считается всё остальное.
const double _narrow = 360;

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  StepEndsWith value = StepEndsWith.timer;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: _narrow,
            child: StepEndingChoice(
              value: value,
              onChanged: (option) => setState(() => value = option),
            ),
          ),
        ),
      ),
    );
  }
}

/// Заливки карточек в том порядке, в каком они стоят на экране.
List<Color?> _fills(WidgetTester tester) {
  return tester
      .widgetList<Material>(
        find.descendant(
          of: find.byType(StepEndingChoice),
          matching: find.byType(Material),
        ),
      )
      .map((material) => material.color)
      .toList();
}

void main() {
  testWidgets('на 360 точках ни одна подпись не рвётся', (tester) async {
    await tester.pumpWidget(const _Host());

    // Высоты сравниваются между собой, а не с числом: перенос — это лишняя
    // строка, и она видна по тому, что подпись стала выше соседней.
    final short = tester.getSize(find.text('по кнопке')).height;

    for (final option in StepEndsWith.values) {
      expect(
        tester.getSize(find.text(option.label)).height,
        short,
        reason: option.label,
      );
    }
  });

  testWidgets('выбранный вариант отличается заливкой', (tester) async {
    await tester.pumpWidget(const _Host());

    final fills = _fills(tester);
    expect(fills, hasLength(StepEndsWith.values.length));

    // Выбрано первое: его заливка своя, остальные две — одинаковые.
    expect(fills[0], isNot(fills[1]));
    expect(fills[1], fills[2]);

    await tester.tap(find.text('по признаку'));
    await tester.pumpAndSettle();

    final after = _fills(tester);
    expect(after[2], isNot(after[1]));
    expect(after[0], after[1]);
    // И заливка выбранного — та же самая, просто переехала на третью карточку.
    expect(after[2], fills[0]);
  });

  testWidgets('текст не прыгает при выборе', (tester) async {
    await tester.pumpWidget(const _Host());

    final before = [
      for (final option in StepEndsWith.values) tester.getTopLeft(find.text(option.label)),
    ];

    await tester.tap(find.text('по признаку'));
    await tester.pumpAndSettle();

    final after = [
      for (final option in StepEndsWith.values) tester.getTopLeft(find.text(option.label)),
    ];

    expect(after, before);
  });

  testWidgets('у каждого варианта есть строка пояснения', (tester) async {
    await tester.pumpWidget(const _Host());

    for (final option in StepEndsWith.values) {
      expect(option.hint, isNotEmpty, reason: option.label);
      expect(find.text(option.hint), findsOneWidget, reason: option.label);
    }
  });

  testWidgets('нажатие отдаёт выбранный вариант', (tester) async {
    await tester.pumpWidget(const _Host());

    await tester.tap(find.text('по кнопке'));
    await tester.pumpAndSettle();

    expect(tester.state<_HostState>(find.byType(_Host)).value, StepEndsWith.user);
  });
}
