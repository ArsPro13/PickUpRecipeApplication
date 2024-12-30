import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

class RecipeTag {
  @JsonKey(name: "seq_num")
  late IconData icon;

  late String name;

  late Color color;

  RecipeTag({required this.icon, required this.name, required this.color});
}
