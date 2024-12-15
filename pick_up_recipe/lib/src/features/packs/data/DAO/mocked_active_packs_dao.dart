import 'dart:convert';

import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';

import '../../../../mocked_recipes.dart';
import 'active_packs_dao.dart';

class MockedActivePacksDAOInstance implements ActivePacksDAO {
  List<PackData> latestRecipes = [];

  @override
  Future<List<PackData>> fetchPacks() async {
    final data1 = json.decode(mockedJson1)["pack"];
    final data2 = json.decode(mockedJson2)["pack"];
    final data3 = json.decode(mockedJson3)["pack"];

    List<PackData> newPacks = [];

    newPacks.add(PackData.fromJson(data1));
    newPacks.add(PackData.fromJson(data2));
    newPacks.add(PackData.fromJson(data3));

    latestRecipes = newPacks;

    return latestRecipes;
  }

  @override
  List<PackData> getPacks() {
    return latestRecipes;
  }

  @override
  Future<PackData?> getPackById(int id) async {
    final data1 = json.decode(mockedJson1)["pack"];
    return PackData.fromJson(data1);
  }
}
