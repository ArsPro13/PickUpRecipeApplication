// Карта вкуса на экране: круг, по которому водят пальцем.
//
// Что точка значит — в `features/recipes/domain/taste_map.dart`. Здесь только
// то, как её ставят и как она выглядит.
//
// ПАЛЕЦ. Карта стоит в прокручиваемой странице, и это главное, что про неё
// надо помнить. Раньше она слушала палец обычным GestureDetector с onTapDown
// и onPanUpdate, и «тянуть точку», как просит подпись над картой, не выходило
// сразу по четырём причинам:
//   • тянуть было нечего: пока точка в центре, ручка не рисовалась вовсе;
//   • движение вверх-вниз забирала прокрутка страницы — ей хватает вдвое
//     меньшего пути, чем жесту «pan»;
//   • движение вбок карта получала, только когда палец этот путь уже прошёл;
//   • палец пересчитывался в точку по всей стороне виджета, а рисовалась
//     точка по радиусу круга — он уже. Ручка вставала не под пальцем, а на
//     три четверти пути к нему.
//
// Теперь правила такие, и других нет:
//   1. Ручка видна всегда. Взяли её — она идёт за пальцем с первого же
//      движения и в любую сторону; страница при этом стоит.
//   2. Нажали в другое место круга — ручка встаёт туда.
//   3. Повели пальцем мимо ручки: вбок — ручка приходит под палец и идёт за
//      ним; вверх-вниз — это прокрутка страницы, карта её не трогает.
//      Придержали палец на месте — тоже взяли, дальше хоть вверх, хоть вниз.
//   4. Мимо круга — углы и подписи осей — карта палец не слушает вовсе.
//
// Третье правило — уступка, и сделана она нарочно. Забирай карта любое
// касание, страница под ней перестала бы прокручиваться: круг занимает
// экран почти во всю ширину. И хуже того — человек, который просто листает
// страницу, заодно переставлял бы свою оценку.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../features/recipes/domain/taste_map.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

/// Карта вкуса: две оси, три кольца, цель обжарщика в центре и своя точка.
///
/// Точку держит тот, кто карту показывает: карта только сообщает, куда её
/// поставили. Подвинули точку снаружи — крестиком под картой, поднятым
/// черновиком — ручка доезжает до нового места сама.
class TasteMap extends StatefulWidget {
  const TasteMap({super.key, required this.point, required this.onChanged});

  final TastePoint point;
  final ValueChanged<TastePoint> onChanged;

  /// Холст ручки. По нему тест находит, где ручка нарисована.
  @visibleForTesting
  static const Key knobKey = ValueKey<String>('taste-map-knob');

  /// Холст круга. По нему тест сверяет, где нарисованы кольца.
  @visibleForTesting
  static const Key fieldKey = ValueKey<String>('taste-map-field');

  @override
  State<TasteMap> createState() => _TasteMapState();
}

class _TasteMapState extends State<TasteMap> with TickerProviderStateMixin {
  /// Ход ручки к новому месту: единица — дошла.
  ///
  /// Едет только нарисованная ручка. Сама точка меняется сразу и один раз:
  /// иначе фраза под картой успела бы за одно нажатие перебрать всё, что
  /// лежит по дороге.
  late final AnimationController _glide = AnimationController(
    vsync: this,
    duration: AppDuration.fast,
    value: 1,
  );

  /// Ручка под пальцем: ноль — лежит, единица — взята.
  late final AnimationController _held = AnimationController(
    vsync: this,
    duration: AppDuration.instant,
    reverseDuration: AppDuration.fast,
  );

  /// Всё, от чего ручку надо перерисовать, помимо самой точки.
  late final Listenable _knobMoves = Listenable.merge([_glide, _held]);

  /// Откуда ручка едет к точке, пока [_glide] не дошёл до единицы. Место на
  /// круге, как у [TastePoint.disc].
  Offset _glideFrom = Offset.zero;

  /// Что карта сказала наружу сама и чего ещё не получила обратно.
  TastePoint? _said;

  /// На сколько ручка отстоит от пальца, который её взял, в точках экрана.
  ///
  /// Взятая ручка остаётся под пальцем тем же местом, за которое её взяли:
  /// прыгни она серединой под палец, одно прикосновение уже меняло бы
  /// оценку. А взятую с краю ещё и видно из-под пальца.
  Offset _grip = Offset.zero;

