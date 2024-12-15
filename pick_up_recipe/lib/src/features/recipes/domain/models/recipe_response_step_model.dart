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

  RecipeResponseStepModel({
    required this.id,
    required this.recipeId,
    required this.seqNum,
    required this.instruction,
    required this.water,
    required this.time,
  });

  factory RecipeResponseStepModel.fromJson(Map<String, dynamic> json) =>
      _$RecipeResponseStepModelFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeResponseStepModelToJson(this);
}
