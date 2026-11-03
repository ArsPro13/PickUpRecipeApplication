// Пересчёт рецепта на другой объём воды.
//
// Простое умножение воды каждого шага даёт другую чашку: в той же воронке
// слой становится глубже, вода идёт через него дольше, и кофе
// переэкстрагируется. Здесь — пересчёт по исследованию «Рецепт на несколько
// человек» (artifacts/scaling-research/…pdf, раздел 13): доза растёт ровно как
// вода, время — как глубина слоя, помол крупнеет ровно настолько, чтобы
// экстракция осталась прежней, и переводится в клики кофемолки человека.
//
// Чистый Dart, как brew_engine.dart: без Flutter, без сети, без состояния.
// Один и тот же вход даёт один и тот же выход — поэтому его можно крутить
// барабаном на каждом кадре и проверять обычным `dart test`.
//
// Формулы повторяют движок витрины `design/mockups/variants/water-scale.html`
// и прототип `artifacts/scaling-research/prototype/scaler.py`; эталоны в
// test/recipe_scaler_test.dart сняты с витрины.

import 'dart:math' as math;

import '../../../grinders/domain/models/grinder_model.dart';
import '../models/recipe_data_model.dart';
import '../models/recipe_step_model.dart';
import 'scaling_profile.dart';

/// Пределы барабана, мл. Меньше — слой слишком тонкий даже для одной чашки,
/// больше — не та задача: литр с лишним варят в батч-брюере.
const int kScaleMinWater = 120;
const int kScaleMaxWater = 1000;

/// Шаг барабана, мл: мельче на кухонных весах всё равно не налить.
const int kScaleWaterStep = 5;

/// Что стоит сказать человеку о пересчитанном рецепте.
enum ScaleWarningKind {
  /// Пролив не помещается над слоем — идёт частями.
  split,

  /// Доза больше, чем советуют практики для этого прибора.
  deepBed,

  /// Доза такая, что честнее сварить в два захода.
  tooDeep,

  /// Нужно крупнее, чем есть на шкале кофемолки.
  grinderEdgeCoarse,

  /// Нужно мельче, чем есть на шкале кофемолки.
  grinderEdgeFine,

  /// Слишком мало кофе — слой тонкий, вкус гуляет.
  tooThin,

  /// В прибор не помещается вся вода (иммерсия, клапан).
  overCapacity,
}

/// Предупреждение с тем, что нужно для текста.
class ScaleWarning {
  const ScaleWarning(
    this.kind, {
    this.parts = 0,
    this.click = '',
    this.tempDrop = 0,
    this.size = '',
    this.biggerSize = '',
    this.grams = 0,
    this.halfWater = 0,
  });

  final ScaleWarningKind kind;

  /// На сколько частей делится пролив.
  final int parts;

  /// Крайнее деление шкалы кофемолки.
  final String click;

  /// На сколько градусов холоднее вода, если помол упёрся в край шкалы.
  final int tempDrop;

  /// Размер прибора, в который не помещается.
  final String size;

  /// Размер побольше, в который войдёт целиком; пусто — такого нет.
  final String biggerSize;

  /// Порог дозы, о котором речь, г.
  final int grams;

  /// Вода на один заход, если варить в два.
  final int halfWater;

  @override
  bool operator ==(Object other) =>
      other is ScaleWarning &&
      other.kind == kind &&
      other.parts == parts &&
      other.click == click &&
      other.tempDrop == tempDrop &&
      other.size == size &&
      other.biggerSize == biggerSize &&
      other.grams == grams &&
      other.halfWater == halfWater;

  @override
  int get hashCode => Object.hash(
      kind, parts, click, tempDrop, size, biggerSize, grams, halfWater);

  @override
  String toString() => 'ScaleWarning($kind)';
}

