// Профиль прибора для пересчёта рецепта на другой объём воды.
//
// Пересчёт зависит не от рецепта, а от того, как устроена воронка: в конусе
// V60 вдвое больше кофе дают слой глубже лишь на четверть, в воронке с плоским
// дном — почти вдвое. Поэтому у каждого прибора своя геометрия, свой объём до
// кромки и своя «семья»: пролив, клапан, иммерсия.
//
// Источник чисел — исследование «Рецепт на несколько человек»
// (artifacts/scaling-research/scaling-recipes-research-2026-11-03.pdf,
// разделы 3–9 и приложение). Здесь — встроенная таблица на базовые методы:
// пересчёт обязан работать без сети, как встроенная палитра. Позже профиль
// приедет полем `scaling` в `default_params` справочника методов, и
// [ScalingProfile.fromJson] его разберёт; таблица останется запасной.

/// Как прибор заваривает — от этого зависит, что вообще пересчитывается.
enum ScalingFamily {
  /// Пролив: вода проходит через слой. Меняются проливы, паузы, слив и помол.
  percolation,

  /// Клапан (Clever, Switch): настаивание, потом слив через бумагу. Помол
  /// прежний, прибавку слива забирает настаивание.
  valve,

  /// Иммерсия (френч-пресс): всё время в воде. Помол прежний, настаивание
  /// чуть короче — большой объём дольше держит тепло.
  immersion,
}

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
  });

  final ScalingFamily family;

  /// Радиус дна воронки, мм. У конуса V60 — радиус отверстия.
  final double bottomRadiusMm;

  /// Наклон стенки от вертикали, градусы. У V60 — 30 (конус 60°).
  final double halfAngleDeg;

  /// Объём до кромки по размерам прибора: `{'01': 194, '02': 310}`.
  /// Пусто — вместимость не проверяется.
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

  /// Объём до кромки для размера [size]; 0 — проверять нечего.
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
    final family = switch (json['family']) {
      'percolation' => ScalingFamily.percolation,
      'valve' => ScalingFamily.valve,
      'immersion' => ScalingFamily.immersion,
      _ => null,
    };
    if (family == null) return null;

    double number(String key, double fallback) =>
        (json[key] as num?)?.toDouble() ?? fallback;
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
    );
  }

  /// Встроенный профиль по slug метода; null — прибор не пересчитывается.
  ///
  /// Аэропресс, эспрессо, мока, турка, сифон и холодные методы здесь
  /// намеренно отсутствуют: у них объём задаёт сам прибор (камера, корзина,
  /// бойлер), и «больше воды» означает другой рецепт — концентрат с доливкой
  /// или несколько заходов, — а не тот же самый на большее число людей.
  static ScalingProfile? builtIn(String slug) => _builtIn[slug];
}

/// Встроенная таблица. Объёмы V60 — расчёт по углу 60° и внутреннему
/// диаметру (раздел 9 исследования); у остальных — оценки по размерам.
const Map<String, ScalingProfile> _builtIn = {
  'hario_v60': ScalingProfile(
    family: ScalingFamily.percolation,
    capacityMl: {'01': 194, '02': 310, '03': 521},
    defaultSize: '02',
    softDoseGrams: 30,
    maxDoseGrams: 50,
  ),
  'origami': ScalingProfile(
    family: ScalingFamily.percolation,
    capacityMl: {'S': 194, 'M': 310},
    defaultSize: 'M',
    softDoseGrams: 30,
    maxDoseGrams: 50,
  ),
  'chemex': ScalingProfile(
    family: ScalingFamily.percolation,
    bottomRadiusMm: 6,
    halfAngleDeg: 33,
    capacityMl: {'6': 560},
    defaultSize: '6',
    softDoseGrams: 50,
    maxDoseGrams: 60,
  ),
  'kalita_wave': ScalingProfile(
    family: ScalingFamily.percolation,
    bottomRadiusMm: 29,
    halfAngleDeg: 21.8,
    capacityMl: {'155': 300, '185': 485},
    defaultSize: '185',
    softDoseGrams: 30,
    maxDoseGrams: 40,
  ),
  'april': ScalingProfile(
    family: ScalingFamily.percolation,
    bottomRadiusMm: 25,
    halfAngleDeg: 25,
    capacityMl: {'': 400},
  ),
  'batch_brewer': ScalingProfile(
    family: ScalingFamily.percolation,
    bottomRadiusMm: 45,
    halfAngleDeg: 15,
    capacityMl: {'': 1800},
    fixedPourRate: true,
  ),
  'hario_switch': ScalingProfile(
    family: ScalingFamily.valve,
    capacityMl: {'02': 310, '03': 521},
    defaultSize: '02',
  ),
  'clever': ScalingProfile(
    family: ScalingFamily.valve,
    bottomRadiusMm: 18,
    halfAngleDeg: 27,
    capacityMl: {'': 500},
  ),
  'french_press': ScalingProfile(
    family: ScalingFamily.immersion,
    bottomRadiusMm: 45,
    halfAngleDeg: 0,
    capacityMl: {'0.35': 350, '0.5': 500, '1.0': 1000, '1.5': 1500},
    defaultSize: '1.0',
  ),
};
