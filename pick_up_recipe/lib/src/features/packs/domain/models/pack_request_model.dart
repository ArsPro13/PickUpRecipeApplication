import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:pick_up_recipe/core/converters.dart';
import 'package:pick_up_recipe/main.dart';

part 'pack_request_model.g.dart';

@JsonSerializable()
class PackRequestModel {
  @JsonKey(name: "pack_country")
  late String packCountry;

  @JsonKey(name: "pack_date")
  late String packDate;

  @JsonKey(name: "pack_descriptors")
  late List<String> packDescriptors;

  @JsonKey(name: "pack_image")
  late String packImage;

  @JsonKey(name: "pack_name")
  late String packName;

  @JsonKey(name: "pack_processing_method")
  late List<String> packProcessingMethod;

  @JsonKey(name: "pack_sca_score")
  late int packScaScore;

  @JsonKey(name: "pack_variety")
  late String packVariety;

  PackRequestModel({
    required this.packCountry,
    required this.packDate,
    required this.packDescriptors,
    required this.packImage,
    required this.packName,
    required this.packProcessingMethod,
    required this.packScaScore,
    required this.packVariety,
  });

  Map<String, dynamic> toStringMap() {
    logger.i(convertDateToString(DateFormat('dd.MM.yyyy').tryParse(packDate)?? DateTime.now()));
    return {
      'pack_country': packCountry,
      'pack_date': convertDateToString(DateFormat('dd.MM.yyyy').tryParse(packDate) ?? DateTime.now()),
      'pack_descriptors': packDescriptors,
      'pack_image': packImage,
      'pack_name': packName,
      'pack_processing_method': packProcessingMethod,
      'pack_sca_score': packScaScore,
      'pack_variety': packVariety,
    };
  }

  @override
  String toString() {
    return 'pack_country: $packCountry, pack_date: $packDate, pack_descriptors: $packDescriptors, pack_image: $packImage, pack_name: $packName, pack_processing_method: $packProcessingMethod, pack_sca_score: $packScaScore, pack_variety: $packVariety';
  }

  factory PackRequestModel.fromJson(Map<String, dynamic> json) =>
      _$PackRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$PackRequestModelToJson(this);
}
