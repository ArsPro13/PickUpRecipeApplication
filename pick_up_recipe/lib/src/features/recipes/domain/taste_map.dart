// Карта вкуса: одна точка вместо анкеты.
//
// Две оси, и каждая отвечает своей группе правил поправки:
//   • горизонталь — экстракция: кисло ← → горько, правит помол, температуру
//     и время контакта;
//   • вертикаль — концентрация: слабо ← → крепко, правит соотношение.
//
// Поэтому одна точка отвечает сразу на оба вопроса, которые нужны
// `pkg/correction`, и человеку не приходится заполнять шесть ползунков ради
// того, чтобы сказать «кисловато и жидко».
//
// Экрана здесь нет намеренно: перевод точки в жалобы — единственная
// нетривиальная логика экрана, и её надо проверять тестом, а не глазами.
// Словарь приходит сюда параметром, `BuildContext` — никогда: тот же приём,
// что у текстов правил формы в `pages/auth_rule_texts.dart`.
//
// Здесь же — перевод между точкой и местом на нарисованном круге. Он тоже
// логика, а не рисование: от него зависит, какую фразу человек получит,
// поставив палец в это место.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../l10n/app_localizations.dart';

/// Насколько сильно отклонение по оси.
///
/// Три кольца, а не непрерывная шкала: человек не различает «на 12%» и
/// «на 19%», а правила поправки всё равно работают ступенями.
enum TasteStrength {
  /// Внутри центрального круга — попадание, жалобы нет.
  none,

  /// Первое кольцо.
  slight,

  /// Второе кольцо.
  noticeable,

  /// Край карты.
  strong;

  /// Слово силы на языке интерфейса: «чуть», «заметно», «сильно».
  /// У попадания слова нет — про него говорят целой фразой.
  String word(AppLocalizations texts) => switch (this) {
        TasteStrength.none => '',
        TasteStrength.slight => texts.rateDegreeSlight,
        TasteStrength.noticeable => texts.rateDegreeNoticeable,
        TasteStrength.strong => texts.rateDegreeStrong,
      };
}

/// Точка на карте вкуса.
///
/// Координаты в диапазоне −1…1 от центра: (0, 0) — «получилось как задумано».
/// Положительный [x] — в сторону горечи, положительный [y] — в сторону
/// крепости. Отрицательные — кислота и водянистость соответственно.
class TastePoint {
  const TastePoint(this.x, this.y);

  /// Точка по месту на круге карты.
  ///
  /// [place] — место в долях радиуса круга: центр — (0, 0), край — на
  /// расстоянии 1. Вправо горечь, вверх крепость — как у самой точки, а не
  /// как на экране, где ось Y смотрит вниз.
  ///
  /// Круг и точка — не одно и то же. Оси у точки независимы, и «сильно кисло
  /// и сильно слабо» — это угол квадрата (−1, −1), а у круга углов нет: при
  /// прямом переводе у края по диагонали выходило бы только «заметно», а
  /// «сильно» по обеим осям лежало бы за кругом, куда ручке идти некуда.
  /// Поэтому круг растягивается до квадрата вдоль луча из центра: расстояние
  /// от центра становится большей из двух осей. Из этого следует всё, что
  /// обещает рисунок:
  ///   • чем дальше ручка от центра, тем сильнее главная жалоба, и граница
  ///     силы — окружность, а не невидимая прямая;
  ///   • пунктир цели — ровно граница «получилось как задумано»;
  ///   • у края по диагонали — «сильно» по обеим осям.
  /// Вдоль самих осей перевод остаётся прямым.
  factory TastePoint.fromDisc(Offset place) {
    final distance = place.distance;
    if (distance == 0) return TastePoint.center;

    // За краем круга — ближайшее место на краю.
    final reach = math.min(distance, 1.0);
    final larger = math.max(place.dx.abs(), place.dy.abs());

    // Сначала деление, потом умножение: большая ось выходит ровно ±reach, и
    // палец на самом краю даёт ровно единицу, а не 0,9999999999999999.
    return TastePoint(place.dx / larger * reach, place.dy / larger * reach);
  }

  static const TastePoint center = TastePoint(0, 0);

  final double x;
  final double y;

  /// Радиус «попадания». Внутри него жалоб нет вовсе.
  ///
  /// Не ноль: точка ставится пальцем, и требовать попадания в математический
  /// центр значило бы, что довольным быть нельзя.
  static const double _deadZone = 0.14;

  /// Радиус цели на круге карты, в долях его радиуса: пунктир рисуется по
  /// нему, и по нему же отпущенная ручка встаёт в центр. Одно число на
  /// правило и на рисунок — иначе пунктир обещал бы одно, а фраза под картой
  /// говорила бы другое.
  static const double targetRadius = _deadZone;

  static const double _slightUpTo = 0.42;
  static const double _noticeableUpTo = 0.72;

