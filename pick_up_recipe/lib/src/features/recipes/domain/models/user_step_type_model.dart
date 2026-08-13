// Свой тип шага: заготовка, которую человек завёл под конкретный метод.
//
// От встроенного типа отличается тем, что у него нет slug в формате рецепта:
// в шаг он кладётся как type='custom' с подписью. Смысл заготовки — не
// набирать одно и то же в каждом рецепте на этом приборе.

/// Чем заканчивается шаг. Значения — как в CHECK таблицы user_step_types.
enum StepEndsWith {
  timer('timer', 'по времени'),
  user('user', 'по кнопке'),
  none('none', 'по признаку');

  const StepEndsWith(this.wire, this.label);

  /// Значение на проводе и в базе.
  final String wire;

  /// Подпись сегмента в форме.
  final String label;

  static StepEndsWith fromWire(String? value) => switch (value) {
        'user' => StepEndsWith.user,
        'none' => StepEndsWith.none,
        _ => StepEndsWith.timer,
      };
}

class UserStepType {
  const UserStepType({
    required this.id,
    required this.brewMethodId,
    required this.label,
    this.icon = 'custom',
    this.endsWith = StepEndsWith.timer,
    this.hasWater = false,
    this.warning = '',
  });

  final int id;
  final int brewMethodId;
  final String label;

  /// Ключ значка из набора шагов — не путь к файлу.
  final String icon;

  final StepEndsWith endsWith;
  final bool hasWater;
  final String warning;

  factory UserStepType.fromJson(Map<String, dynamic> json) => UserStepType(
        id: (json['id'] as num).toInt(),
        brewMethodId: (json['brew_method_id'] as num?)?.toInt() ?? 0,
        label: json['label'] as String? ?? '',
        icon: json['icon'] as String? ?? 'custom',
        endsWith: StepEndsWith.fromWire(json['ends_with'] as String?),
        hasWater: json['has_water'] as bool? ?? false,
        warning: json['warning'] as String? ?? '',
      );
}
