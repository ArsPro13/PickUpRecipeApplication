import 'package:json_annotation/json_annotation.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_response_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';

part 'recipe_data_model.g.dart';

@JsonSerializable()
class RecipeData {
  /// Идентификатор рецепта. Без него нельзя ни сохранить оценку, ни попросить
  /// поправку: обе ручки работают по recipe_id.
  late int id;

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

  /// Температура воды. null — рецепт её не знает: так у исторических записей,
  /// и показывать вместо неё придуманное число нельзя.
  late double? temperature;

  late double load;

  /// Название рецепта. Пусто — экран показывает метод заваривания.
  late String title;

  late String notes;

  late String grindDescriptor;

  late int? agitationLevel;

  late List<RecipeStep> steps;

  RecipeData({
    required this.id,
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
    required this.title,
    required this.notes,
    required this.grindDescriptor,
    required this.agitationLevel,
    required this.steps,
  });

  factory RecipeData.fromJson(Map<String, dynamic> json) =>
      _$RecipeDataFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeDataToJson(this);

  factory RecipeData.fromResponse(RecipeResponseModel response) => RecipeData(
        id: response.id,
        device: response.device,
        date: response.date,
        packId: response.packId,
        grinderId: response.grinderId,
        grindStep: response.grindStep,
        grindSubStep: response.grindSubStep,
        water: response.water,
        time: response.time,
        temperature: response.temperature,
        load: response.load,
        title: response.title,
        notes: response.notes,
        grindDescriptor: response.grindDescriptor,
        agitationLevel: response.agitationLevel,
        steps: response.steps.map((e) => RecipeStep.fromResponse(e)).toList(),
      );
}