/// Рецепт после пересчёта и то, что о нём стоит показать.
class ScaledRecipe {
  const ScaledRecipe({
    required this.recipe,
    required this.water,
    required this.baseWater,
    required this.dose,
    required this.factor,
    required this.bedDepthRatio,
    required this.grindRatio,
    required this.grindStep,
    required this.baseGrindStep,
    required this.size,
    required this.cupMl,
    required this.totalSeconds,
    required this.baseTotalSeconds,
    required this.warnings,
  });

  /// Готов для экрана заваривания и движка: шаги, вода, доза, время, помол.
  final RecipeData recipe;

  /// Вода, как её выбрали, г.
  final int water;

  /// Вода исходного рецепта, г.
  final int baseWater;

  /// Доза, г, до десятых.
  final double dose;

  /// k — во сколько раз больше воды, чем в рецепте.
  final double factor;

  /// λ — во сколько раз глубже слой.
  final double bedDepthRatio;

  /// x* — во сколько раз крупнее помол после округления до клика
  /// (или точное значение, если шкалы кофемолки нет).
  final double grindRatio;

  /// Новое деление кофемолки человека; null — шкалы нет или помол прежний
  /// по смыслу метода (иммерсия).
  final String? grindStep;

  /// Деление, с которого считали.
  final String? baseGrindStep;

  /// Размер прибора, по которому проверяли, помещается ли пролив.
  final String size;

  /// Сколько окажется в чашке, мл: вода минус то, что удержит гуща.
  final int cupMl;

  final int totalSeconds;
  final int baseTotalSeconds;

  final List<ScaleWarning> warnings;

  /// Ничего не пересчитано: вода та же, что в рецепте.
  bool get isOriginal => water == baseWater;
}

/// Можно ли пересчитывать этот рецепт этим прибором.
///
/// Нужны профиль прибора, вода и доза в рецепте и хотя бы один пролив с
/// водой и временем: у исторических рецептов без типов шагов пересчитывать
/// нечего, и честнее не трогать их вовсе.
bool canScaleRecipe(RecipeData recipe, ScalingProfile? profile) {
  if (profile == null || recipe.water <= 0 || recipe.load <= 0) return false;
  return recipe.steps.any((step) =>
      (step.stepType == 'pour' || step.stepType == 'bloom') &&
      step.water > 0 &&
      step.time > 0);
}

/// Пересчитывает [base] на [water] мл воды.
///
/// [scale] — шкала кофемолки человека («деление → средний размер, мкм»),
/// [baseClick] — деление на ней, соответствующее помолу рецепта. Без них
/// помол считается только относительно ([ScaledRecipe.grindRatio]).
/// [grinderId] ставится в пересчитанный рецепт вместе с новым делением —
/// так экран покажет клики, а не слово.
/// [size] — размер прибора; null — размер по умолчанию из профиля.
/// [splitWaitLabel] — подпись паузы между частями пролива: язык экрана
/// знает экран, а не пересчёт.
ScaledRecipe scaleRecipe({
  required RecipeData base,
  required int water,
  required ScalingProfile profile,
  List<GrinderMode> scale = const [],
  String? baseClick,
  int? grinderId,
  String? size,
  String splitWaitLabel = '…',
}) {
  final usedSize = size ?? profile.defaultSize;
  // Та же вода — тот же рецепт, до секунды: округление до 5 с иначе поправило
  // бы шаги, которые никто не просил трогать.
  if (water == base.water || water <= 0 || base.water <= 0) {
    return _original(base, profile, baseClick, usedSize);
  }
  final scaler = _Scaler(
    base: base,
    water: water,
    profile: profile,
    scale: [
      for (final mode in scale)
        if (mode.mode.trim().isNotEmpty && mode.microns > 0) mode,
    ],
    baseClick: baseClick,
    size: usedSize,
    splitWaitLabel: splitWaitLabel,
  );
  return profile.family == ScalingFamily.percolation
      ? scaler.percolation(grinderId)
      : scaler.immersion();
}

