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

/// Шкала подъёма поверхностей.
///
/// Три ступени, а не одна тень: экран не должен быть стопкой одинаковых белых
/// прямоугольников. Главный блок поднят, обычный лежит, подсказка не поднята
/// вовсе. До этого в приложении была ровно одна тень, прописанная числами в
/// `HeroSurface`, — отсюда и ощущение плоского листа.
///
/// Свет падает сверху, поэтому вертикальное смещение всегда положительное.
/// Значения — из `design/tokens/tokens.css`, две тени на ступень: близкая
/// даёт контакт с поверхностью, дальняя — сам подъём.
@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({
    required this.level1,
    required this.level2,
    required this.level3,
    required this.sunkenTint,
  });

  /// Лежит на поверхности: карточка списка, строка метода.
  final List<BoxShadow> level1;

  /// Поднято: главный блок экрана, рамка заваривания.
  final List<BoxShadow> level2;

  /// Парит: нижняя панель, лист поверх экрана.
  final List<BoxShadow> level3;

  /// Вдавленность: поле ввода, дорожка шкалы.
  ///
  /// У Flutter нет внутренней тени, поэтому вдавленность рисуется градиентом
  /// от этого цвета к прозрачному по верхней кромке — см. [SunkenDecoration].
  final Color sunkenTint;

  static const AppShadows light = AppShadows(
    level1: [
      BoxShadow(color: Color(0x0F20242D), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x1420242D), blurRadius: 3, offset: Offset(0, 1)),
    ],
    level2: [
      BoxShadow(color: Color(0x1220242D), blurRadius: 6, offset: Offset(0, 2)),
      BoxShadow(color: Color(0x1420242D), blurRadius: 14, offset: Offset(0, 6)),
    ],
    level3: [
      BoxShadow(color: Color(0x1A20242D), blurRadius: 16, offset: Offset(0, 6)),
      BoxShadow(color: Color(0x1F20242D), blurRadius: 34, offset: Offset(0, 14)),
    ],
    sunkenTint: Color(0x1A20242D),
  );

  /// На тёмном фоне подъём читается не тенью, а более светлой поверхностью,
  /// поэтому тени глубже, но мягче.
  static const AppShadows dark = AppShadows(
    level1: [
      BoxShadow(color: Color(0x4D000000), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x3D000000), blurRadius: 3, offset: Offset(0, 1)),
    ],
    level2: [
      BoxShadow(color: Color(0x57000000), blurRadius: 6, offset: Offset(0, 2)),
      BoxShadow(color: Color(0x4D000000), blurRadius: 14, offset: Offset(0, 6)),
    ],
    level3: [
      BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 6)),
      BoxShadow(color: Color(0x5C000000), blurRadius: 34, offset: Offset(0, 14)),
    ],
    sunkenTint: Color(0x59000000),
  );

  @override
  AppShadows copyWith({
    List<BoxShadow>? level1,
    List<BoxShadow>? level2,
    List<BoxShadow>? level3,
    Color? sunkenTint,
  }) {
    return AppShadows(
      level1: level1 ?? this.level1,
      level2: level2 ?? this.level2,
      level3: level3 ?? this.level3,
      sunkenTint: sunkenTint ?? this.sunkenTint,
    );
  }

  @override
  AppShadows lerp(ThemeExtension<AppShadows>? other, double t) {
    if (other is! AppShadows) return this;
    return AppShadows(
      level1: BoxShadow.lerpList(level1, other.level1, t)!,
      level2: BoxShadow.lerpList(level2, other.level2, t)!,
      level3: BoxShadow.lerpList(level3, other.level3, t)!,
      sunkenTint: Color.lerp(sunkenTint, other.sunkenTint, t)!,
    );
  }
}

/// Оттенки текстуры бумаги.
///
/// Фон не идеально ровный: две едва заметные точечные сетки со сдвигом дают
/// ощущение крафтовой бумаги вместо залитого одним цветом прямоугольника.
@immutable
class PaperColors extends ThemeExtension<PaperColors> {
  const PaperColors({required this.tint, required this.tintSecond});

  final Color tint;
  final Color tintSecond;

  static const PaperColors light = PaperColors(
    tint: Color(0x0A8E6341),
    tintSecond: Color(0x068E6341),
  );

  /// В тёмной теме тёплый оттенок уходит в тёплый уголь: сам коричневый
  /// на почти чёрном выглядит грязным пятном.
  static const PaperColors dark = PaperColors(
    tint: Color(0x08FFECD6),
    tintSecond: Color(0x05FFECD6),
  );

  @override
  PaperColors copyWith({Color? tint, Color? tintSecond}) {
    return PaperColors(
      tint: tint ?? this.tint,
      tintSecond: tintSecond ?? this.tintSecond,
    );
  }

  @override
  PaperColors lerp(ThemeExtension<PaperColors>? other, double t) {
    if (other is! PaperColors) return this;
    return PaperColors(
      tint: Color.lerp(tint, other.tint, t)!,
      tintSecond: Color.lerp(tintSecond, other.tintSecond, t)!,
    );
  }
}

/// Короткий доступ к расширениям темы из виджетов.
extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;
  MetricColors get metrics => Theme.of(this).extension<MetricColors>()!;
  AppColors get palette => Theme.of(this).extension<AppColors>()!;
  AppShadows get shadows => Theme.of(this).extension<AppShadows>()!;
  PaperColors get paper => Theme.of(this).extension<PaperColors>()!;
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

ThemeData _theme(
  ColorScheme scheme,
  AppColors palette,
  AppShadows shadows,
  PaperColors paper,
) {
  final texts = _textTheme(scheme.onSurface, scheme.secondary);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    // Прозрачный, потому что фон рисует PaperBackground под всем приложением:
    // залитый цветом Scaffold закрыл бы текстуру.
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: texts,
    extensions: <ThemeExtension<dynamic>>[MetricColors.standard, palette, shadows, paper],
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
    // Без этого переключатель и ползунок берут зелёный по умолчанию M3 —
    // цвет, которого в наборе нет вовсе: зелёный у нас означает «успех».
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.secondaryContainer
            : scheme.secondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? scheme.primary : palette.border,
      ),
      trackOutlineColor: WidgetStateProperty.all(palette.border),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: palette.border,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.12),
      valueIndicatorColor: scheme.primary,
      valueIndicatorTextStyle: texts.labelSmall?.copyWith(color: scheme.secondaryContainer),
    ),
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
      AppShadows.light,
      PaperColors.light,
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
      AppShadows.dark,
      PaperColors.dark,
    );
