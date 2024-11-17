import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';

abstract interface class PackInfoFromCameraDAO {
  Future<PackData> getInfoByImg(String img);
}