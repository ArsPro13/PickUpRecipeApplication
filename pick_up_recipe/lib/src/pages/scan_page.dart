// Экран 01 «Код с пачки» — вкладка, а не камера.
//
// Вкладка ведёт сюда, а не сразу в видоискатель (ответ на вопрос 32): путей
// здесь три — камера, ручной ввод кода и «кода нет вовсе», — и камера,
// открытая на весь экран, прячет два из них.
//
// Ручной ввод — равноправная половина экрана, а не запасной выход после
// провала: код напечатан под QR буквами именно для того, чтобы его можно было
// набрать, когда камера не берёт (тусклый свет, помятая упаковка, плёнка).
//
// Третий путь — «на пачке нет кода» — сейчас самый частый: код печатают
// только наши обжарщики, а на полке у человека стоят чужие пачки. Поэтому он
// вынесен вниз отдельной коричневой кнопкой и виден целиком на экране 360×640,
// без прокрутки: путь, по которому пойдёт большинство, нельзя прятать
// под сгибом.

import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../routing/app_router.dart';
import '../features/codes/domain/pack_code.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../general_widgets/app_surface.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final TextEditingController _code = TextEditingController();

  /// Ошибка разбора кода. Показывается до похода на сервер: контрольный
  /// символ ловит опечатку локально, и незачем гонять запрос ради этого.
  String? _error;

  @override
  void initState() {
    super.initState();
    _code.addListener(_onChanged);
  }

  @override
  void dispose() {
    _code.removeListener(_onChanged);
    _code.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_error != null) setState(() => _error = null);
    // Кнопка «Открыть рецепт» гаснет и загорается по мере набора, поэтому
    // перерисовка нужна на каждый символ, а не только на ошибке.
    setState(() {});
  }

  bool get _isComplete => PackCode.normalize(_code.text).length == PackCode.length;

  void _submit() {
    final normalized = PackCode.normalize(_code.text);

    setState(() => _error = PackCode.validationError(normalized));
    if (_error != null) return;

    context.router.push(CoffeeRoute(code: normalized));
  }

  void _openCamera() => context.router.push(const RecognitionCameraRoute());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Код с пачки')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s2,
          AppSpacing.s5,
          AppSpacing.s8,
        ),
        children: [
          _CameraFrame(onTap: _openCamera),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'Код мелкий — ищите его в углу пачки',
            style: context.texts.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s4),
          _ManualEntry(
            controller: _code,
            error: _error,
            canSubmit: _isComplete,
            onSubmit: _submit,
            onClear: () => _code.clear(),
          ),
          const SizedBox(height: AppSpacing.s5),
          // Коричневая, а не строка-ссылка: пачек без нашего кода на полке
          // сейчас больше, чем с кодом, и это главное действие экрана для
          // большинства, а не запасной выход после провала.
          AppButton(
            label: 'На пачке нет кода',
            icon: AppIcons.uiCamera,
            onPressed: _openCamera,
          ),
        ],
      ),
    );
  }
}

/// Кадр камеры: рисунок пачки с мелким кодом, прицел вокруг кода и полоса.
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

class _CameraFrameState extends State<_CameraFrame> with SingleTickerProviderStateMixin {
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
      label: 'Открыть камеру',
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
                    // Подпись ушла в верхний правый угол: внизу теперь стоит
                    // прицел вокруг кода, и посередине она легла бы на него.
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s1),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.16),
        borderRadius: AppRadius.rounded,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIcons.uiScan, size: AppSizes.icon16, color: ink),
          const SizedBox(width: AppSpacing.s2),
          Text('нажмите, чтобы навести', style: context.texts.labelSmall?.copyWith(color: ink)),
        ],
      ),
    );
  }
}

/// Рисунок в кадре: пачка, надписи обжарщика и мелкий код в её нижнем углу.
///
/// Прежний рисунок показывал крупный QR по центру пачки и прицел во весь
/// кадр — так код не печатают. На упаковке он мелкий и стоит в углу, обычно
/// нижнем левом, рядом с составом; рисунок должен показывать именно это,
/// иначе человек ищет большой квадрат и не находит.
class _ScannerPainter extends CustomPainter {
  const _ScannerPainter({required this.ink, required this.accent, required this.sweep});

  final Color ink;
  final Color accent;

  /// 0…1 — положение бегущей полосы.
  final double sweep;

  /// Рисунок задуман в прямоугольнике 260×130. Все числа ниже — координаты
  /// внутри него, а не пиксели экрана: масштаб считается один раз.
  static const Size _art = Size(260, 130);

  /// Прицел вокруг кода. Он маленький и сдвинут в левый нижний угол пачки —
  /// это и есть главное, что рисунок должен объяснить.
  static const Rect _codeFrame = Rect.fromLTRB(44, 88, 124, 111);

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

