// Карта вкуса переводит одну точку в жалобы, которые понимает pkg/correction.
//
// Проверяется тестом, а не глазами: ошибка в знаке оси означает, что на жалобу
// «кисло» придёт поправка «мели крупнее» — то есть ровно наоборот.
//
// Здесь же проверяется развилка языков. Фраза «Заметно кисло, чуть слабо»
// живёт сразу в двух местах: под картой на экране и полем комментария в
// запросе к серверу. На экране она обязана говорить на языке телефона, в
// запросе — всегда по-русски: комментарий читают люди в кабинете обжарщика.

import 'dart:math' as math;

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
      expect(const TastePoint(0.6, 0).extractionStrength,
          TasteStrength.noticeable);
      expect(const TastePoint(0.9, 0).extractionStrength, TasteStrength.strong);
    });

    test('подпись собирается словами, а не координатами', () {
      expect(const TastePoint(-0.6, -0.3).summaryFor(ru),
          'Заметно кисло, чуть слабо');
      expect(const TastePoint(0.9, 0).summaryFor(ru), 'Сильно горько');
      expect(const TastePoint(0, 0.6).summaryFor(ru), 'Заметно крепко');
    });

    test('на английском словаре подпись английская и с большой буквы', () {
      expect(const TastePoint(-0.6, -0.3).summaryFor(en),
          'Noticeably sour, slightly weak');
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

      expect(said,
          ['Сильно крепко', 'Сильно слабо', 'Сильно горько', 'Сильно кисло']);
      for (final line in said) {
        expect(line, isNot(contains('ее')),
            reason: 'сравнительной степени быть не должно');
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
          reason:
              'на английском экране осталось русское слово: ${point.summaryFor(en)}',
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

  // Круг на экране и точка — не одно и то же: у точки оси независимы, и её
  // область — квадрат, а рисуют и водят пальцем по кругу. Перевод между ними
  // решает, какую фразу человек получит, поставив палец в это место, — и
  // ошибка в нём выглядит не как падение, а как «я показал одно, а записали
  // другое».
  group('место на круге', () {
    /// Места на круге по всем направлениям на расстоянии [distance] от
    /// центра.
    Iterable<Offset> around(double distance) sync* {
      for (var degrees = 0; degrees < 360; degrees += 15) {
        yield Offset.fromDirection(degrees * math.pi / 180, distance);
      }
    }

    /// Сила главной жалобы — той, что сильнее из двух.
    TasteStrength stronger(TastePoint point) =>
        point.extractionStrength.index >= point.concentrationStrength.index
            ? point.extractionStrength
            : point.concentrationStrength;

    test('вдоль осей круг и точка совпадают', () {
      expect(
          TastePoint.fromDisc(const Offset(0.5, 0)), const TastePoint(0.5, 0));
      expect(TastePoint.fromDisc(const Offset(0, -0.3)),
          const TastePoint(0, -0.3));
      expect(TastePoint.fromDisc(Offset.zero), TastePoint.center);

      expect(const TastePoint(0.5, 0).disc, const Offset(0.5, 0));
      expect(const TastePoint(0, -0.3).disc, const Offset(0, -0.3));
      expect(TastePoint.center.disc, Offset.zero);
    });

    test('палец за краем круга даёт ровно единицу по главной оси', () {
      // Не 0,9999999999999999: по краю проходит граница «сильно», и точка
      // с краю не должна зависеть от того, как округлилось деление.
      for (final place in around(1.2)) {
        final point = TastePoint.fromDisc(place);
        expect(math.max(point.x.abs(), point.y.abs()), 1.0,
            reason: 'место $place дало $point');
      }
    });

    test('у края по диагонали — «сильно» по обеим осям', () {
      final corner = TastePoint.fromDisc(
        const Offset(-math.sqrt1_2, -math.sqrt1_2),
      );

      expect(corner.x, closeTo(-1, 1e-9));
      expect(corner.y, closeTo(-1, 1e-9));
      expect(corner.summaryFor(ru), 'Сильно кисло, сильно слабо');
    });

    test('за краем круга — ближайшее место на краю', () {
      expect(TastePoint.fromDisc(const Offset(3, 0)), const TastePoint(1, 0));
      expect(
          TastePoint.fromDisc(const Offset(0, -40)), const TastePoint(0, -1));

      final far = TastePoint.fromDisc(const Offset(-5, 5));
      expect(far.x, closeTo(-1, 1e-9));
      expect(far.y, closeTo(1, 1e-9));
    });

    test('ручка не выходит за край круга, какой бы ни была точка', () {
      for (final point in const [
        TastePoint.center,
        TastePoint(1, 1),
        TastePoint(-1, 1),
        TastePoint(1, -0.3),
        TastePoint(0.6, -0.3),
        // Старый черновик или чужой клиент могли прислать и такое.
        TastePoint(2.4, -3.1),
      ]) {
        expect(point.disc.distance, lessThanOrEqualTo(1 + 1e-9),
            reason: 'точка $point нарисована за кругом');
      }
    });

    test('туда и обратно — без потерь, в обе стороны', () {
      for (final distance in const [
        0.05,
        0.14,
        0.3,
        0.42,
        0.6,
        0.72,
        0.9,
        1.0
      ]) {
        for (final place in around(distance)) {
          final back = TastePoint.fromDisc(place).disc;
          expect(back.dx, closeTo(place.dx, 1e-9));
          expect(back.dy, closeTo(place.dy, 1e-9));
        }
      }

      for (final point in const [
        TastePoint(0.6, -0.3),
        TastePoint(-1, -1),
        TastePoint(0.05, 0.9),
        TastePoint(-0.72, 0.42),
      ]) {
        final back = TastePoint.fromDisc(point.disc);
        expect(back.x, closeTo(point.x, 1e-9));
        expect(back.y, closeTo(point.y, 1e-9));
      }
    });

    test('пунктир цели — ровно граница «получилось как задумано»', () {
      // Внутри пунктира в любую сторону — попадание, сразу за ним — уже
      // жалоба. При прямом переводе попаданием был квадрат, и по диагонали
      // он вылезал за нарисованный пунктир.
      for (final place in around(TastePoint.targetRadius - 0.01)) {
        expect(TastePoint.fromDisc(place).isCenter, isTrue,
            reason: 'место $place внутри пунктира, а жалоба есть');
      }
      for (final place in around(TastePoint.targetRadius + 0.01)) {
        expect(TastePoint.fromDisc(place).isCenter, isFalse,
            reason: 'место $place за пунктиром, а жалобы нет');
      }
    });

    test('чем дальше от центра, тем сильнее главная жалоба — в любую сторону',
        () {
      for (final place in around(0.3)) {
        expect(stronger(TastePoint.fromDisc(place)), TasteStrength.slight);
      }
      for (final place in around(0.6)) {
        expect(stronger(TastePoint.fromDisc(place)), TasteStrength.noticeable);
      }
      for (final place in around(0.9)) {
        expect(stronger(TastePoint.fromDisc(place)), TasteStrength.strong);
      }
    });

    test('границы колец — ровно там, где меняется слово', () {
      // Кольца на холсте рисуются по этим числам. Раньше у них были свои —
      // трети круга, — и у внутреннего края жёлтого кольца фраза ещё говорила
      // «чуть». Здесь проверяется обещание рисунка: всё кольцо, от края до
      // края и в любую сторону, говорит одним словом.
      const words = [
        TasteStrength.slight,
        TasteStrength.noticeable,
        TasteStrength.strong,
      ];
      const rings = TastePoint.ringRadii;

      expect(rings, hasLength(words.length));
      expect(rings.last, 1.0, reason: 'последнее кольцо — край круга');

      for (var ring = 0; ring < rings.length; ring++) {
        // Изнутри первое кольцо ограничено пунктиром цели, остальные —
        // предыдущим кольцом.
        final inner = ring == 0 ? TastePoint.targetRadius : rings[ring - 1];

        for (final edge in [inner + 0.01, rings[ring] - 0.01]) {
          for (final place in around(edge)) {
            expect(
              stronger(TastePoint.fromDisc(place)),
              words[ring],
              reason: 'кольцо ${ring + 1}, место $place',
            );
          }
        }
      }
    });

    test('стороны не перепутаны: вправо — горько, вверх — крепко', () {
      // «Вверх» здесь — как у точки, а не как на экране: ось переворачивает
      // сам холст.
      expect(TastePoint.fromDisc(const Offset(0.5, 0)).complaints, ['bitter']);
      expect(TastePoint.fromDisc(const Offset(-0.5, 0)).complaints, ['sour']);
      expect(
          TastePoint.fromDisc(const Offset(0, 0.5)).complaints, ['too_strong']);
      expect(TastePoint.fromDisc(const Offset(0, -0.5)).complaints, ['weak']);
    });
  });

  group('щелчок под пальцем', () {
    test('та же фраза — щелчка нет', () {
      // Оба — «заметно горько»: вторая ось у обоих внутри попадания.
      expect(
        const TastePoint(0.5, 0).saysSameAs(const TastePoint(0.6, 0.1)),
        isTrue,
      );
      expect(
        const TastePoint(0.05, -0.1).saysSameAs(TastePoint.center),
        isTrue,
      );
    });

    test('сменилась сила или сторона — щелчок', () {
      expect(
        const TastePoint(0.5, 0).saysSameAs(const TastePoint(0.8, 0)),
        isFalse,
      );
      expect(
        const TastePoint(0.5, 0).saysSameAs(const TastePoint(-0.5, 0)),
        isFalse,
      );
      expect(
        const TastePoint(0.5, 0).saysSameAs(const TastePoint(0.5, 0.3)),
        isFalse,
      );
    });

    test('совпадает с фразой под картой: одна фраза — один ответ', () {
      // Щелчок обещает «фраза сменилась». Сверяем с самой фразой, а не с
      // правилом, по которому щелчок считается.
      const points = [
        TastePoint.center,
        TastePoint(0.1, 0.1),
        TastePoint(0.3, 0),
        TastePoint(-0.3, 0),
        TastePoint(0.6, -0.3),
        TastePoint(0.6, -0.2),
        TastePoint(0.9, 0.9),
        TastePoint(-0.9, 0.5),
      ];

      for (final one in points) {
        for (final other in points) {
          expect(
            one.saysSameAs(other),
            one.summaryRu == other.summaryRu,
            reason: '$one и $other',
          );
        }
      }
    });
  });
}
