import 'package:json_annotation/json_annotation.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_response_model.dart';

part 'pack_model.g.dart';

@JsonSerializable()
class PackData {
  @JsonKey(name: "pack_id")
  late int packId;

  @JsonKey(name: "user_id")
  late String userId;

  @JsonKey(name: "pack_date")
  late String packDate;

  @JsonKey(name: "pack_name")
  late String packName;

  @JsonKey(name: "pack_descriptors")
  late List<String>? packDescriptors;

  @JsonKey(name: "pack_country")
  late String packCountry;

  @JsonKey(name: "pack_processing_method")
  late List<String>? packProcessingMethod;

  @JsonKey(name: "pack_image")
  late String packImage;

  @JsonKey(name: "pack_variety")
  late String packVariety;

  @JsonKey(name: "pack_sca_score")
  late int packScaScore;

  @JsonKey(name: "is_active")
  late bool isActive;

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
    required this.isActive,
  });

  factory PackData.fromJson(Map<String, dynamic> json) =>
      _$PackDataFromJson(json);

  factory PackData.fromResponse(PackResponseBodyModel response) {
    return PackData(
      packId: response.id,
      userId: response.userId.toString(),
      packDate: response.packDate,
      packName: response.packName,
      packDescriptors: response.packDescriptors,
      packCountry: response.packCountry,
      packProcessingMethod: response.packProcessingMethod,
      packImage: response.packImage,
      packVariety: response.packVariety,
      packScaScore: response.packScaScore,
      isActive: true,
    );
  }

  Map<String, dynamic> toJson() => _$PackDataToJson(this);

  @override
  String toString() {
    return 'packId: $packId, userId: $userId, packDate: $packDate, packName: $packName, packDescriptors: $packDescriptors, packCountry: $packCountry, packProcessingMethod: $packProcessingMethod, packImage: $packImage, packVariety: $packVariety, packScaScore: $packScaScore ';
  }
}
