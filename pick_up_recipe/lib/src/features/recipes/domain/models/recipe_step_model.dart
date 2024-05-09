import 'package:json_annotation/json_annotation.dart';

part 'recipe_step_model.g.dart';

@JsonSerializable()
class RecipeStep {
  @JsonKey(name: "seq_num")
  late int seqNum;

  late String instruction;

  late int water;

  late int start;

  late int stop;

  RecipeStep({
    required this.seqNum,
    required this.instruction,
    required this.water,
    required this.start,
    required this.stop,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) =>
      _$RecipeStepFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeStepToJson(this);
}
