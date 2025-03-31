// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_step_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeStep _$RecipeStepFromJson(Map<String, dynamic> json) => RecipeStep(
      seqNum: (json['seq_num'] as num).toInt(),
      instruction: json['instruction'] as String,
      water: (json['water'] as num).toInt(),
      time: (json['time'] as num).toInt(),
      id: (json['id'] as num).toInt(),
    );

Map<String, dynamic> _$RecipeStepToJson(RecipeStep instance) =>
    <String, dynamic>{
      'seq_num': instance.seqNum,
      'instruction': instance.instruction,
      'water': instance.water,
      'time': instance.time,
      'id': instance.id,
    };
