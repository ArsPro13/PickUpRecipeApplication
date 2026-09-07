// Карта вкуса переводит одну точку в жалобы, которые понимает pkg/correction.
//
// Проверяется тестом, а не глазами: ошибка в знаке оси означает, что на жалобу
// «кисло» придёт поправка «мели крупнее» — то есть ровно наоборот.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/taste_map.dart';

void main() {
  group('карта вкуса', () {
    test('центр — это «получилось», а не пустая жалоба', () {
      expect(TastePoint.center.complaints, isEmpty);
      expect(TastePoint.center.isCenter, isTrue);
      expect(TastePoint.center.summary, 'Получилось как задумано');
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
      expect(const TastePoint(-0.6, -0.3).summary, 'Заметно кисло, чуть слабо');
      expect(const TastePoint(0.9, 0).summary, 'Сильно горько');
      expect(const TastePoint(0, 0.6).summary, 'Заметно крепко');
    });

    test('обе оси говорят одной частью речи — наречием, а не сравнением', () {
      // «Крепче» и «слабее» на одном круге с «кисло» и «горько» читались как
      // два разных вопроса. Проверяется здесь, а не глазами: подпись оси на
      // карте и текст плашки собираются из одних и тех же слов.
      final said = [
        const TastePoint(0, 0.9).summary,
        const TastePoint(0, -0.9).summary,
        const TastePoint(0.9, 0).summary,
        const TastePoint(-0.9, 0).summary,
      ];

      expect(said, ['Сильно крепко', 'Сильно слабо', 'Сильно горько', 'Сильно кисло']);
      for (final line in said) {
        expect(line, isNot(contains('ее')), reason: 'сравнительной степени быть не должно');
      }
    });

    test('точка за краем карты подрезается, а не уезжает в бесконечность', () {
      const point = TastePoint(2.4, -3.1);
      expect(point.clamped(), const TastePoint(1, -1));
    });
  });
}
