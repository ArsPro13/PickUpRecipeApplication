// Сканер кода с пачки: живая камера, прицел и переход к кофе.
//
// До 2 ноября 2026 сканера в приложении не было вовсе: кадр-подсказка на
// вкладке «Сканировать» и кнопка «На пачке нет кода» вели на одну и ту же
// форму новой пачки, и владелец, нажимая на кадр, попадал в поля ввода.
// Всё, что нужно после скана, было готово давно: сервер кладёт в QR ссылку
// `<QR_BASE_URL>/r/<код>` (ADR 0004), а страница кофе открывается по коду
// через /packs/by_code. Не хватало только глаза.
//
// Читается только QR. На каждой пачке есть ещё штрихкод EAN, и сканер,
// которому годится любой формат, без конца находил бы его и твердил «не наш».
//
// Прицел — подсказка, а не граница: код ищется по всему кадру. Он мелкий, и
// требовать попасть им в рамку значило бы заставить человека целиться. Если
// в кадре два QR (свой код обжарщика рядом с нашим), берётся наш.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../features/codes/domain/pack_code.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

/// Первый наш код из того, что камера прочитала за кадр, или null.
///
/// Отдельной функцией, а не внутри экрана: решение «открывать ли кофе»
/// проверяется тестом, которому камера не нужна.
String? packCodeFromScan(Iterable<String?> payloads) {
  for (final payload in payloads) {
    final code = PackCode.fromScan(payload ?? '');
    if (code != null) return code;
  }
  return null;
}

/// Сторона прицела. Код на пачке около двух сантиметров: с расстояния, на
/// котором камера его ещё держит в фокусе, он занимает примерно столько.
const double _aimSide = 240;

@RoutePage()
class CodeScannerPage extends StatefulWidget {
  const CodeScannerPage({super.key});

  @override
  State<CodeScannerPage> createState() => _CodeScannerPageState();
}