ScaledRecipe _original(
  RecipeData base,
  ScalingProfile profile,
  String? baseClick,
  String size,
) {
  final total = base.steps.fold(0, (sum, step) => sum + step.time);
  return ScaledRecipe(
    recipe: copyRecipe(base),
    water: base.water,
    baseWater: base.water,
    dose: base.load,
    factor: 1,
    bedDepthRatio: 1,
    grindRatio: 1,
    grindStep: profile.family == ScalingFamily.percolation ? baseClick : null,
    baseGrindStep: baseClick,
    size: size,
    cupMl: (base.water - profile.retainedPerGram * base.load).round(),
    totalSeconds: total,
    baseTotalSeconds: total,
    warnings: const [],
  );
}

// ───────────────────────────── физика ─────────────────────────────

/// Вязкость воды, Па·с: уравнение Фогеля, T в °C.
double waterViscosity(double celsius) =>
    2.414e-5 * math.pow(10, 247.8 / (celsius + 133.15)).toDouble();

/// Энергия активации диффузии внутри частицы, Дж/моль. Оценки 12 (сумма
/// веществ, Corrochano) … 32 (кофеин, Spiro & Selwood); раздел 7.
const double _activationEnergy = 20000;
const double _gasConstant = 8.314;

/// D(T1)/D(T0) — во сколько раз быстрее диффузия при T1 (Аррениус).
double diffusionRatio(double t1, double t0) => math.exp(
    _activationEnergy / _gasConstant * (1 / (t0 + 273.15) - 1 / (t1 + 273.15)));

/// Шаг рецепта в работе пересчёта.
class _Step {
  _Step({
    required this.kind,
    required this.label,
    required this.water,
    required this.duration,
    required this.source,
    this.role = '',
    this.part = 0,
    this.parts = 1,
  });

  final String kind;
  final String label;
  double water;
  double duration;

  /// Индекс исходного шага; −1 — пауза между частями пролива.
  final int source;
  String role;
  final int part;
  final int parts;

  bool get isExtra => source < 0;

  _Step copy(
          {double? water,
          double? duration,
          String? label,
          int? part,
          int? parts}) =>
      _Step(
        kind: kind,
        label: label ?? this.label,
        water: water ?? this.water,
        duration: duration ?? this.duration,
        source: source,
        role: role,
        part: part ?? this.part,
        parts: parts ?? this.parts,
      );
}

class _Schedule {
  _Schedule(this.steps, this.split);

  final List<_Step> steps;

  /// На сколько частей пришлось делить самый большой пролив; 0 — не делили.
  final int split;

  double get contact => steps.fold(0.0, (sum, step) => sum + step.duration);
}

class _Scaler {
  _Scaler({
    required this.base,
    required this.water,
    required this.profile,
    required this.scale,
    required this.baseClick,
    required this.size,
    required this.splitWaitLabel,
  })  : k = water / base.water,
        dose = (base.load * water / base.water * 10).round() / 10 {
    final tan = math.tan(profile.halfAngleDeg * math.pi / 180);
    _tan = tan;
    lambda = _meanDepth(profile.bedMlPerGram * base.load * k) /
        _meanDepth(profile.bedMlPerGram * base.load);
    final t = base.temperature ?? 92;
    slurryBase = t - profile.slurryDeficitC;
    slurry = t - profile.slurryDeficitC * math.pow(k, -1 / 3);
    rho = diffusionRatio(slurry, slurryBase);
    viscosityRatio = waterViscosity(slurry) / waterViscosity(slurryBase);
    capacity = profile.capacityFor(size);
    bedMl = profile.bedMlPerGram * base.load * k;
    steps = _classify();
  }

  final RecipeData base;
  final int water;
  final ScalingProfile profile;
  final List<GrinderMode> scale;
  final String? baseClick;
  final String size;
  final String splitWaitLabel;

  final double k;
  final double dose;
  late final double _tan;
  late final double lambda;
  late final double slurryBase;
  late final double slurry;
  late final double rho;
  late final double viscosityRatio;
  late final double capacity;
  late final double bedMl;
  late final List<_Step> steps;

