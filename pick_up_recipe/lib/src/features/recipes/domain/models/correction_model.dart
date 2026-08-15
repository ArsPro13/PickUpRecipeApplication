// Поправка рецепта по жалобам на вкус.
//
// Считает её бэкенд (`pkg/correction`), клиент только показывает. Здесь важно
// одно: у каждой поправки есть причины — та самая жалоба, которая её вызвала.
// Экран без причин превращается в «сервер сказал мели мельче», и доверия
// такому экрану нет.

import 'recipe_data_model.dart';
import 'recipe_response_model.dart';

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

/// Одна проверка техники — пункт списка «Что проверить».
class ConflictCheck {
  const ConflictCheck({required this.iconKey, required this.title, required this.text});

  /// Ключ иконки на клиенте — то же соглашение, что у справочников.
  final String iconKey;

  final String title;
  final String text;

  factory ConflictCheck.fromJson(Map<String, dynamic> json) => ConflictCheck(
        iconKey: json['icon_key'] as String? ?? '',
        title: json['title'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );
}

/// Пара жалоб, тянущих параметры в разные стороны, — «кисло и горько сразу».
///
/// Это не ошибка ввода: человек действительно так чувствует. Ответ правил
/// в этом случае не про цифры, а про технику, и тексты проверок зависят от
/// группы метода (вопрос 16): «ровность таблетки» у эспрессо и «ровность
/// шапки» у V60 — разные проверки.
class CorrectionConflict {
  const CorrectionConflict({
    required this.complaints,
    required this.explanation,
    required this.checks,
  });

  final List<String> complaints;
  final String explanation;
  final List<ConflictCheck> checks;

  factory CorrectionConflict.fromJson(Map<String, dynamic> json) => CorrectionConflict(
        complaints: [
          for (final complaint in (json['complaints'] as List<dynamic>? ?? []))
            complaint.toString(),
        ],
        explanation: json['explanation'] as String? ?? '',
        checks: [
          for (final check in (json['checks'] as List<dynamic>? ?? []))
            ConflictCheck.fromJson(check as Map<String, dynamic>),
        ],
      );
}

/// Предложение поправки целиком.
class RecipeCorrection {
  const RecipeCorrection({
    required this.changes,
    required this.conflicts,
    this.recipe,
  });

  final List<CorrectionChange> changes;

  /// Конфликты жалоб. Раньше клиент читал поле `checks` с верхнего уровня —
  /// сервер такого не шлёт, и список проверок всегда оказывался пустым.
  final List<CorrectionConflict> conflicts;

  /// Рецепт с уже применёнными поправками — его собирает бэкенд в том же
  /// виде, в каком его принимает POST /recipe/evolve. Конструктор открывает
  /// именно его: клиент не пересчитывает числа сам, и разъехаться с
  /// правилами ему нечем.
  final RecipeData? recipe;

  bool get isEmpty => changes.isEmpty;

  bool get hasConflicts => conflicts.isNotEmpty;

  factory RecipeCorrection.fromJson(Map<String, dynamic> json) => RecipeCorrection(
        changes: [
          for (final change in (json['changes'] as List<dynamic>? ?? []))
            CorrectionChange.fromJson(change as Map<String, dynamic>),
        ],
        conflicts: [
          for (final conflict in (json['conflicts'] as List<dynamic>? ?? []))
            CorrectionConflict.fromJson(conflict as Map<String, dynamic>),
        ],
        // Через модель серверного формата: там pack_id и defaultValue на
        // случай базового рецепта. RecipeData.fromJson ждёт ключ `pack` —
        // это внутренний формат, сервер так не пишет.
        recipe: json['recipe'] == null
            ? null
            : RecipeData.fromResponse(
                RecipeResponseModel.fromJson(json['recipe'] as Map<String, dynamic>),
              ),
      );
}
