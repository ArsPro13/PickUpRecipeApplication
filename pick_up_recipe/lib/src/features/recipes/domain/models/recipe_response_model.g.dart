// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeResponseModel _$RecipeResponseModelFromJson(Map<String, dynamic> json) =>
    RecipeResponseModel(
      id: (json['id'] as num).toInt(),
      packId: (json['pack_id'] as num).toInt(),
      grinderId: (json['grinder_id'] as num).toInt(),
      grindStep: json['grind_step'] as String,
      grindSubStep: json['grind_sub_step'] as String?,
      water: (json['water'] as num).toInt(),
      load: (json['load'] as num).toDouble(),
      time: (json['time'] as num).toInt(),
      date: json['date'] as String,
      device: json['device'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((e) =>
              RecipeResponseStepModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RecipeResponseModelToJson(
        RecipeResponseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pack_id': instance.packId,
      'grinder_id': instance.grinderId,
      'grind_step': instance.grindStep,
      'grind_sub_step': instance.grindSubStep,
      'water': instance.water,
      'load': instance.load,
      'time': instance.time,
      'date': instance.date,
      'device': instance.device,
      'steps': instance.steps,
    };
