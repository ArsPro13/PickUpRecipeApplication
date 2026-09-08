// Лист выбора типа шага: палец по списку листает список.
//
// Та же беда, что была у барабана длительности, и она же на видео владельца:
// шторка тянется за пальцем всей своей площадью, и вертикальное
// перетаскивание достаётся ей, а не содержимому. У барабана это теряло
// выбранное число, здесь — прячет нижние группы: у прибора с полной таблицей
// типов «Пауза и текст» лежит ниже экрана, и добраться до неё нечем.
//
// Проверяется поведение, видимое человеку: список поехал вверх, а лист при
// этом остался на месте и по-прежнему умеет закрываться.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/features/recipes/application/step_types_state.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/step_type_model.dart';
import 'package:pick_up_recipe/src/general_widgets/step_type_sheet.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';

/// Сколько групп и типов в подставном справочнике.
///
/// Двадцать пять типов пятью группами — больше, чем влезает в лист высотой в
/// 0.88 экрана. Список, который помещается целиком, о прокрутке ничего не
/// скажет: он не поедет ни при каком жесте.
const int _groups = 5;
const int _typesPerGroup = 5;

StepTypeReference _reference() {
  return StepTypeReference(
    groups: [
      for (var index = 0; index < _groups; index++)
        StepTypeGroup(
          id: index + 1,
          slug: 'group$index',
          name: 'Группа $index',
          sortOrder: index,
        ),
    ],
    types: [
      for (var index = 0; index < _groups * _typesPerGroup; index++)
        StepType(
          id: index + 1,
          slug: 'type$index',
          name: 'Тип $index',
          shortName: 'Тип $index',
          iconKey: 'pour',
          groupId: index % _groups + 1,
          sortOrder: index,
        ),
    ],
  );
}

/// Что лист ответил. Отдельным объектом, а не возвращаемым значением: ответ
/// приходит после закрытия листа, то есть позже, чем `_openSheet` вернётся.
class _Outcome {
  StepTypePick? pick;
  bool closed = false;
}

/// Открывает лист и отдаёт ящик, в который лист положит свой ответ.
///
/// Локаль задана явно: шапка листа подписана строками из словаря, а не
/// системным языком машины с тестом.
Future<_Outcome> _openSheet(WidgetTester tester) async {
  final outcome = _Outcome();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [stepTypesProvider.overrideWith((ref) async => _reference())],
      child: MaterialApp(
        theme: lightTheme,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                outcome.pick =
                    await showStepTypeSheet(context, allowedStepTypes: const []);
                outcome.closed = true;
              },
              child: const Text('открыть'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('открыть'));
  await tester.pumpAndSettle();

  return outcome;
}

void main() {
  group('лист выбора типа шага', () {
    testWidgets('палец по списку листает список, а не тащит шторку', (tester) async {
      await _openSheet(tester);

      final before = tester.getTopLeft(find.text('Тип 0')).dy;
      final sheetBefore = tester.getRect(find.byType(BottomSheet));

      await tester.drag(find.byType(ListView), const Offset(0, -200), touchSlopY: 0);
      await tester.pumpAndSettle();

      // Список уехал вверх ровно настолько, насколько его тащили.
      expect(tester.getTopLeft(find.text('Тип 0')).dy, closeTo(before - 200, 1));
      // А сам лист остался на месте: это была прокрутка, а не закрытие.
      expect(tester.getRect(find.byType(BottomSheet)), sheetBefore);
    });

    testWidgets('нижняя группа достаётся прокруткой', (tester) async {
      await _openSheet(tester);

      final last = find.text('Тип ${_groups * _typesPerGroup - 1}');
      expect(last, findsNothing, reason: 'иначе список помещается целиком');

      await tester.dragUntilVisible(
        last,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(last, findsOneWidget);
    });

    testWidgets('нажатие по клетке отдаёт выбранный тип', (tester) async {
      final outcome = await _openSheet(tester);

      await tester.tap(find.text('Тип 0'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(outcome.pick, isA<BuiltInStepPick>());
      expect((outcome.pick! as BuiltInStepPick).type.slug, 'type0');
    });

    testWidgets('нажатие мимо листа ничего не выбирает', (tester) async {
      final outcome = await _openSheet(tester);

      // Мимо листа — по затемнению сверху, там же, где палец у человека,
      // передумавшего на полпути.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(outcome.closed, isTrue);
      expect(outcome.pick, isNull);
    });

    testWidgets('системная кнопка «назад» закрывает лист', (tester) async {
      final outcome = await _openSheet(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(outcome.closed, isTrue);
      expect(outcome.pick, isNull);
    });
  });
}
