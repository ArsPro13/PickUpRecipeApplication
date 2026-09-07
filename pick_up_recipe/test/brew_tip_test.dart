// Длинная подсказка шага раскрывается целиком.
//
// На экране заваривания подсказка стояла в одну строку с многоточием, и
// «Воронка должна опустеть примерно к 2:45. Д…» обрывалась ровно там, где
// начиналось полезное. Кнопка-шеврон появляется только у той подсказки,
// которая правда не влезла: у короткой лишний элемент — шум.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/pages/brew_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';

const _long = 'Воронка должна опустеть примерно к 2:45. Дальше начинается '
    'перелив, и в чашке появляется горечь.';
const _short = 'Лей от центра';

const _expand = 'Показать подсказку целиком';
const _collapse = 'Свернуть подсказку';

Future<void> pumpTip(
  WidgetTester tester,
  String text, {
  bool alwaysOpen = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: BrewStepTip(text: text, alwaysOpen: alwaysOpen),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('подсказка шага', () {
    testWidgets('длинная раскрывается и сворачивается обратно', (tester) async {
      await pumpTip(tester, _long);

      expect(find.byTooltip(_expand), findsOneWidget);
      expect(tester.widget<Text>(find.text(_long)).maxLines, 1);
      final collapsed = tester.getSize(find.byType(BrewStepTip)).height;

      await tester.tap(find.byTooltip(_expand));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.text(_long)).maxLines, isNull,
          reason: 'раскрытая подсказка не ограничена строкой');
      expect(tester.getSize(find.byType(BrewStepTip)).height,
          greaterThan(collapsed));
      expect(find.byTooltip(_collapse), findsOneWidget);

      await tester.tap(find.byTooltip(_collapse));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.text(_long)).maxLines, 1);
      expect(tester.getSize(find.byType(BrewStepTip)).height, collapsed);
    });

    testWidgets('у короткой кнопки нет', (tester) async {
      await pumpTip(tester, _short);

      expect(find.text(_short), findsOneWidget);
      expect(find.byTooltip(_expand), findsNothing,
          reason: 'подсказка влезла целиком — раскрывать нечего');
    });

    testWidgets('у текущего шага раскрыта сразу и без кнопки', (tester) async {
      await pumpTip(tester, _long, alwaysOpen: true);

      expect(tester.widget<Text>(find.text(_long)).maxLines, isNull);
      expect(find.byTooltip(_expand), findsNothing,
          reason: 'она и так раскрыта: шеврону нечего делать');
    });
  });
}