  /// Можно ли ручке ехать: человек мог попросить телефон без анимаций.
  bool _motion = true;

  /// Точка, как её знает карта: уже сказанная, даже если экран ещё не
  /// перерисовался.
  TastePoint get _now => _said ?? widget.point;

  _TasteGeometry get _geometry => _TasteGeometry(context.size ?? Size.zero);

  /// Где сейчас нарисована ручка, если точка — [target].
  Offset _placeOf(TastePoint target) => Offset.lerp(
        _glideFrom,
        target.disc,
        Curves.easeOutCubic.transform(_glide.value),
      )!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = !MediaQuery.disableAnimationsOf(context);
  }

  @override
  void didUpdateWidget(TasteMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final mine = widget.point == _said;
    _said = null;
    if (mine || widget.point == oldWidget.point) return;

    // Точку подвинули снаружи. Ручка доезжает, а не перескакивает: скачок
    // читается как «что-то сломалось», а не как «сбросили».
    _glideFromHere(oldWidget.point, over: AppDuration.fast);
  }

  @override
  void dispose() {
    _glide.dispose();
    _held.dispose();
    super.dispose();
  }

  /// Пускает ручку в путь от места, где она нарисована сейчас, пока точка —
  /// [shown]. Дорога занимает [over].
  void _glideFromHere(TastePoint shown, {required Duration over}) {
    if (!_motion) return;
    _glideFrom = _placeOf(shown);
    _glide
      ..duration = over
      ..forward(from: 0);
  }

  /// Сообщает новую точку. [glide] — за сколько ручка до неё доедет; без
  /// него ручка уже там: её ведёт палец.
  void _say(TastePoint next, {Duration? glide}) {
    final before = _now;
    if (next == before) return;

    if (glide != null) _glideFromHere(before, over: glide);

    // Щелчок — как у барабанов: по нему слышно, что фраза под картой
    // сменилась. Палец закрывает ручку, а ладонь — саму фразу.
    if (!next.saysSameAs(before)) HapticFeedback.selectionClick();

    _said = next;
    widget.onChanged(next);
  }

  /// Точка, на которой ручку оставили. Внутри цели она встаёт ровно в центр:
  /// «попал» должно выглядеть как попадание, а не как «чуть-чуть мимо».
  TastePoint _settled(TastePoint point) =>
      point.isCenter ? TastePoint.center : point;

  TastePoint _pointAt(Offset local) =>
      TastePoint.fromDisc(_geometry.toDisc(local));

  /// Что под пальцем: ручка, круг или поля с подписями.
  _TasteSpot _whereIs(Offset local) {
    final geometry = _geometry;
    final knob = geometry.toLocal(_placeOf(widget.point));

    if ((local - knob).distance <= _TasteGeometry.grip) return _TasteSpot.knob;

    return (local - geometry.center).distance <=
            geometry.field + _TasteGeometry.margin
        ? _TasteSpot.field
        : _TasteSpot.outside;
  }

  void _grab(Offset local, {required bool onKnob}) {
    _held.forward();

    if (!onKnob) {
      // Взяли мимо ручки — она сама приходит под палец, и быстро: палец уже
      // лежит на экране и ждёт её.
      _grip = Offset.zero;
      _say(_pointAt(local), glide: AppDuration.instant);
      return;
    }

    // Ручку поймали на ходу: дальше она идёт от того места, где её поймали.
    if (_glide.isAnimating) {
      final caught = TastePoint.fromDisc(_placeOf(_now));
      _glide.value = 1;
      _say(caught);
    }

    _grip = _geometry.toLocal(_now.disc) - local;
  }

  void _drag(Offset local) => _say(_pointAt(local + _grip));

  void _release() {
    _held.reverse();
    _say(_settled(_now), glide: AppDuration.fast);
  }

  void _tap(Offset local) {
    _held.reverse();

    // Нажали на саму ручку — она уже здесь. Сдвигать её на пару точек под
    // середину пальца незачем: это меняло бы оценку от простого касания.
    final knob = _geometry.toLocal(_now.disc);
    final next = (local - knob).distance <= _TasteGeometry.dotReach
        ? _now
        : _pointAt(local);

    _say(_settled(next), glide: AppDuration.fast);
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      // Действий для голосового помощника у карты нет, и это нарочно. Он
      // «нажимает» без места нажатия, и прежняя карта получала от него левый
      // верхний угол — «сильно кисло, сильно крепко».
      excludeFromSemantics: true,
      gestures: <Type, GestureRecognizerFactory>{
        _TasteTouchRecognizer:
            GestureRecognizerFactoryWithHandlers<_TasteTouchRecognizer>(
          () => _TasteTouchRecognizer(debugOwner: this),
          (recognizer) => recognizer
            ..gestureSettings = MediaQuery.maybeGestureSettingsOf(context)
            ..whereIs = _whereIs
            ..onGrab = _grab
            ..onDrag = _drag
            ..onRelease = _release
            ..onTap = _tap,
        ),
      },
      child: Semantics(
        label: texts.rateMapSemantics(widget.point.summaryFor(texts)),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Круг с подписями рисуется один раз, а не на каждое движение
              // пальца: над ним ходит только ручка.
              RepaintBoundary(
                child: CustomPaint(
                  key: TasteMap.fieldKey,
                  painter: _TasteFieldPainter(
                    ends: (
                      sour: texts.rateTasteSour,
                      bitter: texts.rateTasteBitter,
                      strong: texts.rateTasteStrong,
                      weak: texts.rateTasteWeak,
                    ),
                    frame: context.palette.border,
                    ink: context.colors.onSurface,
                    zones: _TasteZones.of(Theme.of(context).brightness),
                    fontFamily: context.texts.bodyMedium?.fontFamily,
                  ),
                ),
              ),
              // И ручка — на своём слое: иначе каждое её движение заново
              // рисовало бы подложку карты вместе с тенью.
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _knobMoves,
                  builder: (context, _) => CustomPaint(
                    key: TasteMap.knobKey,
                    painter: TasteKnobPainter(
                      at: _placeOf(widget.point),
                      held: _held.value,
                      accent: context.colors.primary,
                      rim: context.colors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Размеры карты — одни на рисование и на палец.
///
/// Раньше рисунок мерил от радиуса круга, а палец — от половины стороны, и
/// ручка расходилась с пальцем на четверть пути. Общий расчёт не даёт им
/// разойтись снова.
class _TasteGeometry {
  const _TasteGeometry(this.size);

  final Size size;

  /// Доля стороны под сам круг: остальное — поля под подписи осей.
  static const double _fieldShare = 0.76;

  /// Ручка: сама точка и ореол вокруг. У взятой оба крупнее — так видно,
  /// что она в руке, и её края выглядывают из-под пальца.
  static const double dot = 9;
  static const double dotHeld = 11;
  static const double halo = AppSpacing.s5;
  static const double haloHeld = 30;

  /// Нажатие ближе этого к середине ручки — нажатие на неё саму.
  static const double dotReach = 14;

  /// С какого расстояния палец ещё берёт ручку. Больше нарисованного:
  /// большим пальцем в кружок с ноготь не попадают.
  static const double grip = 30;

  /// Запас за краем круга: нажатие чуть мимо края — это нажатие на край.
  static const double margin = AppSpacing.s3;

  Offset get center => size.center(Offset.zero);

  /// Радиус круга.
  double get field => size.shortestSide / 2 * _fieldShare;

  /// Место на круге → место на холсте. На круге вверх — «крепко», а на
  /// холсте ось Y смотрит вниз.
  Offset toLocal(Offset place) =>
      Offset(center.dx + place.dx * field, center.dy - place.dy * field);

  /// Место на холсте → место на круге.
  Offset toDisc(Offset local) {
    if (field <= 0) return Offset.zero;
    return Offset(
      (local.dx - center.dx) / field,
      (center.dy - local.dy) / field,
    );
  }
}

/// Что оказалось под пальцем.
enum _TasteSpot {
  /// Поля карты: углы, подписи осей.
  outside,

  /// Круг, но не ручка.
  field,

  /// Ручка или место совсем рядом с ней.
  knob,
}

/// Палец на карте: что из его движений — карте, а что — прокрутке страницы.
///
/// Свой распознаватель, а не набор готовых: готовый «pan» ждёт, пока палец
/// пройдёт вдвое больше, чем нужно прокрутке, и вертикаль всегда проигрывает.
/// Здесь спор со страницей решается по правилам из шапки файла.
class _TasteTouchRecognizer extends OneSequenceGestureRecognizer {
  _TasteTouchRecognizer({super.debugOwner})
      : super(allowedButtonsFilter: _primaryOnly);

  static bool _primaryOnly(int buttons) => buttons == kPrimaryButton;

  /// Сколько палец лежит на месте, прежде чем круг отдаёт ему ручку.
  ///
  /// Столько же iOS ждёт, прежде чем отдать касание кнопке внутри списка:
  /// пролистывающий палец за это время уже уходит с места, нажимающий — нет.
  static const Duration _rest = Duration(milliseconds: 150);

  /// Касание ручки короче этого и без движения — «поставь сюда», а не
  /// «взял и отпустил».
  static const Duration _tapWithin = Duration(milliseconds: 250);

  _TasteSpot Function(Offset local)? whereIs;
  void Function(Offset local, {required bool onKnob})? onGrab;
  ValueChanged<Offset>? onDrag;
  VoidCallback? onRelease;
  ValueChanged<Offset>? onTap;

  /// Палец, за которым следим. Второй карта не слушает.
  int? _pointer;

  bool _onKnob = false;
  bool _dragging = false;

  /// Где палец опустился и где он сейчас — на экране.
  Offset _down = Offset.zero;
  Offset _now = Offset.zero;

  /// Где палец сейчас — на карте.
  Offset _local = Offset.zero;

  Duration _downAt = Duration.zero;

  /// Как далеко палец уходил от места касания за всё время.
  double _strayed = 0;

  /// Путь, после которого движение — уже движение, а не дрожь пальца.
  double _slop = kTouchSlop;

  /// Место нажатия, пока спор за него не закончен.
  Offset? _tapAt;

  Timer? _restTimer;
  Offset _restFrom = Offset.zero;

  @override
  String get debugDescription => 'taste map';

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (_pointer != null || !super.isPointerAllowed(event)) return false;
    return whereIs?.call(event.localPosition) != _TasteSpot.outside;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);

    _pointer = event.pointer;
    _onKnob = whereIs?.call(event.localPosition) == _TasteSpot.knob;
    _dragging = false;
    _tapAt = null;
    _down = _now = event.position;
    _local = event.localPosition;
    _downAt = event.timeStamp;
    _strayed = 0;
    _slop = computeHitSlop(event.kind, gestureSettings);

    // Ручку берут сразу: ждать, пока палец пройдёт положенный путь, значит
    // отдать его прокрутке. Мышью страницу не таскают, спорить ей не с кем.
    if (_onKnob || event.kind == PointerDeviceKind.mouse) {
      resolve(GestureDisposition.accepted);
    } else {
      _watchRest();
    }
  }

  /// Ждёт, пока палец полежит на месте.
  void _watchRest() {
    _restFrom = _now;
    _restTimer?.cancel();
    _restTimer = Timer(_rest, () {
      if (_pointer == null || _dragging) return;

      if ((_now - _restFrom).distance <= _slop / 2) {
        resolve(GestureDisposition.accepted);
      } else {
        // Палец ползёт. Куда — решит путь, а не время.
        _watchRest();
      }
    });
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;

    if (event is PointerMoveEvent) {
      _now = event.position;
      _local = event.localPosition;

      final path = _now - _down;
      _strayed = math.max(_strayed, path.distance);

      if (_dragging) {
        onDrag?.call(_local);
      } else if (path.distance > _slop) {
        // Палец пошёл, не дождавшись ручки. Вбок страницу не листают — это
        // карте. Вверх-вниз — прокрутке: уступаем сразу, не дожидаясь, пока
        // она заберёт палец сама.
        resolve(
          path.dx.abs() > path.dy.abs()
              ? GestureDisposition.accepted
              : GestureDisposition.rejected,
        );
      }
    } else if (event is PointerUpEvent) {
      _local = event.localPosition;

      if (!_dragging) {
        // Отпустили, не успев ни повести, ни придержать, — это нажатие.
        // Забираем его сами: место нажатия нужно до того, как арену
        // подметут.
        _tapAt = _local;
        resolve(GestureDisposition.accepted);
      } else if (_onKnob &&
          _strayed <= _slop &&
          event.timeStamp - _downAt <= _tapWithin) {
        onTap?.call(_local);
      } else {
        onRelease?.call();
      }

      stopTrackingPointer(event.pointer);
    } else if (event is PointerCancelEvent) {
      if (_dragging) {
        onRelease?.call();
      } else {
        resolve(GestureDisposition.rejected);
      }

      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) {
    // Спор закончен, кто бы его ни решил, — запись о нём больше не нужна.
    resolvePointer(pointer, GestureDisposition.accepted);
    if (pointer != _pointer || _dragging) return;

    _restTimer?.cancel();

    final tapAt = _tapAt;
    if (tapAt != null) {
      _tapAt = null;
      onTap?.call(tapAt);
      return;
    }

    // Сюда приходят четырьмя путями: взяли ручку, повели пальцем вбок,
    // придержали его на месте — или спорить оказалось не с кем: страница
    // под картой не прокручивается.
    _dragging = true;
    onGrab?.call(_local, onKnob: _onKnob);
  }

  @override
  void rejectGesture(int pointer) {
    resolvePointer(pointer, GestureDisposition.rejected);
    if (pointer != _pointer) return;
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _restTimer?.cancel();
    _restTimer = null;
    _pointer = null;
    _dragging = false;
    _tapAt = null;
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }
}

/// Раскраска колец карты: чем дальше от центра, тем хуже.
///
/// Цвета зашиты числами, а не взяты из темы: это выбранные краски, а не
/// производные от фона. В тёмной теме — мягкий светофор, в светлой —
/// «Пряности»: олива, куркума, паприка. Одни и те же три круга в тёмной теме
/// светофором выглядели правильно, а в светлой краснили — на белом та же
/// заливка читается вдвое громче.
///
/// Непрозрачность у светлой темы выше: заливка ложится на белое и гаснет.
class _TasteZones {
  const _TasteZones(this.colors, this.alpha, this.aim);

  /// От центра наружу: «чуть» (а внутри пунктира — «как задумано»),
  /// «заметно», «сильно». Границы — [TastePoint.ringRadii].
  final List<Color> colors;
  final List<double> alpha;

  /// Пунктир цели обжарщика. Не цвет ближнего кольца: пунктир лежит ПОВЕРХ
  /// этого кольца, и тем же цветом его не видно — проверено на экране.
  final Color aim;

  static const _TasteZones _light = _TasteZones(
    [Color(0xFFA9C24F), Color(0xFFF2B733), Color(0xFFD95F2E)],
    [0.64, 0.58, 0.52],
    Color(0xFF5F7320),
  );

  static const _TasteZones _dark = _TasteZones(
    [Color(0xFF3FBF63), Color(0xFFE5A93C), Color(0xFFE2594A)],
    [0.46, 0.38, 0.32],
    Color(0xFF7BE29A),
  );

  static _TasteZones of(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  Color band(int ring) => colors[ring].withValues(alpha: alpha[ring]);
}

/// Круг карты: кольца, оси, цель и подписи. Всё, что не двигается.
class _TasteFieldPainter extends CustomPainter {
  const _TasteFieldPainter({
    required this.ends,
    required this.frame,
    required this.ink,
    required this.zones,
    required this.fontFamily,
  });

  /// Подписи четырёх концов осей — уже на языке интерфейса: холст словаря
  /// не видит, а по-русски они были прибиты прямо здесь.
  final ({String sour, String bitter, String strong, String weak}) ends;

  final Color frame;
  final Color ink;
  final _TasteZones zones;

  /// Шрифт подписей. Холст темы не видит: стиль, собранный здесь без
  /// семейства, рисовался бы системным шрифтом, а не шрифтом приложения.
  final String? fontFamily;

  /// Доли поля, на которых стоят кольца. Внешнее кольцо и есть край поля.
  ///
  /// Не свои числа, а границы слов: где кончается цвет, там меняется и
  /// фраза под картой.
  static const List<double> _rings = TastePoint.ringRadii;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _TasteGeometry(size);
    final center = geometry.center;
    final field = geometry.field;

    // Кольца заливаются снаружи внутрь: заливки полупрозрачные, и «зелёное
    // поверх жёлтого поверх красного» — это и есть три ступени.
    for (var ring = _rings.length - 1; ring >= 0; ring--) {
      canvas.drawCircle(
        center,
        field * _rings[ring],
        Paint()..color = zones.band(ring),
      );
    }

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppStroke.thin
      ..color = frame;

    for (final fraction in _rings) {
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

    // Цель обжарщика — в центре: «получилось как задумано». Пунктиром, а не
    // сплошным: сплошной круг того же цвета читался как ещё одно кольцо.
    _dashedCircle(
      canvas,
      center,
      field * TastePoint.targetRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.thick
        ..color = zones.aim,
    );

    // Подписи крупнее прежних двенадцати пунктов: карта шириной с ладонь, и
    // мелкая подпись у края круга не читается на ходу.
    final labelSize = (field * 0.14).clamp(12.0, 18.0);

    _label(canvas, ends.sour, Offset(0, center.dy), ink, labelSize);
    _label(canvas, ends.bitter, Offset(size.width, center.dy), ink, labelSize,
        anchorRight: true);
    // Все четыре подписи — наречия, одной частью речи. «Крепче» и «слабее»
    // рядом с «кисло» и «горько» читались как два разных вопроса на одном
    // круге: одна ось спрашивала «по сравнению с чем», вторая — «какое».
    // То же правило держит и английский: одна часть речи на все четыре конца.
    _label(canvas, ends.strong,
        Offset(center.dx, center.dy - field - labelSize), ink, labelSize,
        centered: true);
    _label(canvas, ends.weak, Offset(center.dx, center.dy + field + labelSize),
        ink, labelSize,
        centered: true);
  }

  /// Пунктирная окружность: Flutter рисует пунктир только дугами.
  void _dashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const dashes = 16;
    const sweep = 6.283185307179586 / dashes;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.55, false, paint);
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at,
    Color color,
    double fontSize, {
    bool centered = false,
    bool anchorRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: fontFamily,
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = centered
        ? at.dx - painter.width / 2
        : (anchorRight ? at.dx - painter.width : at.dx);

    painter.paint(canvas, Offset(dx, at.dy - painter.height / 2));
  }

  // Сменившийся язык меняет подписи осей, и без сравнения они остались бы от
  // прошлого языка. Тема меняет раскраску колец и цвет линий — их тоже надо
  // сравнивать.
  @override
  bool shouldRepaint(_TasteFieldPainter oldDelegate) =>
      oldDelegate.ends != ends ||
      oldDelegate.zones != zones ||
      oldDelegate.frame != frame ||
      oldDelegate.ink != ink ||
      oldDelegate.fontFamily != fontFamily;
}

/// Ручка карты и луч к ней из центра.
///
/// Открыта только тестам: где ручка нарисована, иначе не узнать — холст
/// наружу ничего не говорит.
@visibleForTesting
class TasteKnobPainter extends CustomPainter {
  const TasteKnobPainter({
    required this.at,
    required this.held,
    required this.accent,
    required this.rim,
  });

  /// Место ручки на круге, как у [TastePoint.disc].
  final Offset at;

  /// Насколько ручка взята: от нуля до единицы.
  final double held;

  final Color accent;

  /// Ободок ручки. Без него она сливается с кольцом, по которому идёт:
  /// коричневая точка на красном читается пятном, а не ручкой.
  final Color rim;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _TasteGeometry(size);
    final you = geometry.toLocal(at);

    canvas.drawLine(
      geometry.center,
      you,
      Paint()
        ..strokeWidth = AppStroke.thin
        ..color = accent.withValues(alpha: 0.5),
    );

    canvas.drawCircle(
      you,
      lerpDouble(_TasteGeometry.halo, _TasteGeometry.haloHeld, held)!,
      Paint()..color = accent.withValues(alpha: lerpDouble(0.18, 0.28, held)!),
    );

    final dot = lerpDouble(_TasteGeometry.dot, _TasteGeometry.dotHeld, held)!;
    canvas.drawCircle(you, dot + AppStroke.thick, Paint()..color = rim);
    canvas.drawCircle(you, dot, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(TasteKnobPainter oldDelegate) =>
      oldDelegate.at != at ||
      oldDelegate.held != held ||
      oldDelegate.accent != accent ||
      oldDelegate.rim != rim;
}
