// Иконки набора: 109 SVG, нарисованных под этот продукт (ADR 0005).
//
// flutter_svg, а не PNG и не иконочный шрифт (ответ Q17): набор одноцветный,
// перекраска под тему нужна постоянно, а 294 растровых файла под три плотности
// пришлось бы перерисовывать при каждой правке обводки.
//
// Файлы генерируются из спрайта макетов: node scripts/extract-icons.js.
// Руками их не пишут — иначе набор в приложении разъедется с набором в дизайне.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../themes/app_icons.dart';
import '../themes/app_tokens.dart';

/// Иконка из набора.
///
/// Цвет по умолчанию наследуется от текста, как currentColor в макетах:
/// иконка внутри строки должна быть того же цвета, что и строка.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.asset, {
    super.key,
    this.size = AppSizes.icon24,
    this.color,
    this.semanticLabel,
  });

  /// Путь из [AppIcons].
  final String asset;

  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? DefaultTextStyle.of(context).style.color ?? Theme.of(context).colorScheme.onSurface;

    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}

/// Иконка по ключу из справочника с бэкенда.
///
/// Бэкенд отдаёт icon_key вроде 'step-bloom' или 'v60'. Неизвестный ключ —
/// не повод показать пустой квадрат: рисуется запасной значок (ответ на
/// вопрос 22), а сам факт молча не теряется — ключ уезжает в подпись
/// для отладки.
class AppIconByKey extends StatelessWidget {
  const AppIconByKey(
    this.iconKey, {
    super.key,
    required this.fallback,
    this.size = AppSizes.icon24,
    this.color,
    this.semanticLabel,
  });

  final String? iconKey;
  final String fallback;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppIcon(
      AppIcons.byKey(iconKey) ?? fallback,
      size: size,
      color: color,
      semanticLabel: semanticLabel ?? iconKey,
    );
  }
}
