// Набор компонентов, из которых собраны экраны.
//
// Один в один с классами design/mockups/app.css: .card, .btn, .tag, .metric,
// .chip, .state, .row. Пока их не было, каждый экран описывал карточку заново —
// отсюда и семнадцать разных отступов в инвентаризации.
//
// Правило то же, что в вёрстке макетов: в экранах не должно быть ни одного
// числа мимо AppSpacing/AppRadius/AppSizes.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'app_icon.dart';

/// Карточка: поднятая поверхность со скруглением.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s4),
    this.onTap,
    this.flat = false,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Плоская карточка: без тени, с тонкой обводкой.
  final bool flat;

  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? (flat ? context.palette.border : null);

    // Тень из шкалы токенов, а не Material elevation: у M3 первая ступень
    // почти не видна на светлом фоне, и стопка карточек сливалась в один лист.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.medium,
        boxShadow: flat ? null : context.shadows.level1,
      ),
      child: Material(
        color: context.colors.secondaryContainer,
        borderRadius: AppRadius.medium,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.medium,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: AppRadius.medium,
              border: border == null ? null : Border.all(color: border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Вид кнопки.
enum AppButtonKind { primary, secondary, danger }

/// Кнопка-таблетка. По умолчанию во всю ширину: так она стоит в нижней панели.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = AppButtonKind.primary,
    this.icon,
    this.block = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;

  /// Путь к иконке из [AppIcons].
  final String? icon;

  final bool block;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    final (background, foreground, side) = switch (kind) {
      AppButtonKind.primary => (
          context.colors.primary,
          context.colors.secondaryContainer,
          null,
        ),
      AppButtonKind.secondary => (
          context.colors.secondaryContainer,
          context.colors.onSurface,
          BorderSide(color: context.palette.border),
        ),
      AppButtonKind.danger => (
          context.colors.error,
          context.colors.secondaryContainer,
          null,
        ),
    };

    final content = loading
        ? SizedBox(
            height: AppSizes.icon20,
            width: AppSizes.icon20,
            child: CircularProgressIndicator(strokeWidth: AppStroke.thick, color: foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                AppIcon(icon!, size: AppSizes.icon20, color: foreground),
                const SizedBox(width: AppSpacing.s2),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.5),
        disabledForegroundColor: foreground.withValues(alpha: 0.7),
        side: side,
      ),
      child: content,
    );

    return block ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Какой показатель рецепта изображает плитка.
enum MetricKind { temperature, water, dose, grind, time }

extension MetricKindVisuals on MetricKind {
  Color color(BuildContext context) => switch (this) {
        MetricKind.temperature => context.metrics.temperature,
        MetricKind.water => context.metrics.water,
        MetricKind.dose => context.metrics.dose,
        MetricKind.grind => context.metrics.grind,
        // Время идёт тем же цветом, что и температура: в макетах они в одной
        // группе, и заводить пятый цвет ради одного показателя незачем.
        MetricKind.time => context.metrics.temperature,
      };

  String get icon => switch (this) {
        MetricKind.temperature => AppIcons.metricTemperature,
        MetricKind.water => AppIcons.metricWater,
        MetricKind.dose => AppIcons.metricDose,
        MetricKind.grind => AppIcons.metricGrind,
        MetricKind.time => AppIcons.metricTime,
      };
}

/// Плитка показателя: иконка в цветном квадрате и значение под ней.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.kind,
    required this.value,
    this.caption,
  });

  final MetricKind kind;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: AppSizes.metricTile,
          width: AppSizes.metricTile,
          decoration: BoxDecoration(
            color: kind.color(context).withValues(alpha: 0.3),
            borderRadius: AppRadius.medium,
          ),
          child: Center(
            child: AppIcon(kind.icon, size: AppSizes.metricIcon, color: context.colors.onSurface),
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(value, style: context.texts.bodySmall?.copyWith(color: context.colors.onSurface)),
        if (caption != null)
          Text(caption!, style: context.texts.labelSmall, textAlign: TextAlign.center),
      ],
    );
  }
}

/// Метка показателя: та же семантика, что у плитки, но в строку.
class MetricTag extends StatelessWidget {
  const MetricTag({super.key, required this.kind, required this.label});

