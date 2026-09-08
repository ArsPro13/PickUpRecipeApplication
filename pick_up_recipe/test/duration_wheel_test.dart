// Барабан длительности: крутится и отдаёт секунды.
//
// Проверяется то, ради чего барабан и заводили: поворот на одну позицию
// меняет значение ровно на единицу своего разряда. Барабан, который отдаёт
// минуты вместо секунд, портит рецепт молча — на вид он такой же.
//
// Отдельная группа — про саму шторку, а не про барабан внутри неё. Барабан
// был исправен всё это время: жест до него не доходил. Шторка тянулась за
// пальцем всей площадью и забирала вертикальное перетаскивание себе, поэтому
// накрученное в шаг не попадало никогда — на видео владельца 59:00 приезжало
// нулём. Тесты группы держат обе стороны: палец на барабане крутит барабан,
// а закрыть шторку по-прежнему есть чем.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/general_widgets/duration_wheel_sheet.dart';
import 'package:pick_up_recipe/src/pages/recipe_builder_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';

Widget _wheels(int seconds, void Function(int) onChanged) {
  return MaterialApp(
    theme: lightTheme,
    home: Scaffold(
      body: DurationWheels(seconds: seconds, onChanged: onChanged),
    ),
  );
}

/// Крутит барабан на [items] позиций вперёд.
///
/// Тащим ровно на высоту строки и без «броска»: одно движение пальца не даёт
/// скорости, и барабан встаёт на соседнее число, а не улетает по инерции.
Future<void> _spin(WidgetTester tester, int wheel, int items) async {
  await tester.drag(
    find.byType(ListWheelScrollView).at(wheel),
    Offset(0, -AppSizes.tapTarget * items),
    touchSlopY: 0,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('барабан минут и секунд', () {
    testWidgets('поворот секунд меняет секунды', (tester) async {
      var picked = 0;
      await tester.pumpWidget(_wheels(35, (value) => picked = value));

      await _spin(tester, 1, 5);

      expect(picked, 40);
    });

    testWidgets('поворот минут добавляет ровно минуту', (tester) async {
      var picked = 0;
      await tester.pumpWidget(_wheels(35, (value) => picked = value));

      await _spin(tester, 0, 1);

      expect(picked, 95);
    });

    testWidgets('барабан открывается на том, что было в рецепте', (tester) async {
      var picked = 0;
      await tester.pumpWidget(_wheels(160, (value) => picked = value));

      // 2:40 — минуты на двойке, секунды на сорока. Ничего не крутили,
      // значит и сообщать нечего.
      expect(find.text('2'), findsWidgets);
      expect(find.text('40'), findsWidgets);
      expect(picked, 0);

      // А сдвинули на одну секунду назад — приехало 2:39, а не 0:39.
      await _spin(tester, 1, -1);
      expect(picked, 159);
    });

    testWidgets('выбранное ложится в шаг секундами, а не минутами', (tester) async {
      // Ошибка в единице не видна глазом: барабан выглядит так же, а шаг
      // на полторы минуты уезжает в рецепт полутора часами.
      final target = RecipeStep(
        seqNum: 1,
        instruction: 'Пролив',
        water: 100,
        time: 35,
        id: 0,
        stepType: 'pour',
        stepKey: '',
        tip: '',
        isOptional: false,
        untilUser: false,
        untilSign: '',
        warning: '',
      );

      await tester.pumpWidget(_wheels(target.time, (value) => target.time = value));
      await _spin(tester, 0, 1);

      expect(target.time, 95);
      expect(formatDuration(target.time), '1:35');
    });
  });

  group('шторка длительности', () {
    testWidgets('палец на барабане крутит барабан, а не тащит шторку', (tester) async {
      final host = await _openSheet(tester);

      await _spin(tester, 0, 4);

      // Сначала — что барабан вообще шевельнулся: пока жест забирала шторка,
      // четвёрка на экране не появлялась вовсе.
      expect(find.text('4'), findsOneWidget);

      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();

      expect(host.answer, 240);
      expect(host.stepTime, 240);
    });

    testWidgets('нажатие мимо шторки ничего не меняет в шаге', (tester) async {
      final host = await _openSheet(tester);

      await _spin(tester, 0, 4);
      // Мимо шторки — это по затемнению сверху, там же, где палец у человека,
      // передумавшего на полпути.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Готово'), findsNothing, reason: 'шторка должна закрыться');
      expect(host.answer, isNull);
      expect(host.stepTime, 0);
    });

    testWidgets('системная кнопка «назад» закрывает шторку', (tester) async {
      final host = await _openSheet(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Готово'), findsNothing);
      expect(host.answer, isNull);
      expect(host.stepTime, 0);
    });

    testWidgets('за ручку-полоску шторку по-прежнему стягивают вниз', (tester) async {
      final host = await _openSheet(tester);

      // Ручка живёт в верхней полосе шторки высотой в наименьшую цель для
      // пальца — единственное место, откуда перетаскивание осталось.
      final sheet = tester.getRect(find.byType(BottomSheet));
      await tester.dragFrom(
        Offset(sheet.center.dx, sheet.top + AppSizes.tapTarget / 2),
        const Offset(0, AppSizes.tapTarget * 8),
      );
      await tester.pumpAndSettle();

      expect(find.text('Готово'), findsNothing);
      expect(host.answer, isNull);
      expect(host.stepTime, 0);
    });

    testWidgets('на английском телефоне шторка английская', (tester) async {
      // На видео владельца английская шапка «A step type of your own» соседила
      // с русскими «Длительность», «минуты и секунды» и «Готово».
      await _openSheet(tester, locale: const Locale('en'));

      final en = lookupAppLocalizations(const Locale('en'));
      expect(find.text(en.builderDuration), findsOneWidget);
      expect(find.text(en.builderMinutesSeconds), findsOneWidget);
      expect(find.text(en.builderDone), findsOneWidget);

      // Смотрим внутрь шторки: кнопка, которая её открыла, принадлежит
      // тесту, а не шторке, и по-русски подписана намеренно.
      final cyrillic = RegExp('[а-яёА-ЯЁ]');
      final inside = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Text),
      );
      for (final text in tester.widgetList<Text>(inside)) {
        expect(
          cyrillic.hasMatch(text.data ?? ''),
          isFalse,
          reason: 'по-русски осталось: «${text.data}»',
        );
      }
    });
  });
}