  double get baseContact =>
      base.steps.fold(0.0, (sum, step) => sum + step.time.toDouble());

  // ── геометрия: усечённый конус, средняя толщина слоя V/A ──
  double _volume(double h) {
    final rb = profile.bottomRadiusMm, rt = rb + h * _tan;
    return math.pi * h * (rb * rb + rb * rt + rt * rt) / 3 / 1000;
  }

  double _height(double volume) {
    var lo = 0.0, hi = 1000.0;
    for (var i = 0; i < 60; i++) {
      final mid = (lo + hi) / 2;
      if (_volume(mid) < volume) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }

  double _meanDepth(double volume) {
    final h = _height(volume), rt = profile.bottomRadiusMm + h * _tan;
    return volume * 1000 / (math.pi * rt * rt);
  }

  // ── что значит каждая пауза: слив, настаивание или пауза до воды ──
  List<_Step> _classify() {
    var valveOpen = profile.family == ScalingFamily.percolation;
    var seenWater = false;
    final out = <_Step>[];
    for (var i = 0; i < base.steps.length; i++) {
      final step = base.steps[i];
      final kind = step.stepType;
      if (kind == 'close_valve') valveOpen = false;
      if (kind == 'open_valve') valveOpen = true;
      if (kind == 'bloom' || kind == 'pour') seenWater = true;
      final s = _Step(
        kind: kind,
        label: step.instruction,
        water: step.water.toDouble(),
        duration: step.time.toDouble(),
        source: i,
      );
      if (kind == 'wait') {
        s.role = switch (profile.family) {
          ScalingFamily.percolation => seenWater ? 'drain' : 'pause',
          ScalingFamily.valve => valveOpen ? 'drain' : 'steep',
          ScalingFamily.immersion => 'steep',
        };
      }
      out.add(s);
    }
    if (profile.family == ScalingFamily.percolation) {
      for (var i = out.length - 1; i >= 0; i--) {
        if (out[i].kind == 'wait') {
          out[i].role = 'drawdown';
          break;
        }
      }
    }
    return out;
  }

  bool _isWater(String kind) =>
      kind == 'bloom' ||
      kind == 'pour' ||
      kind == 'add_ice' ||
      kind == 'dilute';

  // ── пролив: расписание при помоле x ──
  _Schedule _schedule(double x, {double pauseScale = 1, double? capacityMl}) {
    final cap = capacityMl ?? capacity;
    final rates = [
      for (final s in steps)
        if (s.kind == 'pour' && s.water > 0 && s.duration > 0)
          s.water / s.duration,
    ]..sort();
    final q0 = rates.isEmpty ? 3.0 : rates[rates.length ~/ 2];
    double rate(double r) => profile.fixedPourRate
        ? r
        : math.max(r, math.min(r * k / lambda, profile.maxPourRate));
    final q = rate(q0);
    final drain =
        (profile.bedShare * lambda / (x * x) + (1 - profile.bedShare)) *
            viscosityRatio;

    var last = -1;
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].kind == 'pour') last = i;
    }
    var tail = 60.0;
    var out0 = 2.0;
    if (last >= 0) {
      tail = 0;
      for (var i = last; i < steps.length; i++) {
        tail += steps[i].duration;
      }
      out0 = steps[last].water / tail;
    }
    final outflow = out0 * k / drain;
    final free = math.max(cap * profile.fillMargin - bedMl, 1.0);

    final out = <_Step>[];
    var split = 0;
    for (final s in steps) {
      if (s.kind == 'bloom' && s.water > 0) {
        final w = s.water * k;
        out.add(s.copy(
          water: w,
          duration: s.duration +
              (w / q - s.water / q0) +
              profile.bloomWettingSeconds * (lambda * lambda - 1),
        ));
      } else if (s.kind == 'pour' && s.water > 0) {
        final w = s.water * k;
        final qi = s.duration > 0 ? rate(s.water / s.duration) : q;
        // Пока льют, часть воды уже стекает: пик над слоем меньше пролива.
        final peak = w * math.max(0.5, 1 - 0.5 * outflow / qi);
        var n = 1;
        if (cap > 0 && peak > free) {
          n = (peak / free).ceil();
          split = math.max(split, n);
        }
        final part = w / n;
        for (var j = 0; j < n; j++) {
          out.add(
              s.copy(water: part, duration: part / qi, part: j + 1, parts: n));
          if (j < n - 1) {
            out.add(_Step(
              kind: 'wait',
              label: splitWaitLabel,
              water: 0,
              duration: math.max(5, part / outflow - part / qi),
              source: -1,
              role: 'drain',
            ));
          }
        }
      } else if (s.kind == 'wait') {
        var d = s.duration;
        if (s.role == 'drain' || s.role == 'drawdown') {
          d *= drain;
          if (s.role == 'drain') d *= pauseScale;
        }
        out.add(s.copy(duration: d));
      } else if (_isWater(s.kind)) {
        out.add(s.copy(water: s.water * k));
      } else {
        out.add(s.copy());
      }
    }
    return _Schedule(out, split);
  }

  ScaledRecipe percolation(int? grinderId) {
    final contact0 = baseContact;
    final a = profile.grindExponent;
    double mismatch(double x) =>
        rho * _schedule(x).contact / math.pow(x, a) - contact0;

    var lo = 0.5, hi = 3.0;
    for (var i = 0; i < 50; i++) {
      final mid = (lo + hi) / 2;
      if (mismatch(mid) > 0) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final x = (lo + hi) / 2;

    // Клик по шкале кофемолки — относительно: у разных шкал абсолютные
    // микроны сходятся плохо, а отношения надёжны.
    var xActual = x;
    String? click;
    var clamped = 0; // 1 — крупнее шкалы, −1 — мельче
    final from = _modeOf(baseClick);
    if (from != null) {
      final want = from.microns * x;
      final finest = scale.map((m) => m.microns).reduce(math.min);
      final coarsest = scale.map((m) => m.microns).reduce(math.max);
      if (want > coarsest * 1.005) clamped = 1;
      if (want < finest * 0.995) clamped = -1;
      final near = scale.reduce((best, m) =>
          (m.microns - want).abs() < (best.microns - want).abs() ? m : best);
      click = near.mode;
      xActual = near.microns / from.microns;
    }

    var plan = _schedule(xActual);
    final need = contact0 * math.pow(xActual, a) / rho;
    final pauses = plan.steps
        .where((s) => s.kind == 'wait' && s.role == 'drain')
        .fold(0.0, (sum, s) => sum + s.duration);
    if (pauses > 0 && (need - plan.contact).abs() > 0.03 * contact0) {
      final stretch = (1 + (need - plan.contact) / pauses).clamp(0.5, 2.0);
      plan = _schedule(xActual, pauseScale: stretch.toDouble());
    }

    // Помол упёрся в край шкалы, а контакта всё ещё больше нужного —
    // остаток снимаем температурой, не больше трёх градусов.
    var drop = 0;
    if (clamped == 1 && plan.contact > need * 1.01) {
      final needRho = contact0 * math.pow(xActual, a) / plan.contact;
      var l = slurryBase - 15, h = slurryBase + 5;
      for (var i = 0; i < 50; i++) {
        final mid = (l + h) / 2;
        if (diffusionRatio(mid, slurryBase) < needRho) {
          l = mid;
        } else {
          h = mid;
        }
      }
      drop = math.min(3.0, math.max(0.0, slurry - (l + h) / 2)).round();
    }

    // Не помещается — подскажем размер, в который войдёт целиком.
    var bigger = '';
    if (plan.split > 1) {
      final larger = profile.capacityMl.entries
          .where((entry) => entry.value > capacity)
          .toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (final option in larger) {
        if (_schedule(xActual, capacityMl: option.value).split == 0) {
          bigger = option.key;
          break;
        }
      }
    }

    final warnings = <ScaleWarning>[
      if (profile.maxDoseGrams > 0 && dose > profile.maxDoseGrams)
        ScaleWarning(ScaleWarningKind.tooDeep,
            grams: profile.maxDoseGrams.round(),
            halfWater: (water / 2 / kScaleWaterStep).round() * kScaleWaterStep)
      else if (profile.softDoseGrams > 0 && dose > profile.softDoseGrams)
        ScaleWarning(ScaleWarningKind.deepBed,
            grams: profile.softDoseGrams.round()),
      if (plan.split > 1)
        ScaleWarning(ScaleWarningKind.split,
            parts: plan.split, size: size, biggerSize: bigger),
      if (clamped == 1)
        ScaleWarning(ScaleWarningKind.grinderEdgeCoarse,
            click: click ?? '', tempDrop: drop),
      if (clamped == -1)
        ScaleWarning(ScaleWarningKind.grinderEdgeFine, click: click ?? ''),
      if (dose < profile.minDoseGrams)
        ScaleWarning(ScaleWarningKind.tooThin,
            grams: profile.minDoseGrams.round()),
    ];

    return _finish(
      plan,
      grindRatio: xActual,
      click: click,
      grinderId: grinderId,
      tempDrop: drop,
      warnings: warnings,
    );
  }

  ScaledRecipe immersion() {
    final drain =
        (profile.bedShare * lambda + (1 - profile.bedShare)) * viscosityRatio;
    final rates = [
      for (final s in steps)
        if (s.kind == 'pour' && s.duration > 0) s.water / s.duration,
    ]..sort();
    final q0 = rates.isEmpty ? 5.0 : rates.first;
    final q = math.max(q0, math.min(q0 * k / lambda, profile.maxPourRate));

    final out = <_Step>[];
    var extraDrain = 0.0;
    for (final s in steps) {
      if ((s.kind == 'pour' || s.kind == 'bloom') && s.water > 0) {
        final w = s.water * k;
        out.add(s.copy(water: w, duration: math.max(s.duration, w / q)));
      } else if (s.kind == 'wait' && s.role == 'drain') {
        final d = s.duration * drain;
        extraDrain += (d - s.duration) * profile.drainContribution;
        out.add(s.copy(duration: d));
      } else if (_isWater(s.kind)) {
        out.add(s.copy(water: s.water * k));
      } else {
        out.add(s.copy());
      }
    }
    final steeps =
        out.where((s) => s.kind == 'wait' && s.role == 'steep').toList();
    final steepTotal = steeps.fold(0.0, (sum, s) => sum + s.duration);
    for (final s in steeps) {
      final share = steepTotal > 0 ? s.duration / steepTotal : 0.0;
      s.duration = s.duration / rho - extraDrain * share;
    }

    final warnings = <ScaleWarning>[
      if (capacity > 0 && water + bedMl * 0.32 > capacity)
        ScaleWarning(ScaleWarningKind.overCapacity, size: size),
      if (dose < profile.minDoseGrams)
        ScaleWarning(ScaleWarningKind.tooThin,
            grams: profile.minDoseGrams.round()),
    ];

    return _finish(
      _Schedule(out, 0),
      grindRatio: 1,
      click: baseClick,
      grinderId: null,
      tempDrop: 0,
      warnings: warnings,
    );
  }

  GrinderMode? _modeOf(String? label) {
    if (label == null || scale.isEmpty) return null;
    final wanted = label.trim();
    for (final mode in scale) {
      if (mode.mode.trim() == wanted) return mode;
    }
    final asNumber = double.tryParse(wanted.replaceAll(',', '.'));
    if (asNumber == null) return null;
    for (final mode in scale) {
      if (double.tryParse(mode.mode.trim().replaceAll(',', '.')) == asNumber) {
        return mode;
      }
    }
    return null;
  }

  ScaledRecipe _finish(
    _Schedule plan, {
    required double grindRatio,
    required String? click,
    required int? grinderId,
    required int tempDrop,
    required List<ScaleWarning> warnings,
  }) {
    // Время — до 5 с: секундомер у чайника точнее не прочитать. Шаги,
    // которых пересчёт не коснулся (размешать, нажать поршень), остаются
    // как в рецепте — и пять секунд вместо трёх там никому не нужны.
    for (final s in plan.steps) {
      final untouched =
          !s.isExtra && s.duration == base.steps[s.source].time.toDouble();
      if (untouched || s.duration <= 0) continue;
      s.duration = math.max(5.0, (s.duration / 5).round() * 5.0);
    }

    // Вода — до грамма; остаток от округления — в последний пролив, чтобы
    // сумма сошлась ровно. С выбранной она сходится, когда шаги рецепта
    // складываются в его воду; у рецепта, где не складываются, расхождение
    // остаётся прежним в долях, а не сваливается в последний пролив.
    final watered =
        plan.steps.where((s) => _isWater(s.kind) && s.water > 0).toList();
    for (final s in watered) {
      s.water = s.water.roundToDouble();
    }
    if (watered.isNotEmpty) {
      final baseSum = base.steps
          .where((s) => _isWater(s.stepType) && s.water > 0)
          .fold(0, (sum, s) => sum + s.water);
      final target = (baseSum * k).round();
      final poured =
          watered.where((s) => s.kind == 'bloom' || s.kind == 'pour').toList();
      final sink = poured.isNotEmpty ? poured.last : watered.last;
      sink.water += target - watered.fold(0.0, (sum, s) => sum + s.water);
    }

    final total = plan.steps.fold(0.0, (sum, s) => sum + s.duration).round();
    final recipe = copyRecipe(base);
    recipe
      ..water = water
      ..load = dose
      ..time = total
      ..steps = [
        for (var i = 0; i < plan.steps.length; i++) _stepOf(plan.steps[i], i),
      ];
    if (tempDrop > 0 && base.temperature != null) {
      recipe.temperature = base.temperature! - tempDrop;
    }
    if (click != null &&
        grinderId != null &&
        profile.family == ScalingFamily.percolation) {
      recipe
        ..grinderId = grinderId
        ..grindStep = click
        ..grindSubStep = null;
    }

    return ScaledRecipe(
      recipe: recipe,
      water: water,
      baseWater: base.water,
      dose: dose,
      factor: k,
      bedDepthRatio: lambda,
      grindRatio: grindRatio,
      grindStep: profile.family == ScalingFamily.percolation ? click : null,
      baseGrindStep: baseClick,
      size: size,
      cupMl: (water - profile.retainedPerGram * dose).round(),
      totalSeconds: total,
      baseTotalSeconds: baseContact.round(),
      warnings: warnings,
    );
  }

  RecipeStep _stepOf(_Step s, int index) {
    if (s.isExtra) {
      return RecipeStep(
        seqNum: index + 1,
        instruction: s.label,
        water: 0,
        time: s.duration.round(),
        id: 0,
        stepType: 'wait',
        stepKey: 'scale-wait-$index',
        tip: '',
        isOptional: false,
        untilUser: false,
        untilSign: '',
        warning: '',
      );
    }
    final from = base.steps[s.source];
    final key = from.stepKey.isEmpty ? 's${from.seqNum}' : from.stepKey;
    return RecipeStep(
      seqNum: index + 1,
      instruction: s.parts > 1
          ? '${from.instruction} · ${s.part}/${s.parts}'
          : from.instruction,
      water: s.water.round(),
      time: s.duration.round(),
      id: from.id,
      stepType: from.stepType,
      stepKey: s.parts > 1 ? '$key-${s.part}' : key,
      tip: s.part > 1 ? '' : from.tip,
      isOptional: from.isOptional,
      untilUser: from.untilUser,
      untilSign: from.untilSign,
      warning: s.part > 1 ? '' : from.warning,
    );
  }
}
