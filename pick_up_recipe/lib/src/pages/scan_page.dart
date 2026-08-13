// Экран 01 «Код с пачки» — вкладка, а не камера.
//
// Вкладка ведёт сюда, а не сразу в видоискатель (ответ на вопрос 32): путей
// здесь три — камера, ручной ввод кода и «кода нет вовсе», — и камера,
// открытая на весь экран, прячет два из них.
//
// Ручной ввод — равноправная половина экрана, а не запасной выход после
// провала: код напечатан под QR буквами именно для того, чтобы его можно было
// набрать, когда камера не берёт (тусклый свет, помятая упаковка, плёнка).

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
            'Наведите на код — он напечатан под QR',
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
          const SizedBox(height: AppSpacing.s3),
          _LocalCheckNote(),
          const SizedBox(height: AppSpacing.s5),
          _NoCodeRow(onTap: _openCamera),
        ],
      ),
    );
  }
}

/// Кадр камеры: рисунок пачки с QR, дышащие уголки и бегущая полоса.
///
/// Живого видоискателя здесь нет намеренно. Экран стоит на вкладке и
/// открывается сам при каждом переключении; держать камеру включённой ради
/// вкладки — это разрешение, индикатор записи и разряд батареи на пустом
/// месте. Кадр объясняет, что будет, и открывает настоящий сканер по нажатию.
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
                aspectRatio: 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
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
                    Positioned(
                      bottom: AppSpacing.s4,
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

/// Рисунок в кадре: пачка, QR, напечатанный под ним код и уголки прицела.
class _ScannerPainter extends CustomPainter {
  const _ScannerPainter({required this.ink, required this.accent, required this.sweep});

  final Color ink;
  final Color accent;

  /// 0…1 — положение бегущей полосы.
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    // Рисунок задуман в квадрате 260×260 — тем же, что в макете. Масштаб
    // считается один раз, дальше все числа совпадают с макетом один в один.
    final scale = size.shortestSide / 260;
    canvas.save();
    canvas.translate((size.width - 260 * scale) / 2, (size.height - 260 * scale) / 2);
    canvas.scale(scale);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink
      ..strokeWidth = 2.6;

    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..color = ink.withValues(alpha: 0.4)
      ..strokeWidth = 1.6;

    final solid = Paint()..color = ink;

    // Пачка.
    canvas.drawPath(
      Path()
        ..moveTo(56, 30)
        ..lineTo(196, 26)
        ..lineTo(201, 226)
        ..quadraticBezierTo(126, 238, 50, 228)
        ..close(),
      line,
    );

    // Рамка QR и его глазки.
    canvas.drawRect(const Rect.fromLTWH(82, 78, 88, 80), thin);
    for (final origin in const [Offset(90, 86), Offset(144, 86), Offset(90, 130)]) {
      canvas.drawRect(Rect.fromLTWH(origin.dx, origin.dy, 19, 19), solid);
    }
    for (final origin in const [
      Offset(117, 86),
      Offset(129, 99),
      Offset(117, 114),
      Offset(144, 116),
      Offset(157, 133),
      Offset(130, 137),
      Offset(117, 143),
    ]) {
      canvas.drawRect(Rect.fromLTWH(origin.dx, origin.dy, 9, 9), solid);
    }

    // Код, напечатанный под QR: ровно то, что предлагается набрать руками.
    final label = TextPainter(
      text: TextSpan(
        text: 'ABCD-2345-68',
        style: TextStyle(color: ink.withValues(alpha: 0.85), fontSize: 12, letterSpacing: 2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(127 - label.width / 2, 170));

    canvas.drawLine(const Offset(74, 204), const Offset(138, 204), thin);
    canvas.drawLine(const Offset(74, 214), const Offset(112, 214), thin);

    // Уголки прицела.
    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent
      ..strokeWidth = 3.4;

    canvas.drawPath(Path()..moveTo(66, 92)..lineTo(66, 62)..lineTo(94, 62), bracket);
    canvas.drawPath(Path()..moveTo(190, 92)..lineTo(190, 62)..lineTo(162, 62), bracket);
    canvas.drawPath(Path()..moveTo(66, 162)..lineTo(66, 192)..lineTo(94, 192), bracket);
    canvas.drawPath(Path()..moveTo(190, 162)..lineTo(190, 192)..lineTo(162, 192), bracket);

    // Бегущая полоса ходит внутри прицела, а не по всему кадру.
    final y = 92 + (192 - 92) * sweep;
    canvas.drawLine(
      Offset(62, y),
      Offset(194, y),
      Paint()
        ..color = accent.withValues(alpha: 0.7)
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScannerPainter oldDelegate) {
    return oldDelegate.sweep != sweep || oldDelegate.ink != ink || oldDelegate.accent != accent;
  }
}

/// Ручной ввод кода: вдавленное поле, группы 4-4-2, подпись про контрольный знак.
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
              Text(
                'Ввести код руками',
                style: context.texts.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
          const SizedBox(height: AppSpacing.s1),
          Align(
            alignment: Alignment.centerRight,
            child: Text('десятый знак — контрольный', style: context.texts.labelSmall),
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

/// Пояснение, почему ошибка появилась мгновенно и без сети.
class _LocalCheckNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIcons.uiInfo, size: AppSizes.icon16, color: context.colors.secondary),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              'Проверяем на устройстве, к серверу не обращаемся. '
              'В коде не бывает 0, O, 1, I, L, U и S.',
              style: context.texts.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Второй путь: пачка без кода вовсе.
///
/// Не запасной выход и не ошибка — просто другая дорога, поэтому строка,
/// а не пустое состояние после провала.
class _NoCodeRow extends StatelessWidget {
  const _NoCodeRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: QuietSurface(
          child: Row(
            children: [
              Opacity(
                opacity: 0.7,
                child: AppIcon(
                  AppIcons.uiCamera,
                  size: AppSizes.icon32,
                  color: context.colors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('На пачке нет кода', style: context.texts.bodyMedium),
                    const SizedBox(height: AppSpacing.s1),
                    Text('Снимем пачку и разберём надписи', style: context.texts.labelSmall),
                  ],
                ),
              ),
              Opacity(
                opacity: 0.5,
                child: AppIcon(
                  AppIcons.uiForward,
                  size: AppSizes.icon20,
                  color: context.colors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
