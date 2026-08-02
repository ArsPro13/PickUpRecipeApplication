// Токены оформления: отступы, скругления, размеры, длительности, кривые.
//
// Источник истины — design/tokens/tokens.css. Значения продублированы сюда, а
// не сгенерированы: генератор потребовал бы шага сборки, а вся затея с макетами
// в том, что они открываются двойным кликом. Расхождение этого файла с
// tokens.css означает, что забыли обновить одно из двух.
//
// В виджетах не должно быть ни одного числа мимо этих констант: до них в
// приложении встречалось семнадцать разных отступов и шесть скруглений,
// и поменять радиус кнопок во всём приложении значило обойти все файлы.

import 'package:flutter/material.dart';

/// Отступы. Сетка кратно четырём (ответ на вопрос 29).
abstract final class AppSpacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s12 = 48;
  static const double s16 = 64;
  static const double s18 = 72;
}

abstract final class AppRadius {
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;

  /// Скругление «таблетки»: половина высоты, какой бы она ни была.
  static const double pill = 999;

  static const BorderRadius small = BorderRadius.all(Radius.circular(s));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(m));
  static const BorderRadius large = BorderRadius.all(Radius.circular(l));
  static const BorderRadius rounded = BorderRadius.all(Radius.circular(pill));
}

/// Размеры элементов.
abstract final class AppSizes {
  static const double metricTile = 60;
  static const double metricIcon = 30;
  static const double progressRing = 160;
  static const double progressTrack = 8;
  static const double recipeCard = 250;
  static const double buttonHeight = 50;
  static const double navIcon = 28;

  /// Наименьшая цель для пальца. Ниже — промахи.
  static const double tapTarget = 48;

  /// Размеры иконок набора. Совпадают с классами .ico в макетах:
  /// 24 — базовый, остальные задаются модификатором.
  static const double icon16 = 16;
  static const double icon20 = 20;
  static const double icon24 = 24;
  static const double icon32 = 32;
  static const double icon40 = 40;
  static const double icon48 = 48;
  static const double icon56 = 56;
  static const double icon72 = 72;
}

/// Толщина линий.
abstract final class AppStroke {
  static const double thin = 1;
  static const double thick = 2;

  /// Обводка иконок набора (ADR 0005).
  static const double icon = 1.75;
}

/// Длительности движения (ADR 0006).
abstract final class AppDuration {
  /// Отклик на нажатие: подсветка, смена состояния.
  static const Duration instant = Duration(milliseconds: 80);

  /// Мелкое перемещение, появление подсказки.
  static const Duration fast = Duration(milliseconds: 160);

  /// Смена шага, раскрытие карточки.
  static const Duration base = Duration(milliseconds: 260);

  /// Переход между экранами, крупная перекомпоновка.
  static const Duration slow = Duration(milliseconds: 420);

  /// Фоновое: пар, дыхание индикатора, капли.
  static const Duration ambient = Duration(milliseconds: 2400);
}

/// Кривые движения (ADR 0006).
abstract final class AppCurves {
  static const Curve out = Cubic(0.22, 0.61, 0.36, 1);
  static const Curve inOut = Cubic(0.65, 0, 0.35, 1);

  /// Пружина с лёгким перелётом. Для появления, не для исчезновения.
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);

  /// Вода: медленный старт, длинный хвост. Струя разгоняется и стекает.
  static const Curve water = Cubic(0.45, 0.05, 0.15, 1);
}
