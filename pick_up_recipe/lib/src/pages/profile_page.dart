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
import '../features/settings/application/locale_state.dart';
import '../features/recipes/application/state/recipes_list_state.dart';
import '../general_widgets/app_icon.dart';
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
    final chosen = ref.watch(localeProvider);

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
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                    child: Text(
                      texts.profileNoGrinder,
                      style: context.texts.bodySmall,
                    ),
                  )
                else
                  for (var index = 0;
                      index < grinders.userGrinders.length;
                      index++)
                    AppRow(
                      label: grinders.userGrinders[index].grinder.name,
                      icon: AppIcons.metricGrind,
                      value: grinders.userGrinders[index].isPrimary
                          ? texts.profileGrinderPrimary
                          : null,
                      divider: index < grinders.userGrinders.length - 1,
                      onTap: () =>
                          context.router.push(const GrinderSelectRoute()),
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
          SectionTitle(texts.profileAppTitle),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: AppRow(
              label: texts.profileLanguage,
              icon: AppIcons.uiSettings,
              // Название выбранного языка — на нём самом. «Итальянский»
              // по-русски не поможет тому, кто ищет Italiano, а именно он
              // сюда и приходит.
              value: chosen == null
                  ? texts.profileLanguageSystem
                  : appLocales
                      .firstWhere((item) =>
                          item.locale.languageCode == chosen.languageCode)
                      .label,
              divider: false,
              onTap: () => _chooseLanguage(context, ref, chosen),
            ),
          ),
          SectionTitle(texts.profileAccountTitle),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: AppRow(
              label: texts.profileLogout,
              icon: AppIcons.uiUser,
              divider: false,
              onTap: () async {
                // Выход спрашивает ВСЕГДА, а не только когда в очереди что-то
                // лежит. Строка стоит последней в списке настроек, под сменой
                // языка, — то есть там, куда попадают, листая экран, и промах
                // по ней стоит дороже всего остального на экране вместе
                // взятого: возвращаться придётся через почту и пароль.
                //
                // Текст вопроса при этом разный. Если в очереди что-то есть,
                // человек об этом узнаёт до, а не после: оценка, поставленная
                // в лесу, иначе просто исчезнет вместе с аккаунтом.
                if (!await _confirmLogout(context)) return;

                await ref
                    .read(authenticationStateNotifierProvider.notifier)
                    .logout();
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

/// Выбор языка листом снизу.
///
/// Листом, а не отдельным экраном: вариантов четыре, и уводить ради них с
/// профиля значило бы обставить переключение языка навигацией. Выбор
/// применяется сразу — приложение перерисовывается под рукой, и это самый
/// понятный ответ на вопрос «а что изменится».
Future<void> _chooseLanguage(
    BuildContext context, WidgetRef ref, Locale? chosen) async {
  final texts = AppLocalizations.of(context);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.secondaryContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s5,
              AppSpacing.s5,
              AppSpacing.s5,
              AppSpacing.s2,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child:
                  Text(texts.profileLanguage, style: context.texts.titleMedium),
            ),
          ),
          AppRow(
            label: texts.profileLanguageSystem,
            icon: AppIcons.uiSettings,
            trailing: _LanguageMark(chosen: chosen == null),
            onTap: () {
              ref.read(localeProvider.notifier).choose(null);
              Navigator.of(sheetContext).pop();
            },
          ),
          for (var index = 0; index < appLocales.length; index++)
            AppRow(
              label: appLocales[index].label,
              icon: AppIcons.uiInfo,
              divider: index < appLocales.length - 1,
              trailing: _LanguageMark(
                chosen: chosen?.languageCode ==
                    appLocales[index].locale.languageCode,
              ),
              onTap: () {
                ref
                    .read(localeProvider.notifier)
                    .choose(appLocales[index].locale);
                Navigator.of(sheetContext).pop();
              },
            ),
          const SizedBox(height: AppSpacing.s4),
        ],
      ),
    ),
  );
}

/// Галочка у выбранного языка.
class _LanguageMark extends StatelessWidget {
  const _LanguageMark({required this.chosen});

  final bool chosen;

  @override
  Widget build(BuildContext context) {
    if (!chosen) return const SizedBox(width: AppSizes.icon20);

    return AppIcon(
      AppIcons.uiCheck,
      size: AppSizes.icon20,
      color: context.colors.primary,
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
              value: formatRecipeDate(AppLocalizations.of(context), date),
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

/// Вопрос перед выходом. true — уходим.
///
/// Заголовок и текст зависят от очереди: «выйти, не отправив?» — это про
/// потерю работы, и говорить так, когда терять нечего, значит пугать зря.
Future<bool> _confirmLogout(BuildContext context) async {
  final waiting = Outbox.pending.value;
  final texts = AppLocalizations.of(context);

  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(waiting > 0
          ? texts.profileLogoutTitle
          : texts.profileLogoutConfirmTitle),
      // Склонение «1 дело ждёт / 2 дела ждут / 5 дел ждут» считает ICU:
      // рука знала два варианта и на двух делах говорила «2 дел ждут».
      content: Text(waiting > 0
          ? texts.profileLogoutPending(waiting)
          : texts.profileLogoutConfirm),
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