  /// Где на круге карты проходят границы колец, в долях его радиуса: до
  /// первой — «чуть», до второй — «заметно», дальше и до края — «сильно».
  ///
  /// Кольца рисуются по этим числам, а не по своим. Раньше они стояли на
  /// третях круга — 0,34 и 0,67, — а слова менялись на 0,42 и 0,72: у
  /// внутреннего края жёлтого кольца фраза ещё говорила «чуть», у внутреннего
  /// края красного — ещё «заметно». Цвет под ручкой обещал одно, фраза под
  /// картой говорила другое.
  static const List<double> ringRadii = [_slightUpTo, _noticeableUpTo, 1.0];

  TasteStrength _strength(double value) {
    final magnitude = value.abs();
    if (magnitude <= _deadZone) return TasteStrength.none;
    if (magnitude <= _slightUpTo) return TasteStrength.slight;
    if (magnitude <= _noticeableUpTo) return TasteStrength.noticeable;
    return TasteStrength.strong;
  }

  TasteStrength get extractionStrength => _strength(x);
  TasteStrength get concentrationStrength => _strength(y);

  bool get isCenter =>
      extractionStrength == TasteStrength.none &&
      concentrationStrength == TasteStrength.none;

  /// Жалобы в терминах `pkg/correction`.
  ///
  /// Порядок устойчивый — сначала экстракция, потом концентрация: он попадает
  /// в текст поправки, и прыгающий порядок читался бы как разный ответ на
  /// один и тот же ввод.
  List<String> get complaints {
    final result = <String>[];

    if (extractionStrength != TasteStrength.none) {
      result.add(x < 0 ? 'sour' : 'bitter');
    }
    if (concentrationStrength != TasteStrength.none) {
      result.add(y < 0 ? 'weak' : 'too_strong');
    }

    return result;
  }

  /// Что именно сказал человек — словами языка интерфейса.
  ///
  /// Ровно та строка, что стоит под картой в макете: «Заметно кисло, чуть
  /// слабо». Без неё точка на карте остаётся догадкой — особенно после того,
  /// как палец её отпустил.
  ///
  /// Наречия, а не сравнительная степень. «Слабее» и «крепче» спрашивают
  /// «слабее чего?» — и на одном круге с «кисло» и «горько» читались как
  /// разные вопросы. Одна часть речи на обе оси: круг отвечает на один.
  String summaryFor(AppLocalizations texts) {
    if (isCenter) return texts.rateOnTarget;

    final parts = <String>[];

    if (extractionStrength != TasteStrength.none) {
      parts.add(texts.rateSaid(
        extractionStrength.word(texts),
        x < 0 ? texts.rateTasteSour : texts.rateTasteBitter,
      ));
    }
    if (concentrationStrength != TasteStrength.none) {
      parts.add(texts.rateSaid(
        concentrationStrength.word(texts),
        y < 0 ? texts.rateTasteWeak : texts.rateTasteStrong,
      ));
    }

    final joined = parts.join(', ');
    return joined[0].toUpperCase() + joined.substring(1);
  }

  /// Та же фраза по-русски — она уезжает на сервер полем комментария к оценке.
  ///
  /// Язык телефона на это поле не влияет и влиять не должен: комментарий
  /// читают люди в кабинете обжарщика, и одна и та же жалоба обязана
  /// приходить к ним одними и теми же словами. Основа у обеих фраз общая —
  /// [summaryFor]; разный у них только словарь.
  String get summaryRu =>
      summaryFor(lookupAppLocalizations(const Locale('ru')));

  /// Место точки на круге карты — обратное к [TastePoint.fromDisc]: доли
  /// радиуса, вправо горечь, вверх крепость. За край круга не выходит, какой
  /// бы ни была точка.
  Offset get disc {
    final larger = math.max(x.abs(), y.abs());
    if (larger == 0) return Offset.zero;

    final squeeze = math.min(larger, 1.0) / math.sqrt(x * x + y * y);
    return Offset(x * squeeze, y * squeeze);
  }

  /// Говорит ли точка то же, что и [other], — теми же словами.
  ///
  /// По этому карта щёлкает под пальцем: щелчок — это сменившаяся фраза, а
  /// не каждое движение.
  bool saysSameAs(TastePoint other) =>
      _said(x) == _said(other.x) && _said(y) == _said(other.y);

  /// Сила вместе со стороной: «заметно кисло» и «заметно горько» — разное.
  int _said(double value) => _strength(value).index * (value < 0 ? -1 : 1);

  TastePoint clamped() {
    return TastePoint(
        x.clamp(-1.0, 1.0).toDouble(), y.clamp(-1.0, 1.0).toDouble());
  }

  @override
  String toString() =>
      'TastePoint(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';

  @override
  bool operator ==(Object other) =>
      other is TastePoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
