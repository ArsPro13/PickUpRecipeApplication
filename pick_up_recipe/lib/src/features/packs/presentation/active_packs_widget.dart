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
  bool loaded = false;
  List<PackData> activePacks = [];

  @override
  void initState() {
    loaded = false;
    super.initState();
    fetchPacks();
  }

  Future<void> fetchPacks() async {
    setState(() {
      loaded = false;
    });

    ref.read(activePacksNotifierProvider.notifier).fetchPacks();

    setState(() {
      loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activePacks = ref.watch(activePacksNotifierProvider).activePacks;
    return loaded
        ? SliverList.builder(
            itemCount: activePacks.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: PackSmallCardWidget(pack: activePacks[index]),
              );
            },
          )
        : SliverToBoxAdapter(
            child: SpinKitWaveSpinner(
              color: Theme.of(context).colorScheme.surface,
            ),
          );
  }
}
