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

import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../features/brew_methods/application/brew_methods_state.dart';
import '../features/grinders/application/grinder_state.dart';
import '../features/grinders/domain/grind_translation.dart';
import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/application/step_types_state.dart';
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
  String? _error;

  /// Базовый рецепт грузится по тапу: отдельного экрана под него больше нет,
  /// и пока он едет, строка показывает, что нажатие услышано.
  bool _openingBase = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      // Справочник нужен ради иконки метода: по диплинку сюда приходят
      // мимо экрана выбора, и загрузить его больше некому.
      if (ref.read(brewMethodsProvider).grouped.isEmpty) {
        ref.read(brewMethodsProvider.notifier).load();
      }
      // Кофемолка нужна ради помола: без неё на плитке останется слово, а не
      // деление. По диплинку сюда приходят мимо вкладки «Пачки», где набор
      // загружается обычно.
      if (!ref.read(grinderStateProvider).hasGrinder) {
        ref.read(grinderStateProvider.notifier).loadUserGrinders();
      }
    });
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

  /// Открывает базовый рецепт метода — сразу на завариванием.
  ///
  /// Промежуточного экрана «вот рецепт из справочника» больше нет: он
  /// показывал ровно то же, что показывает экран заваривания до старта —
  /// числа, шаги и подготовку, — и стоил лишнего нажатия на каждой чашке.
  Future<void> _openBase() async {
    if (_openingBase) return;
    setState(() => _openingBase = true);

    try {
      final recipe = await _service.getBaseRecipe(widget.method ?? '');
      if (!mounted) return;

      if (recipe == null) {
        _say(AppLocalizations.of(context).chooseNoBase);
        return;
      }

      await context.router.push(BrewRoute(recipe: recipe, pack: widget.pack));
    } catch (error) {
      if (mounted) {
        _say(AppLocalizations.of(context).chooseBaseFailed('$error'));
      }
    } finally {
      if (mounted) setState(() => _openingBase = false);
    }
  }

  void _say(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return AppScreen(
      title: widget.methodName ?? texts.recipesTitle,
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
                    title: texts.chooseFailed,
                    description: _error,
                    isError: true,
                    primaryAction: AppButton(label: texts.retry, onPressed: _load),
                  ),
                ]
              : _content(),
    );
  }

  /// Помол рецепта делениями основной кофемолки (пункт 8).
  ///
  /// Плитка показывала «${recipe.grindStep} щ.», а у справочного рецепта
  /// grind_step пуст — на месте помола стояло «щ.» без числа.
  GrindReading _grind(RecipeData recipe) {
    return grindReading(
      descriptorSlug: recipe.grindDescriptor,
      reference: ref.watch(grindDescriptorsProvider).valueOrNull ?? const [],
      recipeGrinderId: recipe.grinderId,
      recipeGrindStep: recipe.grindStep,
      grinder: ref.watch(grinderStateProvider).primary,
    );
  }

  List<Widget> _content() {
    final texts = AppLocalizations.of(context);
    final roaster = _recipes.isEmpty ? null : _recipes.first;
    final mine = _recipes.length > 1 ? _recipes.sublist(1) : const <RecipeData>[];

    return [
      if (widget.pack != null)
        Text(widget.pack!.packName, style: context.texts.bodySmall),

      if (roaster != null) ...[
        _Section(
          icon: AppIcons.uiPack,
          title: texts.chooseRoaster,
          note: texts.chooseRoasterNote,
        ),
        _RoasterRecipe(recipe: roaster, pack: widget.pack, grind: _grind(roaster)),
      ],

      _Section(
        icon: AppIcons.metricRatio,
        title: texts.chooseBase,
        note: texts.chooseBaseNote,
      ),
      // Базовый рецепт лежит в базе у каждого метода (миграция
      // 20260813100000). Строка ведёт прямо на заваривание: до старта тот
      // экран и есть рецепт — числа, шаги и подготовка на одном месте.
      InkWell(
        borderRadius: AppRadius.medium,
        onTap: _openBase,
        child: QuietSurface(
          child: Row(
            children: [
              AppIcon(
                // В руках только slug метода, а файлы лежат по icon_key —
                // перевод знает справочник. Пока он не загружен, slug сам
                // по себе верен для новых методов и даёт V60 для старых.
                AppIcons.method(
                  ref.watch(brewMethodsProvider).iconKeyBySlug[widget.method] ??
                      widget.method,
                ),
                size: AppSizes.icon32,
                color: context.colors.secondary,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(texts.chooseMethodRecipe, style: context.texts.bodyMedium),
                    const SizedBox(height: AppSpacing.s1),
                    Text(texts.chooseMethodRecipeNote, style: context.texts.labelSmall),
                  ],
                ),
              ),
              if (_openingBase)
                const SizedBox(
                  height: AppSizes.icon20,
                  width: AppSizes.icon20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                AppIcon(
                  AppIcons.uiForward,
                  size: AppSizes.icon20,
                  color: context.colors.secondary,
                ),
            ],
          ),
        ),
      ),

      if (mine.isNotEmpty) ...[
        _Section(
          icon: AppIcons.uiHistory,
          title: texts.chooseMine,
          note: texts.chooseMineNote,
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
  const _RoasterRecipe({required this.recipe, this.pack, required this.grind});

  final RecipeData recipe;
  final PackData? pack;

  /// Помол делениями кофемолки человека, уже переведённый.
  final GrindReading grind;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return HeroSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MetricTile(kind: MetricKind.dose, value: texts.unitGrams('${recipe.load}')),
              MetricTile(
                kind: MetricKind.water,
                value: texts.unitMillilitres('${recipe.water}'),
              ),
              MetricTile(kind: MetricKind.temperature, value: '${recipe.temperature} °C'),
              MetricTile(
                kind: MetricKind.grind,
                value: grind.isEmpty ? '—' : grind.label,
                caption: grind.caption,
              ),
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
                label: texts.edit,
                kind: AppButtonKind.secondary,
                block: false,
                onPressed: () => context.router.push(
                  RecipeBuilderRoute(recipe: recipe, pack: pack),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: AppButton(
                  label: texts.chooseBrewWithTime(_formatTime(recipe.time)),
                  icon: AppIcons.uiPlay,
                  // Числа рецепта уже над кнопкой — таймер идёт сразу.
                  onPressed: () => context.router.push(
                    BrewRoute(recipe: recipe, pack: pack, autoStart: true),
                  ),
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
