// Тема приложения, собранная из design/tokens/tokens.css.
//
// До этого ThemeData состоял из одного ColorScheme на шесть цветов, а
// типографика, отступы и скругления были прописаны прямо в виджетах: десять
// размеров шрифта, семнадцать отступов, шесть скруглений.
//
// Фирменный цвет коричневый в ОБЕИХ темах, успех — зелёный в обеих (решение
// владельца по вопросу D1). Раньше в тёмной теме и то и другое было синим.
// В тёмной берётся светлый оттенок той же гаммы: сам #8E6341 на фоне #191617
// даёт контраст 3.4:1 — хватает крупным элементам, но не тексту; #C89264
// даёт 6.6:1.

import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Цвета показателей рецепта.
///
/// В ColorScheme им места нет: это не роли Material, а смысловые цвета
/// предметной области. Раньше те же четыре значения повторялись хардкодом
/// в трёх файлах.
@immutable
class MetricColors extends ThemeExtension<MetricColors> {
  const MetricColors({
    required this.temperature,
    required this.water,
    required this.dose,
    required this.grind,
  });

  final Color temperature;
  final Color water;
  final Color dose;
  final Color grind;

  /// Одинаковы в обеих темах: это смысловые цвета, а не оформление.
  static const MetricColors standard = MetricColors(
    temperature: Color(0xFFFF9800),
    water: Color(0xFF448AFF),
    dose: Color(0xFF9A7E65),
    grind: Color(0xFFCDA6FF),
  );

  @override
  MetricColors copyWith({
    Color? temperature,
    Color? water,
    Color? dose,
    Color? grind,
  }) {
    return MetricColors(
      temperature: temperature ?? this.temperature,
      water: water ?? this.water,
      dose: dose ?? this.dose,
      grind: grind ?? this.grind,
    );
  }

  @override
  MetricColors lerp(ThemeExtension<MetricColors>? other, double t) {
    if (other is! MetricColors) return this;
    return MetricColors(
      temperature: Color.lerp(temperature, other.temperature, t)!,
      water: Color.lerp(water, other.water, t)!,
      dose: Color.lerp(dose, other.dose, t)!,
      grind: Color.lerp(grind, other.grind, t)!,
    );
  }
}

/// Цвета, которых нет в ColorScheme, но которые нужны экранам.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.border,
    required this.overlay,
  });

  /// «Шаг завершён». Зелёный в обеих темах — это состояние, а не оформление.
  final Color success;

  /// Разделители и тонкие обводки.
  final Color border;

  /// Затемнение под модальными листами.
  final Color overlay;

  static const AppColors light = AppColors(
    success: Color(0xFF00932A),
    border: Color(0x1A20242D),
    overlay: Color(0x4D20242D),
  );

  static const AppColors dark = AppColors(
    success: Color(0xFF3FBF63),
    border: Color(0x1AA6ABAB),
    overlay: Color(0x4DA6ABAB),
  );

  @override
  AppColors copyWith({Color? success, Color? border, Color? overlay}) {
    return AppColors(
      success: success ?? this.success,
      border: border ?? this.border,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      border: Color.lerp(border, other.border, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
    );
  }
}

/// Короткий доступ к расширениям темы из виджетов.
extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;
  MetricColors get metrics => Theme.of(this).extension<MetricColors>()!;
  AppColors get palette => Theme.of(this).extension<AppColors>()!;
}

/// Типографика. Семь ступеней вместо десяти захардкоженных размеров.
TextTheme _textTheme(Color primary, Color secondary) {
  return TextTheme(
    displayLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2, color: primary),
    titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25, color: primary),
    titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, height: 1.3, color: primary),
    bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, height: 1.4, color: primary),
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.45, color: primary),
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4, color: secondary),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.35, color: secondary),
  );
}

ThemeData _theme(ColorScheme scheme, AppColors palette) {
  final texts = _textTheme(scheme.onSurface, scheme.secondary);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: texts,
    extensions: <ThemeExtension<dynamic>>[MetricColors.standard, palette],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: texts.titleMedium,
      foregroundColor: scheme.onSurface,
    ),
    cardTheme: CardThemeData(
      color: scheme.secondaryContainer,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.secondaryContainer,
        minimumSize: const Size(0, AppSizes.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6, vertical: AppSpacing.s3),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rounded),
        textStyle: texts.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        minimumSize: const Size(0, AppSizes.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6, vertical: AppSpacing.s3),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rounded),
        side: BorderSide(color: palette.border, width: AppStroke.thin),
        textStyle: texts.bodyMedium,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: texts.bodyMedium,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.secondaryContainer,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      hintStyle: texts.bodyMedium?.copyWith(color: scheme.secondary),
      border: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: scheme.primary, width: AppStroke.thick),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: scheme.error, width: AppStroke.thick),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: scheme.secondaryContainer,
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.secondary,
      selectedLabelStyle: texts.labelSmall,
      unselectedLabelStyle: texts.labelSmall,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.secondaryContainer,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
      ),
      showDragHandle: true,
    ),
    dividerTheme: DividerThemeData(color: palette.border, thickness: AppStroke.thin, space: 0),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.secondaryContainer,
      side: BorderSide(color: palette.border),
      labelStyle: texts.labelSmall,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.rounded),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.secondaryContainer,
      contentTextStyle: texts.bodyMedium,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: palette.border,
    ),
  );
}

ThemeData get lightTheme => _theme(
      const ColorScheme.light(
        primary: Color(0xFF8E6341),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF20242D),
        outline: Color(0xFF00932A),
        onSurface: Color(0xFF000000),
        surface: Color(0xFFEFEFF3),
        secondaryContainer: Color(0xFFFFFFFF),
        error: Color(0xFFF44336),
      ),
      AppColors.light,
    );

ThemeData get darkTheme => _theme(
      const ColorScheme.dark(
        primary: Color(0xFFC89264),
        onPrimary: Color(0xFF191617),
        secondary: Color(0xFFA6ABAB),
        outline: Color(0xFF3FBF63),
        onSurface: Color(0xFFFFFFFF),
        surface: Color(0xFF191617),
        secondaryContainer: Color(0xFF222020),
        error: Color(0xFFF44336),
      ),
      AppColors.dark,
    );
