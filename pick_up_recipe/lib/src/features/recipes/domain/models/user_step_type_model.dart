// Свой тип шага: заготовка, которую человек завёл под конкретный метод.
//
// От встроенного типа отличается тем, что у него нет slug в формате рецепта:
// в шаг он кладётся как type='custom' с подписью. Смысл заготовки — не
// набирать одно и то же в каждом рецепте на этом приборе.

/// Чем заканчивается шаг. Значения — как в CHECK таблицы user_step_types.
///
/// Подписи вариантов здесь нет намеренно. Домен отвечает кодом, а не фразой:
/// языка экрана он не знает, а фраза у каждого языка своя — ровно так же
/// устроены правила формы (`domain/auth_rules.dart`). Перевод кода в текст
/// живёт рядом с экраном, расширением `StepEndsWithText` в
/// `general_widgets/step_ending_choice.dart`.
enum StepEndsWith {
  timer('timer'),
  user('user'),
  none('none');

  const StepEndsWith(this.wire);

  /// Значение на проводе и в базе.
  final String wire;

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
