// Профиль прибора для пересчёта рецепта на другой объём воды.
//
// Пересчёт зависит не от рецепта, а от того, как устроен прибор: в конусе
// V60 вдвое больше кофе дают слой глубже лишь на четверть, в воронке с плоским
// дном — почти вдвое; в аэропресс больше камеры не налить; корзина эспрессо
// держит одну дозу, и «больше» значит «ещё один шот». Поэтому у каждого
// прибора своя семья — то, КАК он масштабируется, — и свои числа.
//
// Источник — исследование «Рецепт на несколько человек»
// (artifacts/scaling-research/scaling-recipes-research-*.pdf): разделы 3–12 —
// семьи, приложение — параметры каждого из 71 прибора справочника. Таблица
// встроена в приложение: пересчёт обязан работать без сети, как встроенная
// палитра. Позже профиль приедет полем `scaling` в `default_params`
// справочника методов, и [ScalingProfile.fromJson] его разберёт; таблица
// останется запасной.

import 'scaling_profiles_table.dart';

/// Как прибор масштабируется — от этого зависит, что вообще пересчитывается.
enum ScalingFamily {
  /// Пролив: вода проходит через слой. Меняются проливы, паузы, слив и помол.
  percolation,

  /// Клапан (Clever, Switch): настаивание, потом слив через бумагу. Помол
  /// прежний, прибавку слива забирает настаивание.
  valve,

  /// Иммерсия (френч-пресс, сифон): всё время в воде. Помол прежний,
  /// настаивание чуть короче — большой объём дольше держит тепло.
  immersion,

  /// Нагрев в самом приборе (турка): до пенки вода греется дольше —
  /// пропорционально её массе при том же огне. Остальное как у иммерсии.
  heated,

  /// Камера ограничена (аэропресс): сверх неё воду не налить. Завариваем
  /// крепче — концентрат — и доливаем воду в чашку; когда и концентрату не
  /// хватает места, варим в несколько заходов.
  concentrate,

  /// Порция задана прибором (эспрессо, капсула, гейзер): больше — это ещё
  /// один заход того же рецепта, а не больше воды в корзину.
  repeat,

  /// Несколько порций одновременно (дрип-пакеты, каппинг, фин на каждую
  /// чашку): действия на каждую порцию, ожидание общее.
  parallel,

  /// Холодное настаивание (колд брю): всё растёт вместе с водой, кроме самих
  /// часов настаивания — экстракция при 4–20 °C идёт часами и от объёма не
  /// зависит.
  coldSteep,

  /// Колд дрип: капли идут с той же скоростью, поэтому время растёт как
  /// объём воды.
  coldDrip,
}

/// Чем считаются заходы и порции — для подписи «2 шота», «3 пакета».
enum ScalingUnit { run, shot, capsule, bag, bowl, cup }

/// Числа прибора, по которым считается пересчёт.
///
/// Значения по умолчанию — из приложения к исследованию. Каждое поле
/// подписано тем, что оно значит в формулах, а не тем, как его зовут в JSON.
class ScalingProfile {
  const ScalingProfile({
    required this.family,
    this.bottomRadiusMm = 10,
    this.halfAngleDeg = 30,
    this.capacityMl = const {},
    this.defaultSize = '',
    this.bedMlPerGram = 2.5,
    this.retainedPerGram = 2.0,
    this.bedShare = 0.9,
    this.bloomWettingSeconds = 10,
    this.maxPourRate = 8,
    this.grindExponent = 2.5,
    this.slurryDeficitC = 6,
    this.fillMargin = 0.9,
    this.drainContribution = 0.5,
    this.fixedPourRate = false,
    this.softDoseGrams = 0,
    this.maxDoseGrams = 0,
    this.minDoseGrams = 8,
    this.minWater = 120,
    this.maxWater = 1000,
    this.waterStep = 5,
    this.maxUnits = 6,
    this.unit = ScalingUnit.run,
    this.chamberMl = 0,
    this.displacementMlPerGram = 0.8,
    this.minBrewRatio = 5,
  });

  final ScalingFamily family;

  /// Радиус дна воронки, мм. У конуса V60 — радиус отверстия.
  final double bottomRadiusMm;

  /// Наклон стенки от вертикали, градусы. У V60 — 30 (конус 60°).
  final double halfAngleDeg;

  /// Объём по размерам прибора: `{'01': 194, '02': 310}` — до кромки у
  /// воронок, рабочий объём воды у прессов, туры и колб. Пусто —
  /// вместимость не проверяется.
  final Map<String, double> capacityMl;

  /// Размер, который берём, пока человек свой не выбрал.
  final String defaultSize;

  /// Сколько места занимает мокрый слой на грамм кофе, мл.
  final double bedMlPerGram;

  /// Сколько воды удерживает гуща на грамм кофе (LRR), г.
  final double retainedPerGram;

  /// φ — доля сопротивления слоя с осевшей мелочью в сопротивлении слива.
  /// Остальное — чистая бумага, которой помол безразличен.
  final double bedShare;

  /// Сколько секунд предсмачивания уходит на смачивание слоя.
  final double bloomWettingSeconds;

  /// Предел спокойной струи чайника, г/с.
  final double maxPourRate;

