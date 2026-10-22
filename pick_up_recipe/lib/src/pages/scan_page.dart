// Экран 01 «Код с пачки» — вкладка, а не камера.
//
// Вкладка ведёт сюда, а не сразу в видоискатель (ответ на вопрос 32): камера,
// открытая на весь экран, прячет второй путь — «кода нет вовсе».
//
// Ручного ввода кода здесь больше нет. Владелец сказал прямо: код будет
// маленьким QR-кодом в углу пачки, и вводить никакой код руками не надо.
// Половина экрана под поле с маской 4-4-2 обслуживала случай, которого в
// продукте не будет, и отодвигала главное — кнопку «на пачке нет кода».
//
// «На пачке нет кода» — сейчас самый частый путь: код печатают только наши
// обжарщики, а на полке у человека стоят чужие пачки. Поэтому он стоит
// коричневой кнопкой и виден целиком на экране 360×640, без прокрутки.

import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    void openCamera() => context.router.push(const RecognitionCameraRoute());

    return Scaffold(
      appBar: AppBar(title: Text(texts.scanTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s2,
          AppSpacing.s5,
          AppSpacing.s8,
        ),
        children: [
          _CameraFrame(onTap: openCamera),
          const SizedBox(height: AppSpacing.s3),
          Text(
            texts.scanCodeIsSmall,
            style: context.texts.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s6),
          // Коричневая, а не строка-ссылка: пачек без нашего кода на полке
          // сейчас больше, чем с кодом, и это главное действие экрана для
          // большинства, а не запасной выход после провала.
          AppButton(
            label: texts.scanNoCode,
            icon: AppIcons.uiCamera,
            onPressed: openCamera,
          ),
        ],
      ),
    );
  }
}

