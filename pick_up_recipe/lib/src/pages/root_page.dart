// Корень приложения: четыре вкладки.
//
// Пачки · Рецепты · Сканировать · Профиль. Первая вкладка — «Мои пачки»:
// продукт устроен как «взял пачку → заварил», и открывать его чем-то другим
// значит просить человека сначала найти нужное.
//
// Раньше вкладок было две — «Main» и «Add pack», и вторая сразу открывала
// камеру. Камера прячет два пути из трёх: ручной ввод кода и «нет кода»
// (ответ на вопрос 32), поэтому вкладка «Сканировать» ведёт на экран 01,
// а камера открывается уже оттуда.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../general_widgets/app_icon.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  /// Вкладки в порядке показа.
  ///
  /// Список собирается по локали, а не лежит константой: подписи вкладок —
  /// такой же перевод, как всё остальное, и знать их до появления контекста
  /// неоткуда. Маршруты сравниваются по имени, поэтому пересобранный список
  /// для вкладочного каркаса — тот же самый.
  static List<({PageRouteInfo<dynamic> route, String label, String icon})> tabs(
    AppLocalizations texts,
  ) {
    return [
      (route: const PacksRoute(), label: texts.tabPacks, icon: AppIcons.uiPack),
      (route: const RecipesRoute(), label: texts.tabRecipes, icon: AppIcons.uiHistory),
      (route: const ScanRoute(), label: texts.tabScan, icon: AppIcons.uiScan),
      (route: const ProfileRoute(), label: texts.tabProfile, icon: AppIcons.uiUser),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: tabs(AppLocalizations.of(context)).map((tab) => tab.route).toList(),
      bottomNavigationBuilder: (_, tabsRouter) {
        return _TabBar(tabsRouter: tabsRouter);
      },
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tabsRouter});

  final TabsRouter tabsRouter;

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
              for (var index = 0; index < tabs.length; index++)
                Expanded(
                  child: _TabItem(
                    tab: tabs[index],
                    selected: tabsRouter.activeIndex == index,
                    onTap: () => tabsRouter.setActiveIndex(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.tab, required this.selected, required this.onTap});

  final ({PageRouteInfo<dynamic> route, String label, String icon}) tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.primary : context.colors.secondary;

    return Semantics(
      selected: selected,
      button: true,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(tab.icon, size: AppSizes.navIcon, color: color),
            const SizedBox(height: AppSpacing.s1),
            Text(
              tab.label,
              style: context.texts.labelSmall?.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
