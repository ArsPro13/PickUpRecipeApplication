import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/src/features/packs/data/DAO/active_packs_dao.dart';
import 'active_packs_state.dart';

class ActivePacksStateNotifier extends StateNotifier<ActivePacksState> {
  ActivePacksStateNotifier() : super(const ActivePacksState());

  GetIt getIt = GetIt.instance;

  void clearPacks() {
    state = state.copyWith(activePacks: [], isLoading: false);
  }

  Future<void> fetchPacks() async {
    final ActivePacksDAO dao = getIt.get<ActivePacksDAO>();
    state = state.copyWith(isLoading: true);
    final packs = await dao.fetchPacks();
    state = state.copyWith(activePacks: packs, isLoading: false);
  }
}
