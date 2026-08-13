// Рецепты под конкретное зерно и конкретный метод.
//
// Три раздела в порядке, в котором человек их выбирает: рецепт обжарщика под
// это зерно, базовый рецепт метода и свои прошлые рецепты. Пустых разделов не
// показываем — заголовок над пустотой хуже, чем его отсутствие.
//
// Раньше здесь был выпадающий список из одного реального метода и кнопка
// Generate: метод выбирается на предыдущем экране, а генерация — это способ
// собрать базовый рецепт, а не отдельная функция продукта.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/app_router.dart';
import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/data_sources/remote/recipe_service.dart';
import '../features/recipes/domain/models/recipe_data_model.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class ChoosingRecipePage extends ConsumerStatefulWidget {
  const ChoosingRecipePage({
    super.key,
    required this.packId,
    @QueryParam('method') this.method,
    @QueryParam('name') this.methodName,
    this.pack,
  });

  final int packId;

  /// Slug метода. Пусто — показываем всё, что есть по этой пачке.
  final String? method;

  /// Название метода для шапки.
  final String? methodName;

  final PackData? pack;

  @override
  ConsumerState<ChoosingRecipePage> createState() => _ChoosingRecipePageState();
}

class _ChoosingRecipePageState extends ConsumerState<ChoosingRecipePage> {
  final RecipeService _service = RecipeService();

  List<RecipeData> _recipes = const [];
  bool _loading = true;
  bool _building = false;
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
      final recipes = await _service.getByParams(
        packId: widget.packId,
        device: widget.method,
      );
      if (!mounted) return;
      setState(() {
        _recipes = [...?recipes]..sort((a, b) => b.date.compareTo(a.date));
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

  /// Собирает базовый рецепт метода под это зерно.
  Future<void> _buildBase() async {
    setState(() => _building = true);
    try {
      await _service.generateRecipe(widget.method ?? '', widget.packId);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _building = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: widget.methodName ?? 'Рецепты',
      body: _loading
          ? const [
              SizedBox(height: AppSpacing.s16),
              Center(child: CircularProgressIndicator()),
            ]
          : _error != null
              ? [
                  const SizedBox(height: AppSpacing.s12),
                  AppState(
                    icon: AppIcons.stateError,
                    title: 'Рецепты не открылись',
                    description: _error,
                    isError: true,
                    primaryAction: AppButton(label: 'Повторить', onPressed: _load),
                  ),
                ]
              : _content(),
    );
  }

  List<Widget> _content() {
    final roaster = _recipes.isEmpty ? null : _recipes.first;
    final mine = _recipes.length > 1 ? _recipes.sublist(1) : const <RecipeData>[];

    return [
      if (widget.pack != null)
        Text(widget.pack!.packName, style: context.texts.bodySmall),

      if (roaster != null) ...[
        const _Section(icon: AppIcons.uiPack, title: 'От обжарщика', note: 'под это зерно'),
        _RoasterRecipe(recipe: roaster, pack: widget.pack),
      ],

      const _Section(
        icon: AppIcons.metricRatio,
        title: 'Базовый',
        note: 'из справочника',
      ),
      QuietSurface(
        child: Row(
          children: [
            AppIcon(
              AppIcons.byKey('method-${(widget.method ?? '').replaceAll('_', '-')}') ??
                  AppIcons.methodHarioV60,
              size: AppSizes.icon32,
              color: context.colors.secondary,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Рецепт метода', style: context.texts.bodyMedium),
                  const SizedBox(height: AppSpacing.s1),
                  Text('зерно не учитывает', style: context.texts.labelSmall),
                ],
              ),
            ),
            if (_building)
              const SizedBox(
                width: AppSizes.icon20,
                height: AppSizes.icon20,
                child: CircularProgressIndicator(strokeWidth: AppStroke.thick),
              )
            else
              TextButton(onPressed: _buildBase, child: const Text('Собрать')),
          ],
        ),
      ),

      if (mine.isNotEmpty) ...[
        const _Section(
          icon: AppIcons.uiHistory,
          title: 'Ваши рецепты',
          note: 'прошлые версии',
        ),
        for (final recipe in mine) _VersionRow(recipe: recipe, pack: widget.pack),
      ],

      const SizedBox(height: AppSpacing.s6),
    ];
  }
}

/// Заголовок раздела: иконка, название и пояснение мелким.
class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.note});

  final String icon;
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s6, bottom: AppSpacing.s3),
      child: Row(
        children: [
          AppIcon(icon, size: AppSizes.icon20, color: context.colors.secondary),
          const SizedBox(width: AppSpacing.s2),
          Text(title, style: context.texts.bodyMedium),
          const SizedBox(width: AppSpacing.s2),
          Expanded(child: Text(note, style: context.texts.bodySmall)),
        ],
      ),
    );
  }
}

/// Рецепт обжарщика: показатели плитками и кнопка заваривания с длительностью.
class _RoasterRecipe extends StatelessWidget {
  const _RoasterRecipe({required this.recipe, this.pack});

  final RecipeData recipe;
  final PackData? pack;

  @override
  Widget build(BuildContext context) {
    return HeroSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MetricTile(kind: MetricKind.dose, value: '${recipe.load} г'),
              MetricTile(kind: MetricKind.water, value: '${recipe.water} мл'),
              MetricTile(kind: MetricKind.temperature, value: '${recipe.temperature} °C'),
              MetricTile(kind: MetricKind.grind, value: '${recipe.grindStep} щ.'),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            children: [
              // Правка стоит рядом с завариванием, а не прячется в меню: чаще
              // всего рецепт открывают именно чтобы подвинуть одно число под
              // свою кофемолку. Оригинал обжарщика при этом неприкосновенен —
              // сохранение заводит новую версию.
              // «Править» по содержимому, а не долей ширины: доля отмерялась
              // от «Заварить · 2:30», и слово ужималось сначала до «П…»,
              // потом до «Прав…». Место делит тот, у кого подпись длиннее.
              AppButton(
                label: 'Править',
                kind: AppButtonKind.secondary,
                block: false,
                onPressed: () => context.router.push(
                  RecipeBuilderRoute(recipe: recipe, pack: pack),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: AppButton(
                  label: 'Заварить · ${_formatTime(recipe.time)}',
                  icon: AppIcons.uiPlay,
                  onPressed: () => context.router.push(BrewRoute(recipe: recipe, pack: pack)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Прошлая версия рецепта строкой.
class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.recipe, this.pack});

  final RecipeData recipe;
  final PackData? pack;

  @override
  Widget build(BuildContext context) {
    return AppRow(
      label: _formatDate(recipe.date),
      value: '${recipe.temperature} °C · ${_formatTime(recipe.time)}',
      icon: AppIcons.uiHistory,
      onTap: () => context.router.push(BrewRoute(recipe: recipe, pack: pack)),
    );
  }
}

/// м:сс — тот же формат, что на экране заваривания.
String _formatTime(int seconds) {
  final rest = (seconds % 60).toString().padLeft(2, '0');
  return '${seconds ~/ 60}:$rest';
}

/// Дата рецепта. Сервер отдаёт ISO-строку; неразобранную показываем как есть,
/// а не прячем — пустая строка на месте даты выглядит поломкой.
String _formatDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;

  const months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];
  return '${parsed.day} ${months[parsed.month - 1]}';
}
