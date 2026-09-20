// Кнопка кофемолки в шапке экрана.
//
// Показывает название основной кофемолки, а не значок с многоточием: человек
// должен видеть, в чьих делениях считаются щелчки, не нажимая ничего.
//
// Стоит на трёх экранах, и это не украшение. Помол — единственное число
// рецепта, которое зависит не от рецепта, а от мельницы читающего: одни и те
// же 800 микрон это 22 щелчка на Comandante и 14 на Timemore. Пока кнопки не
// было на заваривании и в конструкторе, ответ на вопрос «а по какой шкале мне
// сейчас показывают?» лежал через вкладку профиля — то есть посреди пролива
// был недостижим.
//
// Узкий вид (`compact`) для шапок, где уже есть заголовок и другие действия:
// там от названия остаётся начало, а целиком оно доступно долгим нажатием.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../features/grinders/application/grinder_state.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'app_icon.dart';

class GrinderButton extends ConsumerWidget {
  const GrinderButton({super.key, this.compact = false});

  /// Узкая шапка: название обрезается сильнее, отступы меньше.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texts = AppLocalizations.of(context);
    final primary = ref.watch(grinderStateProvider).primary;
    final name = primary?.name ?? texts.profileChooseGrinder;

    return Tooltip(
      message: primary == null ? texts.profileChooseGrinder : primary.name,
      child: Semantics(
        button: true,
        label: texts.packsChangeGrinder,
        child: InkWell(
          onTap: () => context.router.push(const GrinderSelectRoute()),
          borderRadius: AppRadius.rounded,
          child: Container(
            constraints: const BoxConstraints(
                minHeight: AppSizes.tapTarget - AppSpacing.s2),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.s2 : AppSpacing.s3,
              vertical: AppSpacing.s2,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.rounded,
              border: Border.all(color: context.palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  AppIcons.metricGrind,
                  size: AppSizes.icon20,
                  color: context.metrics.grind,
                ),
                const SizedBox(width: AppSpacing.s2),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 92 : 140),
                  child: Text(
                    name,
                    style: context.texts.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
