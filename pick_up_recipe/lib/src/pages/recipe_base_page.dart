// Базовый рецепт из справочника: у обжарщика нет рецепта под ваш прибор.
//
// Плашка объясняет не «откуда рецепт», а чего он не знает — сорт и обжарку
// (макет S01). На эспрессо-семействе экран меняет подписи: вода там — выход
// в чашке, доза — в корзину, и жёлтая плашка проговаривает это отдельно
// (S02): подпись плитки берётся из brew_methods.water_meaning, а не из
// предположения, что всё на свете — пуровер.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/app_router.dart';
import '../features/brew_methods/application/brew_methods_state.dart';
import '../features/brew_methods/domain/brew_method.dart';
import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/application/step_types_state.dart';
import '../features/recipes/domain/models/grind_descriptor_model.dart';
import '../features/recipes/data_sources/remote/recipe_service.dart';
import '../features/recipes/domain/models/recipe_data_model.dart';
import '../features/recipes/domain/models/recipe_step_model.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'brew_page.dart';

@RoutePage()
class RecipeBasePage extends ConsumerStatefulWidget {
  const RecipeBasePage({
    super.key,
    required this.method,
    this.methodName,
    this.pack,
  });

  /// Slug метода — по нему ищется справочный рецепт.
  final String method;

  final String? methodName;

  /// Пачка, с которой пришли. Именно она станет пачкой копии при правке:
  /// базовый рецепт неприкосновенен, своя версия начинается с неё (C7).
  final PackData? pack;

  @override
  ConsumerState<RecipeBasePage> createState() => _RecipeBasePageState();
}

class _RecipeBasePageState extends ConsumerState<RecipeBasePage> {
  final RecipeService _service = RecipeService();

  RecipeData? _recipe;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      if (ref.read(brewMethodsProvider).grouped.isEmpty) {
        ref.read(brewMethodsProvider.notifier).load();
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final recipe = await _service.getBaseRecipe(widget.method);
      if (!mounted) return;
      setState(() {
        _recipe = recipe;
        _loading = false;
        if (recipe == null) {
          _error = 'У этого метода нет справочного рецепта.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  /// Метод из справочника — ради water_meaning и человеческого имени.
  BrewMethod? _method() {
    for (final group in ref.watch(brewMethodsProvider).grouped) {
      for (final method in group.methods) {
        if (method.slug == widget.method) return method;
      }
    }
    return null;
  }

  /// Рецепт для конструктора: пачка подставлена.
  ///
  /// У базового рецепта пачки нет, а копия при правке обязана знать,
  /// с какого зерна началась (ветка C7 на бэке).
  RecipeData _forEdit() {
    final recipe = _recipe!;
    if (widget.pack != null) recipe.packId = widget.pack!.packId;
    return recipe;
  }

  /// Рецепт для заваривания: как есть, с packId == 0.
  ///
  /// Ноль — признак базового: по нему экран оценки понимает, что оценку
  /// нельзя вешать на общий рецепт, и сначала заводит свою копию (C7).
  RecipeData _forBrew() => _recipe!;

  @override
  Widget build(BuildContext context) {
    final method = _method();
    final methodName = method?.name ?? widget.methodName ?? widget.method;
    final recipe = _recipe;

    return AppScreen(
      title: widget.pack?.packName ?? methodName,
      body: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (recipe == null)
          AppState(
            icon: AppIcons.stateError,
            title: 'Рецепт не открылся',
            description: _error,
            isError: true,
            primaryAction: AppButton(label: 'Повторить', onPressed: _load),
          )
        else ...[
          _InfoPlate(inCup: method?.waterMeaning == 'in_cup', methodName: methodName),
          const SizedBox(height: AppSpacing.s4),
          _Figs(recipe: recipe, inCup: method?.waterMeaning == 'in_cup', ref: ref),
          if (method?.waterMeaning == 'in_cup') ...[
            const SizedBox(height: AppSpacing.s4),
            _InCupPlate(recipe: recipe),
          ],
          const SizedBox(height: AppSpacing.s5),
          SectionTitle(
            '${_stepsCount(recipe.steps.length)} · ${formatDuration(Duration(seconds: recipe.time))}',
          ),
          for (final (index, step) in recipe.steps.indexed)
            _StepRow(step: step, alt: index.isEven),
        ],
      ],
      bottom: recipe == null
          ? const []
          : [
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Заварить',
                      icon: AppIcons.uiPlay,
                      onPressed: () => context.router.push(
                        BrewRoute(recipe: _forBrew(), pack: widget.pack),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  AppButton(
                    label: 'Править',
                    kind: AppButtonKind.secondary,
                    block: false,
                    onPressed: () => context.router.push(
                      RecipeBuilderRoute(recipe: _forEdit(), pack: widget.pack),
                    ),
                  ),
                ],
              ),
            ],
    );
  }
}

String _stepsCount(int count) {
  final words = switch (count % 10) {
    1 when count % 100 != 11 => 'шаг',
    2 || 3 || 4 when count % 100 < 12 || count % 100 > 14 => 'шага',
    _ => 'шагов',
  };
  return '$count $words';
}

/// «Базовый рецепт из справочника»: чего он не знает и почему это честно.
class _InfoPlate extends StatelessWidget {
  const _InfoPlate({required this.inCup, required this.methodName});

  final bool inCup;
  final String methodName;

  @override
  Widget build(BuildContext context) {
    final text = inCup
        ? 'Числа типовые: под вашу машину и корзину их почти наверняка '
            'придётся сдвинуть.'
        : 'Обжарщик не завёл рецепт под $methodName, поэтому взят типовой: '
            'он учитывает прибор, но не сорт и не обжарку. Заварите и '
            'оцените — подберём точнее.';

    return QuietSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIcons.uiInfo, size: AppSizes.icon20, color: context.colors.secondary),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: 'Базовый рецепт из справочника. ',
                  style: context.texts.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: text),
              ]),
              style: context.texts.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Жёлтая плашка эспрессо: вода здесь — выход в чашке, не «сколько налить».
