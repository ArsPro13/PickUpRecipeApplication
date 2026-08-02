// Экран 04 «Заваривание».
//
// Работает на BrewEngine (ответ D5). До этого экран крутил один
// AnimationController на всю длительность рецепта, и из этого следовали три
// проблемы разом: при сворачивании приложения контроллер вставал, пауза не
// сохраняла состояние, а прогресс накапливался кадрами — то есть пропущенный
// кадр означал потерянное время. Для колд брю на двенадцать часов такой плеер
// неприменим в принципе.
//
// Движок считает состояние из абсолютных меток времени, поэтому сворачивание
// перестаёт быть особым случаем: время идёт само, а таймер интерфейса нужен
// только чтобы перерисовывать.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/domain/brew_engine.dart';
import '../features/recipes/domain/brew_step.dart';
import '../features/recipes/domain/models/recipe_data_model.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

/// Собирает шаги плеера из рецепта, пришедшего с сервера.
List<BrewStep> brewStepsOf(RecipeData recipe) {
  return [
    for (final step in recipe.steps)
      BrewStep.fromResponse(
        seqNum: step.seqNum,
        instruction: step.instruction,
        timeSec: step.time,
        waterMl: step.water,
      ),
  ];
}

@RoutePage()
class BrewPage extends StatefulWidget {
  const BrewPage({super.key, required this.recipe, required this.pack});

  final RecipeData recipe;
  final PackData? pack;

  @override
  State<BrewPage> createState() => _BrewPageState();
}

class _BrewPageState extends State<BrewPage> with WidgetsBindingObserver {
  late final BrewEngine _engine = BrewEngine(steps: brewStepsOf(widget.recipe));

  /// Таймер перерисовки. Он не считает время — только просит движок отдать
  /// снимок. Поэтому пропущенный тик ничего не ломает.
  Timer? _ticker;

  late BrewSnapshot _snapshot = _engine.snapshot();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Возвращение из фона — это просто ещё один запрос снимка: движок сам
    // знает, сколько прошло по настенным часам.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _snapshot = _engine.snapshot());
    if (_snapshot.isFinished) _stopTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _toggle() {
    if (!_engine.isStarted) {
      _engine.start();
      _startTicker();
    } else if (_snapshot.status == BrewStatus.paused) {
      _engine.resume();
      _startTicker();
    } else {
      _engine.pause();
      _stopTicker();
    }
    _refresh();
  }

  void _skip() {
    _engine.skipCurrentStep();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _engine.steps;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const AppIcon(AppIcons.uiBack, size: AppSizes.icon24),
        ),
        title: Text(widget.pack?.packName ?? widget.recipe.device),
      ),
      body: Column(
        children: [
          _Header(recipe: widget.recipe, snapshot: _snapshot),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s2,
                AppSpacing.s4,
                AppSpacing.s4,
              ),
              itemCount: steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s2),
              itemBuilder: (context, index) => _StepCard(
                step: steps[index],
                index: index,
                snapshot: _snapshot,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: switch (_snapshot.status) {
                        BrewStatus.idle => 'Начать',
                        BrewStatus.running => 'Пауза',
                        BrewStatus.paused => 'Продолжить',
                        BrewStatus.finished => 'Готово',
                      },
                      icon: _snapshot.isRunning ? AppIcons.uiPause : AppIcons.uiPlay,
                      onPressed: _snapshot.isFinished ? null : _toggle,
                    ),
                  ),
                  if (_engine.isStarted && !_snapshot.isFinished) ...[
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: AppButton(
                        label: 'Пропустить шаг',
                        kind: AppButtonKind.secondary,
                        onPressed: _skip,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Шапка: показатели рецепта и общий прогресс.
class _Header extends StatelessWidget {
  const _Header({required this.recipe, required this.snapshot});

  final RecipeData recipe;
  final BrewSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MetricTile(kind: MetricKind.temperature, value: '${recipe.temperature} °C'),
              MetricTile(kind: MetricKind.dose, value: '${recipe.load} г'),
              MetricTile(
                kind: MetricKind.water,
                value: '${snapshot.waterPouredG.round()} / ${snapshot.waterTotalG.round()} мл',
              ),
              MetricTile(kind: MetricKind.grind, value: '${recipe.grindStep} щ'),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          // Один индикатор на весь набор: два прогресса рядом читаются как
          // соревнование, а человеку нужно знать, сколько осталось всего.
          ClipRRect(
            borderRadius: AppRadius.rounded,
            child: LinearProgressIndicator(
              value: snapshot.totalProgress,
              minHeight: AppSizes.progressTrack,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            '${formatDuration(snapshot.elapsedTotal)} из ${formatDuration(snapshot.totalDuration)}',
            style: context.texts.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Карточка шага: подпись, время, вода и состояние.
class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.index, required this.snapshot});

  final BrewStep step;
  final int index;
  final BrewSnapshot snapshot;

  bool get _isActive => snapshot.stepIndex == index && !snapshot.isFinished;
  bool get _isDone => snapshot.stepIndex > index || snapshot.isFinished;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isDone ? 0.6 : 1,
      child: AppCard(
        flat: !_isActive,
        borderColor: _isActive ? context.colors.primary : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(
                  AppIcons.byKey('step-${step.type.wireName.replaceAll('_', '-')}') ??
                      AppIcons.stepCustom,
                  size: AppSizes.icon24,
                  color: _isDone ? context.palette.success : context.colors.onSurface,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(child: Text(step.label, style: context.texts.bodyLarge)),
                Text(
                  _isActive
                      ? formatDuration(snapshot.remainingInStep)
                      : formatDuration(step.duration),
                  style: context.texts.bodySmall,
                ),
              ],
            ),
            if (step.waterG > 0 || step.isOptional) ...[
              const SizedBox(height: AppSpacing.s2),
              Wrap(
                spacing: AppSpacing.s2,
                children: [
                  if (step.waterG > 0)
                    MetricTag(kind: MetricKind.water, label: '${step.waterG.round()} мл'),
                  if (step.isOptional) const AppChip(label: 'необязательный'),
                ],
              ),
            ],
            if (_isActive) ...[
              const SizedBox(height: AppSpacing.s3),
              ClipRRect(
                borderRadius: AppRadius.rounded,
                child: LinearProgressIndicator(value: snapshot.stepProgress),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Формат м:сс. Часы появляются только когда они есть — у колд брю.
String formatDuration(Duration duration) {
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (duration.inHours > 0) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '${duration.inHours}:$minutes:$seconds';
  }
  return '${duration.inMinutes}:$seconds';
}
