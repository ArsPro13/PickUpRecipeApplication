// Нижняя навигация на экранах вне вкладок.
//
// Вкладочный каркас живёт только в корне, поэтому на открытых поверх него
// экранах — рецепт, заваривание, оценка — панель исчезала, и человек
// оказывался в ветке без выхода: единственная дорога назад — стрелка в
// шапке, по одному шагу за раз. Эта панель повторяет корневую и уводит
// прямо на нужную вкладку, схлопывая стопку.
//
// Ничего не подсвечено намеренно: мы не внутри вкладки, и зажжённый значок
// «Пачки» на экране заваривания врал бы о том, где мы находимся.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../pages/root_page.dart';
import 'app_icon.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = RootScreen.tabs(AppLocalizations.of(context));

    return Container(
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        border: Border(top: BorderSide(color: context.palette.border)),
        boxShadow: context.shadows.level3,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.tapTarget + AppSpacing.s4,
          child: Row(
            children: [
              for (final tab in tabs)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: tab.label,
                    child: InkWell(
                      // navigate, а не push: возвращаться на вкладку стопкой
                      // из пяти экранов незачем — она и есть начало пути.
                      onTap: () => context.router.navigate(tab.route),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(
                            tab.icon,
                            size: AppSizes.navIcon,
                            color: context.colors.secondary,
                          ),
                          const SizedBox(height: AppSpacing.s1),
                          Text(
                            tab.label,
                            style: context.texts.labelSmall?.copyWith(
                              color: context.colors.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
