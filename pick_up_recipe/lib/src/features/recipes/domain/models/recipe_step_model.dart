import 'package:json_annotation/json_annotation.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_response_step_model.dart';

part 'recipe_step_model.g.dart';

@JsonSerializable()
class RecipeStep {
  @JsonKey(name: "seq_num")
  late int seqNum;

  late String instruction;

  late int water;

  late int time;

  late int id;

  @JsonKey(name: "step_type", defaultValue: '')
  late String stepType;

  @JsonKey(name: "step_key", defaultValue: '')
  late String stepKey;

  @JsonKey(defaultValue: '')
  late String tip;

  @JsonKey(name: "is_optional", defaultValue: false)
  late bool isOptional;

  @JsonKey(name: "until_user", defaultValue: false)
  late bool untilUser;

  @JsonKey(name: "until_sign", defaultValue: '')
  late String untilSign;

  @JsonKey(defaultValue: '')
  late String warning;

  RecipeStep({
    required this.seqNum,
    required this.instruction,
    required this.water,
    required this.time,
    required this.id,
    required this.stepType,
    required this.stepKey,
    required this.tip,
    required this.isOptional,
    required this.untilUser,
    required this.untilSign,
    required this.warning,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) =>
      _$RecipeStepFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeStepToJson(this);

  factory RecipeStep.fromResponse(RecipeResponseStepModel response) =>
      RecipeStep(
        seqNum: response.seqNum,
        instruction: response.instruction,
        water: response.water,
        time: response.time,
        id: response.id,
        stepType: response.stepType,
        stepKey: response.stepKey,
        tip: response.tip,
        isOptional: response.isOptional,
        untilUser: response.untilUser,
        untilSign: response.untilSign,
        warning: response.warning,
      );
}