  /// a — показатель в правиле помола x^a = ρ·t(x)/t₀.
  final double grindExponent;

  /// Насколько суспензия в исходном рецепте холоднее чайника из-за потерь
  /// через поверхность, °C. Растёт с объёмом как k^(−1/3).
  final double slurryDeficitC;

  /// До какой доли объёма заполняем воронку.
  final double fillMargin;

  /// η — какую долю прибавки слива считаем контактом в иммерсии.
  final double drainContribution;

  /// Скорость подачи воды задана машиной (батч-брюер) и не растёт с объёмом.
  final bool fixedPourRate;

  /// С какой дозы слой глубже, чем советуют практики, г; 0 — не предупреждать.
  /// У V60 — 30: Рао советует 20–25 г, Гагне — до 22–24 г.
  final double softDoseGrams;

  /// С какой дозы честнее сварить в два захода, г; 0 — не предупреждать.
  final double maxDoseGrams;

  /// Меньше этой дозы слой слишком тонкий, и вкус гуляет от чашки к чашке, г.
  final double minDoseGrams;

  /// Барабан: от, до и шаг, мл (у эспрессо — граммы в чашке). У заходов и
  /// порций барабан другой — кратные рецепту, до [maxUnits].
  final int minWater;
  final int maxWater;
  final int waterStep;

  /// Сколько заходов или порций предлагать (repeat, parallel).
  final int maxUnits;

  /// Как называть заход или порцию.
  final ScalingUnit unit;

  /// Объём камеры, мл (concentrate): вода с кофе вместе. 0 — не задан.
  final double chamberMl;

  /// Сколько места в камере занимает грамм кофе, мл.
  final double displacementMlPerGram;

  /// Крепче этого концентрат не варим: при соотношении ниже 1:5 вода не
  /// успевает экстрагировать — дальше честнее ещё один заход.
  final double minBrewRatio;

  /// Барабан кратен рецепту: каждое деление — ещё одна порция.
  bool get countsUnits =>
      family == ScalingFamily.repeat || family == ScalingFamily.parallel;

  /// Объём для размера [size]; 0 — проверять нечего.
  double capacityFor(String? size) {
    if (capacityMl.isEmpty) return 0;
    return capacityMl[size] ??
        capacityMl[defaultSize] ??
        capacityMl.values.first;
  }

  /// Разбирает поле `scaling` из `default_params` справочника методов.
  ///
  /// Чего в JSON нет — берётся по умолчанию; неизвестная семья — null:
  /// пересчитывать прибор, про который мы ничего не знаем, хуже, чем не
  /// пересчитывать вовсе.
  static ScalingProfile? fromJson(Map<String, dynamic> json) {
    final family = ScalingFamily.values
        .where((value) => value.name == json['family'])
        .firstOrNull;
    if (family == null) return null;

    double number(String key, double fallback) =>
        (json[key] as num?)?.toDouble() ?? fallback;
    int whole(String key, int fallback) =>
        (json[key] as num?)?.round() ?? fallback;
    final geometry = json['geometry'] as Map<String, dynamic>? ?? const {};
    final sizes = json['sizes_ml'] as Map<String, dynamic>? ?? const {};

    return ScalingProfile(
      family: family,
      bottomRadiusMm: (geometry['r_bottom_mm'] as num?)?.toDouble() ?? 10,
      halfAngleDeg: (geometry['half_angle_deg'] as num?)?.toDouble() ?? 30,
      capacityMl: {
        for (final entry in sizes.entries)
          entry.key: (entry.value as num).toDouble(),
      },
      defaultSize: json['default_size'] as String? ?? '',
      bedMlPerGram: number('bed_ml_per_g', 2.5),
      retainedPerGram: number('lrr', 2.0),
      bedShare: number('phi_bed', 0.9),
      bloomWettingSeconds: number('bloom_wet_s', 10),
      maxPourRate: number('q_max_g_s', 8),
      grindExponent: number('grind_exponent', 2.5),
      slurryDeficitC: number('slurry_deficit_c', 6),
      fillMargin: number('fill_margin', 0.9),
      drainContribution: number('drain_efficiency', 0.5),
      fixedPourRate: json['fixed_pour_rate'] as bool? ?? false,
      softDoseGrams: number('soft_dose_g', 0),
      maxDoseGrams: number('max_dose_g', 0),
      minDoseGrams: number('min_dose_g', 8),
      minWater: whole('min_water', 120),
      maxWater: whole('max_water', 1000),
      waterStep: whole('water_step', 5),
      maxUnits: whole('max_units', 6),
      unit: ScalingUnit.values
              .where((value) => value.name == json['unit'])
              .firstOrNull ??
          ScalingUnit.run,
      chamberMl: number('chamber_ml', 0),
      displacementMlPerGram: number('displacement_ml_per_g', 0.8),
      minBrewRatio: number('min_brew_ratio', 5),
    );
  }

  /// Встроенный профиль по slug метода; null — прибор не пересчитывается.
  ///
  /// В таблице все 71 прибор справочника на 03.11.2026; прибор, которого
  /// в ней нет (добавили на сервере позже), не пересчитывается, пока профиль
  /// не приедет с сервера или не встанет в таблицу.
  static ScalingProfile? builtIn(String slug) => scalingProfiles[slug];
}
