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

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
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
          const SectionTitle('Что накопилось'),
          _Stats(
            stats: stats,
            // Крутилки здесь нет вовсе: без сети списки отдают сохранённое, и
            // ждать вечно человеку было бы не за чем. Пока не посчитали —
            // одна строка, а не пять нулей, которых не было.
            counting: recipes.groups.isEmpty &&
                packs.activePacks.isEmpty &&
                (recipes.isLoading || packs.isLoading),
          ),
          const SectionTitle('Мои кофемолки'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Column(
              children: [
                if (grinders.userGrinders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                    child: Text(
                      'Кофемолка не выбрана. Без неё рецепт показывает крупность словами, '
                      'а не щелчками вашей кофемолки.',
                      style: context.texts.bodySmall,
                    ),
                  )
                else
                  for (var index = 0; index < grinders.userGrinders.length; index++)
                    AppRow(
                      label: grinders.userGrinders[index].grinder.name,
                      icon: AppIcons.metricGrind,
                      value: grinders.userGrinders[index].isPrimary ? 'основная' : null,
                      divider: index < grinders.userGrinders.length - 1,
                      onTap: () => context.router.push(const GrinderSelectRoute()),
                    ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          AppButton(
            label: grinders.userGrinders.isEmpty ? 'Выбрать кофемолку' : 'Изменить набор',
            kind: AppButtonKind.secondary,
            onPressed: () => context.router.push(const GrinderSelectRoute()),
          ),
          const SectionTitle('Аккаунт'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: AppRow(
              label: 'Выйти',
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
    if (counting || stats.isEmpty) {
      return AppCard(
        child: Text(
          counting
              ? 'Считаем ваши пачки и рецепты…'
              : 'Пока считать нечего. Отсканируйте пачку и заварите по рецепту — '
                  'здесь появятся ваши цифры.',
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
                caption: countWord(stats.recipes, 'рецепт', 'рецепта', 'рецептов'),
              ),
              _Number(
                value: stats.versions,
                caption: countWord(stats.versions, 'версия', 'версии', 'версий'),
              ),
              _Number(
                value: stats.packs,
                caption: countWord(stats.packs, 'пачка', 'пачки', 'пачек'),
              ),
              if (stats.countries > 0)
                _Number(
                  value: stats.countries,
                  caption: countWord(stats.countries, 'страна', 'страны', 'стран'),
                ),
              if (stats.varieties > 0)
                _Number(
                  value: stats.varieties,
                  caption: countWord(stats.varieties, 'сорт', 'сорта', 'сортов'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          if (stats.favourite != null)
            AppRow(
              label: 'Чаще всего',
              icon: AppIcons.uiHistory,
              value: '${stats.favourite!.name} · '
                  '${stats.favourite!.recipes} '
                  '${countWord(stats.favourite!.recipes, 'рецепт', 'рецепта', 'рецептов')}',
              divider: date != null,
            ),
          if (date != null)
            AppRow(
              label: 'Первый рецепт',
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

  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Выйти, не отправив?'),
      content: Text(
        'Связи не было, и $waiting ${waiting == 1 ? 'дело ждёт' : 'дел ждут'} отправки — '
        'оценки и правки рецептов. Выход сотрёт их вместе с аккаунтом.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Остаться'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Выйти'),
        ),
      ],
    ),
  );

  return leave ?? false;
}
