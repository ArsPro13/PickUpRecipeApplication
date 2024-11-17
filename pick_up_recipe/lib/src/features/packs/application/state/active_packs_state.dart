import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/src/features/packs/application/state/active_packs_state_notifier.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';

class ActivePacksState {
  final List<PackData> activePacks;

  const ActivePacksState({this.activePacks = const []});

  ActivePacksState copyWith({List<PackData>? activePacks}) {
    return ActivePacksState(
      activePacks: activePacks ?? this.activePacks,
    );
  }

  List<Object?> get props => [activePacks];
}

final activePacksNotifierProvider =
StateNotifierProvider<ActivePacksStateNotifier, ActivePacksState>(
      (ref) => ActivePacksStateNotifier(),
);