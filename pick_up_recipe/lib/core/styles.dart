import 'package:flutter/material.dart';

ButtonStyle secondaryButtonStyle(BuildContext context) {
  return ButtonStyle(
    backgroundColor: WidgetStateProperty.all<Color>(
        Theme.of(context).colorScheme.secondaryContainer),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .secondary
              .withOpacity(0.1),
        ),
      ),
    ),
  );
}