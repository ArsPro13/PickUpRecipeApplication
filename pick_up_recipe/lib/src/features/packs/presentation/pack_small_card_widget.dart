import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';

import 'package:pick_up_recipe/src/features/recipes/presentation/recipe_small_card_widget.dart';
import 'package:pick_up_recipe/src/mocked_recipes.dart';

class PackSmallCardWidget extends StatefulWidget {
  const PackSmallCardWidget({
    super.key,
    required this.pack,
  });

  final PackData pack;

  @override
  State<PackSmallCardWidget> createState() => _PackSmallCardWidgetState();
}

class _PackSmallCardWidgetState extends State<PackSmallCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 200,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: FittedBox(
                fit: BoxFit.cover,
                child: widget.pack.packImage.length > 30
                    ? Image.memory(
                        base64Decode(widget.pack.packImage),
                      )
                    : Image.memory(
                        base64Decode(baseImage),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Text(
                  widget.pack.packName,
                  style: const TextStyle(fontSize: 24),
                ),
                Text(
                  'Обжарено ${convertDate(widget.pack.packDate)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
