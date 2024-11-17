import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';

abstract interface class PackInfoDAO {
  Future<PackData?> sendPack(
    String packCountry,
    String packDate,
    List<String> packDescriptors,
    String packImage,
    String packName,
    List<String> packProcessingMethod,
    int packScaScore,
    String packVariety,
  );
}
