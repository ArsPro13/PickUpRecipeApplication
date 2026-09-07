// Шторка с правовым документом не должна поднимать за собой клавиатуру.
//
// Владелец описал это так: «при регистрации когда дергаю вниз слайдер
// просмотра политики обработки данных, то снова открывается клавиатура если
// она была установлена на ввод но скрыта». Причина не в шторке как таковой:
// модальный маршрут возвращает фокус тому, кто его держал до открытия, и для
// поля ввода возврат фокуса означает клавиатуру.
//
// Проверяется поведение, видимое человеку: поднялась клавиатура или нет и
// цел ли набранный текст. Про фокус тест спрашивает отдельно — это причина,
// по которой клавиатура возвращалась, и именно её легко сломать обратно.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/legal/domain/legal_document.dart';
import 'package:pick_up_recipe/src/general_widgets/legal_sheet.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';

/// Форма с полем и ссылкой на документ — то же сочетание, что на регистрации.
///
/// Ссылку открывает распознаватель нажатия, а не кнопка: на экране это часть
/// строки согласия, и фокус сам по себе с поля не уходит.
Widget _formWithLegalLink(TextEditingController controller, FocusNode focus) {
  return MaterialApp(
    theme: lightTheme,
    home: Scaffold(
      body: Builder(
        builder: (context) => Column(
          children: [
            TextField(controller: controller, focusNode: focus),
            GestureDetector(
              onTap: () => showLegalSheet(context, LegalKind.privacy),
              child: const Text('политика обработки данных'),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  late TextEditingController controller;
  late FocusNode focus;

  setUp(() {
    controller = TextEditingController();
    focus = FocusNode();
  });

  tearDown(() {
    controller.dispose();
    focus.dispose();
  });

  group('шторка политики', () {
    testWidgets('закрытие не поднимает спрятанную клавиатуру', (tester) async {
      await tester.pumpWidget(_formWithLegalLink(controller, focus));

      await tester.enterText(find.byType(TextField), 'me@example.com');
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);

      // Человек прячет клавиатуру системной кнопкой «назад»: она уходит, а
      // курсор остаётся в поле. Ровно в этом состоянии и открывают политику.
      tester.testTextInput.hide();
      expect(tester.testTextInput.isVisible, isFalse);

      await tester.tap(find.text('политика обработки данных'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsOneWidget, reason: 'лист не открылся');

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsNothing, reason: 'лист не закрылся');

      expect(
        tester.testTextInput.isVisible,
        isFalse,
        reason: 'клавиатура вернулась сама, хотя человек её прятал',
      );
      expect(focus.hasFocus, isFalse, reason: 'фокус вернулся в поле и позвал клавиатуру');
      expect(controller.text, 'me@example.com', reason: 'набранное потерялось');
    });

    testWidgets('лист, потянутый вниз, тоже не возвращает клавиатуру', (tester) async {
      await tester.pumpWidget(_formWithLegalLink(controller, focus));

      await tester.enterText(find.byType(TextField), 'me@example.com');
      await tester.pump();
      tester.testTextInput.hide();

      await tester.tap(find.text('политика обработки данных'));
      await tester.pumpAndSettle();

      // Жест владельца: тянем лист вниз, пока он не уедет за нижний край.
      await tester.drag(find.byIcon(Icons.close), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsNothing, reason: 'лист не закрылся жестом');

      expect(tester.testTextInput.isVisible, isFalse);
      expect(focus.hasFocus, isFalse);
      expect(controller.text, 'me@example.com');
    });

    testWidgets('открытая клавиатура уходит вместе с открытием листа', (tester) async {
      await tester.pumpWidget(_formWithLegalLink(controller, focus));

      await tester.enterText(find.byType(TextField), 'me@example.com');
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.tap(find.text('политика обработки данных'));
      await tester.pumpAndSettle();
      expect(
        tester.testTextInput.isVisible,
        isFalse,
        reason: 'клавиатура осталась под листом и закрывает документ',
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(controller.text, 'me@example.com');
    });
  });
}
