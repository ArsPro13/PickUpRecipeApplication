import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/src/features/packs/data_sources/remote/pack_service.dart';
import 'active_packs_state.dart';

class ActivePacksStateNotifier extends StateNotifier<ActivePacksState> {
  ActivePacksStateNotifier() : super(const ActivePacksState());

  GetIt getIt = GetIt.instance;

  void clearPacks() {
    state = state.copyWith(activePacks: [], isLoading: false);
  }

  Future<void> fetchPacks() async {
    final PackService packService = PackService();

    state = state.copyWith(isLoading: true);
    try {
      final packs = await packService.getPacks();
      state = state.copyWith(activePacks: packs, isLoading: false);
    } catch (error) {
      // Полка молчит только в одном случае — сети нет и в памяти пусто
      // (первый запуск без связи). Крутилка в этом случае крутилась бы
      // вечно: исключение уходило из postFrameCallback в никуда, и
      // isLoading оставался поднятым навсегда.
      logger.e('Полка не загрузилась', error: error);
      state = state.copyWith(isLoading: false);
    }
  }
}