    // Пачка: верх заварен планкой, низ чуть провис под зерном.
    canvas.drawPath(
      Path()
        ..moveTo(38, 34)
        ..lineTo(152, 30)
        ..lineTo(158, 120)
        ..quadraticBezierTo(98, 130, 32, 122)
        ..close(),
      line,
    );
    canvas.drawLine(const Offset(44, 42), const Offset(148, 39), thin);

    // Надписи обжарщика: крупные, читаются издалека. Они здесь ради контраста
    // с кодом — рядом с ними видно, насколько он мелкий.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(48, 52, 26, 24), const Radius.circular(4)),
      thin,
    );
    canvas.drawLine(const Offset(84, 58), const Offset(142, 56), thin);
    canvas.drawLine(const Offset(84, 70), const Offset(120, 69), thin);
    canvas.drawLine(const Offset(48, 86), const Offset(140, 84), thin);

    // Сам код — тем же кеглем, каким его печатают: мелким.
    final label = TextPainter(
      text: TextSpan(
        text: 'ABCD-2345-68',
        style: TextStyle(color: ink.withValues(alpha: 0.85), fontSize: 8, letterSpacing: 0.6),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(_codeFrame.center.dx - label.width / 2, 94));

    // Уголки прицела: короткие, по размеру кода, а не по размеру кадра.
    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent
      ..strokeWidth = 2.4;

    const arm = 9.0;
    final corners = <(Offset, double, double)>[
      (_codeFrame.topLeft, 1, 1),
      (_codeFrame.topRight, -1, 1),
      (_codeFrame.bottomLeft, 1, -1),
      (_codeFrame.bottomRight, -1, -1),
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
    final y = _codeFrame.top + _codeFrame.height * sweep;
    canvas.drawLine(
      Offset(_codeFrame.left, y),
      Offset(_codeFrame.right, y),
      Paint()
        ..color = accent.withValues(alpha: 0.7)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScannerPainter oldDelegate) {
    return oldDelegate.sweep != sweep || oldDelegate.ink != ink || oldDelegate.accent != accent;
  }
}

/// Ручной ввод кода: вдавленное поле и маска 4-4-2.
///
/// Пояснения про контрольный знак и локальную проверку здесь больше нет:
/// человеку, который просто переписывает код с пачки, устройство алгоритма
/// не нужно, а места на экране оно занимало столько же, сколько кнопка.
class _ManualEntry extends StatelessWidget {
  const _ManualEntry({
    required this.controller,
    required this.error,
    required this.canSubmit,
    required this.onSubmit,
    required this.onClear,
  });

  final TextEditingController controller;
  final String? error;
  final bool canSubmit;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return QuietSurface(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIcon(AppIcons.uiEdit, size: AppSizes.icon20, color: context.colors.secondary),
              const SizedBox(width: AppSpacing.s2),
              // Expanded, а не голый Text: при крупном системном шрифте
              // заголовок не влезал в строку и вылезал за карточку.
              Expanded(
                child: Text(
                  'Ввести код руками',
                  style: context.texts.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Container(
            decoration: sunkenDecoration(
              context,
              outline: error != null ? context.colors.error : null,
            ),
            padding: const EdgeInsets.only(left: AppSpacing.s4, right: AppSpacing.s2),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => onSubmit(),
                    style: context.texts.bodyLarge?.copyWith(
                      letterSpacing: AppSpacing.s1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    inputFormatters: [
                      // Код печатается с дефисами, вводится как угодно:
                      // приводим к печатному виду на лету, чтобы человек видел
                      // ровно то же, что напечатано на пачке.
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final formatted = PackCode.format(PackCode.normalize(newValue.text));
                        return TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }),
                    ],
                    decoration: InputDecoration(
                      hintText: 'ABCD-2345-68',
                      hintStyle: context.texts.bodyLarge?.copyWith(
                        color: context.colors.secondary.withValues(alpha: 0.38),
                        letterSpacing: AppSpacing.s1,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  IconButton(
                    onPressed: onClear,
                    tooltip: 'Очистить',
                    icon: AppIcon(
                      AppIcons.uiClose,
                      size: AppSizes.icon20,
                      color: context.colors.secondary,
                    ),
                  ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(AppIcons.uiWarning, size: AppSizes.icon20, color: context.colors.error),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Text(
                    error!,
                    style: context.texts.bodySmall?.copyWith(color: context.colors.error),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.s3),
          AppButton(
            label: 'Открыть рецепт',
            icon: AppIcons.uiForward,
            kind: AppButtonKind.secondary,
            onPressed: canSubmit ? onSubmit : null,
          ),
        ],
      ),
    );
  }
}
