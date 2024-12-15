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

  RecipeStep({
    required this.seqNum,
    required this.instruction,
    required this.water,
    required this.time,
    required this.id,
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
      );
}
