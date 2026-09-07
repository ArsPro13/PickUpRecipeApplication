// Шаг рецепта для движка проигрывания.
//
// Существующая модель RecipeStep (recipe_step_model.dart) остаётся как есть:
// на ней держится текущий экран заваривания. Этот тип — то, что нужно именно
// плееру, и он строится из того же ответа сервера фабрикой fromResponse.
//
// Типы шагов совпадают с docs/spec/recipe-schema.md. Строковые значения —
// ровно те, что приходят с сервера в поле step_type.
//
// Признаки завершения (`untilUser`, `untilSign`) сами по себе ни о чём не
// говорят экрану: вопрос «шаг ждёт человека?» задаётся один на все экраны и
// живёт в step_ending.dart. Читать эти поля напрямую — значит завести второй
// ответ на тот же вопрос.

/// Тип шага. Значения совпадают с enum в docs/spec/recipe.schema.json.
enum BrewStepType {
  bloom('bloom'),
  pour('pour'),
  wait('wait'),
  stir('stir'),
  swirl('swirl'),
  press('press'),
  invert('invert'),
  flip('flip'),
  removeFilter('remove_filter'),
  openValve('open_valve'),
  closeValve('close_valve'),
  grind('grind'),
  addIce('add_ice'),
  dilute('dilute'),
  serve('serve'),
  note('note'),
  custom('custom');

  const BrewStepType(this.wireName);

  /// Значение, которое приходит с сервера.
  final String wireName;

  /// Разбирает значение с сервера.
  ///
  /// У исторических рецептов step_type пустой: до формата v1 тип шага не
  /// хранился. Такие шаги становятся [BrewStepType.custom] — подпись при этом
  /// сохраняется, поэтому пользователь ничего не теряет.
  static BrewStepType fromWire(String? value) {
    if (value == null || value.isEmpty) return BrewStepType.custom;
    for (final type in BrewStepType.values) {
      if (type.wireName == value) return type;
    }
    return BrewStepType.custom;
  }

  /// Добавляет ли шаг воду. Совпадает с правилом схемы: вода разрешена
  /// только этим четырём типам.
  bool get addsWater =>
      this == BrewStepType.bloom ||
      this == BrewStepType.pour ||
      this == BrewStepType.addIce ||
      this == BrewStepType.dilute;

  /// Нужно ли предупредить пользователя до начала шага.
  ///
  /// Переворот аэропресса с горячей водой и отжим — действия, которые нельзя
  /// начинать врасплох.
  bool get needsWarning =>
      this == BrewStepType.invert ||
      this == BrewStepType.flip ||
      this == BrewStepType.press;
}

/// Шаг в том виде, в каком его проигрывает движок.
class BrewStep {
  const BrewStep({
    required this.id,
    required this.type,
    required this.label,
    required this.duration,
    this.waterG = 0,
    this.tip = '',
    this.isOptional = false,
    this.untilUser = false,
    this.untilSign = '',
    this.warning = '',
  });

  final String id;
  final BrewStepType type;
  final String label;
  final Duration duration;

  /// Вода, добавляемая на этом шаге (приращение, не накопительный итог).
  final double waterG;

  final String tip;
  final bool isOptional;

  /// Шаг заканчивается не по таймеру, а по человеку: он сам говорит «сделал».
  final bool untilUser;

  /// Признак, по которому шаг кончается: «пока воронка не опустеет».
  /// Пусто — признака нет, ориентир только время.
  final String untilSign;

  /// Предупреждение обжарщика: «не дави до упора — горечь».
  final String warning;

  /// Собирает шаг из того, что отдаёт сервер.
  ///
  /// [stepType] и [stepKey] появились вместе с форматом v1 и у исторических
  /// рецептов отсутствуют — тогда тип станет custom, а ключ соберётся из
  /// порядкового номера.
  factory BrewStep.fromResponse({
    required int seqNum,
    required String instruction,
    required int timeSec,
    required int waterMl,
    String? stepType,
    String? stepKey,
    String? tip,
    bool isOptional = false,
    bool untilUser = false,
    String? untilSign,
    String? warning,
  }) {
    final type = BrewStepType.fromWire(stepType);

    return BrewStep(
      id: (stepKey == null || stepKey.isEmpty) ? 's$seqNum' : stepKey,
      type: type,
      label: instruction,
      duration: Duration(seconds: timeSec),
      untilUser: untilUser,
      untilSign: untilSign ?? '',
      warning: warning ?? '',
      // Вода приписывается только тем типам, которым она разрешена схемой.
      // Историческая строка могла содержать воду у шага размешивания —
      // повторять эту ошибку в плеере незачем.
      waterG: type.addsWater ? waterMl.toDouble() : 0,
      tip: tip ?? '',
      isOptional: isOptional,
    );
  }

  @override
  String toString() => 'BrewStep($id, ${type.wireName}, ${duration.inSeconds}s)';
}
