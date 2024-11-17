import 'package:pick_up_recipe/src/features/packs/data_sources/remote/pack_service.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';

import 'active_packs_dao.dart';

class ActivePacksDAOImpl implements ActivePacksDAO {
  List<PackData> latestPacks = [];
  final PackService _packService = PackService();

  @override
  Future<List<PackData>> fetchPacks() async {
    try {
      final packs =
          await _packService.getPacks(null, null, null, null, null, null, null);

      latestPacks = [];
      for (final pack in packs ?? []) {
        latestPacks.add(PackData.fromResponse(pack));
      }

      return latestPacks;
    } catch (e) {
      rethrow;
    }
  }

  @override
  List<PackData> getPacks() {
    return latestPacks;
  }
}
