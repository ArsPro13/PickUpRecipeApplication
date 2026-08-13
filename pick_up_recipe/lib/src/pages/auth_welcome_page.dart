// Экран приветствия — первое, что видит человек без аккаунта.
//
// Гостя нет (ответ на вопрос 9), поэтому экран не уговаривает, а объясняет,
// что даёт аккаунт. Три строки — не преимущества, а факты о том, что иначе
// потеряется: обещание должно быть проверяемым.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../routing/app_router.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class AuthWelcomePage extends StatelessWidget {
  const AuthWelcomePage({super.key});

  /// Что хранит аккаунт. Порядок по убыванию того, что больнее потерять.
  static const List<({String icon, String title, String subtitle})> _keeps = [
    (
      icon: AppIcons.uiHistory,
      title: 'Ваши рецепты',
      subtitle: 'версии переживают смену телефона',
    ),
    (
      icon: AppIcons.metricGrind,
      title: 'Кофемолку',
      subtitle: 'помол пересчитывается в ваши щелчки',
    ),
    (
      icon: AppIcons.uiPack,
      title: 'Историю пачек',
      subtitle: 'что и как заваривали полгода назад',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      body: [
        const SizedBox(height: AppSpacing.s8),
        Column(
          children: [
            AppIcon(
              AppIcons.methodV60,
              size: AppSizes.icon72,
              color: context.colors.primary,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text('PickUpRecipe', style: context.texts.titleLarge),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Рецепт от того, кто жарил это зерно',
              style: context.texts.bodyMedium?.copyWith(color: context.colors.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s6),
        Text('Аккаунт хранит', style: context.texts.bodySmall),
        const SizedBox(height: AppSpacing.s2),
        HeroSurface(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          child: Column(
            children: [
              for (var i = 0; i < _keeps.length; i++) ...[
                if (i > 0) Divider(height: 1, color: context.palette.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                  child: IconRow(
                    icon: _keeps[i].icon,
                    title: _keeps[i].title,
                    subtitle: _keeps[i].subtitle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
      bottom: [
        AppButton(
          label: 'Создать аккаунт',
          onPressed: () => context.router.push(const AuthRegisterRoute()),
        ),
        AppButton(
          label: 'Войти',
          kind: AppButtonKind.secondary,
          onPressed: () => context.router.push(AuthLoginRoute()),
        ),
      ],
    );
  }
}
