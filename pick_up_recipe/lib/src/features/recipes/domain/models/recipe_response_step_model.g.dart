// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_response_step_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeResponseStepModel _$RecipeResponseStepModelFromJson(
        Map<String, dynamic> json) =>
    RecipeResponseStepModel(
      id: (json['id'] as num).toInt(),
      recipeId: (json['recipe_id'] as num).toInt(),
      seqNum: (json['seq_num'] as num).toInt(),
      instruction: json['instruction'] as String,
      water: (json['water'] as num).toInt(),
      time: (json['time'] as num).toInt(),
    );

Map<String, dynamic> _$RecipeResponseStepModelToJson(
        RecipeResponseStepModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recipe_id': instance.recipeId,
      'seq_num': instance.seqNum,
      'instruction': instance.instruction,
      'time': instance.time,
      'water': instance.water,
    };
