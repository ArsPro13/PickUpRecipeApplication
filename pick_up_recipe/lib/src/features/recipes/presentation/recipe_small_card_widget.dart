import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/main.dart';
import 'package:pick_up_recipe/src/features/packs/data/DAO/active_packs_dao.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/presentation/recipe_tags_widget.dart';

import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_tag_model.dart';
import 'package:pick_up_recipe/src/mocked_recipes.dart';

String convertDate(String date) {
  return '${date.substring(8, 10)}.${date.substring(5, 7)}.${date.substring(0, 4)}';
}

Widget getTags(RecipeData recipe) {
  List<RecipeTag> tags = [];

  tags.add(RecipeTag(
      icon: Icons.coffee_maker_outlined,
      name: recipe.device.toString(),
      color: Colors.orange));
  tags.add(RecipeTag(
      icon: Icons.scale_outlined,
      name: '${recipe.load.toString()} g',
      color: const Color.fromARGB(255, 154, 126, 101)));
  tags.add(RecipeTag(
      icon: Icons.water_drop_outlined,
      name: '${recipe.water.toString()} ml',
      color: Colors.blueAccent));
  tags.add(RecipeTag(
      icon: Icons.blur_on_sharp,
      name: '${recipe.grindStep.toString()} click',
      color: const Color.fromARGB(255, 205, 166, 255)));

  return RecipeTagsWidget(tags: tags);
}

class RecipeSmallCardWidget extends StatefulWidget {
  const RecipeSmallCardWidget({
    super.key,
    required this.recipe,
  });

  final RecipeData recipe;

  @override
  State<RecipeSmallCardWidget> createState() => RecipeSmallCardWidgetState();
}

class RecipeSmallCardWidgetState extends State<RecipeSmallCardWidget> with AutomaticKeepAliveClientMixin {
  final getIt = GetIt.instance;
  PackData? _pack;
  bool isLoadingPack = false;

  @override
  void initState() {
    Future(() => loadPack());
    super.initState();
  }

  void loadPack() async {
    final ActivePacksDAO dao = getIt.get<ActivePacksDAO>();
    setState(() {
      isLoadingPack = true;
      _pack = null;
    });
    final pack = await dao.getPackById(widget.recipe.packId);

    logger.i('loaded pack: id: ${pack?.packId}, name: ${pack?.packName}');

    if (mounted) {
      setState(() {
        isLoadingPack = false;
        _pack = pack;
      });
    }
  }

  void _onCardTap() {
    context.router.push(BrewRoute(recipe: widget.recipe, pack: _pack));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: _onCardTap,
      child: Container(
        height: 250,
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: isLoadingPack
            ? SpinKitWaveSpinner(
                color: Theme.of(context).colorScheme.surface,
              )
            : Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 2 / 5,
                  height: 260,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: Image.memory(
                        base64Decode(_pack?.packImage ?? baseImage),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Text(
                            _pack?.packName ?? 'Coffee',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 21),
                          ),
                        ),
                        Text('Brewed ${convertDate(widget.recipe.date)}'),
                        getTags(widget.recipe),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
