// Полоска состояния связи над всем приложением.
//
// Появляется только когда есть что сказать: сети нет или что-то ждёт
// отправки. В обычной жизни её не видно вовсе — постоянная плашка «онлайн»
// сообщала бы то, что и так всегда так.
//
// Почему сверху и на всех экранах сразу: без сети меняется поведение каждого
// списка (показывается сохранённое), и объяснять это на каждом экране заново
// значит не объяснить нигде.

import 'package:flutter/material.dart';

import '../../core/offline/network_status.dart';
import '../../core/offline/outbox.dart';
import '../../l10n/app_localizations.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'app_icon.dart';

class OfflineBar extends StatelessWidget {
  const OfflineBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([NetworkStatus.online, Outbox.pending]),
      builder: (context, _) {
        final online = NetworkStatus.online.value;
        final waiting = Outbox.pending.value;

        if (online && waiting == 0) return child;

        return Column(
          children: [
            _Bar(online: online, waiting: waiting),
            // Отступ под шапку забрала полоска — иначе экран отсчитает его
            // второй раз и уедет вниз на высоту статус-бара.
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.online, required this.waiting});

  final bool online;
  final int waiting;

  @override
  Widget build(BuildContext context) {
    final offline = !online;

    return Material(
      color: offline
          ? context.colors.secondaryContainer
          : context.colors.primary.withValues(alpha: 0.14),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s2,
          ),
          child: Row(
            children: [
              AppIcon(
                offline ? AppIcons.uiWarning : AppIcons.uiHistory,
                size: AppSizes.icon16,
                color: offline ? context.colors.secondary : context.colors.primary,
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  offlineBarText(
                    AppLocalizations.of(context),
                    online: online,
                    waiting: waiting,
                  ),
                  style: context.texts.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Что написано на полоске.
///
/// Отдельной функцией ради теста: строк три, и каждая должна говорить правду
/// про своё состояние, а не общее «что-то не так».
///
/// Склонение «1 дело / 2 дела / 5 дел» считает ICU внутри `offlinePending`, а
/// не эта функция: у каждого языка своя таблица форм, и написанная руками
/// работала бы ровно для одного из них.
String offlineBarText(
  AppLocalizations l10n, {
  required bool online,
  required int waiting,
}) {
  if (online) return waiting == 0 ? '' : l10n.offlineSyncing;
  if (waiting == 0) return l10n.offlineCached;

  return l10n.offlinePending(waiting);
}
