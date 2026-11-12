// Карта вкуса под пальцем.
//
// Владелец написал: «не получается пальцем из стартовой точки двигать этот
// ползунок». Причин было четыре, и каждая здесь закрыта своим тестом: ручки
// в центре не было вовсе, вертикаль забирала прокрутка страницы, вбок карта
// просыпалась только через порог, а ручка вставала не под пальцем.
//
// Проверяется тестом, а не только на телефоне: спор карты с прокруткой —
// это правила, а правило, которое никто не проверяет, тихо ломается при
// следующей правке соседнего виджета. Поэтому карта здесь стоит так же, как
// на экране оценки, — в длинном прокручиваемом списке.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/taste_map.dart';
import 'package:pick_up_recipe/src/general_widgets/taste_map_view.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';

/// Страница с картой: что на ней сейчас и что карта успела сказать.
class _Page {
  _Page(this.point);

  TastePoint point;

  /// Всё, что карта сообщила наружу, по порядку.
  final List<TastePoint> heard = [];

  final ScrollController scroll = ScrollController();

  /// Перерисовать страницу — так точку двигают снаружи, мимо карты.
  late StateSetter refresh;
}

/// Сторона карты и сколько над ней пустого места.
const double _side = 400;
const double _above = 100;

/// Радиус круга: те же 76% от половины стороны, что и на холсте.
const double _field = _side / 2 * 0.76;

/// Место на круге → место на экране. На круге вверх — «крепко».
Offset _at(double dx, double dy) =>
    const Offset(_side / 2, _above + _side / 2) + Offset(dx, -dy) * _field;

Offset _atPlace(Offset place) => _at(place.dx, place.dy);

