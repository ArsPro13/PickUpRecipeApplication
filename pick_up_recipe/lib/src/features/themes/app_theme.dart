import 'dart:ui';

import 'package:flutter/material.dart';

class AppTheme extends ThemeExtension<AppTheme> {
  static AppTheme defaultThemeData = const AppTheme(
    primaryColor: Color.fromARGB(255, 1, 1, 159),
    secondaryColor: Color.fromARGB(255, 32, 36, 45),
    outlineColor: Color.fromARGB(255, 0, 147, 42),
    onBackgroundColor: Color.fromARGB(255, 255, 255, 255),
    backgroundColor: Color.fromARGB(255, 239, 239, 243),
  );

  final Color primaryColor;
  final Color secondaryColor;
  final Color outlineColor;
  final Color onBackgroundColor;
  final Color backgroundColor;

  const AppTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.outlineColor,
    required this.onBackgroundColor,
    required this.backgroundColor,
  });

  @override
  ThemeExtension<AppTheme> copyWith(
      {Color? primaryColor,
      Color? secondaryColor,
      Color? outlineColor,
      Color? onBackgroundColor,
      Color? backgroundColor}) {
    return AppTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.backgroundColor,
      outlineColor: outlineColor ?? this.backgroundColor,
      onBackgroundColor: onBackgroundColor ?? this.backgroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  @override
  ThemeExtension<AppTheme> lerp(
    ThemeExtension<AppTheme>? other,
    double t,
  ) {
    if (other is! AppTheme?) {
      return this;
    }

    return AppTheme(
      backgroundColor: Color.lerp(backgroundColor, other?.backgroundColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other?.secondaryColor, t)!,
      outlineColor: Color.lerp(outlineColor, other?.outlineColor, t)!,
      onBackgroundColor:
          Color.lerp(onBackgroundColor, other?.onBackgroundColor, t)!,
      primaryColor: Color.lerp(primaryColor, other?.primaryColor, t)!,
    );
  }
}
