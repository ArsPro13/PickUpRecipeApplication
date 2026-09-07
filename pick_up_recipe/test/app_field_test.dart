// Поле ввода общей формы: что человек видит, когда в поле не смотрит.
//
// Обе проверки здесь про покой, а не про ввод: набранный текст видно и так,
// а вот заполненная форма, к которой вернулись глазами, — это ровно те поля,
// в которых сейчас нет курсора.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/general_widgets/app_field.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';

/// Два поля рядом — как в любой форме входа: из первого уходят во второе.
Widget _twoFields(TextEditingController first, TextEditingController second) {
  return MaterialApp(
    theme: lightTheme,
    home: Scaffold(
      body: SizedBox(
        width: 200,
        child: Column(
          children: [
            AppField(label: 'Почта', controller: first),
            AppField(label: 'Пароль', controller: second),
          ],
        ),
      ),
    ),
  );
}

/// Прокрутка строки внутри поля. Своего контроллера у поля снаружи нет,
/// поэтому смотрим на ту прокрутку, которую EditableText показывает глазу.
ScrollPosition _lineOffset(WidgetTester tester, int index) {
  return tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(TextField).at(index),
          matching: find.byType(Scrollable),
        ),
      )
      .position;
}

void main() {
  testWidgets('уходя из поля, видим начало строки, а не хвост', (tester) async {
    final email = TextEditingController();
    final password = TextEditingController();
    addTearDown(email.dispose);
    addTearDown(password.dispose);

    await tester.pumpWidget(_twoFields(email, password));

    // Длинная почта: в 200 логических пикселей она не помещается, и поле,
    // пока в нём набирают, отмотано к концу — курсор всегда виден.
    await tester.enterText(
      find.byType(TextField).first,
      'andrey.shinkarenko.long.address@example-mail-server.com',
    );
    await tester.pumpAndSettle();
    expect(
      _lineOffset(tester, 0).pixels,
      greaterThan(0),
      reason: 'строка должна не помещаться, иначе проверять нечего',
    );

    // Человек ушёл в следующее поле.
    await tester.tap(find.byType(TextField).last);
    await tester.pumpAndSettle();

    expect(
      _lineOffset(tester, 0).pixels,
      0,
      reason: 'поле без фокуса показывает хвост почты вместо её начала',
    );
  });

  testWidgets('вернулись в поле — курсор снова виден', (tester) async {
    final email = TextEditingController();
    final password = TextEditingController();
    addTearDown(email.dispose);
    addTearDown(password.dispose);

    await tester.pumpWidget(_twoFields(email, password));

    await tester.enterText(
      find.byType(TextField).first,
      'andrey.shinkarenko.long.address@example-mail-server.com',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).last);
    await tester.pumpAndSettle();

    // Возврат в поле: отмотка к началу не должна оставаться прибитой —
    // человек продолжает дописывать с конца, и конец обязан быть виден.
    await tester.showKeyboard(find.byType(TextField).first);
    await tester.pumpAndSettle();

    expect(_lineOffset(tester, 0).pixels, greaterThan(0));
    expect(email.text, endsWith('example-mail-server.com'));
  });
}
