// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_from_image_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackFromImageResponseModel _$PackFromImageResponseModelFromJson(
        Map<String, dynamic> json) =>
    PackFromImageResponseModel(
      packName: json['pack_name'] as String?,
      packVariety: json['pack_variety'] as String?,
      packDescriptors: (json['pack_descriptors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      packProcessingMethod: (json['pack_processing_method'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      packCountry: json['pack_country'] as String?,
    );

Map<String, dynamic> _$PackFromImageResponseModelToJson(
        PackFromImageResponseModel instance) =>
    <String, dynamic>{
      'pack_name': instance.packName,
      'pack_variety': instance.packVariety,
      'pack_processing_method': instance.packProcessingMethod,
      'pack_descriptors': instance.packDescriptors,
      'pack_country': instance.packCountry,
    };
