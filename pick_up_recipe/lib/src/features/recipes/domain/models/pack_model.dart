import 'package:json_annotation/json_annotation.dart';

part 'pack_model.g.dart';

@JsonSerializable()
class PackData {
  @JsonKey(name: "pack_id")
  late String packId;

  @JsonKey(name: "user_id")
  late String userId;

  @JsonKey(name: "pack_date")
  late String packDate;

  @JsonKey(name: "pack_name")
  late String packName;

  @JsonKey(name: "pack_descriptors")
  late List<String> packDescriptors;

  @JsonKey(name: "pack_country")
  late String packCountry;

  @JsonKey(name: "pack_processing_method")
  late List<String> packProcessingMethod;

  @JsonKey(name: "pack_image")
  late String packImage;

  @JsonKey(name: "pack_variety")
  late String packVariety;

  @JsonKey(name: "pack_sca_score")
  late int packScaScore;

  PackData({
    required this.packId,
    required this.userId,
    required this.packDate,
    required this.packName,
    required this.packDescriptors,
    required this.packCountry,
    required this.packProcessingMethod,
    required this.packImage,
    required this.packVariety,
    required this.packScaScore,
  });

  factory PackData.fromJson(Map<String, dynamic> json) =>
      _$PackDataFromJson(json);

  Map<String, dynamic> toJson() => _$PackDataToJson(this);
}
