// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackData _$PackDataFromJson(Map<String, dynamic> json) => PackData(
      packId: json['pack_id'] as String,
      userId: json['user_id'] as String,
      packDate: json['pack_date'] as String,
      packName: json['pack_name'] as String,
      packDescriptors: (json['pack_descriptors'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      packCountry: json['pack_country'] as String,
      packProcessingMethod: (json['pack_processing_method'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      packImage: json['pack_image'] as String,
      packVariety: json['pack_variety'] as String,
      packScaScore: (json['pack_sca_score'] as num).toInt(),
      isActive: json['is_active'] as bool,
    );

Map<String, dynamic> _$PackDataToJson(PackData instance) => <String, dynamic>{
      'pack_id': instance.packId,
      'user_id': instance.userId,
      'pack_date': instance.packDate,
      'pack_name': instance.packName,
      'pack_descriptors': instance.packDescriptors,
      'pack_country': instance.packCountry,
      'pack_processing_method': instance.packProcessingMethod,
      'pack_image': instance.packImage,
      'pack_variety': instance.packVariety,
      'pack_sca_score': instance.packScaScore,
      'is_active': instance.isActive,
    };
