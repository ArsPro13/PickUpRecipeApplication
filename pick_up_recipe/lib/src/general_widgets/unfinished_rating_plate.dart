// Плашка «оценка не дописана» над списком.
//
// Жила на «Пачках», пока они были главным экраном. Когда главными стали
// «Рецепты» (2 ноября 2026), плашка понадобилась двум экранам сразу и
// переехала сюда — к остальным общим виджетам.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../features/recipes/application/rating_draft.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'app_icon.dart';
import 'app_kit.dart';

/// Плашка «оценка не дописана».
///
/// Место выбрано так же, как у плашки офлайна на странице кофе: рядом с тем,
/// ради чего экран открыли, и без своего экрана. Стоит на главном экране —
/// «Рецептах»: его человек видит после перезапуска, и там же лежит сама
/// заваренная чашка. Осталась и на «Пачках», где жила, пока главными были
/// они: убрать её оттуда значило бы спрятать то, к чему уже привыкли.
///
/// Смотрит прямо за `RatingDrafts.current`, а не через провайдер: черновик
/// пишет чужой экран, и второй источник правды между ними только разошёлся бы
/// с первым.
class UnfinishedRatingPlate extends StatelessWidget {
  const UnfinishedRatingPlate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RatingDraft?>(
      valueListenable: RatingDrafts.current,
      builder: (context, draft, _) {
        if (draft == null) return const SizedBox.shrink();

        final texts = AppLocalizations.of(context);

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s2,
            AppSpacing.s4,
            0,
          ),
          child: AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s3,
            ),
            onTap: () => context.router.push(
              RatingRoute(recipe: draft.recipe, pack: draft.pack),
            ),
            child: Row(
              children: [
                AppIcon(
                  AppIcons.uiStar,
                  size: AppSizes.icon20,
                  color: context.colors.primary,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(texts.ratingDraftTitle,
                          style: context.texts.bodyMedium),
                      Text(
                        draft.summaryFor(texts).isEmpty
                            ? texts.ratingDraftContinue
                            : texts.ratingDraftContinueWith(
                                draft.summaryFor(texts)),
                        style: context.texts.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: RatingDrafts.clear,
                  tooltip: texts.remove,
                  icon: AppIcon(
                    AppIcons.uiClose,
                    size: AppSizes.icon16,
                    color: context.colors.secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
