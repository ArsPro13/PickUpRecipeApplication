// Экран 05 «Как получилось» — оценка чашки.
//
// Обязательного здесь ровно два элемента: карта вкуса и звёзды. Всё, что нужно
// правилам поправки, лежит выше разделителя «Необязательно», и человек,
// который закроет экран сразу после звёзд, ничего не потеряет.
//
// Карта вместо анкеты потому, что одна точка отвечает на оба вопроса правил:
// горизонталь — экстракция (помол, температура, время), вертикаль —
// концентрация (соотношение). Шесть ползунков спрашивали бы то же самое
// шестью вопросами, из которых пять не влияют ни на одну поправку.
//
// Это не бланк SCA: там десять признаков с шагом 0,25 и нет горечи вовсе,
// а у нас на ней держатся правила. Режим каппинга, если понадобится, —
// отдельный экран.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/app_router.dart';
import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/data_sources/remote/recipe_service.dart';
import '../features/recipes/domain/models/recipe_data_model.dart';
import '../features/recipes/domain/taste_map.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class RatingPage extends ConsumerStatefulWidget {
  const RatingPage({super.key, required this.recipe, this.pack});

  final RecipeData recipe;
  final PackData? pack;

  @override
  ConsumerState<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends ConsumerState<RatingPage> {
  final RecipeService _service = RecipeService();

  TastePoint _point = TastePoint.center;

  /// Общее впечатление в звёздах. 0 — ещё не поставили.
  int _stars = 0;

  bool _busy = false;
  String? _error;

  /// Шесть осей раскрываются по требованию: в обязательную часть они не
  /// входят, а развёрнутые сразу превращают экран в анкету.
  bool _detailsOpen = false;

  late double _aroma = 5;
  late double _flavor = 5;
  late double _aftertaste = 5;
  late double _acidity = 5;
  late double _bitterness = 5;
  late double _sweetness = 5;

  /// Звёзды 1…5 → шкала 0…10, в которой живёт recipes_estimations.
  double get _overall => _stars * 2;

  Future<void> _submit() async {
    if (_stars == 0) {
      setState(() => _error = 'Поставьте общую оценку — по ней рецепт попадёт в историю');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _service.postEstimation(
        recipeId: widget.recipe.id,
        // Развёрнутые оси необязательны. Если их не трогали, все шесть идут
        // общей оценкой: человек сказал одно число, и растаскивать его на
        // шесть разных выдуманных — хуже, чем повторить honest-но одно.
        aroma: _detailsOpen ? _aroma : _overall,
        flavor: _detailsOpen ? _flavor : _overall,
        aftertaste: _detailsOpen ? _aftertaste : _overall,
        acidity: _detailsOpen ? _acidity : _overall,
        bitterness: _detailsOpen ? _bitterness : _overall,
        sweetness: _detailsOpen ? _sweetness : _overall,
        overall: _overall,
        comment: _point.isCenter ? '' : _point.summary,
      );

      if (!mounted) return;

      // Жалоб нет — поправку просить не за что: чашка получилась.
      if (_point.complaints.isEmpty) {
        await context.router.maybePop();
        return;
      }

      await context.router.push(
        CorrectionReviewRoute(
          recipe: widget.recipe,
          pack: widget.pack,
          complaints: _point.complaints,
          summary: _point.summary,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      widget.pack?.packName,
      widget.recipe.title.isNotEmpty ? widget.recipe.title : widget.recipe.device,
    ].whereType<String>().where((it) => it.isNotEmpty).join(' · ');

    return AppScreen(
      title: 'Как получилось',
      body: [
        if (subtitle.isNotEmpty) ...[
          Text(subtitle, style: context.texts.bodySmall),
          const SizedBox(height: AppSpacing.s3),
        ],

        HeroSurface(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: TasteMap(
            point: _point,
            onChanged: (point) => setState(() => _point = point),
          ),
        ),

        const SizedBox(height: AppSpacing.s3),
        _SummaryLine(
          point: _point,
          onReset: _point.isCenter ? null : () => setState(() => _point = TastePoint.center),
        ),

        const SizedBox(height: AppSpacing.s3),
        _Stars(
          value: _stars,
          onChanged: (value) => setState(() {
            _stars = value;
            _error = null;
          }),
        ),

        if (_error != null) ...[
          const SizedBox(height: AppSpacing.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(AppIcons.uiWarning, size: AppSizes.icon20, color: context.colors.error),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  _error!,
                  style: context.texts.bodySmall?.copyWith(color: context.colors.error),
                ),
              ),
            ],
          ),
        ],

        const _OptionalDivider(),

        QuietSurface(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Разобрать по осям', style: context.texts.bodyMedium),
                  ),
                  Switch(
                    value: _detailsOpen,
                    onChanged: (value) => setState(() => _detailsOpen = value),
                  ),
                ],
              ),
              if (_detailsOpen) ...[
                const SizedBox(height: AppSpacing.s2),
                _Axis(label: 'Аромат', value: _aroma, onChanged: (v) => setState(() => _aroma = v)),
                _Axis(label: 'Вкус', value: _flavor, onChanged: (v) => setState(() => _flavor = v)),
                _Axis(
                  label: 'Послевкусие',
                  value: _aftertaste,
                  onChanged: (v) => setState(() => _aftertaste = v),
                ),
                _Axis(
                  label: 'Кислотность',
                  value: _acidity,
                  onChanged: (v) => setState(() => _acidity = v),
                ),
                _Axis(
                  label: 'Горечь',
                  value: _bitterness,
                  onChanged: (v) => setState(() => _bitterness = v),
                ),
                _Axis(
                  label: 'Сладость',
                  value: _sweetness,
                  onChanged: (v) => setState(() => _sweetness = v),
                ),
              ],
            ],
          ),
        ),
      ],
      bottom: [
        AppButton(
          label: _point.complaints.isEmpty ? 'Сохранить' : 'Что поправить',
          loading: _busy,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}

/// Карта вкуса: две оси, три кольца, цель обжарщика в центре и своя точка.
class TasteMap extends StatelessWidget {
  const TasteMap({super.key, required this.point, required this.onChanged});

  final TastePoint point;
  final ValueChanged<TastePoint> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;

        void report(Offset local) {
          // Точка карты — доля от половины стороны: (0,0) в центре,
          // ±1 у края. Ось Y перевёрнута: вверх на экране — это «крепче».
          final half = size / 2;
          onChanged(
            TastePoint(
              (local.dx - half) / half,
              -(local.dy - half) / half,
            ).clamped(),
          );
        }

        return GestureDetector(
          onTapDown: (details) => report(details.localPosition),
          onPanUpdate: (details) => report(details.localPosition),
          child: Semantics(
            label: 'Карта вкуса. ${point.summary}',
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _TasteMapPainter(
                  point: point,
                  frame: context.palette.border,
                  ink: context.colors.secondary,
                  accent: context.colors.primary,
                  target: context.palette.success,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TasteMapPainter extends CustomPainter {
  const _TasteMapPainter({
    required this.point,
    required this.frame,
    required this.ink,
    required this.accent,
    required this.target,
  });

  final TastePoint point;
  final Color frame;
  final Color ink;
  final Color accent;
  final Color target;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final half = size.width / 2;

    // Поле оставляет поля под подписи осей.
    final field = half * 0.74;

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppStroke.thin
      ..color = frame;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: field * 2, height: field * 2),
        const Radius.circular(AppRadius.l),
      ),
      line,
    );

    // Три кольца — три ступени силы: чуть, заметно, сильно.
    for (final fraction in const [0.3, 0.6, 0.9]) {
      canvas.drawCircle(center, field * fraction, line);
    }

    canvas.drawLine(
      Offset(center.dx - field, center.dy),
      Offset(center.dx + field, center.dy),
      line,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - field),
      Offset(center.dx, center.dy + field),
      line,
    );

    // Цель обжарщика — в центре: «получилось как задумано».
    canvas.drawCircle(
      center,
      field * 0.14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.thick
        ..color = target,
    );

    _label(canvas, 'кисло', Offset(center.dx - field - AppSpacing.s2, center.dy), ink,
        align: TextAlign.right, anchorRight: true);
    _label(canvas, 'горько', Offset(center.dx + field + AppSpacing.s2, center.dy), ink);
    _label(canvas, 'крепче', Offset(center.dx, center.dy - field - AppSpacing.s5), ink,
        centered: true);
    _label(canvas, 'слабее', Offset(center.dx, center.dy + field + AppSpacing.s3), ink,
        centered: true);

    if (point.isCenter) return;

    final you = Offset(center.dx + point.x * field, center.dy - point.y * field);

    canvas.drawLine(
      center,
      you,
      Paint()
        ..strokeWidth = AppStroke.thin
        ..color = accent.withValues(alpha: 0.5),
    );
    canvas.drawCircle(you, AppSpacing.s5, Paint()..color = accent.withValues(alpha: 0.18));
    canvas.drawCircle(you, AppSpacing.s2, Paint()..color = accent);
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at,
    Color color, {
    TextAlign align = TextAlign.left,
    bool centered = false,
    bool anchorRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 12)),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();

    final dx = centered
        ? at.dx - painter.width / 2
        : (anchorRight ? at.dx - painter.width : at.dx);

    painter.paint(canvas, Offset(dx, at.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(_TasteMapPainter oldDelegate) => oldDelegate.point != point;
}

/// Что человек сказал картой — словами.
class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.point, required this.onReset});

  final TastePoint point;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return QuietSurface(
      child: Row(
        children: [
          AppIcon(
            point.isCenter ? AppIcons.uiCheck : AppIcons.uiWarning,
            size: AppSizes.icon20,
            color: point.isCenter ? context.palette.success : context.colors.primary,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(child: Text(point.summary, style: context.texts.bodyMedium)),
          if (onReset != null)
            IconButton(
              onPressed: onReset,
              tooltip: 'Убрать',
              icon: AppIcon(
                AppIcons.uiClose,
                size: AppSizes.icon16,
                color: context.colors.secondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Общее впечатление: пять звёзд.
class _Stars extends StatelessWidget {
  const _Stars({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return QuietSurface(
      child: Row(
        children: [
          Text('Общее', style: context.texts.bodyMedium),
          const SizedBox(width: AppSpacing.s2),
          for (var star = 1; star <= 5; star++)
            IconButton(
              onPressed: () => onChanged(star),
              tooltip: '$star из 5',
              constraints: const BoxConstraints(
                minWidth: AppSizes.tapTarget - AppSpacing.s4,
                minHeight: AppSizes.tapTarget - AppSpacing.s4,
              ),
              padding: EdgeInsets.zero,
              icon: AppIcon(
                star <= value ? AppIcons.uiStarFilled : AppIcons.uiStar,
                size: AppSizes.icon24,
                color: star <= value ? context.colors.primary : context.colors.secondary,
              ),
            ),
          const Spacer(),
          if (value > 0)
            Text(
              '$value',
              style: context.texts.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

/// Разделитель «Необязательно»: всё нужное правилам осталось выше.
class _OptionalDivider extends StatelessWidget {
  const _OptionalDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5),
      child: Row(
        children: [
          Text('Необязательно', style: context.texts.bodySmall),
          const SizedBox(width: AppSpacing.s3),
          Expanded(child: Divider(color: context.palette.border)),
        ],
      ),
    );
  }
}

/// Одна ось развёрнутой оценки.
class _Axis extends StatelessWidget {
  const _Axis({required this.label, required this.value, required this.onChanged});

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: AppSpacing.s18 + AppSpacing.s5, child: Text(label, style: context.texts.bodySmall)),
        Expanded(
          child: Slider(
            value: value,
            max: 10,
            divisions: 40,
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: AppSpacing.s12,
          child: Text(
            value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2),
            style: context.texts.bodySmall,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
