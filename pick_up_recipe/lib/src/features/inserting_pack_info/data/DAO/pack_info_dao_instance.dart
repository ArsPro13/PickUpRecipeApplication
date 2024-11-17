import 'package:pick_up_recipe/src/features/inserting_pack_info/data/DAO/pack_info_dao.dart';
import 'package:pick_up_recipe/src/features/packs/data_sources/remote/pack_service.dart';


import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_request_model.dart';

class PackInfoDAOInstance implements PackInfoDAO {
  final PackService _packService = PackService();

  @override
  Future<PackData?> sendPack(
    String packCountry,
    String packDate,
    List<String> packDescriptors,
    String packImage,
    String packName,
    List<String> packProcessingMethod,
    int packScaScore,
    String packVariety,
  ) async {
    try {
      final pack = await _packService.addPack(
        PackRequestModel(
          packCountry: packCountry,
          packDate: packDate,
          packDescriptors: packDescriptors,
          packImage: packImage,
          packName: packName,
          packProcessingMethod: packProcessingMethod,
          packScaScore: packScaScore,
          packVariety: packVariety,
        ),
      );
      return pack;
    } catch (e) {
      rethrow;
    }
  }
}
