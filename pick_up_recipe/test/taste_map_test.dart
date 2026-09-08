// Карта вкуса переводит одну точку в жалобы, которые понимает pkg/correction.
//
// Проверяется тестом, а не глазами: ошибка в знаке оси означает, что на жалобу
// «кисло» придёт поправка «мели крупнее» — то есть ровно наоборот.
//
// Здесь же проверяется развилка языков. Фраза «Заметно кисло, чуть слабо»
// живёт сразу в двух местах: под картой на экране и полем комментария в
// запросе к серверу. На экране она обязана говорить на языке телефона, в
// запросе — всегда по-русски: комментарий читают люди в кабинете обжарщика.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/taste_map.dart';

void main() {
  late AppLocalizations ru;
  late AppLocalizations en;

  final cyrillic = RegExp(r'[А-Яа-яЁё]');

  setUpAll(() async {
    ru = await AppLocalizations.delegate.load(const Locale('ru'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('карта вкуса', () {
    test('центр — это «получилось», а не пустая жалоба', () {
      expect(TastePoint.center.complaints, isEmpty);
      expect(TastePoint.center.isCenter, isTrue);
      expect(TastePoint.center.summaryFor(ru), 'Получилось как задумано');
    });

    test('мелкое дрожание пальца не превращается в жалобу', () {
      const point = TastePoint(0.1, -0.1);
      expect(point.complaints, isEmpty);
      expect(point.isCenter, isTrue);
    });

    test('влево — кисло, вправо — горько', () {
      expect(const TastePoint(-0.5, 0).complaints, ['sour']);
      expect(const TastePoint(0.5, 0).complaints, ['bitter']);
    });

    test('вниз — слабо, вверх — крепко', () {
      expect(const TastePoint(0, -0.5).complaints, ['weak']);
      expect(const TastePoint(0, 0.5).complaints, ['too_strong']);
    });

    test('обе оси дают две жалобы, экстракция первой', () {
      expect(const TastePoint(-0.6, -0.6).complaints, ['sour', 'weak']);
      expect(const TastePoint(0.6, 0.6).complaints, ['bitter', 'too_strong']);
    });

    test('кольца задают силу отклонения', () {
      expect(const TastePoint(0.3, 0).extractionStrength, TasteStrength.slight);
      expect(const TastePoint(0.6, 0).extractionStrength, TasteStrength.noticeable);
      expect(const TastePoint(0.9, 0).extractionStrength, TasteStrength.strong);
    });

    test('подпись собирается словами, а не координатами', () {
      expect(const TastePoint(-0.6, -0.3).summaryFor(ru), 'Заметно кисло, чуть слабо');
      expect(const TastePoint(0.9, 0).summaryFor(ru), 'Сильно горько');
      expect(const TastePoint(0, 0.6).summaryFor(ru), 'Заметно крепко');
    });

    test('на английском словаре подпись английская и с большой буквы', () {
      expect(const TastePoint(-0.6, -0.3).summaryFor(en), 'Noticeably sour, slightly weak');
      expect(const TastePoint(0.9, 0).summaryFor(en), 'Very bitter');
      expect(TastePoint.center.summaryFor(en), 'Turned out just as intended');
    });

    test('обе оси говорят одной частью речи — наречием, а не сравнением', () {
      // «Крепче» и «слабее» на одном круге с «кисло» и «горько» читались как
      // два разных вопроса. Проверяется здесь, а не глазами: подпись оси на
      // карте и текст плашки собираются из одних и тех же слов.
      final said = [
        const TastePoint(0, 0.9).summaryFor(ru),
        const TastePoint(0, -0.9).summaryFor(ru),
        const TastePoint(0.9, 0).summaryFor(ru),
        const TastePoint(-0.9, 0).summaryFor(ru),
      ];

      expect(said, ['Сильно крепко', 'Сильно слабо', 'Сильно горько', 'Сильно кисло']);
      for (final line in said) {
        expect(line, isNot(contains('ее')), reason: 'сравнительной степени быть не должно');
      }
    });

    test('концы одной оси остаются противоположными на обоих языках', () {
      // Перевод легко теряет смысл оси: «strong» на обоих концах вертикали
      // или один и тот же корень у «кисло» и «горько» превратили бы карту в
      // круг без сторон, и жалобу стало бы нечем прочитать.
      for (final texts in [ru, en]) {
        final ends = {
          'кисло': const TastePoint(-0.9, 0).summaryFor(texts),
          'горько': const TastePoint(0.9, 0).summaryFor(texts),
          'слабо': const TastePoint(0, -0.9).summaryFor(texts),
          'крепко': const TastePoint(0, 0.9).summaryFor(texts),
        };

        expect(
          ends.values.toSet().length,
          4,
          reason: 'четыре конца двух осей слились в одно слово: $ends',
        );
        expect(
          ends['кисло'],
          isNot(ends['горько']),
          reason: 'горизонталь перестала различать стороны',
        );
        expect(
          ends['слабо'],
          isNot(ends['крепко']),
          reason: 'вертикаль перестала различать стороны',
        );
      }
    });

    test('английская подпись не тащит за собой кириллицу', () {
      for (final point in const [
        TastePoint.center,
        TastePoint(-0.3, 0),
        TastePoint(0.9, 0.9),
        TastePoint(-0.6, -0.9),
      ]) {
        expect(
          cyrillic.hasMatch(point.summaryFor(en)),
          isFalse,
          reason: 'на английском экране осталось русское слово: ${point.summaryFor(en)}',
        );
      }
    });

    test('на сервер фраза уезжает русской, даже когда экран английский', () {
      // Поле комментария читают люди в кабинете обжарщика, и язык телефона
      // на него не влияет: одна и та же жалоба обязана приходить к ним
      // одними и теми же словами.
      const point = TastePoint(0.6, -0.3);

      expect(point.summaryRu, 'Заметно горько, чуть слабо');
      expect(point.summaryFor(en), 'Noticeably bitter, slightly weak');
      expect(point.summaryRu, point.summaryFor(ru));
    });

    test('точка за краем карты подрезается, а не уезжает в бесконечность', () {
      const point = TastePoint(2.4, -3.1);
      expect(point.clamped(), const TastePoint(1, -1));
    });
  });
}
