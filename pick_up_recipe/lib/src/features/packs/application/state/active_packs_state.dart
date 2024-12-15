import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/src/features/packs/application/state/active_packs_state_notifier.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';

class ActivePacksState {
  final List<PackData> activePacks;
  final bool isLoading;

  const ActivePacksState({this.activePacks = const [], this.isLoading = false});

  ActivePacksState copyWith({List<PackData>? activePacks, bool? isLoading}) {
    return ActivePacksState(
      activePacks: activePacks ?? this.activePacks,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<Object?> get props => [activePacks];
}

final activePacksNotifierProvider =
    StateNotifierProvider<ActivePacksStateNotifier, ActivePacksState>(
  (ref) => ActivePacksStateNotifier(),
);
