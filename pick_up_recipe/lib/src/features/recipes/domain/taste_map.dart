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
// Флаттера здесь нет намеренно: перевод точки в жалобы — единственная
// нетривиальная логика экрана, и её надо проверять тестом, а не глазами.

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

  String get word => switch (this) {
        TasteStrength.none => '',
        TasteStrength.slight => 'чуть',
        TasteStrength.noticeable => 'заметно',
        TasteStrength.strong => 'сильно',
      };
}

/// Точка на карте вкуса.
///
/// Координаты в диапазоне −1…1 от центра: (0, 0) — «получилось как задумано».
/// Положительный [x] — в сторону горечи, положительный [y] — в сторону
/// крепости. Отрицательные — кислота и водянистость соответственно.
class TastePoint {
  const TastePoint(this.x, this.y);

  static const TastePoint center = TastePoint(0, 0);

  final double x;
  final double y;

  /// Радиус «попадания». Внутри него жалоб нет вовсе.
  ///
  /// Не ноль: точка ставится пальцем, и требовать попадания в математический
  /// центр значило бы, что довольным быть нельзя.
  static const double _deadZone = 0.14;

  static const double _slightUpTo = 0.42;
  static const double _noticeableUpTo = 0.72;

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
      extractionStrength == TasteStrength.none && concentrationStrength == TasteStrength.none;

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

  /// Что именно сказал человек — словами.
  ///
  /// Ровно та строка, что стоит под картой в макете: «Заметно кисло, чуть
  /// слабее». Без неё точка на карте остаётся догадкой — особенно после того,
  /// как палец её отпустил.
  String get summary {
    if (isCenter) return 'Получилось как задумано';

    final parts = <String>[];

    if (extractionStrength != TasteStrength.none) {
      parts.add('${extractionStrength.word} ${x < 0 ? 'кисло' : 'горько'}');
    }
    if (concentrationStrength != TasteStrength.none) {
      parts.add('${concentrationStrength.word} ${y < 0 ? 'слабее' : 'крепче'}');
    }

    final joined = parts.join(', ');
    return joined[0].toUpperCase() + joined.substring(1);
  }

  TastePoint clamped() {
    return TastePoint(x.clamp(-1.0, 1.0).toDouble(), y.clamp(-1.0, 1.0).toDouble());
  }

  @override
  String toString() => 'TastePoint(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';

  @override
  bool operator ==(Object other) => other is TastePoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