class _InCupPlate extends StatelessWidget {
  const _InCupPlate({required this.recipe});

  final RecipeData recipe;

  @override
  Widget build(BuildContext context) {
    final ratio = recipe.load > 0 ? (recipe.water / recipe.load) : 0;

    return QuietSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIcons.uiWarning, size: AppSizes.icon20, color: context.colors.tertiary),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              '${recipe.water} г — это выход в чашке, а не сколько налить. '
              'Соотношение 1:${ratio.toStringAsFixed(1).replaceAll('.', ',')}, '
              'и следят именно за весом напитка.',
              style: context.texts.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Четыре плитки чисел. Подписи зависят от метода: у эспрессо доза идёт
/// «в корзину», вода — «в чашке».
class _Figs extends StatelessWidget {
  const _Figs({required this.recipe, required this.inCup, required this.ref});

  final RecipeData recipe;
  final bool inCup;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final descriptors = ref.watch(grindDescriptorsProvider).valueOrNull;
    final grindWord = descriptors == null
        ? recipe.grindDescriptor
        : grindDescriptorName(descriptors, recipe.grindDescriptor);

    final figs = <(String, String, String)>[
      if (recipe.load > 0)
        (AppIcons.metricDose, '${formatAmount(recipe.load)} г', inCup ? 'в корзину' : 'кофе'),
      if (grindWord.isNotEmpty) (AppIcons.metricGrind, grindWord, 'помол'),
      if (recipe.water > 0)
        (AppIcons.metricWater, '${recipe.water} ${inCup ? 'г' : 'мл'}', inCup ? 'в чашке' : 'вода'),
      if (recipe.temperature != null)
        (AppIcons.metricTemperature, '${formatAmount(recipe.temperature!)}°', 'вода'),
    ];

    return Row(
      children: [
        for (final (icon, value, label) in figs)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
              child: Column(
                children: [
                  AppIcon(icon, size: AppSizes.icon20, color: context.colors.secondary),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    value,
                    style: context.texts.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(label, style: context.texts.labelSmall, maxLines: 1),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Строка шага: значок типа, подпись, вода и время.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.alt});

  final RecipeStep step;
  final bool alt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: alt ? context.colors.surfaceContainerHighest.withValues(alpha: 0.35) : null,
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        children: [
          AppIcon(
            AppIcons.step(step.stepType),
            size: AppSizes.icon20,
            color: context.colors.secondary,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(child: Text(step.instruction, style: context.texts.bodySmall)),
          if (step.water > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s2),
              child: Text(
                '+${step.water}',
                style: context.texts.labelSmall?.copyWith(color: context.colors.primary),
              ),
            ),
          Text(
            formatDuration(Duration(seconds: step.time)),
            style: context.texts.labelSmall,
          ),
        ],
      ),
    );
  }
}
