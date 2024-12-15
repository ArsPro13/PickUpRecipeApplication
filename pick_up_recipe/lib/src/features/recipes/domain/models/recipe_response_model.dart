import 'package:json_annotation/json_annotation.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_response_step_model.dart';

part 'recipe_response_model.g.dart';

@JsonSerializable()
class RecipeResponseModel {
  late int id;

  @JsonKey(name: "pack_id")
  late int packId;

  @JsonKey(name: "grinder_id")
  late int grinderId;

  @JsonKey(name: "grind_step")
  late String grindStep;

  @JsonKey(name: "grind_sub_step")
  late String? grindSubStep;

  late int water;

  late double load;

  late int time;

  late String date;

  late String device;

  late List<RecipeResponseStepModel> steps;

  RecipeResponseModel({
    required this.id,
    required this.packId,
    required this.grinderId,
    required this.grindStep,
    required this.grindSubStep,
    required this.water,
    required this.load,
    required this.time,
    required this.date,
    required this.device,
    required this.steps,
  });

  factory RecipeResponseModel.fromJson(Map<String, dynamic> json) =>
      _$RecipeResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeResponseModelToJson(this);
}
