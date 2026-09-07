// Экран приветствия — первое, что видит человек без аккаунта.
//
// Гостя нет (ответ на вопрос 9), поэтому экран не уговаривает, а объясняет,
// что даёт аккаунт. Три строки — не преимущества, а факты о том, что иначе
// потеряется: обещание должно быть проверяемым.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    // Что хранит аккаунт. Порядок по убыванию того, что больнее потерять.
    final keeps = <({String icon, String title, String subtitle})>[
      (
        icon: AppIcons.uiHistory,
        title: texts.welcomeKeepsRecipes,
        subtitle: texts.welcomeKeepsRecipesNote,
      ),
      (
        icon: AppIcons.metricGrind,
        title: texts.welcomeKeepsGrinder,
        subtitle: texts.welcomeKeepsGrinderNote,
      ),
      (
        icon: AppIcons.uiPack,
        title: texts.welcomeKeepsPacks,
        subtitle: texts.welcomeKeepsPacksNote,
      ),
    ];

    return AppScreen(
      showNav: false,
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
              texts.welcomeTagline,
              style: context.texts.bodyMedium?.copyWith(color: context.colors.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s6),
        Text(texts.welcomeKeepsTitle, style: context.texts.bodySmall),
        const SizedBox(height: AppSpacing.s2),
        HeroSurface(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          child: Column(
            children: [
              for (var i = 0; i < keeps.length; i++) ...[
                if (i > 0) Divider(height: 1, color: context.palette.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                  child: IconRow(
                    icon: keeps[i].icon,
                    title: keeps[i].title,
                    subtitle: keeps[i].subtitle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
      bottom: [
        AppButton(
          label: texts.authCreateAccount,
          onPressed: () => context.router.push(const AuthRegisterRoute()),
        ),
        AppButton(
          label: texts.authSignIn,
          kind: AppButtonKind.secondary,
          onPressed: () => context.router.push(AuthLoginRoute()),
        ),
      ],
    );
  }
}