/// Шторка с барабаном поверх экрана, который запоминает её ответ.
///
/// Локаль задана явно: шторка подписана строками из словаря, а не системным
/// языком машины с тестом.
class _SheetHost extends StatefulWidget {
  const _SheetHost({this.locale = const Locale('ru')});

  /// Язык телефона. Русский по умолчанию: остальным проверкам этой группы
  /// нужен предсказуемый язык, а не какой именно.
  final Locale locale;

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  /// Длительность шага, в который приезжает выбранное. Ноль — как на видео.
  int stepTime = 0;

  /// Что вернула шторка в последний раз. null — закрыли, ничего не выбрав.
  int? answer;

  /// Сколько раз шторку открывали: закрытие «мимо» не должно ни менять шаг,
  /// ни притворяться, что шторки не было.
  int opened = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      locale: widget.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              opened++;
              final picked = await showDurationSheet(context, seconds: stepTime);
              if (!context.mounted) return;
              setState(() {
                answer = picked;
                if (picked != null) stepTime = picked;
              });
            },
            child: const Text('открыть'),
          ),
        ),
      ),
    );
  }
}

Future<_SheetHostState> _openSheet(
  WidgetTester tester, {
  Locale locale = const Locale('ru'),
}) async {
  await tester.pumpWidget(_SheetHost(locale: locale));
  await tester.tap(find.text('открыть'));
  await tester.pumpAndSettle();

  return tester.state<_SheetHostState>(find.byType(_SheetHost));
}
