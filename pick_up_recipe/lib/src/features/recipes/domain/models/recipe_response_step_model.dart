import 'package:json_annotation/json_annotation.dart';

part 'recipe_response_step_model.g.dart';

@JsonSerializable()
class RecipeResponseStepModel {
  late int id;

  @JsonKey(name: "recipe_id")
  late int recipeId;

  @JsonKey(name: "seq_num")
  late int seqNum;

  late String instruction;

  late int time;

  late int water;

  // Поля формата v1. У исторических шагов их нет, поэтому все с умолчанием:
  // пустой step_type означает шаг, записанный до появления типов.

  /// Тип шага: bloom, pour, wait, stir… По нему выбирается значок.
  @JsonKey(name: "step_type", defaultValue: '')
  late String stepType;

  @JsonKey(name: "step_key", defaultValue: '')
  late String stepKey;

  /// Подсказка, которую читают во время шага.
  @JsonKey(defaultValue: '')
  late String tip;

  @JsonKey(name: "is_optional", defaultValue: false)
  late bool isOptional;

  /// Шаг закрывает человек, а не таймер: момент снятия турки с огня ловят
  /// на глаз, и длительность рядом становится справочной.
  @JsonKey(name: "until_user", defaultValue: false)
  late bool untilUser;

  /// Что человек должен увидеть, чтобы закрыть шаг.
  @JsonKey(name: "until_sign", defaultValue: '')
  late String untilSign;

  /// Предупреждение, которое надо прочесть ДО начала шага.
  @JsonKey(defaultValue: '')
  late String warning;

  RecipeResponseStepModel({
    required this.id,
    required this.recipeId,
    required this.seqNum,
    required this.instruction,
    required this.water,
    required this.time,
    required this.stepType,
    required this.stepKey,
    required this.tip,
    required this.isOptional,
    required this.untilUser,
    required this.untilSign,
    required this.warning,
  });

  factory RecipeResponseStepModel.fromJson(Map<String, dynamic> json) =>
      _$RecipeResponseStepModelFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeResponseStepModelToJson(this);
}
