// Выбор окончания шага: три вещи, которые сломались у сегментов.
//
// Экран узкий по определению — 360 точек это половина живых телефонов, — и
// именно на нём «по признаку» переносилось с разрывом слова, выбранный
// вариант ничем не отличался от остальных, а надпись съезжала от галочки.
// Каждая из трёх бед проверяется отдельно: они независимы и чинятся по-разному.
//
// Четвёртая беда — язык. Подписи вариантов и пояснения к ним были вшиты в код
// по-русски, и на английском телефоне форма выходила наполовину русской:
// «A step type of your own» и тут же «по времени». Про это — последняя группа.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/user_step_type_model.dart';
import 'package:pick_up_recipe/src/general_widgets/step_ending_choice.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';

/// Ширина узкого телефона. Форма живёт в полях экрана по 20 точек, но здесь
/// важна именно ширина устройства — от неё считается всё остальное.
const double _narrow = 360;

class _Host extends StatefulWidget {
  const _Host({this.locale = const Locale('ru')});

  /// Язык телефона. Русский по умолчанию: остальные проверки этой формы
  /// сравнивают ширины и заливки, и им нужен язык, а не какой именно.
  final Locale locale;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  StepEndsWith value = StepEndsWith.timer;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      locale: widget.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: _narrow,
            child: StepEndingChoice(
              value: value,
              onChanged: (option) => setState(() => value = option),
            ),
          ),
        ),
      ),
    );
  }
}

/// Заливки карточек в том порядке, в каком они стоят на экране.
List<Color?> _fills(WidgetTester tester) {
  return tester
      .widgetList<Material>(
        find.descendant(
          of: find.byType(StepEndingChoice),
          matching: find.byType(Material),
        ),
      )
      .map((material) => material.color)
      .toList();
}

void main() {
  // Подписи уехали в словарь: берём их той же локалью, что увидит человек.
  final ru = lookupAppLocalizations(const Locale('ru'));
  final en = lookupAppLocalizations(const Locale('en'));

  testWidgets('на 360 точках ни одна подпись не рвётся', (tester) async {
    await tester.pumpWidget(const _Host());

    // Высоты сравниваются между собой, а не с числом: перенос — это лишняя
    // строка, и она видна по тому, что подпись стала выше соседней.
    final short = tester.getSize(find.text(ru.builderEndsUser)).height;

    for (final option in StepEndsWith.values) {
      expect(
        tester.getSize(find.text(option.label(ru))).height,
        short,
        reason: option.label(ru),
      );
    }
  });

  testWidgets('выбранный вариант отличается заливкой', (tester) async {
    await tester.pumpWidget(const _Host());

    final fills = _fills(tester);
    expect(fills, hasLength(StepEndsWith.values.length));

    // Выбрано первое: его заливка своя, остальные две — одинаковые.
    expect(fills[0], isNot(fills[1]));
    expect(fills[1], fills[2]);

    await tester.tap(find.text(ru.builderEndsSign));
    await tester.pumpAndSettle();

    final after = _fills(tester);
    expect(after[2], isNot(after[1]));
    expect(after[0], after[1]);
    // И заливка выбранного — та же самая, просто переехала на третью карточку.
    expect(after[2], fills[0]);
  });

  testWidgets('текст не прыгает при выборе', (tester) async {
    await tester.pumpWidget(const _Host());

    final before = [
      for (final option in StepEndsWith.values) tester.getTopLeft(find.text(option.label(ru))),
    ];

    await tester.tap(find.text(ru.builderEndsSign));
    await tester.pumpAndSettle();

    final after = [
      for (final option in StepEndsWith.values) tester.getTopLeft(find.text(option.label(ru))),
    ];

    expect(after, before);
  });

  testWidgets('у каждого варианта есть строка пояснения', (tester) async {
    await tester.pumpWidget(const _Host());

    for (final option in StepEndsWith.values) {
      expect(option.hint(ru), isNotEmpty, reason: option.label(ru));
      expect(find.text(option.hint(ru)), findsOneWidget, reason: option.label(ru));
    }
  });

  testWidgets('нажатие отдаёт выбранный вариант', (tester) async {
    await tester.pumpWidget(const _Host());

    await tester.tap(find.text(ru.builderEndsUser));
    await tester.pumpAndSettle();

    expect(tester.state<_HostState>(find.byType(_Host)).value, StepEndsWith.user);
  });

  group('на английском телефоне', () {
    testWidgets('в форме не остаётся русских слов', (tester) async {
      await tester.pumpWidget(const _Host(locale: Locale('en')));

      // Спрашиваем не про конкретные слова, а про язык целиком: любая
      // забытая строка выдаст себя кириллицей, и добавить её в форму
      // незаметно больше не выйдет.
      final cyrillic = RegExp('[а-яёА-ЯЁ]');
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final shown = text.data ?? '';
        expect(
          cyrillic.hasMatch(shown),
          isFalse,
          reason: 'по-русски осталось: «$shown»',
        );
      }
    });

    testWidgets('на каждый вариант — своя подпись и своё пояснение', (tester) async {
      await tester.pumpWidget(const _Host(locale: Locale('en')));

      for (final option in StepEndsWith.values) {
        expect(find.text(option.label(en)), findsOneWidget, reason: option.wire);
        expect(find.text(option.hint(en)), findsOneWidget, reason: option.wire);
        // Подписи трёх вариантов различны в обоих языках: одинаковые
        // читались бы как один и тот же выбор, повторённый трижды.
        expect(option.label(en), isNot(option.label(ru)), reason: option.wire);
      }
    });
  });
}
