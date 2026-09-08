// Фотография пачки.
//
// Кнопки «разобрать надписи с фотографии» здесь больше нет: владелец попросил
// убрать её на время. Сам разбор никуда не делся — PackService.getPackByImage,
// модель ответа и состояния сканирования в нотифаере остались на месте и ждут,
// когда распознавание вернут; ушла только дорога к ним с экрана.
//
// Снимок нужен и сам по себе. Пачек без нашего кода на полке большинство, и
// фотография — единственное, по чему человек узнаёт свою пачку в списке:
// «Бразилия · Серрадо» у него таких три. Поэтому кадр сохраняется вместе с
// пачкой (pack_image), а рамка с подсказкой объясняет, что именно снимать.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pick_up_recipe/core/converters.dart';
import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';
import 'package:pick_up_recipe/src/general_widgets/app_icon.dart';
import 'package:pick_up_recipe/src/general_widgets/app_kit.dart';
import 'package:pick_up_recipe/src/themes/app_icons.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';

class InsertingPackInfoCameraWidget extends ConsumerStatefulWidget {
  const InsertingPackInfoCameraWidget({super.key});

  @override
  ConsumerState<InsertingPackInfoCameraWidget> createState() =>
      _InsertingPackInfoCameraWidgetState();
}

class _InsertingPackInfoCameraWidgetState
    extends ConsumerState<InsertingPackInfoCameraWidget> {
  final ImagePicker _picker = ImagePicker();

  /// Камера открыта или снимок ещё жмётся: второй раз жать нельзя.
  bool _busy = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);

    // Подписи берём до похода в камеру: после await контекст трогать нельзя,
    // а сообщение об ошибке нужно на том же языке, что и остальной экран.
    final texts = AppLocalizations.of(context);
    final formNotifier = ref.read(formNotifierProvider.notifier);
    try {
      final image = await _picker.pickImage(
        source: source,
        // Те же пределы, что были у распознавания: пачка целиком читается и
        // в 720 точек по ширине, а в base64 такой кадр весит меньше мегабайта.
        maxHeight: 1440,
        maxWidth: 720,
        imageQuality: 60,
      );
      // Человек передумал и закрыл камеру — это не ошибка.
      if (image == null) return;

      await formNotifier.updateImage(image: await convertXFileToBase64(image));
      await formNotifier.finishScanning();
    } catch (error) {
      logger.e('Снимок пачки не получился', error: error);
      await formNotifier.finishScanning(error: texts.packFormPhotoFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(formNotifierProvider);
    final image = state.image;
    final texts = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (image == null)
          _PhotoHint(onTap: _busy ? null : () => _pickImage(ImageSource.camera))
        else
          _PhotoPreview(base64Image: image),
        const SizedBox(height: AppSpacing.s3),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: image == null
                    ? texts.packFormPhotoTake
                    : texts.packFormPhotoRetake,
                icon: AppIcons.uiCamera,
                kind: image == null ? AppButtonKind.primary : AppButtonKind.secondary,
                loading: _busy,
                onPressed: () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: AppButton(
                label: texts.packFormPhotoFromGallery,
                icon: AppIcons.uiPack,
                kind: AppButtonKind.secondary,
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
        if (state.imageErrorMessage != null) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            texts.packFormPhotoFailed,
            style: context.texts.labelSmall?.copyWith(color: context.colors.error),
          ),
        ],
      ],
    );
  }
}

/// Рамка-подсказка: что снимать и зачем.
///
/// Пунктирная рамка, как у «добавить шаг» в конструкторе: приглашение завести
/// новое, а не уже существующий элемент. Внутри дышит прицел вокруг пачки —
/// движение показывает, что пачку надо поместить в кадр целиком.
class _PhotoHint extends StatefulWidget {
  const _PhotoHint({required this.onTap});

  final VoidCallback? onTap;

  @override
  State<_PhotoHint> createState() => _PhotoHintState();
}

class _PhotoHintState extends State<_PhotoHint> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: AppDuration.ambient,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashedBorderBox(
      onTap: widget.onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s5,
      ),
      child: Column(
        children: [
          SizedBox(
            height: AppSizes.icon72,
            child: AnimatedBuilder(
              animation: _breath,
              builder: (context, _) => CustomPaint(
                painter: _FramingPainter(
                  ink: context.colors.secondary,
                  accent: context.colors.primary,
                  breath: AppCurves.inOut.transform(_breath.value),
                ),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            AppLocalizations.of(context).packFormPhotoTitle,
            style: context.texts.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            AppLocalizations.of(context).packFormPhotoNote,
            style: context.texts.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Прицел, дышащий вокруг пачки: уголки то сходятся к ней, то расходятся.
class _FramingPainter extends CustomPainter {
  const _FramingPainter({required this.ink, required this.accent, required this.breath});

  final Color ink;
  final Color accent;

  /// 0…1 — насколько уголки сошлись к пачке.
  final double breath;

  /// Рисунок задуман в прямоугольнике 120×72.
  static const Size _art = Size(120, 72);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / _art.height;
    canvas.save();
    canvas.translate((size.width - _art.width * scale) / 2, 0);
    canvas.scale(scale);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink
      ..strokeWidth = 2;

    // Пачка: планка сверху, чуть провисший низ.
    canvas.drawPath(
      Path()
        ..moveTo(48, 12)
        ..lineTo(74, 11)
        ..lineTo(76, 60)
        ..quadraticBezierTo(60, 64, 46, 61)
        ..close(),
      line,
    );
    canvas.drawLine(
      const Offset(51, 18),
      const Offset(71, 17),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = ink.withValues(alpha: 0.5)
        ..strokeWidth = 1.4,
    );

    // Уголки прицела: на вдохе отходят от пачки, на выдохе прижимаются.
    final spread = 8 + 10 * (1 - breath);
    final frame = Rect.fromLTRB(46 - spread, 11 - spread, 76 + spread, 61 + spread);

    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent
      ..strokeWidth = 2.4;

    const arm = 9.0;
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

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FramingPainter oldDelegate) {
    return oldDelegate.breath != breath ||
        oldDelegate.ink != ink ||
        oldDelegate.accent != accent;
  }
}

/// Снятый кадр: то, что уедет на сервер в pack_image.
class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.base64Image});

  final String base64Image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.medium,
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: Image.memory(
          base64Decode(base64Image),
          fit: BoxFit.cover,
          // Битый base64 не должен ронять форму: показываем заглушку и даём
          // переснять — снимок здесь не обязателен.
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: context.colors.secondaryContainer,
            child: Center(
              child: AppIcon(
                AppIcons.uiCamera,
                size: AppSizes.icon32,
                color: context.colors.secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
