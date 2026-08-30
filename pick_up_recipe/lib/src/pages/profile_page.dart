// Экран «Профиль» — четвёртая вкладка.
//
// Профиль живёт на сервере, а не локально (ответ на вопрос 19): переустановка
// приложения не должна стирать кофемолку, без неё щелчки в рецептах показать
// нечем.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/outbox.dart';
import '../../routing/app_router.dart';
import '../features/authentication/provider/authentication_state_notifier.dart';
import '../features/grinders/application/grinder_state.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final grinders = ref.watch(grinderStateProvider);

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
