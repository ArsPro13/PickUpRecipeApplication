import 'package:json_annotation/json_annotation.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_response_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';

part 'recipe_data_model.g.dart';

@JsonSerializable()
class RecipeData {
  late String device;

  late String date;

  @JsonKey(name: "pack")
  late int packId;

  @JsonKey(name: "grinder_id")
  late int grinderId;

  @JsonKey(name: "grind_step")
  late String grindStep;

  @JsonKey(name: "grind_sub_step")
  late String? grindSubStep;

  late int water;

  late int time;

  late int temperature;

  late double load;

  late List<RecipeStep> steps;


  RecipeData({
    required this.device,
    required this.date,
    required this.packId,
    required this.grinderId,
    required this.grindStep,
    required this.grindSubStep,
    required this.water,
    required this.time,
    required this.temperature,
    required this.load,
    required this.steps,
  });

  factory RecipeData.fromJson(Map<String, dynamic> json) =>
      _$RecipeDataFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeDataToJson(this);

  factory RecipeData.fromResponse(RecipeResponseModel response) => RecipeData(
        device: response.device,
        date: response.date,
        packId: response.packId,
        grinderId: response.grinderId,
        grindStep: response.grindStep,
        grindSubStep: response.grindSubStep,
        water: response.water,
        time: response.time,
        // todo
        temperature: 95,
        load: response.load,
        steps: response.steps.map((e) => RecipeStep.fromResponse(e)).toList(),
      );
}
