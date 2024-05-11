import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';

import '../../recipes/presentation/recipe_small_card_widget.dart';

String convertDescriptorsToLine(List<String> descriptors) {
  String ans = '';
  for (int i = 0; i < descriptors.length; ++i) {
    ans += descriptors[i];
    if (i < descriptors.length - 1) {
      ans += ', ';
    }
  }
  return ans;
}

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
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.memory(
                base64Decode(widget.pack.packImage),
                height: 120,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.pack.packName,
                  style: const TextStyle(fontSize: 24),
                ),
                Text('Produced on ${convertDate(widget.pack.packDate)}'),
                Text('Descriptors: ${convertDescriptorsToLine(widget.pack.packDescriptors)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
