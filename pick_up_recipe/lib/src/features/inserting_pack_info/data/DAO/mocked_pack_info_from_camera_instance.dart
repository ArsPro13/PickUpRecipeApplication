import 'package:pick_up_recipe/src/features/inserting_pack_info/data/DAO/pack_info_from_camera_dao.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';

 class MockedPackInfoFromCameraDAO implements PackInfoFromCameraDAO {
  @override
  Future<PackData> getInfoByImg(String img) async {
    final pack = PackData(packId: '123', userId: '1', packDate: '12.12.2024', packName: 'Kenya AA', packDescriptors: ['fruity', 'Caramel'], packCountry: 'Kenya', packProcessingMethod: ['method1', 'method2'], packImage: 'packImage', packVariety: 'packVariety', packScaScore: 90, isActive: true);
    return pack;
  }
}