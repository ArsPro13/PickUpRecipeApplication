// Экран «Код с пачки»: путь «на пачке нет кода» самый частый.
//
// Код печатают только наши обжарщики, а на полке у человека стоят чужие
// пачки — значит кнопка этого пути обязана быть на виду, а не под сгибом.
// Проверяется самый тесный экран, ради которого правку и делали: 360×640
// с нижней навигацией вкладок.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/pages/scan_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';

void main() {
  /// Высота панели вкладок: экран живёт на вкладке, и панель забирает нижнюю
  /// полосу окна. В тесте её нет, поэтому она вычитается вручную.
  const navBar = AppSizes.tapTarget + AppSpacing.s4;

  Future<void> pumpScan(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: lightTheme, home: const ScanPage()));
    // Не pumpAndSettle: полоса прицела бежит по кругу и не успокоится никогда.
    await tester.pump();
  }

  group('код с пачки', () {
    testWidgets('кнопка «На пачке нет кода» видна на 360×640 без прокрутки', (tester) async {
      await pumpScan(tester);

      final button = find.text('На пачке нет кода');
      expect(button, findsOneWidget);
      expect(
        tester.getRect(button).bottom,
        lessThanOrEqualTo(640 - navBar),
        reason: 'кнопка уехала под сгиб — рисунок-подсказка снова вырос',
      );
    });

    testWidgets('она коричневая, как главное действие', (tester) async {
      await pumpScan(tester);

      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('На пачке нет кода'),
          matching: find.byType(ElevatedButton),
        ),
      );

      expect(
        button.style?.backgroundColor?.resolve(const {}),
        lightTheme.colorScheme.primary,
      );
    });

    testWidgets('устройство проверки кода на экране не объясняется', (tester) async {
      await pumpScan(tester);

      expect(find.textContaining('контрольн'), findsNothing);
      expect(find.textContaining('к серверу'), findsNothing);
    });
  });
}
