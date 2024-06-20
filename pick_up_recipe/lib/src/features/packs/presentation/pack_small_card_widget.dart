import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';

import '../../recipes/presentation/recipe_small_card_widget.dart';
import '../../themes/app_theme.dart';

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
    final theme = Theme.of(context).extension<AppTheme>() ?? AppTheme.defaultThemeData;

    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: theme.onBackgroundColor,
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
                child: Image.memory(
                  base64Decode(widget.pack.packImage),
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
