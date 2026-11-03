// Пересчёт рецепта на другой объём воды.
//
// Простое умножение воды каждого шага даёт другую чашку: в той же воронке
// слой становится глубже, вода идёт через него дольше, и кофе
// переэкстрагируется. Здесь — пересчёт по исследованию «Рецепт на несколько
// человек» (artifacts/scaling-research/…pdf): у пролива доза растёт ровно как
// вода, время — как глубина слоя, помол крупнеет ровно настолько, чтобы
// экстракция осталась прежней, и переводится в клики кофемолки человека.
//
// Остальные приборы масштабируются по-своему — это задаёт семья профиля
// (scaling_profile.dart): настаивание, нагрев в турке, концентрат с доливкой
// у аэропресса, заходы у эспрессо и гейзера, порции у дрип-пакетов и
// каппинга, холодное настаивание и колд дрип.
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

  /// Камера меньше воды: заварим концентрат и дольём воду в чашку.
  bypass,

  /// Не помещается и концентрат — варим в несколько заходов.
  runs,

  /// Колба колд дрипа меньше воды — доливать по ходу.
  refill,
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
    this.water = 0,
    this.chamber = 0,
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

  /// Сколько воды долить в чашку (bypass), мл.
  final int water;

  /// Объём камеры или колбы, мл.
  final int chamber;

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
      other.halfWater == halfWater &&
      other.water == water &&
      other.chamber == chamber;

  @override
  int get hashCode => Object.hash(kind, parts, click, tempDrop, size,
      biggerSize, grams, halfWater, water, chamber);

  @override
  String toString() => 'ScaleWarning($kind)';
}

/// Подписи шагов, которые добавляет пересчёт. Язык экрана знает экран, а
/// не пересчёт, поэтому слова приходят снаружи.
class ScaleLabels {
  const ScaleLabels({
    this.splitWait = '…',
    this.dilute = '…',
    this.diluteCold = '…',
  });

  /// Пауза между частями пролива: «Ждём, пока уйдёт».
  final String splitWait;

  /// Доливка воды в концентрат: «Долейте горячую воду».
  final String dilute;

  /// Доливка у холодного рецепта: «Долейте холодную воду».
  final String diluteCold;
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
    this.family = ScalingFamily.percolation,
    this.runs = 1,
    this.unit = ScalingUnit.run,
    this.bypassWater = 0,
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

  /// Как прибор масштабировался.
  final ScalingFamily family;

  /// Сколько заходов или порций: 2 шота, 3 пакета, 2 захода аэропресса.
  final int runs;

  /// Чем считаются заходы — для подписи.
  final ScalingUnit unit;

  /// Сколько воды доливается в чашку после камеры, мл (на все заходы).
  final int bypassWater;

