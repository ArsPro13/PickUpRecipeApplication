// Материал приложения: тёплая бумага под всем и вдавленные поверхности.
//
// В макетах фон не залит одним цветом: две едва заметные точечные сетки со
// сдвигом дают крафтовую бумагу. Разница мизерная по контрасту и решающая по
// впечатлению — ровная заливка читается как незакрашенный прямоугольник, и
// именно от неё экраны выглядят плоскими.
//
// Всё рисуется кодом, без картинок: ассет пришлось бы тянуть в трёх плотностях
// и он всё равно тайлился бы с видимым швом.

import 'package:flutter/material.dart';

import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

/// Фон приложения: цвет поверхности плюс текстура бумаги.
///
/// Вешается один раз на всё приложение через `MaterialApp.builder`, а не на
/// каждый экран: перерисовывать сетку точек под каждым Scaffold незачем, а
/// забыть её на одном экране — легко.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final paper = context.paper;

    return DecoratedBox(
      decoration: BoxDecoration(color: context.colors.surface),
      child: CustomPaint(
        painter: _PaperPainter(tint: paper.tint, tintSecond: paper.tintSecond),
        child: child,
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter({required this.tint, required this.tintSecond});

  final Color tint;
  final Color tintSecond;

  /// Шаги сеток взаимно непериодичны: 13 и 19 — простые числа, и совпадение
  /// точек повторяется только раз в 247 пикселей. С круглыми шагами вроде
  /// 12 и 18 глаз ловит регулярный муар.
  static const double _stepFirst = 13;
  static const double _stepSecond = 19;
  static const double _dotRadius = 0.9;

  @override
  void paint(Canvas canvas, Size size) {
    _dots(canvas, size, _stepFirst, const Offset(0.2, 0.3), tint);
    _dots(canvas, size, _stepSecond, const Offset(0.7, 0.65), tintSecond);
  }

  void _dots(Canvas canvas, Size size, double step, Offset phase, Color color) {
    final paint = Paint()..color = color;
    final startX = step * phase.dx;
    final startY = step * phase.dy;

    for (var y = startY; y < size.height; y += step) {
      for (var x = startX; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PaperPainter oldDelegate) {
    return oldDelegate.tint != tint || oldDelegate.tintSecond != tintSecond;
  }
}

/// Оформление вдавленной поверхности: поле ввода, дорожка шкалы.
///
/// У Flutter нет внутренней тени, поэтому вдавленность собирается из двух
/// вещей: заливка темнее поднятой поверхности и градиент по верхней кромке.
/// Вместе они читаются как углубление, хотя ни одна тень внутрь не уходит.
///
/// Толщина обводки — параметром: тонкая рамка отделяет поверхность от фона,
/// а толстая говорит, что с ней сейчас работают, и путать эти два сообщения
/// одной шириной нельзя.
BoxDecoration sunkenDecoration(
  BuildContext context, {
  BorderRadius borderRadius = AppRadius.small,
  Color? color,
  Color? outline,
  double outlineWidth = AppStroke.thick,
}) {
  final surface = color ?? context.colors.surface;

  return BoxDecoration(
    borderRadius: borderRadius,
    border: outline == null ? null : Border.all(color: outline, width: outlineWidth),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.alphaBlend(context.shadows.sunkenTint, surface),
        surface,
      ],
      // Тень лежит только на верхней кромке: свет падает сверху, и глубина
      // читается по тому, что противоположный край остаётся чистым.
      stops: const [0, 0.14],
    ),
  );
}

/// Поверхность заданной ступени подъёма.
///
/// Три ступени вместо одной тени: `Level.flat` лежит, `raised` поднято,
/// `float` парит. Ступень выбирается по смыслу блока, а не по вкусу.
enum SurfaceLevel { flat, raised, float }

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.level = SurfaceLevel.flat,
    this.padding = const EdgeInsets.all(AppSpacing.s4),
    this.borderRadius = AppRadius.medium,
    this.color,
    this.border,
  });

  final Widget child;
  final SurfaceLevel level;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final shadows = context.shadows;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.colors.secondaryContainer,
        borderRadius: borderRadius,
        border: border,
        boxShadow: switch (level) {
          SurfaceLevel.flat => shadows.level1,
          SurfaceLevel.raised => shadows.level2,
          SurfaceLevel.float => shadows.level3,
        },
      ),
      child: child,
    );
  }
}
