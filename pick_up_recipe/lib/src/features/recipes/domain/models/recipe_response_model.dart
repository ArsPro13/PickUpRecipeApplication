import 'package:json_annotation/json_annotation.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_response_step_model.dart';

part 'recipe_response_model.g.dart';

@JsonSerializable()
class RecipeResponseModel {
  late int id;

  // 0 — у рецепта нет пачки: так устроен справочный рецепт метода.
  // null в JSON именно это и означает, а не ошибку данных.
  @JsonKey(name: "pack_id", defaultValue: 0)
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

  // Поля формата рецепта v1. Все необязательные: у исторических рецептов их
  // нет, и запрашивать их у сервера как обязательные значит уронить разбор
  // на первой же старой записи.

  /// Название рецепта. Пусто — показываем метод заваривания.
  @JsonKey(defaultValue: '')
  late String title;

  @JsonKey(defaultValue: '')
  late String notes;

  /// Температура воды. Раньше клиент подставлял сюда 95 для всех рецептов.
  late double? temperature;

  /// Крупность помола словами — slug из справочника.
  @JsonKey(name: "grind_descriptor", defaultValue: '')
  late String grindDescriptor;

  /// Уровень агитации 0…4.
  @JsonKey(name: "agitation_level")
  late int? agitationLevel;

  @JsonKey(name: "brew_method_id")
  late int? brewMethodId;

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
    required this.title,
    required this.notes,
    required this.temperature,
    required this.grindDescriptor,
    required this.agitationLevel,
    required this.brewMethodId,
    required this.steps,
  });

  factory RecipeResponseModel.fromJson(Map<String, dynamic> json) =>
      _$RecipeResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeResponseModelToJson(this);
}