  /// Доза одного захода, г.
  double get dosePerRun => runs > 1 ? dose / runs : dose;

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
/// [labels] — подписи шагов, которые добавляет пересчёт.
ScaledRecipe scaleRecipe({
  required RecipeData base,
  required int water,
  required ScalingProfile profile,
  List<GrinderMode> scale = const [],
  String? baseClick,
  int? grinderId,
  String? size,
  ScaleLabels labels = const ScaleLabels(),
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
    labels: labels,
  );
  return switch (profile.family) {
    ScalingFamily.percolation => scaler.percolation(grinderId),
    ScalingFamily.valve || ScalingFamily.immersion => scaler.immersion(),
    ScalingFamily.heated => scaler.heated(),
    ScalingFamily.concentrate => scaler.concentrate(),
    ScalingFamily.repeat => scaler.repeat(),
    ScalingFamily.parallel => scaler.parallel(),
    ScalingFamily.coldSteep => scaler.coldSteep(),
    ScalingFamily.coldDrip => scaler.coldDrip(),
  };
}

/// Деления барабана для этого рецепта и прибора.
///
/// У заходов и порций — кратные рецепту: эспрессо 36, 72, 108 г, дрип-пакеты
/// 150, 300, 450 мл. У остальных — от и до с шагом профиля. Вода рецепта и
/// уже выбранная стоят на барабане всегда, даже вне шага: «Как в рецепте»
/// обязано попасть ровно в неё.
List<int> scaleWheelValues(RecipeData base, ScalingProfile profile,
    {int? current}) {
  if (profile.countsUnits) {
    return [
      for (var n = 1; n <= math.max(1, profile.maxUnits); n++) base.water * n,
    ];
  }
  final step = math.max(1, profile.waterStep);
  final low = math.min(profile.minWater, base.water);
  final high = math.max(profile.maxWater, base.water);
  return <int>{
    for (var water = low - low % step; water <= high; water += step)
      if (water >= low) water,
    base.water,
    if (current != null) current,
  }.toList()
    ..sort();
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
    family: profile.family,
    unit: profile.unit,
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
    this.run = 0,
    this.runs = 1,
    this.units = 1,
  });

  final String kind;
  final String label;
  double water;
  double duration;

  /// Индекс исходного шага; −1 — шаг, которого в рецепте не было (пауза
  /// между частями пролива, доливка в концентрат).
  final int source;
  String role;
  final int part;
  final int parts;

  /// Заход из [runs] — у эспрессо, гейзера, аэропресса в несколько заходов.
  final int run;
  final int runs;

  /// Сколько порций делается этим действием сразу (дрип-пакеты, каппинг).
  final int units;

  bool get isExtra => source < 0;

  _Step copy({
    double? water,
    double? duration,
    String? label,
    int? part,
    int? parts,
    int? run,
    int? runs,
    int? units,
  }) =>
      _Step(
        kind: kind,
        label: label ?? this.label,
        water: water ?? this.water,
        duration: duration ?? this.duration,
        source: source,
        role: role,
        part: part ?? this.part,
        parts: parts ?? this.parts,
        run: run ?? this.run,
        runs: runs ?? this.runs,
        units: units ?? this.units,
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
    required this.labels,
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
  final ScaleLabels labels;

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
          ScalingFamily.immersion ||
          ScalingFamily.concentrate ||
          ScalingFamily.coldSteep =>
            'steep',
          // Ждём пенку — это нагрев, а не настаивание.
          ScalingFamily.heated => step.untilUser ? 'heat' : 'steep',
          ScalingFamily.repeat ||
          ScalingFamily.parallel ||
          ScalingFamily.coldDrip =>
            'pause',
        };
      }
      // Открытый клапан, который держат дольше паузы, — это и есть слив
      // (Gina: у неё нет отдельного шага ожидания после клапана).
      if (kind == 'open_valve' && step.time >= 20) s.role = 'drain';
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
    // Нагрев без «ждём пенку» (перколятор): греется первая пауза после
    // заливки, дальше — уже само заваривание.
    if (profile.family == ScalingFamily.heated &&
        !out.any((s) => s.role == 'heat')) {
      for (final s in out) {
        if (s.kind == 'wait') {
          s.role = 'heat';
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
              label: labels.splitWait,
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
      } else if (s.role == 'drain') {
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
      // Треть настаивания остаётся всегда. Иначе у цилиндра (Pulsar) втрое
      // глубже слой сливается так долго, что «забирает» всё настаивание и
      // уводит время в минус. Это уже за пределами объёма прибора — о том
      // скажет предупреждение.
      s.duration = math.max(
        s.duration / rho - extraDrain * share,
        s.duration / rho / 3,
      );
    }

    final warnings = _capacityWarnings();

    return _finish(
      _Schedule(out, 0),
      grindRatio: 1,
      click: baseClick,
      grinderId: null,
      tempDrop: 0,
      warnings: warnings,
    );
  }

  /// Скорость, с которой рецепт льёт воду, г/с — у заходов и порций та же.
  double get _basePourRate {
    final rates = [
      for (final s in steps)
        if ((s.kind == 'pour' || s.kind == 'bloom') &&
            s.water > 0 &&
            s.duration > 0)
          s.water / s.duration,
    ]..sort();
    return rates.isEmpty ? 5.0 : rates.first;
  }

  // ── турка: нагрев до пенки растёт как масса воды ──
  ScaledRecipe heated() {
    final q0 = _basePourRate;
    final out = <_Step>[
      for (final s in steps)
        if ((s.kind == 'pour' || s.kind == 'bloom') && s.water > 0)
          s.copy(
              water: s.water * k,
              duration: math.max(s.duration, s.water * k / q0))
        else if (s.role == 'heat')
          // При том же огне тепла в секунду столько же, а греть надо в k раз
          // больше воды: до пенки — в k раз дольше.
          s.copy(duration: s.duration * k)
        else if (_isWater(s.kind))
          s.copy(water: s.water * k)
        else
          s.copy(),
    ];
    return _finish(
      _Schedule(out, 0),
      grindRatio: 1,
      click: baseClick,
      grinderId: null,
      tempDrop: 0,
      warnings: _capacityWarnings(),
    );
  }

  // ── холодное настаивание: часы настаивания от объёма не зависят ──
  ScaledRecipe coldSteep() {
    final out = <_Step>[
      for (final s in steps)
        if ((s.kind == 'pour' || s.kind == 'bloom') && s.water > 0)
          s.copy(water: s.water * k, duration: s.duration * k)
        else if (s.kind == 'remove_filter' || s.kind == 'press')
          // Процедить в k раз больше — в k раз дольше.
          s.copy(duration: s.duration * k)
        else if (_isWater(s.kind))
          s.copy(water: s.water * k)
        else
          s.copy(),
    ];
    return _finish(
      _Schedule(out, 0),
      grindRatio: 1,
      click: baseClick,
      grinderId: null,
      tempDrop: 0,
      warnings: _capacityWarnings(),
    );
  }

  // ── колд дрип: капли с той же скоростью — время как объём ──
  ScaledRecipe coldDrip() {
    var longest = -1;
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].kind != 'wait') continue;
      if (longest < 0 || steps[i].duration > steps[longest].duration) {
        longest = i;
      }
    }
    final out = <_Step>[
      for (var i = 0; i < steps.length; i++)
        if ((steps[i].kind == 'pour' || steps[i].kind == 'bloom') &&
            steps[i].water > 0)
          steps[i]
              .copy(water: steps[i].water * k, duration: steps[i].duration * k)
        else if (i == longest)
          steps[i].copy(duration: steps[i].duration * k)
        else if (_isWater(steps[i].kind))
          steps[i].copy(water: steps[i].water * k)
        else
          steps[i].copy(),
    ];
    return _finish(
      _Schedule(out, 0),
      grindRatio: 1,
      click: baseClick,
      grinderId: null,
      tempDrop: 0,
      warnings: [
        if (capacity > 0 && water > capacity)
          ScaleWarning(ScaleWarningKind.refill, chamber: capacity.round()),
        if (dose < profile.minDoseGrams)
          ScaleWarning(ScaleWarningKind.tooThin,
              grams: profile.minDoseGrams.round()),
      ],
    );
  }

  /// Сколько порций выбрано: барабан у заходов кратен рецепту.
  int get _units => math.max(1, (water / base.water).round());

  // ── заходы: тот же рецепт ещё раз — шот за шотом, гейзер за гейзером ──
  ScaledRecipe repeat() {
    final n = _units;
    final out = <_Step>[
      for (var run = 1; run <= n; run++)
        for (final s in steps) s.copy(run: n > 1 ? run : 0, runs: n),
    ];
    return _finish(
      _Schedule(out, 0),
      grindRatio: 1,
      click: baseClick,
      grinderId: null,
      tempDrop: 0,
      warnings: const [],
      waterOverride: base.water * n,
      doseOverride: base.load * n,
      runs: n,
    );
  }

  // ── порции разом: действие на каждую, ожидание общее ──
  ScaledRecipe parallel() {
    final n = _units;
    final out = <_Step>[
      for (final s in steps)
        if (s.kind == 'wait')
          s.copy()
        else if (_isWater(s.kind))
          s.copy(water: s.water * n, duration: s.duration * n, units: n)
        else
          s.copy(duration: s.duration * n, units: n),
    ];
    return _finish(
      _Schedule(out, 0),
      grindRatio: 1,
      click: baseClick,
      grinderId: null,
      tempDrop: 0,
      warnings: const [],
      waterOverride: base.water * n,
      doseOverride: base.load * n,
      runs: n,
    );
  }

  /// Вода, которую рецепт льёт в камеру (без доливки), мл.
  double get _chamberWaterBase => steps
      .where((s) => (s.kind == 'pour' || s.kind == 'bloom') && s.water > 0)
      .fold(0.0, (sum, s) => sum + s.water);

  /// Концентрат в камере и вода в чашку — раздел 11 исследования.
  ///
  /// Крепость чашки та же, что у рецепта: сухих в чашке на грамм напитка
  /// столько же. В камере W_b = min(W, V − v·D) воды; гуща удерживает L·D;
  /// при крепком концентрате (низкое соотношение) экстракция немного ниже —
  /// до −10 % к 1:5 (равновесие Liang 2021). Ищем наименьшую дозу D, при
  /// которой e·D/W_b · (W_b − L·D) ≥ D₀/W₀ · (W − L·D).
  ({double dose, double brewWater, double bypass, bool fits}) _concentrate(
      double total) {
    final d0 = base.load, w0 = _chamberWaterBase;
    final lrr = profile.retainedPerGram;
    final chamber = profile.chamberMl;
    final v = profile.displacementMlPerGram;
    final kk = total / w0;

    // Помещается и так — просто больше всего, без доливки. Но не больше
    // кофе, чем камера честно отожмёт: 36 г у Prismo — уже второй заход.
    if (chamber <= 0 || total + v * d0 * kk <= chamber) {
      final dose = d0 * kk;
      return (
        dose: dose,
        brewWater: total,
        bypass: 0.0,
        fits: profile.maxDoseGrams <= 0 || dose <= profile.maxDoseGrams,
      );
    }

    final r0 = w0 / d0, target = d0 / w0;
    double lag(double ratio) =>
        0.10 * ((r0 - ratio) / (r0 - 5)).clamp(0.0, 1.0).toDouble();
    for (var d = d0 * kk * 0.8; d <= d0 * kk * 3; d += 0.05) {
      final brew = math.min(total, chamber - v * d);
      if (brew <= lrr * d) break;
      final strength = (1 - lag(brew / d)) * d / brew * (brew - lrr * d);
      if (strength >= target * (total - lrr * d)) {
        final fits = (profile.maxDoseGrams <= 0 || d <= profile.maxDoseGrams) &&
            brew / d >= profile.minBrewRatio;
        return (dose: d, brewWater: brew, bypass: total - brew, fits: fits);
      }
    }
    return (dose: d0 * kk, brewWater: total, bypass: 0.0, fits: false);
  }

  // ── камера: концентрат с доливкой, а когда не влезает — заходы ──
  ScaledRecipe concentrate() {
    final total = _chamberWaterBase * k;
    var n = 1;
    var plan = _concentrate(total);
    while (!plan.fits && n < math.max(1, profile.maxUnits)) {
      n += 1;
      plan = _concentrate(total / n);
    }

    final q0 = _basePourRate;
    final share =
        _chamberWaterBase > 0 ? plan.brewWater / _chamberWaterBase : k;
    var lastPress = -1;
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].kind == 'press' || steps[i].kind == 'flip') lastPress = i;
    }
    if (lastPress < 0) {
      lastPress = steps.lastIndexWhere((s) => s.kind != 'serve');
    }

    final out = <_Step>[];
    for (var run = 1; run <= n; run++) {
      for (var i = 0; i < steps.length; i++) {
        final s = steps[i];
        final r = n > 1 ? run : 0;
        if ((s.kind == 'pour' || s.kind == 'bloom') && s.water > 0) {
          final w = s.water * share;
          out.add(s.copy(
              water: w,
              duration: math.max(s.duration, w / q0),
              run: r,
              runs: n));
        } else {
          out.add(s.copy(run: r, runs: n));
        }
        if (i == lastPress && plan.bypass >= 1) {
          out.add(_Step(
            kind: 'dilute',
            // Аэропресс со льдом доливают холодной: горячая вода в чашке
            // испортила бы весь смысл.
            label: (base.temperature ?? 90) < 40
                ? labels.diluteCold
                : labels.dilute,
            water: plan.bypass,
            duration: math.max(5, plan.bypass / profile.maxPourRate),
            source: -1,
            run: r,
            runs: n,
          ));
        }
      }
    }

    return _finish(
      _Schedule(out, 0),
      grindRatio: 1,
      click: baseClick,
      grinderId: null,
      tempDrop: 0,
      warnings: [
        if (n > 1)
          ScaleWarning(ScaleWarningKind.runs,
              parts: n, chamber: profile.chamberMl.round())
        else if (plan.bypass >= 1)
          ScaleWarning(ScaleWarningKind.bypass,
              water: plan.bypass.round(), chamber: profile.chamberMl.round()),
      ],
      doseOverride: (plan.dose * n * 10).round() / 10,
      runs: n,
      bypassWater: (plan.bypass * n).round(),
    );
  }

  /// Сколько воды стоит в приборе разом, мл.
  ///
  /// У клапана — только то, что налито при закрытом кране: у Gina второй
  /// пролив идёт при открытом и сразу уходит в чашку, в воронке его от силы
  /// половина. У Clever и Switch кран закрыт всё время — там это вся вода.
  double get _heldWater {
    if (profile.family != ScalingFamily.valve) return water.toDouble();
    var open = false;
    var held = 0.0, peak = 0.0;
    for (final s in steps) {
      if (s.kind == 'close_valve' || s.kind == 'open_valve') {
        open = s.kind == 'open_valve';
        held = 0;
      }
      if ((s.kind == 'pour' || s.kind == 'bloom') && s.water > 0) {
        final w = s.water * k;
        if (open) {
          peak = math.max(peak, w / 2);
        } else {
          held += w;
          peak = math.max(peak, held);
        }
      }
    }
    return peak;
  }

  /// Не войдёт в прибор: вода с кофе больше его объёма.
  List<ScaleWarning> _capacityWarnings() => [
        if (capacity > 0 && _heldWater + bedMl * 0.32 > capacity)
          ScaleWarning(ScaleWarningKind.overCapacity, size: size),
        if (dose < profile.minDoseGrams)
          ScaleWarning(ScaleWarningKind.tooThin,
              grams: profile.minDoseGrams.round()),
      ];

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
    int? waterOverride,
    double? doseOverride,
    int runs = 1,
    int bypassWater = 0,
  }) {
    final finalWater = waterOverride ?? water;
    final finalDose = doseOverride ?? dose;
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
      final target = (baseSum * finalWater / base.water).round();
      final poured =
          watered.where((s) => s.kind == 'bloom' || s.kind == 'pour').toList();
      final sink = poured.isNotEmpty ? poured.last : watered.last;
      sink.water += target - watered.fold(0.0, (sum, s) => sum + s.water);
    }

    final total = plan.steps.fold(0.0, (sum, s) => sum + s.duration).round();
    final recipe = copyRecipe(base);
    recipe
      ..water = finalWater
      ..load = finalDose
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
      water: finalWater,
      baseWater: base.water,
      dose: finalDose,
      factor: finalWater / base.water,
      bedDepthRatio: lambda,
      grindRatio: grindRatio,
      grindStep: profile.family == ScalingFamily.percolation ? click : null,
      baseGrindStep: baseClick,
      size: size,
      cupMl: (finalWater - profile.retainedPerGram * finalDose).round(),
      totalSeconds: total,
      baseTotalSeconds: baseContact.round(),
      warnings: warnings,
      family: profile.family,
      runs: runs,
      unit: profile.unit,
      bypassWater: bypassWater,
    );
  }

  RecipeStep _stepOf(_Step s, int index) {
    if (s.isExtra) {
      return RecipeStep(
        seqNum: index + 1,
        instruction: s.runs > 1 && s.run > 0
            ? '${s.run}/${s.runs} · ${s.label}'
            : s.label,
        water: s.water.round(),
        time: s.duration.round(),
        id: 0,
        stepType: s.kind,
        stepKey: 'scale-${s.kind}-$index',
        tip: '',
        isOptional: false,
        untilUser: false,
        untilSign: '',
        warning: '',
      );
    }
    final from = base.steps[s.source];
    final key = from.stepKey.isEmpty ? 's${from.seqNum}' : from.stepKey;
    var label = from.instruction;
    var stepKey = key;
    // Подписи без слов, чтобы не знать языка экрана: «2/3 · …» — второй
    // заход из трёх, «… · 2/3» — вторая часть пролива, «×3» — сразу на три
    // порции. Номер захода — впереди: длинное «Смолоть и засыпать в
    // фильтр» обрезается многоточием, и номер в конце пропадал бы первым.
    if (s.runs > 1 && s.run > 0) {
      label = '${s.run}/${s.runs} · $label';
      stepKey = '$stepKey-r${s.run}';
    }
    if (s.parts > 1) {
      label = '$label · ${s.part}/${s.parts}';
      stepKey = '$stepKey-${s.part}';
    }
    if (s.units > 1) label = '$label ×${s.units}';
    final repeated = s.part > 1 || s.run > 1;
    return RecipeStep(
      seqNum: index + 1,
      instruction: label,
      water: s.water.round(),
      time: s.duration.round(),
      id: from.id,
      stepType: from.stepType,
      stepKey: stepKey,
      tip: repeated ? '' : from.tip,
      isOptional: from.isOptional,
      untilUser: from.untilUser,
      untilSign: from.untilSign,
      warning: repeated ? '' : from.warning,
    );
  }
}
