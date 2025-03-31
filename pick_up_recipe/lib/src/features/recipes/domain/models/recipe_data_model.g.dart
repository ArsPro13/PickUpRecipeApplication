// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeData _$RecipeDataFromJson(Map<String, dynamic> json) => RecipeData(
      device: json['device'] as String,
      date: json['date'] as String,
      packId: (json['pack'] as num).toInt(),
      grinderId: (json['grinder_id'] as num).toInt(),
      grindStep: json['grind_step'] as String,
      grindSubStep: json['grind_sub_step'] as String?,
      water: (json['water'] as num).toInt(),
      time: (json['time'] as num).toInt(),
      temperature: (json['temperature'] as num).toInt(),
      load: (json['load'] as num).toDouble(),
      steps: (json['steps'] as List<dynamic>)
          .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RecipeDataToJson(RecipeData instance) =>
    <String, dynamic>{
      'device': instance.device,
      'date': instance.date,
      'pack': instance.packId,
      'grinder_id': instance.grinderId,
      'grind_step': instance.grindStep,
      'grind_sub_step': instance.grindSubStep,
      'water': instance.water,
      'time': instance.time,
      'temperature': instance.temperature,
      'load': instance.load,
      'steps': instance.steps,
    };
