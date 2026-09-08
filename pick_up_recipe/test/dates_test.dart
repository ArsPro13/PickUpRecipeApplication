// Дата на двух языках.
//
// Русская таблица месяцев лежала тремя копиями и в английский экран уезжала
// как есть: «9 сентября» посреди английских подписей. Проверяется не только
// перевод слова, но и порядок: у английского день идёт после месяца, и
// склейка «день пробел месяц» в коде дала бы «9 September».

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/core/dates.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipes_list_state.dart';

void main() {
  late AppLocalizations ru;
  late AppLocalizations en;

  setUpAll(() async {
    ru = await AppLocalizations.delegate.load(const Locale('ru'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('дата', () {
    test('день и месяц по-русски', () {
      expect(formatDayMonth(ru, DateTime(2026, 9, 9)), '9 сентября');
    });

    test('день и месяц по-английски: месяц впереди', () {
      expect(formatDayMonth(en, DateTime(2026, 9, 9)), 'September 9');
    });

    test('все двенадцать месяцев переведены', () {
      for (var month = 1; month <= 12; month++) {
        final english = formatDayMonth(en, DateTime(2026, month, 1));
        expect(
          RegExp(r'[А-Яа-яЁё]').hasMatch(english),
          isFalse,
          reason: 'месяц $month остался русским на английском экране: $english',
        );
      }
    });

    test('год добавляется только к чужому году', () {
      final thisYear = DateTime.now().year;
      expect(
        formatRecipeDate(ru, DateTime(thisYear, 7, 28).toIso8601String()),
        '28 июля',
      );
      expect(
        formatRecipeDate(ru, DateTime(thisYear - 1, 7, 28).toIso8601String()),
        '28 июля ${thisYear - 1}',
      );
    });

    test('неразобранная строка показывается как есть', () {
      expect(formatRecipeDate(ru, 'не дата'), 'не дата');
    });
  });
}
