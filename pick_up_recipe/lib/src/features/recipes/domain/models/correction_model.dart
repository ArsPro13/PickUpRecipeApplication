// Поправка рецепта по жалобам на вкус.
//
// Считает её бэкенд (`pkg/correction`), клиент только показывает. Здесь важно
// одно: у каждой поправки есть причины — та самая жалоба, которая её вызвала.
// Экран без причин превращается в «сервер сказал мели мельче», и доверия
// такому экрану нет.

/// Почему параметр поменялся.
class CorrectionReason {
  const CorrectionReason({required this.complaint, required this.text});

  /// Код жалобы: sour, bitter, weak, too_strong, flat, astringent.
  final String complaint;

  /// Объяснение человеческим языком.
  final String text;

  factory CorrectionReason.fromJson(Map<String, dynamic> json) => CorrectionReason(
        complaint: json['complaint'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );
}

/// Один изменённый параметр: было → стало.
class CorrectionChange {
  const CorrectionChange({
    required this.param,
    required this.from,
    required this.to,
    required this.reasons,
    this.stepId,
    this.hint,
  });

  /// Что меняется: grind_steps, temperature_c, ratio, agitation, contact_time_sec.
  final String param;

  final num from;
  final num to;

  final List<CorrectionReason> reasons;

  /// Шаг, на котором поправку видно: температура на первом проливе, помол на
  /// помоле, агитация на размешивании (ответ A3).
  final String? stepId;

  /// Подсказка к направлению — «минус — мельче».
  final String? hint;

  factory CorrectionChange.fromJson(Map<String, dynamic> json) => CorrectionChange(
        param: json['param'] as String? ?? '',
        from: json['from'] as num? ?? 0,
        to: json['to'] as num? ?? 0,
        stepId: json['step_id'] as String?,
        hint: json['hint'] as String?,
        reasons: [
          for (final reason in (json['reasons'] as List<dynamic>? ?? []))
            CorrectionReason.fromJson(reason as Map<String, dynamic>),
        ],
      );

  /// Название параметра для человека.
  String get title => switch (param) {
        'grind_steps' => 'Помол',
        'temperature_c' => 'Температура',
        'ratio' => 'Соотношение',
        'agitation' => 'Размешивание',
        'contact_time_sec' => 'Время контакта',
        'dose_g' => 'Доза',
        _ => param,
      };

  String _format(num value) => switch (param) {
        'grind_steps' => value > 0 ? '+$value' : '$value',
        'temperature_c' => '$value °C',
        'ratio' => '1:${value.toStringAsFixed(1)}',
        'contact_time_sec' => '${(value / 60).floor()}:'
            '${(value % 60).toInt().toString().padLeft(2, '0')}',
        'dose_g' => '$value г',
        _ => '$value',
      };

  String get fromLabel => _format(from);
  String get toLabel => _format(to);
}

/// Предложение поправки целиком.
class RecipeCorrection {
  const RecipeCorrection({required this.changes, required this.checks});

  final List<CorrectionChange> changes;

  /// «Что проверить» — приходит, когда жалобы тянут параметр в разные стороны.
  /// Тексты зависят от группы метода (вопрос 16).
  final List<String> checks;

  bool get isEmpty => changes.isEmpty;

  factory RecipeCorrection.fromJson(Map<String, dynamic> json) => RecipeCorrection(
        changes: [
          for (final change in (json['changes'] as List<dynamic>? ?? []))
            CorrectionChange.fromJson(change as Map<String, dynamic>),
        ],
        checks: [
          for (final check in (json['checks'] as List<dynamic>? ?? [])) check.toString(),
        ],
      );
}
