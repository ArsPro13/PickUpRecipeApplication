// Каркас экрана: шапка, прокручиваемое тело, закреплённая нижняя панель.
//
// Ровно то, что в макетах называется .appbar + .screen + .bar. Форма
// повторяется на всех пяти экранах входа и на половине остальных, и без
// общего каркаса каждый описывал бы её заново — со своими отступами.
//
// Главное отличие от обычного Scaffold: действие живёт внизу, отделено
// линией и не уезжает вместе с содержимым. На экране входа кнопка «Войти»
// не должна прятаться под клавиатуру или уходить за край при длинной ошибке.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'app_icon.dart';

/// Экран с шапкой и нижней панелью действий.
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    this.title,
    required this.body,
    this.actions = const [],
    this.bottom = const [],
    this.showBack = true,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.s5,
      AppSpacing.s5,
      AppSpacing.s5,
      AppSpacing.s5,
    ),
  });

  final String? title;

  /// Содержимое прокручиваемой части.
  final List<Widget> body;

  /// Кнопки справа в шапке.
  final List<Widget> actions;

  /// Нижняя панель: главное действие и всё, что к нему прилагается.
  /// Пусто — панели нет вовсе.
  final List<Widget> bottom;

  final bool showBack;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              automaticallyImplyLeading: false,
              leading: showBack && context.router.canPop()
                  ? IconButton(
                      onPressed: () => context.router.maybePop(),
                      icon: const AppIcon(AppIcons.uiBack, size: AppSizes.icon24),
                      tooltip: 'Назад',
                    )
                  : null,
              actions: actions,
            ),
      body: Column(
        children: [
          Expanded(
            child: ListView(padding: padding, children: body),
          ),
          if (bottom.isNotEmpty) AppBottomBar(children: bottom),
        ],
      ),
    );
  }
}

/// Нижняя панель действий: отделена линией, поднимается над клавиатурой.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.palette.border)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s3,
            AppSpacing.s5,
            AppSpacing.s5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.s2),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Главная поверхность экрана.
///
/// Экран не должен быть стопкой одинаковых серых карточек: главный блок
/// поднят тенью, остальное тише. Здесь живёт то, ради чего экран открыли, —
/// форма, список шагов, набор полей.
class HeroSurface extends StatelessWidget {
  const HeroSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s5),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        borderRadius: AppRadius.large,
        boxShadow: [
          BoxShadow(
            color: context.palette.overlay.withValues(alpha: 0.10),
            blurRadius: AppSpacing.s3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Приглушённая поверхность: пояснение, подсказка, свёрнутый шаг.
/// Без тени и без заливки — только тонкая рамка.
class QuietSurface extends StatelessWidget {
  const QuietSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.s4,
      vertical: AppSpacing.s3,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: AppRadius.medium,
        border: Border.all(color: context.palette.border),
      ),
      child: child,
    );
  }
}

/// Строка «иконка + заголовок + пояснение».
///
/// Три таких строки на экране приветствия, по одной — под формой регистрации
/// и на подтверждении почты.
class IconRow extends StatelessWidget {
  const IconRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.iconSize = AppSizes.icon20,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(icon, size: iconSize, color: iconColor ?? context.colors.primary),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.texts.bodyMedium),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.s1),
                Text(subtitle!, style: context.texts.labelSmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Строка «Нет аккаунта? Создать» под главной кнопкой.
class SwapLine extends StatelessWidget {
  const SwapLine({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question, style: context.texts.bodyMedium?.copyWith(color: context.colors.secondary)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppSizes.tapTarget - AppSpacing.s4),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
          ),
          child: Text(action, style: context.texts.bodyMedium?.copyWith(color: context.colors.primary)),
        ),
      ],
    );
  }
}
