import 'package:json_annotation/json_annotation.dart';

part 'pack_from_image_response_model.g.dart';

@JsonSerializable()
class PackFromImageResponseModel {
  @JsonKey(name: "pack_name")
  late String? packName;

  @JsonKey(name: "pack_variety")
  late String? packVariety;

  @JsonKey(name: "pack_processing_method")
  late List<String>? packProcessingMethod;

  @JsonKey(name: "pack_descriptors")
  late List<String>? packDescriptors;


  @JsonKey(name: "pack_country")
  late String? packCountry;

  PackFromImageResponseModel({
    required this.packName,
    required this.packVariety,
    required this.packDescriptors,
    required this.packProcessingMethod,
    required this.packCountry,
  });

  factory PackFromImageResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PackFromImageResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$PackFromImageResponseModelToJson(this);
}