class _CodeScannerPageState extends State<CodeScannerPage>
    with WidgetsBindingObserver {
  /// Контроллер свой, а не виджета сканера: он нужен ради фонарика. Цена —
  /// сворачивание приложения: за чужим контроллером виджет не следит, и
  /// гасить камеру приходится самим (didChangeAppLifecycleState).
  final MobileScannerController _camera = MobileScannerController(
    autoStart: false,
    formats: const [BarcodeFormat.qrCode],
  );

  StreamSubscription<BarcodeCapture>? _reads;

  /// Код найден, экран уходит к кофе: следующие кадры уже ни к чему.
  bool _done = false;

  /// Камера держит в кадре чужой QR — подпись под прицелом говорит об этом.
  bool _foreign = false;
  Timer? _foreignFade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listen();
    unawaited(_start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Пока разрешения нет, поверх висит системный вопрос о камере, и он сам
    // дёргает жизненный цикл. Запускать камеру на этом «возвращении» нельзя:
    // отказ тут же вызвал бы вопрос снова, и так по кругу.
    if (!_camera.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _listen();
        unawaited(_start());
      case AppLifecycleState.inactive:
        unawaited(_reads?.cancel());
        _reads = null;
        unawaited(_camera.stop());
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foreignFade?.cancel();
    unawaited(_reads?.cancel());
    _reads = null;
    super.dispose();
    unawaited(_camera.dispose());
  }

  void _listen() {
    _reads ??= _camera.barcodes.listen(_onRead);
  }

  /// Запуск камеры.
  ///
  /// Отказ в разрешении и поломку камеры сканер кладёт в своё состояние, и
  /// их показывает [_CameraProblem]. Бросает он, только если экран закрыли
  /// раньше, чем камера проснулась, — тогда и показывать некому.
  Future<void> _start() async {
    try {
      await _camera.start();
    } on MobileScannerException catch (_) {}
  }

  void _onRead(BarcodeCapture capture) {
    if (_done || !mounted) return;

    final code = packCodeFromScan(
      capture.barcodes.map((barcode) => barcode.rawValue),
    );
    if (code == null) {
      _showForeign();
      return;
    }

    _done = true;
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_camera.stop());
    // Вместо сканера, а не поверх него: «назад» со страницы кофе ведёт на
    // вкладку, а не в камеру, которая тут же прочитала бы тот же код снова.
    unawaited(context.router.replace(CoffeeRoute(code: code)));
  }

  /// Подпись про чужой код держится, пока он в кадре, и гаснет через пару
  /// секунд после того, как ушёл: камера читает много раз в секунду, и без
  /// задержки подпись мигала бы.
  void _showForeign() {
    _foreignFade?.cancel();
    _foreignFade = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _foreign = false);
    });
    if (!_foreign) setState(() => _foreign = true);
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return Scaffold(
      // Камера — изображение, а не поверхность: чёрная в обеих темах.
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          texts.scanTitle,
          style: context.texts.titleMedium?.copyWith(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const AppIcon(
            AppIcons.uiBack,
            size: AppSizes.icon24,
            color: Colors.white,
          ),
          tooltip: texts.back,
        ),
        actions: [_TorchButton(camera: _camera)],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _camera,
            errorBuilder: (context, error) => _CameraProblem(
              error: error,
              onRetry: () => unawaited(_start()),
            ),
          ),
          // Прицел и подпись — только поверх живой камеры: на месте ошибки
          // рамка звала бы навести то, чего нет.
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _camera,
            builder: (context, state, _) {
              if (state.error != null) return const SizedBox.shrink();

              return LayoutBuilder(
                builder: (context, constraints) => Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _AimPainter(accent: context.colors.primary),
                    ),
                    // Сразу под прицелом: подпись читается вместе с рамкой,
                    // а не внизу экрана, куда взгляд при наведении не идёт.
                    Positioned(
                      top: constraints.maxHeight / 2 +
                          _aimSide / 2 +
                          AppSpacing.s6,
                      left: 0,
                      right: 0,
                      child: _Hint(
                        text: _foreign
                            ? texts.scannerForeignCode
                            : texts.scannerAim,
                        warning: _foreign,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Подпись под прицелом: что делать, а если в кадре чужой код — что с ним.
class _Hint extends StatelessWidget {
  const _Hint({required this.text, required this.warning});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
      child: AnimatedSwitcher(
        duration: AppDuration.fast,
        child: Container(
          key: ValueKey(text),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s2,
          ),
          decoration: BoxDecoration(
            // Подложка, а не голый текст: под подписью — живая картинка, и
            // белые буквы на светлой пачке пропали бы.
            color: warning
                ? context.colors.primary
                : Colors.black.withValues(alpha: 0.55),
            borderRadius: AppRadius.rounded,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: context.texts.bodySmall?.copyWith(
              color: warning ? context.colors.secondaryContainer : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Затемнение вокруг прицела и его уголки — как на рисунке во вкладке, чтобы
/// человек узнал то, что ему уже показали.
class _AimPainter extends CustomPainter {
  const _AimPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final window = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: _aimSide,
        height: _aimSide,
      ),
      const Radius.circular(AppRadius.l),
    );

    canvas.drawDRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.zero),
      window,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4
      ..color = accent;

    const arm = 28.0;
    final box = window.outerRect;
    for (final (corner, towardsX, towardsY) in [
      (box.topLeft, 1.0, 1.0),
      (box.topRight, -1.0, 1.0),
      (box.bottomLeft, 1.0, -1.0),
      (box.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx, corner.dy + arm * towardsY)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx + arm * towardsX, corner.dy),
        bracket,
      );
    }
  }

  @override
  bool shouldRepaint(_AimPainter oldDelegate) => oldDelegate.accent != accent;
}

/// Фонарик: код мелкий, а на кухне бывает темно. Где вспышки нет, кнопки нет.
class _TorchButton extends StatelessWidget {
  const _TorchButton({required this.camera});

  final MobileScannerController camera;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: camera,
      builder: (context, state, _) {
        if (!state.isRunning || state.torchState == TorchState.unavailable) {
          return const SizedBox.shrink();
        }

        final on = state.torchState == TorchState.on;
        return Semantics(
          toggled: on,
          child: IconButton(
            onPressed: () => unawaited(camera.toggleTorch()),
            tooltip: AppLocalizations.of(context).scannerTorch,
            icon: AppIcon(
              AppIcons.uiFlashlight,
              size: AppSizes.icon24,
              color: on ? context.colors.primary : Colors.white,
            ),
          ),
        );
      },
    );
  }
}

/// Камера не открылась: нет разрешения или она занята и сломана.
///
/// Без разрешения повторный запрос система может уже не показать, поэтому
/// подпись ведёт в настройки телефона, а «Повторить» — для тех, кто только
/// что оттуда вернулся.
class _CameraProblem extends StatelessWidget {
  const _CameraProblem({required this.error, required this.onRetry});

  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(
                AppIcons.uiCamera,
                size: AppSizes.metricIcon,
                color: Colors.white,
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                denied ? texts.scannerNoAccess : texts.scannerFailed,
                textAlign: TextAlign.center,
                style: context.texts.bodyMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.s6),
              AppButton(label: texts.retry, onPressed: onRetry, block: false),
            ],
          ),
        ),
      ),
    );
  }
}
