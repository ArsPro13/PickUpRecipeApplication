// Разбор поправки: что предлагается поменять и почему.
//
// Ключевое здесь — «почему». Поправка без причины читается как «сервер сказал
// мели мельче», и следовать такому совету незачем: человек не понимает, что
// именно он лечит, и в следующий раз повторит ту же ошибку.
//
// Причины приходят с бэкенда отдельным списком с ключом жалобы (ответ A2), и
// в поправку попадают только те жалобы, которые этот параметр действительно
// двигают. Ничего не сохраняется: применить поправку — отдельное действие.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/data_sources/remote/recipe_service.dart';
import '../features/recipes/domain/models/correction_model.dart';
import '../features/recipes/domain/models/recipe_data_model.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class CorrectionReviewPage extends ConsumerStatefulWidget {
  const CorrectionReviewPage({
    super.key,
    required this.recipe,
    required this.complaints,
    required this.summary,
    this.pack,
  });

  final RecipeData recipe;
  final PackData? pack;

  /// Коды жалоб: sour, bitter, weak, too_strong.
  final List<String> complaints;

  /// Та же жалоба словами — то, что человек сказал картой вкуса.
  final String summary;

  @override
  ConsumerState<CorrectionReviewPage> createState() => _CorrectionReviewPageState();
}

class _CorrectionReviewPageState extends ConsumerState<CorrectionReviewPage> {
  final RecipeService _service = RecipeService();

  RecipeCorrection? _correction;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final correction = await _service.suggestCorrection(
        recipeId: widget.recipe.id,
        complaints: widget.complaints,
      );
      if (!mounted) return;
      setState(() {
        _correction = correction;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final correction = _correction;

    return AppScreen(
      title: 'Что поправить',
      body: [
        Text(widget.summary, style: context.texts.bodySmall),
        const SizedBox(height: AppSpacing.s4),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          AppState(
            icon: AppIcons.stateError,
            title: 'Поправка не пришла',
            description: _error,
            isError: true,
            primaryAction: AppButton(label: 'Повторить', onPressed: _load),
          )
        else if (correction == null || correction.isEmpty)
          const AppState(
            icon: AppIcons.uiCheck,
            title: 'Менять нечего',
            description: 'По этой жалобе правила ничего не двигают — '
                'рецепт уже на границе своих значений.',
          )
        else ...[
          for (final change in correction.changes) ...[
            _ChangeCard(change: change),
            const SizedBox(height: AppSpacing.s3),
          ],
          if (correction.checks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text('Что проверить', style: context.texts.bodyMedium),
            const SizedBox(height: AppSpacing.s2),
            for (final check in correction.checks) ...[
              QuietSurface(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(
                      AppIcons.uiInfo,
                      size: AppSizes.icon20,
                      color: context.colors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(child: Text(check, style: context.texts.bodySmall)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
            ],
          ],
        ],
      ],
      bottom: [
        AppButton(
          label: 'Готово',
          kind: AppButtonKind.secondary,
          onPressed: () => context.router.maybePop(),
        ),
      ],
    );
  }
}

/// Один параметр: было → стало и почему.
class _ChangeCard extends StatelessWidget {
  const _ChangeCard({required this.change});

  final CorrectionChange change;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(change.title, style: context.texts.bodyMedium)),
              if (change.hint != null)
                Text(change.hint!, style: context.texts.labelSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Expanded(
                child: Text(
                  change.fromLabel,
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.secondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              AppIcon(
                AppIcons.uiForward,
                size: AppSizes.icon20,
                color: context.colors.secondary,
              ),
              Expanded(
                child: Text(
                  change.toLabel,
                  style: context.texts.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          for (final reason in change.reasons) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(reason.text, style: context.texts.labelSmall),
          ],
        ],
      ),
    );
  }
}
