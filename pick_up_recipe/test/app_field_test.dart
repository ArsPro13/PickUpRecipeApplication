// Поле ввода общей формы: что человек видит, когда в поле не смотрит.
//
// Обе проверки здесь про покой, а не про ввод: набранный текст видно и так,
// а вот заполненная форма, к которой вернулись глазами, — это ровно те поля,
// в которых сейчас нет курсора.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/general_widgets/app_field.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';

/// Два поля рядом — как в любой форме входа: из первого уходят во второе.
Widget _twoFields(TextEditingController first, TextEditingController second) {
  return MaterialApp(
    theme: lightTheme,
    // Глаз у поля пароля подписан из словаря, поэтому делегаты нужны и здесь.
    // Язык задан прямо: проверяются русские подписи, а не системный язык
    // машины, на которой запустили тест.
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
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

/// Одно поле — для проверок оформления, где второе только мешает.
Widget _oneField(TextEditingController controller, {String? error}) {
  return MaterialApp(
    theme: lightTheme,
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: 200,
        child: AppField(label: 'Название', controller: controller, error: error),
      ),
    ),
  );
}

/// Рамка поля: её рисует контейнер вокруг строки, а не сам TextField.
BorderSide _frame(WidgetTester tester) {
  final box = tester.widget<Container>(
    find
        .ancestor(of: find.byType(TextField).first, matching: find.byType(Container))
        .first,
  );

  return ((box.decoration! as BoxDecoration).border! as Border).top;
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

  testWidgets('в покое рамка видима', (tester) async {
    final name = TextEditingController();
    addTearDown(name.dispose);

    await tester.pumpWidget(_oneField(name));

    final frame = _frame(tester);

    // Пустое поле без фокуса — это то, что человек видит, открыв экран
    // «Свой тип шага». Прозрачная рамка оставляла на месте поля полосу фона.
    expect(frame.color.a, greaterThan(0), reason: 'поле сливается с фоном');
    expect(frame.color, lightTheme.extension<AppColors>()!.border);
    expect(frame.width, AppStroke.thin, reason: 'форма из полей не должна стать решёткой');
  });

  testWidgets('покой, фокус и ошибка различимы', (tester) async {
    final name = TextEditingController();
    addTearDown(name.dispose);

    await tester.pumpWidget(_oneField(name));
    final calm = _frame(tester);

    await tester.showKeyboard(find.byType(TextField).first);
    await tester.pump();
    final focused = _frame(tester);

    await tester.pumpWidget(_oneField(name, error: 'Название не может быть пустым'));
    await tester.pump();
    final broken = _frame(tester);

    // Три состояния — три разных ответа. Совпади любые два, и рамка
    // перестанет что-либо сообщать: «поле есть», «пишут сюда», «здесь беда».
    expect(calm.color, isNot(focused.color));
    expect(calm.color, isNot(broken.color));
    expect(focused.color, isNot(broken.color));

    // Работа и беда весомее покоя не только цветом: цвет не единственное,
    // чем человек различает состояния.
    expect(focused.width, greaterThan(calm.width));
    expect(broken.width, greaterThan(calm.width));
  });
}
