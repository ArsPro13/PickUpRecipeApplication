import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/core/library_revision.dart';
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
  (ref) {
    final notifier = ActivePacksStateNotifier();

    // Тот же способ, что у списка рецептов: новая пачка или новое заваривание
    // поднимают `LibraryRevision`, и полка перечитывает себя сама.
    ref.listen<int>(libraryRevisionProvider, (_, __) => notifier.fetchPacks());

    return notifier;
  },
);
