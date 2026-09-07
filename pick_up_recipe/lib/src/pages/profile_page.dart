// Экран «Профиль» — четвёртая вкладка.
//
// Профиль живёт на сервере, а не локально (ответ на вопрос 19): переустановка
// приложения не должна стирать кофемолку, без неё щелчки в рецептах показать
// нечем.
//
// Сверху — счёт накопленного. Считается из двух списков, которые приложение и
// так держит на руках: своих ручек под статистику нет, и заводить их ради
// четырёх цифр значило бы платить запросом за каждое открытие вкладки.
//
// Ни одна подпись здесь не обещает того, чего система не считает. Ни числа
// завариваний (таблица на сервере есть, но в неё никто не пишет), ни средней
// оценки (она лежит по запросу на рецепт и в список не приходит), ни «дней
// подряд». Цифра, которой не из чего взяться, — это не украшение пустого
// экрана, а обещание, которое некому выполнить.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/outbox.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../features/authentication/provider/authentication_state_notifier.dart';
import '../features/grinders/application/grinder_state.dart';
import '../features/packs/application/state/active_packs_state.dart';
import '../features/profile/application/profile_stats.dart';
import '../features/recipes/application/state/recipes_list_state.dart';
import '../general_widgets/app_kit.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(grinderStateProvider.notifier).loadUserGrinders();
      // Списки общие с первыми двумя вкладками: если человек пришёл оттуда,
      // цифры уже посчитаны, а если открыл профиль первым — посчитаются
      // здесь. Без сети оба списка отдают сохранённое.
      ref.read(recipesListProvider.notifier).load();
      ref.read(activePacksNotifierProvider.notifier).fetchPacks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final grinders = ref.watch(grinderStateProvider);
    final recipes = ref.watch(recipesListProvider);
    final packs = ref.watch(activePacksNotifierProvider);
    final stats = buildProfileStats(recipes.groups, packs.activePacks);
    final texts = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(texts.profileTitle)),
      // Разделы лежат на поднятых поверхностях, а не строками по голому фону:
      // без подъёма экран читался как список ссылок, в котором «Выйти» стоит
      // ровно так же, как кофемолка.
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s2,
          AppSpacing.s5,
          AppSpacing.s8,
        ),
        children: [
          SectionTitle(texts.profileStatsTitle),
          _Stats(
            stats: stats,
            // Крутилки здесь нет вовсе: без сети списки отдают сохранённое, и
            // ждать вечно человеку было бы не за чем. Пока не посчитали —
            // одна строка, а не пять нулей, которых не было.
            counting: recipes.groups.isEmpty &&
                packs.activePacks.isEmpty &&
                (recipes.isLoading || packs.isLoading),
          ),
          SectionTitle(texts.profileGrindersTitle),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Column(
              children: [
                if (grinders.userGrinders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                    child: Text(
                      texts.profileNoGrinder,
                      style: context.texts.bodySmall,
                    ),
                  )
                else
                  for (var index = 0; index < grinders.userGrinders.length; index++)
                    AppRow(
                      label: grinders.userGrinders[index].grinder.name,
                      icon: AppIcons.metricGrind,
                      value: grinders.userGrinders[index].isPrimary
                          ? texts.profileGrinderPrimary
                          : null,
                      divider: index < grinders.userGrinders.length - 1,
                      onTap: () => context.router.push(const GrinderSelectRoute()),
                    ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          AppButton(
            label: grinders.userGrinders.isEmpty
                ? texts.profileChooseGrinder
                : texts.profileChangeGrinders,
            kind: AppButtonKind.secondary,
            onPressed: () => context.router.push(const GrinderSelectRoute()),
          ),
          SectionTitle(texts.profileAccountTitle),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: AppRow(
              label: texts.profileLogout,
              icon: AppIcons.uiUser,
              divider: false,
              onTap: () async {
                // Выход стирает и очередь отправки. Если в ней что-то есть,
                // человек об этом узнаёт до, а не после: оценка, поставленная
                // в лесу, иначе просто исчезнет вместе с аккаунтом.
                if (Outbox.pending.value > 0 && !await _confirmLogout(context)) {
                  return;
                }

                await ref.read(authenticationStateNotifierProvider.notifier).logout();
                if (context.mounted) {
                  await context.router.replaceAll([const AuthWelcomeRoute()]);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Счёт накопленного: числа крупно, два факта строками.
class _Stats extends StatelessWidget {
  const _Stats({required this.stats, required this.counting});

  final ProfileStats stats;

  /// Списки ещё не приехали и сохранённого тоже нет — первый запуск.
  final bool counting;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    if (counting || stats.isEmpty) {
      return AppCard(
        child: Text(
          counting ? texts.profileCounting : texts.profileNothingYet,
          style: context.texts.bodySmall,
        ),
      );
    }

    final date = stats.firstRecipeDate;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s4),
          // Числа сеткой, а не строками: пять строк «Рецептов … 7» читаются
          // как настройки, а сетка — как счёт.
          Wrap(
            spacing: AppSpacing.s6,
            runSpacing: AppSpacing.s4,
            children: [
              _Number(
                value: stats.recipes,
                caption: texts.profileRecipes(stats.recipes),
              ),
              _Number(
                value: stats.versions,
                caption: texts.profileVersions(stats.versions),
              ),
              _Number(
                value: stats.packs,
                caption: texts.profilePacks(stats.packs),
              ),
              if (stats.countries > 0)
                _Number(
                  value: stats.countries,
                  caption: texts.profileCountries(stats.countries),
                ),
              if (stats.varieties > 0)
                _Number(
                  value: stats.varieties,
                  caption: texts.profileVarieties(stats.varieties),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          if (stats.favourite != null)
            AppRow(
              label: texts.profileFavourite,
              icon: AppIcons.uiHistory,
              value: texts.profileFavouriteValue(
                stats.favourite!.name,
                stats.favourite!.recipes,
              ),
              divider: date != null,
            ),
          if (date != null)
            AppRow(
              label: texts.profileFirstRecipe,
              icon: AppIcons.uiPack,
              value: formatRecipeDate(date),
              divider: false,
            ),
        ],
      ),
    );
  }
}

/// Одно число со словом под ним.
class _Number extends StatelessWidget {
  const _Number({required this.value, required this.caption});

  final int value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value', style: context.texts.titleLarge),
        Text(caption, style: context.texts.labelSmall),
      ],
    );
  }
}

/// Предупреждение о несделанной отправке перед выходом.
Future<bool> _confirmLogout(BuildContext context) async {
  final waiting = Outbox.pending.value;
  final texts = AppLocalizations.of(context);

  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(texts.profileLogoutTitle),
      // Склонение «1 дело ждёт / 2 дела ждут / 5 дел ждут» считает ICU:
      // рука знала два варианта и на двух делах говорила «2 дел ждут».
      content: Text(texts.profileLogoutPending(waiting)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(texts.profileStay),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(texts.profileLogout),
        ),
      ],
    ),
  );

  return leave ?? false;
}
