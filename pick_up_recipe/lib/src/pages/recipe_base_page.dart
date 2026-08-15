// Базовый рецепт из справочника: у обжарщика нет рецепта под ваш прибор.
//
// Разметка — макет S01 (recipe-base.html): в шапке метод, компактная плашка
// происхождения, карточка-герой с иконкой прибора и цветными плитками
// показателей, шаги в пунктирной рамке — они из шаблона, а не от человека.
// «Заварить» начинает сразу: рецепт целиком перед глазами, и отдельный экран
// подготовки после него был бы этим же экраном ещё раз.
//
// На эспрессо-семействе подписи меняются: вода там — выход в чашке, доза —
// в корзину, и жёлтая плашка проговаривает это отдельно (S02): подпись
// берётся из brew_methods.water_meaning, а не из предположения, что всё на
// свете — пуровер.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/app_router.dart';
import '../features/brew_methods/application/brew_methods_state.dart';
import '../features/brew_methods/domain/brew_method.dart';
import '../features/grinders/application/grinder_state.dart';
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

  /// Метод из справочника и имя его группы — ради water_meaning, иконки
  /// и подписи «иммерсия · 1:14 · около 1:45» на карточке.
  (BrewMethod?, String) _method() {
    for (final group in ref.watch(brewMethodsProvider).grouped) {
      for (final method in group.methods) {
        if (method.slug == widget.method) return (method, group.name);
      }
    }
    return (null, '');
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
    final (method, groupName) = _method();
    final methodName = method?.name ?? widget.methodName ?? widget.method;
    final recipe = _recipe;
    final inCup = method?.waterMeaning == 'in_cup';

    final subtitle = [
      if (widget.pack?.packName.isNotEmpty ?? false) widget.pack!.packName,
      if (widget.pack?.roasterName.isNotEmpty ?? false) widget.pack!.roasterName,
    ].join(' · ');

    return AppScreen(
      title: methodName,
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
          if (subtitle.isNotEmpty) ...[
            Text(subtitle, style: context.texts.bodySmall),
            const SizedBox(height: AppSpacing.s3),
          ],
          _SourcePlate(inCup: inCup),
          const SizedBox(height: AppSpacing.s4),
          _HeroCard(
            recipe: recipe,
            method: method,
            methodName: methodName,
            groupName: groupName,
            inCup: inCup,
            ref: ref,
          ),
          if (inCup) ...[
            const SizedBox(height: AppSpacing.s4),
            _InCupPlate(recipe: recipe),
          ],
          const SizedBox(height: AppSpacing.s5),
          const SectionTitle('Шаги · из шаблона метода'),
          DashedBorderBox(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s1,
            ),
            child: Column(
              children: [
                for (final (index, step) in recipe.steps.indexed) ...[
                  if (index > 0) Divider(height: 1, color: context.palette.border),
                  _StepRow(step: step),
                ],
              ],
            ),
          ),
        ],
      ],
      bottom: recipe == null
          ? const []
          : [
              AppButton(
                label: 'Заварить',
                icon: AppIcons.uiPlay,
                onPressed: () => context.router.push(
                  // Сразу к завариванию: этот экран и есть подготовка.
                  BrewRoute(recipe: _forBrew(), pack: widget.pack, autoStart: true),
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
              AppButton(
                label: 'Отредактировать',
                icon: AppIcons.uiEdit,
                kind: AppButtonKind.secondary,
                onPressed: () => context.router.push(
                  RecipeBuilderRoute(recipe: _forEdit(), pack: widget.pack),
                ),
              ),
            ],
    );
  }
}

/// Происхождение рецепта — раньше параметров, но в две строки, не в абзац.
class _SourcePlate extends StatelessWidget {
  const _SourcePlate({required this.inCup});

  final bool inCup;

  @override
  Widget build(BuildContext context) {
    return DashedBorderBox(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        children: [
          AppIcon(AppIcons.uiInfo, size: AppSizes.icon32, color: context.colors.secondary),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Базовый рецепт', style: context.texts.bodyMedium),
                Text(
                  inCup
                      ? 'типовой — под машину и корзину числа сдвигают'
                      : 'собран по прибору, зерно не учитывает',
                  style: context.texts.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка-герой: прибор, подпись группы и четыре цветные плитки чисел.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.recipe,
    required this.method,
    required this.methodName,
    required this.groupName,
    required this.inCup,
    required this.ref,
  });

  final RecipeData recipe;
  final BrewMethod? method;
  final String methodName;
  final String groupName;
  final bool inCup;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final descriptors = ref.watch(grindDescriptorsProvider).valueOrNull;
    final grindWord = descriptors == null
        ? recipe.grindDescriptor
        : grindDescriptorName(descriptors, recipe.grindDescriptor);

    final grinder = ref.watch(grinderStateProvider).primary;

    return HeroSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                AppIcons.method(method?.iconKey ?? recipe.device),
                size: AppSizes.icon40,
                color: context.colors.primary,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(methodName, style: context.texts.titleMedium),
                    Text(_caption(), style: context.texts.labelSmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recipe.load > 0)
                Expanded(
                  child: MetricTile(
                    kind: MetricKind.dose,
                    value: '${formatAmount(recipe.load)} г',
                    caption: inCup ? 'в корзину' : null,
                  ),
                ),
              if (recipe.water > 0)
                Expanded(
                  child: MetricTile(
                    kind: MetricKind.water,
                    value: '${recipe.water} ${inCup ? 'г' : 'мл'}',
                    caption: inCup ? 'в чашке' : null,
                  ),
                ),
              if (recipe.temperature != null)
                Expanded(
                  child: MetricTile(
                    kind: MetricKind.temperature,
                    value: '${formatAmount(recipe.temperature!)} °C',
                  ),
                ),
              if (grindWord.isNotEmpty)
                Expanded(
                  child: MetricTile(kind: MetricKind.grind, value: grindWord),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Divider(height: 1, color: context.palette.border),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              AppIcon(
                AppIcons.metricGrind,
                size: AppSizes.icon16,
                color: context.metrics.grind,
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  // Щелчков в справочнике нет — честная строка вместо числа:
                  // помол дан словом, деление человек подбирает на своей.
                  grinder == null
                      ? 'Помол словом из справочника'
                      : 'Деление подберите на вашей ${grinder.name}',
                  style: context.texts.labelSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// «иммерсия · 1:14 · около 1:45» — группа, соотношение, время.
  String _caption() {
    final parts = [
      if (groupName.isNotEmpty) groupName.toLowerCase(),
      if (recipe.load > 0 && recipe.water > 0)
        '1:${(recipe.water / recipe.load).toStringAsFixed(1).replaceAll('.', ',')}',
      if (recipe.time > 0) 'около ${formatDuration(Duration(seconds: recipe.time))}',
    ];
    return parts.join(' · ');
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

/// Строка шага в пунктирной рамке: значок, подпись, «вода · время» справа.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final RecipeStep step;

  @override
  Widget build(BuildContext context) {
    final value = [
      if (step.water > 0) '${step.water} г',
      if (step.time > 0) formatDuration(Duration(seconds: step.time)),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      child: Row(
        children: [
          AppIcon(
            AppIcons.step(step.stepType),
            size: AppSizes.icon20,
            // Цвет воды — только у шагов, которые её льют (как в макете).
            color: step.water > 0 ? context.metrics.water : context.colors.onSurface,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(child: Text(step.instruction, style: context.texts.bodyMedium)),
          Text(value, style: context.texts.labelSmall),
        ],
      ),
    );
  }
}
