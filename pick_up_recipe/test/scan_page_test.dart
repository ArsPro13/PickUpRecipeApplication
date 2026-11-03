// Экран «Код с пачки»: путь «на пачке нет кода» самый частый.
//
// Код печатают только наши обжарщики, а на полке у человека стоят чужие
// пачки — значит кнопка этого пути обязана быть на виду, а не под сгибом.
// Проверяется самый тесный экран, ради которого правку и делали: 360×640
// с нижней навигацией вкладок.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/pages/scan_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';

/// Роутер, который никуда не ведёт, а записывает, куда его просили: вопрос
/// тут не «нарисовался ли экран», а «какой экран открыли».
class _RecordingRouter extends RootStackRouter {
  final List<PageRouteInfo> pushed = [];

  @override
  List<AutoRoute> get routes => const [];

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    pushed.add(route);
    return null;
  }
}

void main() {
  /// Высота панели вкладок: экран живёт на вкладке, и панель забирает нижнюю
  /// полосу окна. В тесте её нет, поэтому она вычитается вручную.
  const navBar = AppSizes.tapTarget + AppSpacing.s4;

  Future<_RecordingRouter> pumpScan(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = _RecordingRouter();
    await tester.pumpWidget(MaterialApp(
      theme: lightTheme,
      // Экран берёт подписи из локали, поэтому делегаты нужны и здесь.
      // Язык задан прямо: проверяются русские подписи, а не системный язык
      // машины, на которой запустили тест.
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StackRouterScope(
        controller: router,
        stateHash: 0,
        child: const ScanPage(),
      ),
    ));
    // Не pumpAndSettle: полоса прицела бежит по кругу и не успокоится никогда.
    await tester.pump();

    return router;
  }

  group('код с пачки', () {
    testWidgets('кнопка «На пачке нет кода» видна на 360×640 без прокрутки',
        (tester) async {
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

    testWidgets('устройство проверки кода на экране не объясняется',
        (tester) async {
      await pumpScan(tester);

      expect(find.textContaining('контрольн'), findsNothing);
      expect(find.textContaining('к серверу'), findsNothing);
    });

    testWidgets('кода руками не вводят: поля и кнопки под него нет',
        (tester) async {
      // Владелец: код будет маленьким QR в углу пачки, «не надо никакой код
      // вводить руками, убери этот блок».
      await pumpScan(tester);

      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('руками'), findsNothing);
      expect(find.text('Открыть рецепт'), findsNothing);
    });

    // Владелец 2 ноября 2026: «при клике, чтобы сканировать, перекидывает в
    // обычное поле ввода информации о пачке». Кадр и кнопка вели в одну и
    // ту же форму — сканера за кадром не было.
    testWidgets('кадр открывает сканер, а не форму пачки', (tester) async {
      final router = await pumpScan(tester);

      await tester.tap(find.text('нажмите, чтобы навести'));
      await tester.pump();

      expect(router.pushed.single.routeName, CodeScannerRoute.name);
    });

    testWidgets('«На пачке нет кода» ведёт в форму пачки', (tester) async {
      final router = await pumpScan(tester);

      await tester.tap(find.text('На пачке нет кода'));
      await tester.pump();

      expect(router.pushed.single.routeName, RecognitionCameraRoute.name);
    });

    testWidgets('подписи «Код мелкий» больше нет — под кадром сказано, '
        'что даст скан', (tester) async {
      await pumpScan(tester);

      expect(find.textContaining('мелкий'), findsNothing);
      expect(find.textContaining('в углу пачки'), findsNothing);
      expect(
        find.text('QR-код с пачки откроет рецепты для этого кофе'),
        findsOneWidget,
      );
    });
  });
}
