// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeData _$RecipeDataFromJson(Map<String, dynamic> json) => RecipeData(
      device: json['device'] as String,
      date: json['date'] as String,
      pack: PackData.fromJson(json['pack'] as Map<String, dynamic>),
      grinderId: json['grinder_id'] as String,
      grindStep: (json['grind_step'] as num).toInt(),
      grindSubStep: (json['grind_sub_step'] as num).toInt(),
      water: (json['water'] as num).toInt(),
      time: (json['time'] as num).toInt(),
      temperature: (json['temperature'] as num).toInt(),
      load: (json['load'] as num).toInt(),
      steps: (json['steps'] as List<dynamic>)
          .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RecipeDataToJson(RecipeData instance) =>
    <String, dynamic>{
      'device': instance.device,
      'date': instance.date,
      'pack': instance.pack,
      'grinder_id': instance.grinderId,
      'grind_step': instance.grindStep,
      'grind_sub_step': instance.grindSubStep,
      'water': instance.water,
      'time': instance.time,
      'temperature': instance.temperature,
      'load': instance.load,
      'steps': instance.steps,
    };
