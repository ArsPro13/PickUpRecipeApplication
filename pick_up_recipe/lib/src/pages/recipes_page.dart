// Экран 07 «Рецепты» — вторая вкладка.
//
// История завариваний, сгруппированная парой «кофе + метод» (ответ Q23b):
// цепочка версий внутри пары раскрывается стопкой на месте, а не уводит
// на отдельный экран.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/app_router.dart';
import '../features/recipes/application/state/recipes_list_state.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class RecipesPage extends ConsumerStatefulWidget {
  const RecipesPage({super.key});

  @override
  ConsumerState<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends ConsumerState<RecipesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recipesListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Мои рецепты')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(recipesListProvider.notifier).load(),
        child: _body(state),
      ),
    );
  }

  Widget _body(RecipesListState state) {
    if (state.isLoading && state.groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.groups.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height / 6),
          AppState(
            icon: AppIcons.uiHistory,
            title: 'Ещё ни одного заваривания',
            description: 'Заварите кофе по рецепту — он появится здесь вместе с оценкой',
            primaryAction: AppButton(
              label: 'К пачкам',
              onPressed: () => AutoTabsRouter.of(context).setActiveIndex(0),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.s4),
      itemCount: state.groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
      itemBuilder: (context, index) => _GroupCard(group: state.groups[index]),
    );
  }
}

/// Одна группа истории: кофе + метод, версии стопкой.
class _GroupCard extends StatefulWidget {
  const _GroupCard({required this.group});

  final RecipeGroup group;

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final versions = widget.group.versions;
    final latest = versions.first;
    final hidden = versions.length - 1;

    return AppCard(
      onTap: () => context.router.push(ChoosingRecipeRoute(packId: latest.packId, method: latest.method, methodName: latest.title)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.group.title,
                  style: context.texts.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppIcon(
                AppIcons.uiForward,
                size: AppSizes.icon20,
                color: context.colors.secondary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              MetricTag(kind: MetricKind.dose, label: '${latest.doseG.toStringAsFixed(1)} г'),
              MetricTag(kind: MetricKind.water, label: '${latest.waterG} мл'),
              if (latest.temperatureC != null)
                MetricTag(
                  kind: MetricKind.temperature,
                  label: '${latest.temperatureC!.toStringAsFixed(0)} °C',
                ),
            ],
          ),
          if (hidden > 0) ...[
            const SizedBox(height: AppSpacing.s2),
            // Счётчик раскрывает стопку на месте (ответ на вопрос 35):
            // уводить на отдельный экран ради списка версий незачем.
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Свернуть версии' : 'ещё $hidden ${_versionWord(hidden)}'),
            ),
          ],
          if (_expanded)
            for (final version in versions.skip(1))
              AppRow(
                label: version.title,
                value: version.subtitle,
                onTap: () => context.router.push(ChoosingRecipeRoute(packId: version.packId, method: version.method, methodName: version.title)),
              ),
        ],
      ),
    );
  }

  String _versionWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'версия';
    if ([2, 3, 4].contains(count % 10) && !(count % 100 >= 12 && count % 100 <= 14)) {
      return 'версии';
    }
    return 'версий';
  }
}
