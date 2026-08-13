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

import '../../routing/app_router.dart';
import '../general_widgets/app_icon.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  /// Вкладки в порядке показа.
  static const List<({PageRouteInfo<dynamic> route, String label, String icon})> tabs = [
    (route: PacksRoute(), label: 'Пачки', icon: AppIcons.uiPack),
    (route: RecipesRoute(), label: 'Рецепты', icon: AppIcons.uiHistory),
    (route: ScanRoute(), label: 'Сканировать', icon: AppIcons.uiScan),
    (route: ProfileRoute(), label: 'Профиль', icon: AppIcons.uiUser),
  ];

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: tabs.map((tab) => tab.route).toList(),
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
              for (var index = 0; index < RootScreen.tabs.length; index++)
                Expanded(
                  child: _TabItem(
                    tab: RootScreen.tabs[index],
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
