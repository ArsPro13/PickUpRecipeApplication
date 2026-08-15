// Конфликт жалоб: «кисло и горько сразу» (макеты S15/S16).
//
// Это не ошибка ввода — человек действительно так чувствует. Но жалобы тянут
// параметры в разные стороны, и двигать цифры сейчас значит лечить наугад.
// Ответ правил в этом случае — про технику: тексты проверок приходят с бэка
// и зависят от группы метода («ровность таблетки» у эспрессо, «ровность
// шапки» у V60).
//
// Отдельной страницы «что изменилось» больше нет: если человек всё же хочет
// цифры, вторая кнопка открывает конструктор с уже применённой поправкой.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/app_router.dart';
import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/domain/models/correction_model.dart';
import '../features/recipes/domain/models/recipe_data_model.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class RatingConflictPage extends ConsumerWidget {
  const RatingConflictPage({
    super.key,
    required this.recipe,
    required this.summary,
    required this.correction,
    this.pack,
  });

  final RecipeData recipe;
  final PackData? pack;

  /// Жалоба словами — то, что человек сказал картой вкуса.
  final String summary;

  /// Ответ правил: конфликты с проверками и, на всякий случай, поправка.
  final RecipeCorrection correction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScreen(
      title: 'Что проверить',
      body: [
        Text(summary, style: context.texts.bodySmall),
        const SizedBox(height: AppSpacing.s4),
        for (final conflict in correction.conflicts) ...[
          _ConflictPlate(conflict: conflict),
          const SizedBox(height: AppSpacing.s4),
          for (final check in conflict.checks) ...[
            _CheckRow(check: check),
            const SizedBox(height: AppSpacing.s2),
          ],
          const SizedBox(height: AppSpacing.s2),
        ],
      ],
      bottom: [
        // Главный выход — перезаварить, следя за техникой: prep-состояние
        // экрана заваривания снова попросит смолоть.
        AppButton(
          label: 'Заварить так же ещё раз',
          icon: AppIcons.uiPlay,
          onPressed: () => context.router.replace(
            BrewRoute(recipe: recipe, pack: pack),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        AppButton(
          label: 'Всё равно открыть конструктор',
          kind: AppButtonKind.secondary,
          onPressed: () => context.router.replace(
            RecipeBuilderRoute(
              recipe: correction.recipe ?? recipe,
              original: correction.recipe == null ? null : recipe,
              correctionLabel: correction.recipe == null ? null : summary,
              pack: pack,
            ),
          ),
        ),
      ],
    );
  }
}

/// Жёлтая плашка конфликта: почему цифры сейчас — не ответ.
class _ConflictPlate extends StatelessWidget {
  const _ConflictPlate({required this.conflict});

  final CorrectionConflict conflict;

  @override
  Widget build(BuildContext context) {
    return QuietSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIcons.uiWarning, size: AppSizes.icon20, color: context.colors.tertiary),
          const SizedBox(width: AppSpacing.s3),
          Expanded(child: Text(conflict.explanation, style: context.texts.bodySmall)),
        ],
      ),
    );
  }
}

/// Одна проверка техники: значок, заголовок, объяснение.
class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check});

  final ConflictCheck check;

  @override
  Widget build(BuildContext context) {
    return QuietSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            AppIcons.byKey(check.iconKey) ?? AppIcons.uiInfo,
            size: AppSizes.icon20,
            color: context.colors.secondary,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(check.title, style: context.texts.bodyMedium),
                const SizedBox(height: AppSpacing.s1),
                Text(check.text, style: context.texts.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
