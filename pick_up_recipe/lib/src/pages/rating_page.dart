// Экран 05 «Как получилось» — оценка чашки.
//
// Обязательного здесь нет вовсе. Карта вкуса всегда в каком-то положении,
// звёзды можно не ставить, оси можно не трогать — и кнопка внизу работает
// при любом их сочетании. Так и должно быть: оценку ставят через минуту
// после чашки, часто одной рукой, и экран, который отказывается закрываться,
// пока в него не ткнули в нужное место, просто закроют силой.
//
// Раньше звёзды были обязательны, и кнопка на них молча ничего не делала:
// объяснение появлялось строкой ниже, за краем экрана. Незаполненные звёзды
// теперь уезжают как «не сказал» (в базе NULL), а не как ноль — ноль на шкале
// 0…10 значит «отвратительно» и попал бы в среднюю по позиции у обжарщика.
//
// Карта вместо анкеты потому, что одна точка отвечает на оба вопроса правил:
// горизонталь — экстракция (помол, температура, время), вертикаль —
// концентрация (соотношение). Шесть ползунков спрашивали бы то же самое
// шестью вопросами, из которых пять не влияют ни на одну поправку.
//
// Это не бланк SCA: там десять признаков с шагом 0,25 и нет горечи вовсе,
// а у нас на ней держатся правила. Режим каппинга, если понадобится, —
// отдельный экран.
//
// Всё натыканное переживает выход: экран пишет черновик в `RatingDrafts` и
// поднимает его обратно при возврате. Оценку ставят отвлекаясь, и потерянная
// половина работы не восстанавливается — чашка уже выпита.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/network_status.dart';
import '../../core/offline/offline_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/application/rating_draft.dart';
import '../features/recipes/domain/models/correction_model.dart';
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

  /// Общее впечатление в звёздах. 0 — не поставили, и это нормально.
  int _stars = 0;

  bool _busy = false;
  String? _error;

  /// Какие ползунки трогали. Нетронутая ось не уезжает вовсе: середина шкалы —
  /// это положение ползунка по умолчанию, а не то, что человек сказал.
  ///
  /// По одной оси, а не общим признаком: подпись обещает, что уедет только
  /// подвинутое, и «тронул аромат — поехали все шесть» было бы обманом.
  final Set<String> _touched = {};

  double _aroma = 5;
  double _flavor = 5;
  double _aftertaste = 5;
  double _acidity = 5;
  double _bitterness = 5;
  double _sweetness = 5;

  /// Отложенная запись черновика.
  ///
  /// Точку карты ведут пальцем, и запись на каждом кадре означала бы полсотни
  /// обращений к хранилищу за один жест. Пишем, когда рука остановилась.
  Timer? _draftWrite;

  /// Звёзды 1…5 → шкала 0…10, в которой живёт recipes_estimations.
  /// null — звёзд не ставили.
  double? get _overall => _stars == 0 ? null : _stars * 2;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  @override
  void dispose() {
    // Уходят с этого экрана чаще всего именно посреди оценки — дописываем то,
    // что не успел отложенный таймер, иначе последнее движение пропадёт.
    if (_draftWrite?.isActive ?? false) {
      _draftWrite!.cancel();
      unawaited(RatingDrafts.save(_draft()));
    }
    super.dispose();
  }

  /// Поднимает незаконченную оценку этой же чашки.
  ///
  /// Сверяем и рецепт, и пачку: базовый рецепт обжарщика один на всех, и
  /// перенести на другую пачку чужую половину оценки было бы хуже, чем
  /// потерять её.
  Future<void> _restoreDraft() async {
    final draft = await RatingDrafts.load();
    if (!mounted || draft == null) return;
    if (draft.recipe.id != widget.recipe.id) return;
    if (draft.pack?.packId != widget.pack?.packId) return;

    setState(() {
      _point = draft.point;
      _stars = draft.stars;
      for (final axis in draft.axes.entries) {
        _touched.add(axis.key);
        switch (axis.key) {
          case 'aroma':
            _aroma = axis.value;
          case 'flavor':
            _flavor = axis.value;
          case 'aftertaste':
            _aftertaste = axis.value;
          case 'acidity':
            _acidity = axis.value;
          case 'bitterness':
            _bitterness = axis.value;
          case 'sweetness':
            _sweetness = axis.value;
        }
      }
    });
  }

  RatingDraft _draft() => RatingDraft(
        recipe: widget.recipe,
        pack: widget.pack,
        point: _point,
        stars: _stars,
        axes: {
          for (final axis in _touched) axis: _axisValue(axis),
        },
        savedAt: DateTime.now(),
      );

  double _axisValue(String axis) => switch (axis) {
        'aroma' => _aroma,
        'flavor' => _flavor,
        'aftertaste' => _aftertaste,
        'acidity' => _acidity,
        'bitterness' => _bitterness,
        _ => _sweetness,
      };

  /// Запомнить сказанное — не сразу, а как только рука остановится.
  void _remember() {
    _draftWrite?.cancel();
    _draftWrite = Timer(AppDuration.slow, () => RatingDrafts.save(_draft()));
  }

  /// Отправляет оценку; [wantCorrection] — ещё и открыть рецепт с поправкой.
  ///
  /// Отдельной страницы «что изменилось» нет: по макету diff убран, и
  /// «Поправить рецепт» ведёт прямо в конструктор, где поправка уже
  /// применена, изменения помечены точками и её можно отменить целиком.
  Future<void> _submit({required bool wantCorrection}) async {
    final texts = AppLocalizations.of(context);

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Базовый рецепт (packId == 0) общий, и оценку на него не повесить:
      // владельца у него нет. Первая оценка и есть «первая правка» из C7 —
      // заводим свою копию с пачкой, с которой пришли, и оцениваем её.
      // Дальше вся цепочка — поправка, правки — идёт по копии.
      if (widget.recipe.packId == 0 && widget.pack != null) {
        widget.recipe.packId = widget.pack!.packId;
        widget.recipe.id = await _service.evolveRecipe(widget.recipe);
      }

      await _service.postEstimation(
        recipeId: widget.recipe.id,
        // Уезжает только сказанное. Нетронутые оси не размазываются общей
        // оценкой и не подменяются серединой шкалы: и то, и другое — числа,
        // которых человек не называл.
        aroma: _touched.contains('aroma') ? _aroma : null,
        flavor: _touched.contains('flavor') ? _flavor : null,
        aftertaste: _touched.contains('aftertaste') ? _aftertaste : null,
        acidity: _touched.contains('acidity') ? _acidity : null,
        bitterness: _touched.contains('bitterness') ? _bitterness : null,
        sweetness: _touched.contains('sweetness') ? _sweetness : null,
        overall: _overall,
        // По-русски и на английском телефоне: комментарий читают люди в
        // кабинете обжарщика, и язык этого поля — не язык телефона.
        comment: _point.isCenter ? '' : _point.summaryRu,
      );

      // Оценка уехала (или встала в очередь) — продолжать больше нечего.
      _draftWrite?.cancel();
      await RatingDrafts.clear();

      if (!mounted) return;

      if (!wantCorrection || _point.complaints.isEmpty) {
        if (!NetworkStatus.online.value) {
          _say(texts.rateSavedOffline);
        }
        await context.router.maybePop();
        return;
      }

      // Сервер отвечает и списком изменений, и готовым поправленным
      // рецептом: числа считает он, клиент их не выдумывает.
      final RecipeCorrection correction;
      try {
        correction = await _service.suggestCorrection(
          recipeId: widget.recipe.id,
          complaints: _point.complaints,
        );
      } on OfflineException {
        // Поправку считает сервер по своим правилам — повторить их на
        // телефоне значит завести вторые правила, которые разойдутся с
        // первыми. Оценка уже в очереди; рецепт можно поправить руками.
        if (!mounted) return;
        _say(texts.rateSavedCorrectionLater);
        await context.router.maybePop();
        return;
      }

      if (!mounted) return;

      // Жалобы тянут в разные стороны — сначала техника, не цифры (S15/S16).
      if (correction.hasConflicts) {
        await context.router.replace(
          RatingConflictRoute(
            recipe: widget.recipe,
            pack: widget.pack,
            summary: _point.summaryFor(texts),
            correction: correction,
          ),
        );
        return;
      }

      if (correction.isEmpty || correction.recipe == null) {
        _say(texts.rateNothingToChange);
        await context.router.maybePop();
        return;
      }

      // replace, а не push: возврат из конструктора должен вести к списку
      // рецептов, а не на уже отправленную оценку.
      await context.router.replace(
        RecipeBuilderRoute(
          recipe: correction.recipe!,
          original: widget.recipe,
          correctionLabel: _point.summaryFor(texts),
          pack: widget.pack,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Ползунок подвинули: запоминаем это отдельно от значения.
  ///
  /// Без такого признака нетронутая середина шкалы уехала бы как «пятёрка по
  /// аромату» — число, которого никто не называл.
  void _axis(String axis, VoidCallback change) {
    setState(() {
      change();
      _touched.add(axis);
    });
    _remember();
  }

  void _say(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    final subtitle = [
      widget.pack?.packName,
      widget.recipe.title.isNotEmpty ? widget.recipe.title : widget.recipe.device,
    ].whereType<String>().where((it) => it.isNotEmpty).join(' · ');

    return AppScreen(
      title: texts.rateTitle,
      body: [
        if (subtitle.isNotEmpty) ...[
          Text(subtitle, style: context.texts.bodySmall),
          const SizedBox(height: AppSpacing.s3),
        ],

        HeroSurface(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: TasteMap(
            point: _point,
            onChanged: (point) {
              setState(() => _point = point);
              _remember();
            },
          ),
        ),

        const SizedBox(height: AppSpacing.s3),
        _SummaryLine(
          point: _point,
          onReset: _point.isCenter
              ? null
              : () {
                  setState(() => _point = TastePoint.center);
                  _remember();
                },
        ),

        const SizedBox(height: AppSpacing.s3),
        _Stars(
          value: _stars,
          onChanged: (value) {
            setState(() {
              _stars = value;
              _error = null;
            });
            _remember();
          },
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

        Text(texts.rateAxesTitle, style: context.texts.bodyMedium),
        const SizedBox(height: AppSpacing.s1),
        Text(texts.rateAxesHint, style: context.texts.labelSmall),
        const SizedBox(height: AppSpacing.s3),

        QuietSurface(
          child: Column(
            children: [
              _Axis(
                label: texts.rateAxisAroma,
                value: _aroma,
                onChanged: (v) => _axis('aroma', () => _aroma = v),
              ),
              _Axis(
                label: texts.rateAxisFlavor,
                value: _flavor,
                onChanged: (v) => _axis('flavor', () => _flavor = v),
              ),
              _Axis(
                label: texts.rateAxisAftertaste,
                value: _aftertaste,
                onChanged: (v) => _axis('aftertaste', () => _aftertaste = v),
              ),
              _Axis(
                label: texts.rateAxisAcidity,
                value: _acidity,
                onChanged: (v) => _axis('acidity', () => _acidity = v),
              ),
              _Axis(
                label: texts.rateAxisBitterness,
                value: _bitterness,
                onChanged: (v) => _axis('bitterness', () => _bitterness = v),
              ),
              _Axis(
                label: texts.rateAxisSweetness,
                value: _sweetness,
                onChanged: (v) => _axis('sweetness', () => _sweetness = v),
              ),
            ],
          ),
        ),
      ],
      bottom: [
        if (_point.complaints.isEmpty)
          AppButton(
            label: texts.rateSave,
            loading: _busy,
            onPressed: _busy ? null : () => _submit(wantCorrection: false),
          )
        else ...[
          AppButton(
            label: texts.rateFixRecipe,
            icon: AppIcons.uiEdit,
            loading: _busy,
            onPressed: _busy ? null : () => _submit(wantCorrection: true),
          ),
          // Своей распорки здесь нет: панель уже разводит соседей на
          // AppSpacing.s2, и стоявший тут s3 только складывался с ним —
          // выходило двадцать восемь точек, из-за которых вторая кнопка
          // прижималась к нижней навигации.
          AppButton(
            label: texts.rateJustSave,
            kind: AppButtonKind.secondary,
            onPressed: _busy ? null : () => _submit(wantCorrection: false),
          ),
        ],
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
    final texts = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;

        void report(Offset local) {
          // Точка карты — доля от половины стороны: (0,0) в центре,
          // ±1 у края. Ось Y перевёрнута: вверх на экране — это «крепко».
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
            label: texts.rateMapSemantics(point.summaryFor(texts)),
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _TasteMapPainter(
                  point: point,
                  ends: (
                    sour: texts.rateTasteSour,
                    bitter: texts.rateTasteBitter,
                    strong: texts.rateTasteStrong,
                    weak: texts.rateTasteWeak,
                  ),
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
    required this.ends,
    required this.frame,
    required this.ink,
    required this.accent,
    required this.target,
  });

  final TastePoint point;

  /// Подписи четырёх концов осей — уже на языке интерфейса: холст словаря
  /// не видит, а по-русски они были прибиты прямо здесь.
  final ({String sour, String bitter, String strong, String weak}) ends;

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

    _label(canvas, ends.sour, Offset(center.dx - field - AppSpacing.s2, center.dy), ink,
        align: TextAlign.right, anchorRight: true);
    _label(canvas, ends.bitter, Offset(center.dx + field + AppSpacing.s2, center.dy), ink);
    // Все четыре подписи — наречия, одной частью речи. «Крепче» и «слабее»
    // рядом с «кисло» и «горько» читались как два разных вопроса на одном
    // круге: одна ось спрашивала «по сравнению с чем», вторая — «какое».
    // То же правило держит и английский: одна часть речи на все четыре конца.
    _label(canvas, ends.strong, Offset(center.dx, center.dy - field - AppSpacing.s5), ink,
        centered: true);
    _label(canvas, ends.weak, Offset(center.dx, center.dy + field + AppSpacing.s3), ink,
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

  // Не только точка: сменившийся язык оставляет точку на месте, а подписи
  // осей меняет, и без сравнения они остались бы от прошлого языка.
  @override
  bool shouldRepaint(_TasteMapPainter oldDelegate) =>
      oldDelegate.point != point || oldDelegate.ends != ends;
}

/// Что человек сказал картой — словами.
class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.point, required this.onReset});

  final TastePoint point;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return QuietSurface(
      child: Row(
        children: [
          AppIcon(
            point.isCenter ? AppIcons.uiCheck : AppIcons.uiWarning,
            size: AppSizes.icon20,
            color: point.isCenter ? context.palette.success : context.colors.primary,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(child: Text(point.summaryFor(texts), style: context.texts.bodyMedium)),
          if (onReset != null)
            IconButton(
              onPressed: onReset,
              tooltip: texts.remove,
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
    final texts = AppLocalizations.of(context);

    return QuietSurface(
      child: Row(
        children: [
          Text(texts.rateOverall, style: context.texts.bodyMedium),
          const SizedBox(width: AppSpacing.s2),
          for (var star = 1; star <= 5; star++)
            IconButton(
              onPressed: () => onChanged(star),
              tooltip: texts.rateStarsOf(star),
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
    final texts = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5),
      child: Row(
        children: [
          Text(texts.rateOptional, style: context.texts.bodySmall),
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
