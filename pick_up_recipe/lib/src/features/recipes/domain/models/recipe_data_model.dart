import 'package:json_annotation/json_annotation.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';

part 'recipe_data_model.g.dart';

@JsonSerializable()
class RecipeData {
  late String device;

  late String date;

  @JsonKey(name: "pack")
  late PackData pack;

  @JsonKey(name: "grinder_id")
  late String grinderId;

  @JsonKey(name: "grind_step")
  late int grindStep;

  @JsonKey(name: "grind_sub_step")
  late int grindSubStep;

  late int water;

  late int time;

  late int temperature;

  late int load;

  late List<RecipeStep> steps;

  RecipeData({
    required this.device,
    required this.date,
    required this.pack,
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
}