  final MetricKind kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s1),
      decoration: BoxDecoration(
        color: kind.color(context).withValues(alpha: 0.3),
        borderRadius: AppRadius.rounded,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(kind.icon, size: AppSizes.icon16, color: context.colors.onSurface),
          const SizedBox(width: AppSpacing.s1),
          Text(label, style: context.texts.labelSmall?.copyWith(color: context.colors.onSurface)),
        ],
      ),
    );
  }
}

/// Выбираемая метка: дескриптор вкуса, жалоба, вариант оси оценки.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? icon;

  /// Цвет выбранного состояния. По умолчанию фирменный.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.colors.primary;
    final foreground = selected ? context.colors.secondaryContainer : context.colors.onSurface;

    return Material(
      color: selected ? accent : context.colors.secondaryContainer,
      borderRadius: AppRadius.rounded,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rounded,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rounded,
            border: Border.all(color: selected ? accent : context.palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                AppIcon(icon!, size: AppSizes.icon16, color: foreground),
                const SizedBox(width: AppSpacing.s1),
              ],
              Text(label, style: context.texts.bodySmall?.copyWith(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Строка списка: подпись слева, значение и шеврон справа.
class AppRow extends StatelessWidget {
  const AppRow({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.onTap,
    this.trailing,
    this.divider = true,
  });

  final String label;
  final String? value;
  final String? icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Черта под строкой. Последней в списке она не нужна: висящая линия
  /// читается как обрезанный список, которого нет.
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.tapTarget),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
        decoration: BoxDecoration(
          border: divider
              ? Border(bottom: BorderSide(color: context.palette.border))
              : null,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              AppIcon(icon!, size: AppSizes.icon20, color: context.colors.secondary),
              const SizedBox(width: AppSpacing.s3),
            ],
            Expanded(child: Text(label, style: context.texts.bodyMedium)),
            if (value != null)
              Text(value!, style: context.texts.bodySmall, textAlign: TextAlign.right),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null) ...[
              const SizedBox(width: AppSpacing.s2),
              AppIcon(AppIcons.uiForward, size: AppSizes.icon20, color: context.colors.secondary),
            ],
          ],
        ),
      ),
    );
  }
}

/// Пустое состояние или ошибка: иконка, заголовок, объяснение и действие.
///
/// Отдельный компонент, потому что таких экранов в наборе шесть, и все они
/// об одном: что произошло, почему это не тупик и что делать дальше.
class AppState extends StatelessWidget {
  const AppState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.primaryAction,
    this.secondaryAction,
    this.isError = false,
  });

  final String icon;
  final String title;
  final String? description;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppIcon(
              icon,
              size: AppSizes.icon48,
              color: isError ? context.colors.error : context.colors.secondary,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(title, style: context.texts.titleMedium, textAlign: TextAlign.center),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(
                description!,
                style: context.texts.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (primaryAction != null) ...[
              const SizedBox(height: AppSpacing.s6),
              primaryAction!,
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: AppSpacing.s3),
              secondaryAction!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Прямоугольник с пунктирной обводкой.
///
/// Пунктира в `Border` у Flutter нет, поэтому он рисуется вручную. Нужен
/// дважды и оба раза об одном: действие, которое создаёт новое, — «добавить
/// шаг» в конструкторе и «своё» в листе типов. Сплошная рамка там читается
/// как уже существующий элемент, а не как приглашение его завести.
class DashedBorderBox extends StatelessWidget {
  const DashedBorderBox({
    super.key,
    required this.child,
    this.color,
    this.borderRadius = AppRadius.medium,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.s3),
  });

  final Widget child;
  final Color? color;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color ?? context.palette.border,
        radius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final BorderRadius radius;

  /// Штрих и просвет подобраны так, чтобы на скруглении радиусом 12 не
  /// собиралась сплошная дуга: на коротких штрихах пунктир перестаёт читаться.
  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()..addRRect(radius.toRRect(Offset.zero & size));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppStroke.thin;

    for (final metric in outline.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        final end = math.min(start + _dash, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

/// Заголовок раздела внутри экрана.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s6, bottom: AppSpacing.s3),
      child: Row(
        children: [
          Expanded(child: Text(text, style: context.texts.bodySmall)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