/// Кадр камеры: рисунок пачки с маленьким QR-кодом в углу, прицел вокруг
/// кода и бегущая полоса.
///
/// Живого видоискателя здесь нет намеренно. Экран стоит на вкладке и
/// открывается сам при каждом переключении; держать камеру включённой ради
/// вкладки — это разрешение, индикатор записи и разряд батареи на пустом
/// месте. Кадр объясняет, что будет, и открывает настоящий сканер по нажатию.
///
/// Пропорция 2:1, а не квадрат: квадратный кадр занимал всю верхнюю половину
/// экрана и сталкивал кнопку «на пачке нет кода» за нижний край.
class _CameraFrame extends StatefulWidget {
  const _CameraFrame({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CameraFrame> createState() => _CameraFrameState();
}

class _CameraFrameState extends State<_CameraFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: AppDuration.ambient,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Кадр остаётся тёмным в обеих темах: это изображение, а не поверхность.
    final frame = Color.alphaBlend(
      context.colors.onSurface.withValues(alpha: 0.9),
      context.colors.surface,
    );
    final ink = context.colors.surface;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).scanOpenCamera,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.large,
          boxShadow: context.shadows.level2,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.large,
          child: Material(
            color: frame,
            child: InkWell(
              onTap: widget.onTap,
              child: AspectRatio(
                aspectRatio: 2,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _sweep,
                        builder: (context, _) => CustomPaint(
                          painter: _ScannerPainter(
                            ink: ink,
                            accent: context.colors.primary,
                            sweep: Curves.easeInOut.transform(_sweep.value),
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                    // Подпись в верхнем правом углу, над пачкой: пачка
                    // начинается ниже, и даже на узком телефоне, где
                    // подпись дотягивается до неё по ширине, они не
                    // налезают друг на друга.
                    Positioned(
                      top: AppSpacing.s3,
                      right: AppSpacing.s3,
                      child: _ScannerStatus(ink: ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Подпись в кадре: камера жива и пока ничего не нашла.
class _ScannerStatus extends StatelessWidget {
  const _ScannerStatus({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3, vertical: AppSpacing.s1),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.16),
        borderRadius: AppRadius.rounded,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIcons.uiScan, size: AppSizes.icon16, color: ink),
          const SizedBox(width: AppSpacing.s2),
          Text(
            AppLocalizations.of(context).scanTapToAim,
            style: context.texts.labelSmall?.copyWith(color: ink),
          ),
        ],
      ),
    );
  }
}

/// Рисунок в кадре: ровная пачка, надписи обжарщика и маленький QR-код в её
/// нижнем правом углу.
///
/// Пачка ровная — прямоугольник со скруглёнными углами, а не перекошенный
/// мешок: владелец попросил «сделай ровно», и кривые грани читались как
/// неаккуратный рисунок, а не как помятая упаковка. Кода буквами больше нет:
/// на пачке будет QR, и рисунок показывает ровно его — маленький квадрат в
/// углу, а не крупный по центру, иначе человек ищет большой квадрат и не
/// находит.
class _ScannerPainter extends CustomPainter {
  const _ScannerPainter(
      {required this.ink, required this.accent, required this.sweep});

  final Color ink;
  final Color accent;

  /// 0…1 — положение бегущей полосы.
  final double sweep;

  /// Рисунок задуман в прямоугольнике 260×130. Все числа ниже — координаты
  /// внутри него, а не пиксели экрана: масштаб считается один раз.
  static const Size _art = Size(260, 130);

  /// Пачка стоит левее середины и начинается ниже верхнего края: над ней,
  /// справа сверху, лежит подпись кадра.
  static const Rect _pack = Rect.fromLTRB(24, 36, 118, 124);

  /// Клетка QR-кода и их число по стороне. Код нарисован сеткой 11×11 —
  /// настоящий QR мельче, но на рисунке в три сантиметра его модули
  /// слились бы в серое пятно.
  static const double _module = 2;
  static const int _cells = 11;

  /// Сам код — в нижнем правом углу пачки.
  static final Rect _qr = Rect.fromLTWH(
    _pack.right - 7 - _module * _cells,
    _pack.bottom - 7 - _module * _cells,
    _module * _cells,
    _module * _cells,
  );

  /// Клетки кода, кроме трёх угловых меток. Заданы раз и навсегда: рисунок
  /// перерисовывается каждый кадр ради полосы, и случайный узор мерцал бы.
  static const List<(int, int)> _data = [
    (4, 0), (6, 0), (5, 1), (4, 2), (6, 2), (5, 3), //
    (0, 4), (2, 4), (4, 4), (5, 4), (7, 4), (9, 4), //
    (1, 5), (3, 5), (6, 5), (8, 5), (10, 5), //
    (0, 6), (2, 6), (4, 6), (5, 6), (9, 6), //
    (5, 7), (7, 7), (10, 7), //
    (4, 8), (6, 8), (8, 8), (10, 8), //
    (5, 9), (7, 9), (9, 9), //
    (4, 10), (6, 10), (8, 10), (10, 10),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / _art.width, size.height / _art.height);
    canvas.save();
    canvas.translate(
      (size.width - _art.width * scale) / 2,
      (size.height - _art.height * scale) / 2,
    );
    canvas.scale(scale);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink
      ..strokeWidth = 2.6;

    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = ink.withValues(alpha: 0.4)
      ..strokeWidth = 1.6;

    // Пачка: ровный прямоугольник и планка шва сверху.
    canvas.drawRRect(
      RRect.fromRectAndRadius(_pack, const Radius.circular(8)),
      line,
    );
    canvas.drawLine(
      Offset(_pack.left + 7, _pack.top + 11),
      Offset(_pack.right - 7, _pack.top + 11),
      thin,
    );

    // Надписи обжарщика: крупные, читаются издалека. Они здесь ради контраста
    // с кодом — рядом с ними видно, насколько он мелкий.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(34, 56, 18, 18), const Radius.circular(4)),
      thin,
    );
    canvas.drawLine(const Offset(60, 60), const Offset(108, 60), thin);
    canvas.drawLine(const Offset(60, 69), const Offset(96, 69), thin);
    canvas.drawLine(const Offset(34, 85), const Offset(108, 85), thin);
    // Нижняя строка короче: справа от неё в углу стоит код.
    canvas.drawLine(const Offset(34, 95), const Offset(74, 95), thin);

    _paintCode(canvas);
    _paintAim(canvas);

    canvas.restore();
  }

  /// QR-код: три угловые метки и клетки между ними.
  void _paintCode(Canvas canvas) {
    final fill = Paint()..color = ink.withValues(alpha: 0.85);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = ink.withValues(alpha: 0.85)
      ..strokeWidth = _module * 0.6;

    Rect cell(int x, int y, [int span = 1]) => Rect.fromLTWH(
          _qr.left + x * _module,
          _qr.top + y * _module,
          _module * span,
          _module * span,
        );

    // Угловые метки — то, по чему QR узнают с первого взгляда: квадрат в
    // квадрате в трёх углах из четырёх.
    for (final (x, y) in const [(0, 0), (_cells - 3, 0), (0, _cells - 3)]) {
      canvas.drawRect(cell(x, y, 3).deflate(_module * 0.3), ring);
      canvas.drawRect(cell(x + 1, y + 1), fill);
    }
    for (final (x, y) in _data) {
      canvas.drawRect(cell(x, y), fill);
    }
  }

  /// Уголки прицела и полоса: по размеру кода, а не по размеру кадра.
  void _paintAim(Canvas canvas) {
    final frame = _qr.inflate(4);

    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent
      ..strokeWidth = 2.4;

    const arm = 7.0;
    final corners = <(Offset, double, double)>[
      (frame.topLeft, 1, 1),
      (frame.topRight, -1, 1),
      (frame.bottomLeft, 1, -1),
      (frame.bottomRight, -1, -1),
    ];
    for (final (origin, towardsX, towardsY) in corners) {
      canvas.drawPath(
        Path()
          ..moveTo(origin.dx, origin.dy + arm * towardsY)
          ..lineTo(origin.dx, origin.dy)
          ..lineTo(origin.dx + arm * towardsX, origin.dy),
        bracket,
      );
    }

    // Полоса ходит внутри прицела: она показывает, что читают именно код,
    // а не пачку целиком.
    final y = frame.top + frame.height * sweep;
    canvas.drawLine(
      Offset(frame.left + 2, y),
      Offset(frame.right - 2, y),
      Paint()
        ..color = accent.withValues(alpha: 0.7)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScannerPainter oldDelegate) {
    return oldDelegate.sweep != sweep ||
        oldDelegate.ink != ink ||
        oldDelegate.accent != accent;
  }
}
