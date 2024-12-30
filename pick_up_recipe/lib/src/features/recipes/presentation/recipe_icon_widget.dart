import 'package:flutter/material.dart';

class RecipeIconWidget extends StatelessWidget {
  const RecipeIconWidget({
    super.key,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: color.withValues(alpha: 0.3),
          ),
          child: Icon(
            icon,
            size: 30,
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Text(value),
      ],
    );
  }
}
