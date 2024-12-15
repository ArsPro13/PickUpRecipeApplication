import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pick_up_recipe/src/features/packs/application/state/active_packs_state.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/packs/presentation/pack_small_card_widget.dart';

class ActivePacksWidget extends ConsumerStatefulWidget {
  const ActivePacksWidget({super.key});

  @override
  ConsumerState<ActivePacksWidget> createState() => _LatestRecipesWidgetState();
}

class _LatestRecipesWidgetState extends ConsumerState<ActivePacksWidget> {
  List<PackData> activePacks = [];

  @override
  void initState() {
    super.initState();
    Future(() => fetchPacks());
  }

  Future<void> fetchPacks() async {
    await ref.read(activePacksNotifierProvider.notifier).fetchPacks();
  }

  @override
  Widget build(BuildContext context) {
    final activePacks = ref.watch(activePacksNotifierProvider).activePacks;
    final isLoading = ref.watch(activePacksNotifierProvider).isLoading;

    final reversedPacks = activePacks.reversed.toList();

    return isLoading
        ? SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 70),
              child: SpinKitWaveSpinner(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          )
        : SliverList.builder(
            itemCount: reversedPacks.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: PackSmallCardWidget(pack: reversedPacks[index]),
              );
            },
          );
  }
}
