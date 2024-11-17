import 'package:json_annotation/json_annotation.dart';

part 'pack_response_model.g.dart';

@JsonSerializable()
class PackResponseBodyModel {
  @JsonKey(name: "id")
  late int id;

  @JsonKey(name: "pack_country")
  late String packCountry;

  @JsonKey(name: "pack_date")
  late String packDate;

  @JsonKey(name: "pack_descriptors")
  late List<String>? packDescriptors;

  @JsonKey(name: "pack_image")
  late String packImage;

  @JsonKey(name: "pack_name")
  late String packName;

  @JsonKey(name: "pack_processing_method")
  late List<String>? packProcessingMethod;

  @JsonKey(name: "pack_sca_score")
  late int packScaScore;

  @JsonKey(name: "pack_variety")
  late String packVariety;

  @JsonKey(name: "user_id")
  late int userId;

  PackResponseBodyModel({
    required this.id,
    required this.packCountry,
    required this.packDate,
    required this.packDescriptors,
    required this.packImage,
    required this.packName,
    required this.packProcessingMethod,
    required this.packScaScore,
    required this.packVariety,
    required this.userId,
  });

  factory PackResponseBodyModel.fromJson(Map<String, dynamic> json) =>
      _$PackResponseBodyModelFromJson(json);

  Map<String, dynamic> toJson() => _$PackResponseBodyModelToJson(this);
}
