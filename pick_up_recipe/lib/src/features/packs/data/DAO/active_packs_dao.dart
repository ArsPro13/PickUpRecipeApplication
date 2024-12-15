import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';

abstract interface class ActivePacksDAO {
  Future<List<PackData>> fetchPacks();
  List<PackData> getPacks();
  Future<PackData?> getPackById(int id);
}