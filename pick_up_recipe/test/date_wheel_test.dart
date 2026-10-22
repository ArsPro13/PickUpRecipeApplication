// Барабан даты: недопустимой даты на нём не набрать.
//
// Маска дд.мм.гггг пропускала «31.04» до самой проверки, а будущую дату —
// до сервера, где та молча становилась сегодняшней. Барабан обязан не
// выпустить ни то, ни другое: тридцать первое в апреле и завтрашний день
// бледные, и остановиться на них нельзя — барабан отъедет к допустимой дате.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/general_widgets/app_wheel.dart';
import 'package:pick_up_recipe/src/general_widgets/date_wheel_sheet.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';

/// Барабан с запоминанием последнего ответа.
Future<List<DateTime>> _pump(
  WidgetTester tester, {
  required DateTime initial,
  required DateTime latest,
  Locale locale = const Locale('ru'),
}) async {
  final answers = <DateTime>[];
  await tester.pumpWidget(MaterialApp(
    theme: lightTheme,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: DateWheels(
        initial: initial,
        latest: latest,
        onChanged: answers.add,
      ),
    ),
  ));
  return answers;
}

/// Крутит колонку на [items] строк вперёд — с порогом пальца, как в тесте
/// барабана длительности.
Future<void> _spin(WidgetTester tester, int column, int items) async {
  final distance = kWheelItemExtent * items;
  await tester.drag(
    find.byType(ListWheelScrollView).at(column),
    Offset(0, -(distance + distance.sign * kDragSlopDefault)),
  );
  await tester.pumpAndSettle();
}

int _selected(WidgetTester tester, int column) {
  final wheel = tester
      .widget<ListWheelScrollView>(find.byType(ListWheelScrollView).at(column));
  return (wheel.controller! as FixedExtentScrollController).selectedItem;
}

void main() {
  group('допустимая дата', () {
    final latest = DateTime(2026, 10, 22);

    test('будущего нет: дальше сегодняшнего барабан не пускает', () {
      expect(settleDate(DateTime(2026, 12, 31), latest: latest), latest);
      expect(settleDate(DateTime(2026, 10, 23), latest: latest), latest);
      expect(settleDate(DateTime(2026, 10, 21), latest: latest),
          DateTime(2026, 10, 21));
    });

    test('двадцать девятое февраля в невисокосный год — двадцать восьмое', () {
      // 2020 старше барабана и поднимается до 2021-го, а в нём февраль
      // короче: двадцать девятого там нет.
      expect(settleDate(DateTime(2020, 2, 29), latest: latest),
          DateTime(2021, 2, 28));
    });

    test('год старше барабана поднимается до первого его года', () {
      expect(settleDate(DateTime(2001, 5, 9), latest: latest),
          DateTime(2021, 5, 9));
    });
  });

  group('колонки', () {
    testWidgets('31 марта плюс месяц — это 30 апреля, а не 1 мая',
        (tester) async {
      final answers = await _pump(
        tester,
        initial: DateTime(2026, 3, 31),
        latest: DateTime(2026, 10, 22),
      );

      // По-русски колонки: число, месяц, год.
      await _spin(tester, 1, 1);

      expect(answers.last, DateTime(2026, 4, 30));
      // И сама колонка чисел доехала до тридцатого: барабан не стоит на
      // бледном тридцать первом.
      expect(_selected(tester, 0) % 31, 29);
    });

    testWidgets('поворот в будущее возвращается к сегодняшнему дню',
        (tester) async {
      final answers = await _pump(
        tester,
        initial: DateTime(2026, 10, 20),
        latest: DateTime(2026, 10, 22),
      );

      await _spin(tester, 0, 5);

      expect(answers.last, DateTime(2026, 10, 22));
      expect(_selected(tester, 0) % 31, 21);
    });

    testWidgets('по-английски месяц стоит впереди числа', (tester) async {
      await _pump(
        tester,
        initial: DateTime(2026, 10, 22),
        latest: DateTime(2026, 10, 22),
        locale: const Locale('en'),
      );

      final month = tester.getCenter(find.text('October'));
      final day = tester.getCenter(find.text('22').first);
      expect(month.dx, lessThan(day.dx));
    });
  });
}
