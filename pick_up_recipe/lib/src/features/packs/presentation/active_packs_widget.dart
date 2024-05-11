import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/packs/presentation/pack_small_card_widget.dart';

import '../data/DAO/active_packs_dao.dart';

class ActivePacksWidget extends StatefulWidget {
  const ActivePacksWidget({super.key});

  @override
  State<ActivePacksWidget> createState() => _LatestRecipesWidgetState();
}

class _LatestRecipesWidgetState extends State<ActivePacksWidget> {
  bool loaded = false;
  List<PackData> activePacks = [];
  GetIt getIt = GetIt.instance;
  late final ActivePacksDAO dao;

  @override
  void initState() {
    dao = getIt.get<ActivePacksDAO>();
    loaded = false;
    super.initState();
    fetchPacks(dao);
  }

  Future<void> fetchPacks(ActivePacksDAO dao) async {
    setState(() {
      loaded = false;
    });
    activePacks = await dao.fetchPacks();
    setState(() {
      loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      // padding: const EdgeInsets.only(top: 10),
      itemCount: activePacks.length,
      itemBuilder: (context, index) {
        return PackSmallCardWidget(pack: activePacks[index]);
      },
    );
  }
}