/// Где ручка нарисована прямо сейчас — место на круге.
Offset _knob(WidgetTester tester) {
  final canvas = tester.widget<CustomPaint>(find.byKey(TasteMap.knobKey));
  return (canvas.painter! as TasteKnobPainter).at;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Ставит карту в прокручиваемую страницу. [scrollable] — есть ли странице
  /// куда прокручиваться: под картой либо два экрана пустоты, либо ничего.
  Future<_Page> pumpMap(
    WidgetTester tester, {
    TastePoint start = TastePoint.center,
    bool scrollable = true,
  }) async {
    tester.view.physicalSize = const Size(_side, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final page = _Page(start);
    addTearDown(page.scroll.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              page.refresh = setState;

              return ListView(
                controller: page.scroll,
                children: [
                  const SizedBox(height: _above),
                  TasteMap(
                    point: page.point,
                    onChanged: (next) => setState(() {
                      page.point = next;
                      page.heard.add(next);
                    }),
                  ),
                  if (scrollable) const SizedBox(height: 2000),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return page;
  }

  group('ручка', () {
    testWidgets('видна с самого начала и стоит в центре — тянуть есть что',
        (tester) async {
      await pumpMap(tester);

      expect(_knob(tester), Offset.zero);

      // Не просто «стоит», а нарисована: раньше в центре холст выходил, не
      // дойдя до ручки, и подпись «тяните точку» просила тянуть пустоту.
      expect(
        find.byKey(TasteMap.knobKey),
        paints
          ..circle(x: _side / 2, y: _side / 2, radius: 20)
          ..circle(x: _side / 2, y: _side / 2, radius: 11)
          ..circle(
            x: _side / 2,
            y: _side / 2,
            radius: 9,
            color: lightTheme.colorScheme.primary,
          ),
      );
    });

    testWidgets('идёт за пальцем с первого движения и вниз — страница стоит',
        (tester) async {
      final page = await pumpMap(tester);

      final finger = await tester.startGesture(_at(0, 0));
      await tester.pump();

      // Три точки — меньше любого порога, после которого жест считается
      // движением. Ручка уже идёт.
      await finger.moveBy(const Offset(0, 3));
      await tester.pump();
      expect(_knob(tester).dy, closeTo(-3 / _field, 1e-9));

      await finger.moveBy(const Offset(0, 73));
      await tester.pump();

      expect(page.point.x, 0);
      expect(page.point.y, closeTo(-0.5, 1e-9));
      expect(page.scroll.offset, 0, reason: 'прокрутка забрала палец');

      await finger.up();
      await tester.pumpAndSettle();
      expect(page.point.summaryRu, 'Заметно слабо');
    });

    testWidgets('идёт и вверх, и вбок, и наискосок', (tester) async {
      final page = await pumpMap(tester);

      for (final way in const [
        Offset(0, -60),
        Offset(60, 0),
        Offset(-60, 0),
        Offset(45, 45),
        Offset(-45, -45),
      ]) {
        page.refresh(() => page.point = TastePoint.center);
        await tester.pumpAndSettle();

        final finger = await tester.startGesture(_at(0, 0));
        await finger.moveBy(way);
        await tester.pump();

        expect(
          _atPlace(_knob(tester)),
          within(distance: 1e-6, from: _at(0, 0) + way),
          reason: 'ручка не под пальцем после движения на $way',
        );

        await finger.up();
        await tester.pumpAndSettle();
      }

      expect(page.scroll.offset, 0);
    });

    testWidgets('взятая с краю не прыгает серединой под палец', (tester) async {
      final page = await pumpMap(tester, start: const TastePoint(0.5, 0));

      // Палец лёг на двадцать точек правее ручки — и ручка остаётся на те
      // же двадцать точек левее пальца, пока её ведут.
      final finger =
          await tester.startGesture(_at(0.5, 0) + const Offset(20, 0));
      await tester.pump();
      expect(page.heard, isEmpty, reason: 'касание уже сдвинуло оценку');

      await finger.moveBy(const Offset(0, -30));
      await tester.pump();

      expect(_knob(tester).dx, closeTo(0.5, 1e-9));
      expect(_knob(tester).dy, closeTo(30 / _field, 1e-9));

      await finger.up();
      await tester.pumpAndSettle();
    });

    testWidgets('за край круга не выходит, а у края по диагонали — «сильно»',
        (tester) async {
      final page = await pumpMap(tester);

      final finger = await tester.startGesture(_at(0, 0));
      await finger.moveBy(const Offset(-400, 400));
      await tester.pump();

      expect(_knob(tester).distance, closeTo(1, 1e-9));
      expect(page.point.summaryRu, 'Сильно кисло, сильно слабо');

      await finger.up();
      await tester.pumpAndSettle();
    });

    testWidgets('отпущенная внутри цели встаёт ровно в центр', (tester) async {
      final page = await pumpMap(tester, start: const TastePoint(0.5, 0));

      final finger = await tester.startGesture(_at(0.5, 0));
      await finger.moveBy(const Offset(-0.5 * _field + 6, 6));
      await tester.pump();

      // Пока палец на карте, ручка стоит под ним, а не в центре.
      expect(page.point.isCenter, isTrue);
      expect(page.point, isNot(TastePoint.center));

      await finger.up();
      await tester.pumpAndSettle();

      expect(page.point, TastePoint.center);
      expect(_knob(tester), Offset.zero);
    });
  });

  group('нажатие', () {
    testWidgets('ставит ручку ровно туда, куда нажали', (tester) async {
      final page = await pumpMap(tester);

      await tester.tapAt(_at(0.5, 0.25));
      await tester.pumpAndSettle();

      expect(page.heard, hasLength(1));
      expect(_knob(tester).dx, closeTo(0.5, 1e-9));
      expect(_knob(tester).dy, closeTo(0.25, 1e-9));
    });

    testWidgets('ручка доезжает до места, а оценка меняется сразу',
        (tester) async {
      final page = await pumpMap(tester);

      await tester.tapAt(_at(0.8, 0));
      await tester.pump();

      // Фраза под картой не должна перебирать всё, что лежит по дороге.
      expect(page.heard, hasLength(1));
      expect(page.point.x, closeTo(0.8, 1e-9));

      await tester.pump(const Duration(milliseconds: 60));
      expect(_knob(tester).dx, inExclusiveRange(0, 0.8));

      await tester.pumpAndSettle();
      expect(_knob(tester).dx, closeTo(0.8, 1e-9));
      expect(page.heard, hasLength(1));
    });

    testWidgets('на саму ручку оценку не меняет', (tester) async {
      const start = TastePoint(0.5, 0.2);
      final page = await pumpMap(tester, start: start);

      await tester.tapAt(_atPlace(start.disc) + const Offset(6, -4));
      await tester.pumpAndSettle();

      expect(page.heard, isEmpty);
    });

    testWidgets('рядом с ручкой переставляет её под палец', (tester) async {
      await pumpMap(tester, start: const TastePoint(0.5, 0));

      await tester.tapAt(_at(0.5, 0) + const Offset(22, 0));
      await tester.pumpAndSettle();

      expect(_knob(tester).dx, closeTo(0.5 + 22 / _field, 1e-9));
    });

    testWidgets('чуть мимо края круга — это нажатие на край', (tester) async {
      final page = await pumpMap(tester);

      await tester.tapAt(_at(1, 0) + const Offset(8, 0));
      await tester.pumpAndSettle();

      expect(page.point, const TastePoint(1, 0));
    });

    testWidgets('мимо круга карта не слышит', (tester) async {
      final page = await pumpMap(tester);

      // Угол виджета: здесь поля под подписи осей, а не карта.
      await tester.tapAt(const Offset(12, _above + 12));
      await tester.pumpAndSettle();

      expect(page.heard, isEmpty);
    });
  });

  group('карта и прокрутка страницы', () {
    testWidgets('свайп вверх мимо ручки листает страницу, оценка на месте',
        (tester) async {
      final page = await pumpMap(tester, start: const TastePoint(0.6, -0.3));

      await tester.dragFrom(_at(-0.5, 0.5), const Offset(0, -120));
      await tester.pumpAndSettle();

      expect(page.scroll.offset, greaterThan(0));
      expect(page.heard, isEmpty,
          reason: 'листали страницу, а сдвинули оценку');
    });

    testWidgets('повели вбок мимо ручки — она приходит под палец',
        (tester) async {
      final page = await pumpMap(tester);

      final finger = await tester.startGesture(_at(-0.6, 0.4));
      await finger.moveBy(const Offset(30, 0));
      await tester.pumpAndSettle();

      expect(_knob(tester).dx, closeTo(-0.6 + 30 / _field, 1e-9));
      expect(_knob(tester).dy, closeTo(0.4, 1e-9));

      // Раз карта палец взяла, дальше он ведёт ручку и вниз.
      await finger.moveBy(const Offset(0, 100));
      await tester.pump();

      expect(_knob(tester).dy, closeTo(0.4 - 100 / _field, 1e-9));
      expect(page.scroll.offset, 0);

      await finger.up();
      await tester.pumpAndSettle();
    });

    testWidgets('придержали палец мимо ручки — она приходит, и её ведут вниз',
        (tester) async {
      final page = await pumpMap(tester);

      final finger = await tester.startGesture(_at(0, 0.6));
      await tester.pump(const Duration(milliseconds: 100));
      expect(page.heard, isEmpty, reason: 'палец ещё мог уйти в прокрутку');

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(_knob(tester).dy, closeTo(0.6, 1e-9));

      await finger.moveBy(const Offset(0, 150));
      await tester.pump();

      expect(_knob(tester).dy, closeTo(0.6 - 150 / _field, 1e-9));
      expect(page.scroll.offset, 0);

      await finger.up();
      await tester.pumpAndSettle();
    });

    testWidgets('палец, который ползёт, а не лежит, ручку не получает',
        (tester) async {
      final page = await pumpMap(tester);

      // Медленное начало прокрутки: за полторы десятых секунды палец уже
      // сдвинулся, хоть и меньше порога. Это не «придержали».
      final finger = await tester.startGesture(_at(0, 0.6));
      await tester.pump(const Duration(milliseconds: 80));
      await finger.moveBy(const Offset(0, -12));
      await tester.pump(const Duration(milliseconds: 80));
      expect(page.heard, isEmpty);

      await finger.moveBy(const Offset(0, -30));
      await finger.moveBy(const Offset(0, -60));
      await tester.pump();
      await finger.up();
      await tester.pumpAndSettle();

      expect(page.scroll.offset, greaterThan(0));
      expect(page.heard, isEmpty);
    });

    testWidgets('странице некуда прокручиваться — круг отдаёт ручку сразу',
        (tester) async {
      final page = await pumpMap(tester, scrollable: false);

      final finger = await tester.startGesture(_at(0, 0.6));
      await tester.pump();
      await finger.moveBy(const Offset(0, 40));
      await tester.pumpAndSettle();

      expect(_knob(tester).dy, closeTo(0.6 - 40 / _field, 1e-9));
      expect(page.heard, isNotEmpty);

      await finger.up();
      await tester.pumpAndSettle();
    });

    testWidgets('второй палец не сбивает ручку', (tester) async {
      final page = await pumpMap(tester);

      final finger = await tester.startGesture(_at(0, 0));
      await finger.moveBy(const Offset(60, 0));
      await tester.pump();

      final second = await tester.startGesture(_at(-0.5, -0.5), pointer: 7);
      await second.moveBy(const Offset(0, 40));
      await tester.pump();
      await second.up();

      await finger.moveBy(const Offset(16, 0));
      await tester.pump();

      expect(_knob(tester).dx, closeTo(76 / _field, 1e-9));
      expect(_knob(tester).dy, 0);
      expect(page.point.summaryRu, 'Заметно горько');

      await finger.up();
      await tester.pumpAndSettle();
    });
  });

  group('кольца', () {
    testWidgets('нарисованы там, где меняется слово', (tester) async {
      await pumpMap(tester);

      // Заливки идут снаружи внутрь: «сильно», «заметно», «чуть». Числа —
      // из правил точки, а не свои: у холста были свои трети круга, и цвет
      // под ручкой расходился с фразой под картой.
      const center = _side / 2;
      const rings = TastePoint.ringRadii;

      expect(
        find.byKey(TasteMap.fieldKey),
        paints
          ..circle(x: center, y: center, radius: _field * rings[2])
          ..circle(x: center, y: center, radius: _field * rings[1])
          ..circle(x: center, y: center, radius: _field * rings[0]),
      );
    });

    testWidgets('ручка у внутреннего края кольца уже говорит его словом',
        (tester) async {
      final page = await pumpMap(tester);
      const rings = TastePoint.ringRadii;

      // На волосок за границей зелёного — уже «заметно», а не «чуть».
      await tester.tapAt(_at(rings[0] + 0.02, 0));
      await tester.pumpAndSettle();
      expect(page.point.summaryRu, 'Заметно горько');

      // На волосок за границей жёлтого — уже «сильно».
      await tester.tapAt(_at(0, -(rings[1] + 0.02)));
      await tester.pumpAndSettle();
      expect(page.point.summaryRu, 'Сильно слабо');

      // А на волосок до границы — ещё прежнее слово.
      await tester.tapAt(_at(-(rings[0] - 0.02), 0));
      await tester.pumpAndSettle();
      expect(page.point.summaryRu, 'Чуть кисло');
    });
  });

  group('карта снаружи', () {
    testWidgets('точку сбросили — ручка доезжает до центра, а не скачет',
        (tester) async {
      final page = await pumpMap(tester, start: const TastePoint(0.8, 0));

      page.refresh(() => page.point = TastePoint.center);
      await tester.pump();
      expect(_knob(tester).dx, closeTo(0.8, 1e-9));

      await tester.pump(const Duration(milliseconds: 60));
      expect(_knob(tester).dx, inExclusiveRange(0, 0.8));

      await tester.pumpAndSettle();
      expect(_knob(tester), Offset.zero);
      expect(page.heard, isEmpty, reason: 'сброс снаружи карта не повторяет');
    });

    testWidgets('без анимаций в телефоне ручка встаёт сразу', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

      await pumpMap(tester);

      await tester.tapAt(_at(0.8, 0));
      await tester.pump();

      expect(_knob(tester).dx, closeTo(0.8, 1e-9));
    });

    testWidgets('щёлкает, только когда меняется фраза', (tester) async {
      var clicks = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') clicks++;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await pumpMap(tester);

      final finger = await tester.startGesture(_at(0, 0));
      await tester.pump();
      expect(clicks, 0, reason: 'ручку взяли — фраза та же');

      // Из цели наружу: «получилось» сменилось на «чуть горько».
      await finger.moveBy(const Offset(0.3 * _field, 0));
      await tester.pump();
      expect(clicks, 1);

      // Дальше по тому же кольцу фраза не меняется.
      await finger.moveBy(const Offset(0.05 * _field, 0));
      await tester.pump();
      expect(clicks, 1);

      // Следующее кольцо: «заметно горько».
      await finger.moveBy(const Offset(0.2 * _field, 0));
      await tester.pump();
      expect(clicks, 2);

      await finger.up();
      await tester.pumpAndSettle();
      expect(clicks, 2);
    });

    testWidgets('голосовому помощнику нечем нажать на карту вслепую',
        (tester) async {
      final handle = tester.ensureSemantics();
      final page = await pumpMap(tester);

      // У нажатия без места нет места на карте: раньше оно ставило точку в
      // левый верхний угол — «сильно кисло, сильно крепко».
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Карта вкуса. Получилось как задумано'),
        ),
        isSemantics(hasTapAction: false, hasLongPressAction: false),
      );
      expect(page.heard, isEmpty);

      handle.dispose();
    });
  });
}
