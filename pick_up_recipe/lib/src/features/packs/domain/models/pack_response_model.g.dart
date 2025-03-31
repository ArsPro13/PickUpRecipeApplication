// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackResponseBodyModel _$PackResponseBodyModelFromJson(
        Map<String, dynamic> json) =>
    PackResponseBodyModel(
      id: (json['id'] as num).toInt(),
      packCountry: json['pack_country'] as String,
      packDate: json['pack_date'] as String,
      packDescriptors: (json['pack_descriptors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      packImage: json['pack_image'] as String,
      packName: json['pack_name'] as String,
      packProcessingMethod: (json['pack_processing_method'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      packScaScore: (json['pack_sca_score'] as num).toInt(),
      packVariety: json['pack_variety'] as String,
      userId: (json['user_id'] as num).toInt(),
    );

Map<String, dynamic> _$PackResponseBodyModelToJson(
        PackResponseBodyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pack_country': instance.packCountry,
      'pack_date': instance.packDate,
      'pack_descriptors': instance.packDescriptors,
      'pack_image': instance.packImage,
      'pack_name': instance.packName,
      'pack_processing_method': instance.packProcessingMethod,
      'pack_sca_score': instance.packScaScore,
      'pack_variety': instance.packVariety,
      'user_id': instance.userId,
    };
