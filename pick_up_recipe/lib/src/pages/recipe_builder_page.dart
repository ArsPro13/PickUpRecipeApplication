// Конструктор рецепта.
//
// Заменяет страницу «вот что изменилось»: diff не рисуется, человек попадает
// прямо в рецепт и правит его. Страница поправок показывала, ЧТО система
// решила, но не давала это изменить; конструктор отвечает на оба вопроса
// сразу — видно текущее значение и видно, как его подвинуть.
//
// От поправок остались две вещи: строка сверху «поправлено под …» с отменой и
// точка у изменённых значений. Этого хватает, чтобы понять, что тронула
// система, и экран не превращается в таблицу сравнения. Расплата честная:
// каким рецепт был до поправки, не видно, и вернуть отдельное значение
// назад нельзя — только отменить поправку целиком.
//
// Сумма воды по шагам и общее время считаются на месте: рецепт, где шаги не
// сходятся с общей водой, нельзя ни заварить, ни сохранить молча.

import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/app_router.dart';
import '../features/brew_methods/application/brew_methods_state.dart';
import '../features/brew_methods/domain/brew_method.dart';
import '../features/grinders/application/grinder_state.dart';
import '../features/grinders/domain/grind_translation.dart';
import '../features/grinders/domain/models/grinder_model.dart';
import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/application/step_types_state.dart';
import '../features/recipes/data_sources/remote/recipe_service.dart';
import '../features/recipes/domain/brew_step.dart';
import '../features/recipes/domain/models/recipe_data_model.dart';
import '../features/recipes/domain/models/recipe_step_model.dart';
import '../features/recipes/domain/models/step_type_model.dart';
import '../features/recipes/domain/models/user_step_type_model.dart';
import '../general_widgets/amount_stepper.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../general_widgets/duration_wheel_sheet.dart';
import '../general_widgets/step_type_sheet.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class RecipeBuilderPage extends ConsumerStatefulWidget {
  const RecipeBuilderPage({
    super.key,
    required this.recipe,
    this.pack,
    this.method,
    this.correctionLabel,
    this.original,
  });

  final RecipeData recipe;
  final PackData? pack;

  /// Метод заваривания: из него берётся список разрешённых типов шагов.
  /// null — экран найдёт его сам по `device` рецепта; не нашёл, значит лист
  /// покажет весь справочник, и это лучше пустого листа.
  final BrewMethod? method;

  /// Под что поправлено — «заметно кисло». null: пришли не из поправки,
  /// строки сверху нет.
  final String? correctionLabel;

  /// Рецепт до поправки. Нужен для двух вещей: точек у изменённых значений
  /// и кнопки «Отменить».
  final RecipeData? original;

  @override
  ConsumerState<RecipeBuilderPage> createState() => _RecipeBuilderPageState();
}

class _RecipeBuilderPageState extends ConsumerState<RecipeBuilderPage> {
  final RecipeService _service = RecipeService();

  /// Рабочая копия. Правки не должны трогать рецепт у того, кто нас открыл:
  /// уйти отсюда назад — значит отказаться от правок, а не унести их с собой.
  late RecipeData _recipe = copyRecipe(widget.recipe);

  /// Отменена ли поправка. Отмена возвращает исходный рецепт и гасит точки.
  bool _corrected = true;

  int? _openStep;
  bool _saving = false;

  /// Идентификатор сохранённой версии. Пока null — рецепт не сохранён, и
  /// уходить с экрана не с чем.
  int? _savedId;

  /// Рецепт, каким он был на последнем сохранении (или при открытии).
  ///
  /// Сравнением с ним и определяется, есть ли что терять. Хранится строкой,
  /// а не копией модели: у RecipeData нет равенства по значению, а списки
  /// шагов пришлось бы сравнивать вручную.
  late String _saved = jsonEncode(_recipe.toJson());

  bool get _dirty => jsonEncode(_recipe.toJson()) != _saved;

  @override
  void initState() {
    super.initState();
    // Рецепт мог приехать с водой у шага, который её не льёт: до формата v1
    // тип шага не хранился, а поле воды было у всех подряд. Чистим сразу, до
    // первого показа, — иначе итог соврёт ещё до того, как что-то тронули.
    dropStrayWater(_recipe);
    // Справочник методов нужен ради одного поля — allowed_step_types. Тот, кто
    // нас открыл, метод передать не обязан: у него на руках только рецепт.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.method != null) return;
      if (ref.read(brewMethodsProvider).grouped.isEmpty) {
        ref.read(brewMethodsProvider.notifier).load();
      }
    });
  }

  /// Метод рецепта: переданный или найденный по `device`.
  ///
  /// `device` — это slug метода: под этим же именем рецепты и запрашиваются.
  BrewMethod? get _method {
    if (widget.method != null) return widget.method;
    if (_recipe.device.isEmpty) return null;

    for (final group in ref.read(brewMethodsProvider).grouped) {
      for (final method in group.methods) {
        if (method.slug == _recipe.device) return method;
      }
    }
    return null;
  }

  bool get _showsCorrection => widget.correctionLabel != null && widget.original != null && _corrected;

  /// Общая вода расходится с суммой по шагам. Не запрет, а предупреждение:
  /// у части методов часть воды не наливается шагом — она уже в приборе.
  bool get _waterMismatch => _stepWater != _recipe.water;

  /// Вода по шагам — только с тех, которые её льют. Остальным она в рецепте
  /// не нужна: плеер такую воду выбрасывает, и, считая её здесь, экран
  /// предупреждал бы о расхождении, которого в заваривании не будет.
  int get _stepWater =>
      _recipe.steps.where(stepTakesWater).fold(0, (sum, step) => sum + step.water);

  int get _totalTime => _recipe.steps.fold(0, (sum, step) => sum + step.time);

  @override
  Widget build(BuildContext context) {
    // Справочник методов приезжает асинхронно: смотрим за ним, чтобы список
    // разрешённых типов шагов появился, как только он загрузится.
    ref.watch(brewMethodsProvider);
    final method = _method;
    final grinder = ref.watch(grinderStateProvider).primary;

    final screen = AppScreen(
      title: 'Ваш рецепт',
      onBack: _leave,
      body: [
        Text(_subtitle(), style: context.texts.labelSmall),
        const SizedBox(height: AppSpacing.s3),
        if (_showsCorrection) ...[
          _CorrectionRow(
            label: widget.correctionLabel!,
            onUndo: _undoCorrection,
          ),
          const SizedBox(height: AppSpacing.s4),
        ],
        _params(grinder),
        const SizedBox(height: AppSpacing.s4),
        Row(
          children: [
            Expanded(child: Text('Шаги', style: context.texts.bodyMedium)),
            Text('потяните за ручку', style: context.texts.labelSmall),
          ],
        ),
        const SizedBox(height: AppSpacing.s2),
        _steps(),
        const SizedBox(height: AppSpacing.s2),
        DashedBorderBox(
          onTap: () => _addStep(method),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(AppIcons.uiPlus, size: AppSizes.icon20, color: context.colors.secondary),
              const SizedBox(width: AppSpacing.s2),
              Text('Добавить шаг', style: context.texts.bodyMedium?.copyWith(
                color: context.colors.secondary,
              )),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        _totals(),
      ],
      bottom: [
        Row(
          children: [
            Expanded(
              // Кнопка не гаснет после сохранения: правку можно продолжить
              // и сохранить ещё раз — цепочка версий это и есть.
              child: AppButton(
                label: 'Сохранить',
                kind: AppButtonKind.secondary,
                loading: _saving,
                onPressed: _save,
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: AppButton(
                label: 'Заварить',
                icon: AppIcons.uiPlay,
                onPressed: _saving ? null : _brew,
              ),
            ),
          ],
        ),
        // Сохранение — конец дела, и после него нужен выход, а не молчание:
        // «Сохранено» в снекбаре гасло, а человек оставался в редакторе,
        // не понимая, закончил он или нет.
        if (_savedId != null)
          AppButton(
            label: 'На главную',
            icon: AppIcons.uiPack,
            onPressed: () => context.router.navigate(const PacksRoute()),
          ),
      ],
    );

    return PopScope(
      // Несохранённые правки не должны уходить по нажатию кнопки телефона:
      // экран открывается и с готовой поправкой, а она стоит человеку чашки.
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leave();
      },
      child: screen,
    );
  }

  String _subtitle() {
    final method = _method;
    final parts = [
      if (widget.pack?.packName.isNotEmpty ?? false) widget.pack!.packName,
      if (method != null) method.name else if (_recipe.device.isNotEmpty) _recipe.device,
    ];
    return parts.join(' · ');
  }

  // ── Параметры ────────────────────────────────────────────────────────────

  Widget _params(Grinder? grinder) {
    // Помол показывается делением кофемолки человека (пункт 8): раньше на
    // этой строке стояло значение grind_step, а у справочного рецепта оно
    // пусто — оставался прочерк с подписью «средне-тонкий».
    final grind = grindReading(
      descriptorSlug: _recipe.grindDescriptor,
      reference: ref.watch(grindDescriptorsProvider).valueOrNull ?? const [],
      recipeGrinderId: _recipe.grinderId,
      recipeGrindStep: _recipe.grindStep,
      grinder: grinder,
    );

    return HeroSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Параметры', style: context.texts.bodyMedium),
          const SizedBox(height: AppSpacing.s2),
          _ParamRow(
            kind: MetricKind.dose,
            name: 'Доза',
            value: '${formatDecimal(_recipe.load)} г',
            changed: _changed('load'),
            onTap: () => _editDecimal(
              title: 'Доза',
              suffix: 'г',
              value: _recipe.load,
              apply: (value) => _recipe.load = value,
            ),
          ),
          _ParamRow(
            kind: MetricKind.water,
            name: 'Вода',
            value: '${_recipe.water} мл',
            changed: _changed('water'),
            onTap: () => _editInt(
              title: 'Вода',
              suffix: 'мл',
              value: _recipe.water,
              apply: (value) => _recipe.water = value,
            ),
          ),
          _ParamRow(
            kind: MetricKind.temperature,
            name: 'Температура',
            value: _recipe.temperature == null
                ? '—'
                : '${formatDecimal(_recipe.temperature!)} °C',
            changed: _changed('temperature'),
            onTap: () => _editDecimal(
              title: 'Температура',
              suffix: '°C',
              value: _recipe.temperature ?? 93,
              apply: (value) => _recipe.temperature = value,
            ),
          ),
          _ParamRow(
            kind: MetricKind.grind,
            name: 'Помол',
            caption: grind.caption,
            value: grind.isEmpty ? '—' : grind.label,
            changed: _changed('grind_step'),
            onTap: () => _editText(
              title: 'Помол',
              value: _recipe.grindStep,
              // Человек правит помол в делениях своей кофемолки, поэтому
              // вместе со значением запоминается и она: иначе следующая
              // отрисовка снова показала бы пересчитанное «примерно».
              apply: (value) {
                _recipe.grindStep = value;
                if (grinder != null) _recipe.grinderId = grinder.id;
              },
            ),
          ),
          // Соотношение не правится: оно производное от дозы и воды, и дать
          // его подвинуть значило бы завести второй способ задать одно и то же.
          _ParamRow(
            kind: MetricKind.time,
            icon: AppIcons.metricRatio,
            name: 'Соотношение',
            value: _ratio(),
            readOnly: true,
          ),
        ],
      ),
    );
  }

  String _ratio() {
    if (_recipe.load <= 0) return '—';
    return '1 : ${formatDecimal(_recipe.water / _recipe.load)}';
  }

  // ── Шаги ─────────────────────────────────────────────────────────────────

  Widget _steps() {
    final reference = ref.watch(stepTypesProvider).valueOrNull;

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _recipe.steps.length,
      onReorderItem: _reorder,
      itemBuilder: (context, index) {
        final step = _recipe.steps[index];
        return Padding(
          // Ключ по самому объекту шага, а не по индексу и не по названию:
          // при перестановке индексы меняются местами, а список опознаёт
          // строки как раз по ключам — с индексом в ключе он переставлял бы
          // не то, что тащат.
          key: ObjectKey(step),
          padding: const EdgeInsets.only(bottom: AppSpacing.s2),
          child: _StepRow(
            index: index,
            step: step,
            type: reference?.bySlug(step.stepType),
            open: _openStep == index,
            changed: _stepChanged(index),
            onToggle: () => setState(() => _openStep = _openStep == index ? null : index),
            onPickType: () => _pickType(index),
            onWaterChanged: (value) => setState(() => step.water = value),
            onEditTime: () => _editDuration(step),
            onEditText: () => _editStepText(step),
            onRemove: () => _removeStep(index),
          ),
        );
      },
    );
  }

  /// `onReorderItem`, а не `onReorder`: он отдаёт уже поправленный индекс —
  /// у старого приходилось самому вычитать единицу при движении вниз, и это
  /// ровно то место, где список тихо переставлял не тот шаг.
  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final step = _recipe.steps.removeAt(oldIndex);
      _recipe.steps.insert(newIndex, step);
      _renumber();
      _openStep = null;
    });
  }

  /// Порядковые номера пересобираются после каждой перестановки: они уезжают
  /// на бэк как есть, и рецепт с двумя третьими шагами там не соберётся.
  void _renumber() {
    for (var i = 0; i < _recipe.steps.length; i++) {
      _recipe.steps[i].seqNum = i + 1;
    }
  }

  Future<void> _addStep(BrewMethod? method) async {
    final pick = await showStepTypeSheet(
      context,
      allowedStepTypes: method?.allowedStepTypes ?? const [],
      brewMethodId: method?.id ?? 0,
      methodName: method?.name,
    );
    if (pick == null || !mounted) return;

    final blank = await _stepFromPick(pick, method);
    if (blank == null || !mounted) return;

    setState(() {
      blank.seqNum = _recipe.steps.length + 1;
      _recipe.steps.add(blank);
      _openStep = _recipe.steps.length - 1;
    });
  }

  /// Заготовка шага из того, что выбрали в листе.
  ///
  /// «Новый» сначала уводит в форму своего типа: шаг появится, только если
  /// заготовку сохранили. null — человек передумал.
  Future<RecipeStep?> _stepFromPick(StepTypePick pick, BrewMethod? method) async {
    switch (pick) {
      case BuiltInStepPick(:final type):
        return RecipeStep(
          seqNum: 0,
          instruction: type.name,
          water: 0,
          time: 0,
          id: 0,
          stepType: type.slug,
          stepKey: '',
          tip: '',
          isOptional: false,
          untilUser: false,
          untilSign: '',
          warning: type.warning,
        );

      case UserStepPick(:final type):
        return RecipeStep(
          seqNum: 0,
          instruction: type.label,
          water: 0,
          time: 0,
          id: 0,
          stepType: 'custom',
          stepKey: '',
          tip: '',
          isOptional: false,
          untilUser: type.endsWith != StepEndsWith.timer,
          untilSign: '',
          warning: type.warning,
        );

      case CustomStepPick():
        final created = await context.router.push<UserStepType>(
          CustomStepRoute(brewMethodId: method?.id ?? 0, methodName: method?.name),
        );
        if (created == null) return null;
        return RecipeStep(
          seqNum: 0,
          instruction: created.label,
          water: 0,
          time: 0,
          id: 0,
          stepType: 'custom',
          stepKey: '',
          tip: '',
          isOptional: false,
          untilUser: created.endsWith != StepEndsWith.timer,
          untilSign: '',
          warning: created.warning,
        );
    }
  }

  Future<void> _pickType(int index) async {
    final step = _recipe.steps[index];
    final pick = await showStepTypeSheet(
      context,
      allowedStepTypes: _method?.allowedStepTypes ?? const [],
      currentSlug: step.stepType,
      brewMethodId: _method?.id ?? 0,
      methodName: _method?.name,
    );
    if (pick == null || !mounted) return;

    final replacement = await _stepFromPick(pick, _method);
    if (replacement == null || !mounted) return;

    setState(() {
      // Подпись меняется вместе с типом только если её не правили руками:
      // человек, назвавший шаг «долить до 250», не должен потерять это
      // название из-за смены типа с пролива на долив.
      final untouched = step.instruction.isEmpty || _isTypeName(step.instruction);
      step.stepType = replacement.stepType;
      if (untouched) step.instruction = replacement.instruction;
      if (step.warning.isEmpty) step.warning = replacement.warning;
      // Чем шаг кончается — свойство типа, а не набранное человеком: старый
      // признак от прежнего типа пережил бы смену и врал бы в строке.
      step.untilUser = replacement.untilUser;
      step.untilSign = replacement.untilSign;
      // Вода переживала смену типа: на паузе оставались «2 г» от пролива,
      // и они же попадали в итог, хотя ни в какой чашке их уже нет.
      dropStrayWater(_recipe);
    });
  }

  bool _isTypeName(String instruction) {
    final reference = ref.read(stepTypesProvider).valueOrNull;
    if (reference == null) return false;
    return reference.types.any((type) => type.name == instruction);
  }

  void _removeStep(int index) {
    setState(() {
      _recipe.steps.removeAt(index);
      _renumber();
      _openStep = null;
    });
  }

  // ── Итоги ────────────────────────────────────────────────────────────────

  Widget _totals() {
    return QuietSurface(
      child: Column(
        children: [
          Row(
            children: [
              AppIcon(
                _waterMismatch ? AppIcons.uiWarning : AppIcons.uiCheck,
                size: AppSizes.icon20,
                color: _waterMismatch ? context.colors.error : context.palette.success,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(child: Text('Вода по шагам', style: context.texts.bodySmall)),
              Text(
                '$_stepWater из ${_recipe.water} г',
                style: context.texts.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Divider(height: AppSpacing.s6, color: context.palette.border),
          Row(
            children: [
              AppIcon(AppIcons.metricTime, size: AppSizes.icon20, color: context.colors.secondary),
              const SizedBox(width: AppSpacing.s3),
              Expanded(child: Text('Общее время', style: context.texts.bodySmall)),
              Text(
                formatDuration(_totalTime),
                style: context.texts.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Что изменила система ─────────────────────────────────────────────────

  void _undoCorrection() {
    setState(() {
      _recipe = copyRecipe(widget.original!);
      _corrected = false;
      _openStep = null;
    });
  }

  bool _changed(String key) {
    if (!_showsCorrection) return false;
    final was = widget.original!;
    return switch (key) {
      'load' => was.load != _recipe.load,
      'water' => was.water != _recipe.water,
      'temperature' => was.temperature != _recipe.temperature,
      'grind_step' => was.grindStep != _recipe.grindStep,
      _ => false,
    };
  }

  /// Шаг сравнивается со своим прежним состоянием по номеру в списке.
  ///
  /// Не по `id`: у шага, добавленного здесь же, идентификатора ещё нет, а
  /// нумерация в момент показа поправки совпадает с исходной — переставлять
  /// шаги человек начинает уже после того, как увидел точки.
  bool _stepChanged(int index) {
    if (!_showsCorrection) return false;
    final was = widget.original!.steps;
    if (index >= was.length) return true;
    final before = was[index];
    final now = _recipe.steps[index];
    return before.time != now.time ||
        before.water != now.water ||
        before.stepType != now.stepType;
  }

  // ── Правка значений ──────────────────────────────────────────────────────

  Future<void> _editInt({
    required String title,
    required String suffix,
    required int value,
    required void Function(int) apply,
  }) async {
    final result = await _askNumber(title: title, suffix: suffix, initial: '$value');
    if (result == null) return;
    setState(() => apply(result.round()));
  }

  Future<void> _editDecimal({
    required String title,
    required String suffix,
    required double value,
    required void Function(double) apply,
  }) async {
    final result = await _askNumber(
      title: title,
      suffix: suffix,
      initial: formatDecimal(value),
      decimal: true,
    );
    if (result == null) return;
    setState(() => apply(result));
  }

  Future<double?> _askNumber({
    required String title,
    required String suffix,
    required String initial,
    bool decimal = false,
  }) {
    final controller = TextEditingController(text: initial);

    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]')),
          ],
          decoration: InputDecoration(suffixText: suffix),
          onSubmitted: (text) => Navigator.of(context).pop(parseNumber(text)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(parseNumber(controller.text)),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  Future<void> _editDuration(RecipeStep step) async {
    final seconds = await showDurationSheet(context, seconds: step.time);
    if (seconds == null || !mounted) return;
    setState(() => step.time = seconds);
  }

  Future<void> _editText({
    required String title,
    required String value,
    required void Function(String) apply,
  }) async {
    final controller = TextEditingController(text: value);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (text) => Navigator.of(context).pop(text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Готово'),
          ),
        ],
      ),
    );

    if (result == null) return;
    setState(() => apply(result));
  }

  Future<void> _editStepText(RecipeStep step) async {
    final name = TextEditingController(text: step.instruction);
    final tip = TextEditingController(text: step.tip);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Шаг'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: AppSpacing.s3),
            TextField(
              controller: tip,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Подсказка'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Готово'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    setState(() {
      step.instruction = name.text.trim();
      step.tip = tip.text.trim();
    });
  }

  // ── Действия ─────────────────────────────────────────────────────────────

  /// Спрашивает, точно ли уходим, пока правки не сохранены.
  ///
  /// Экран открывается и с уже применённой поправкой — уйти с него молча
  /// значит выбросить её вместе со всем, что человек поправил руками.
  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Уйти без сохранения?'),
        content: const Text('Правки не сохранены — новая версия не появится.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Остаться'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Уйти'),
          ),
        ],
      ),
    );

    return leave ?? false;
  }

  Future<void> _leave() async {
    if (await _confirmLeave() && mounted) {
      await context.router.maybePop();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final savedId = await _service.evolveRecipe(_recipe);
      if (!mounted) return;
      setState(() {
        // С сервера приезжает только идентификатор новой версии. Шаги на
        // экране уже те, что уехали, — перечитывать их незачем, а «Заварить»
        // после сохранения должно вести на сохранённое, а не на прежнее.
        _recipe.id = savedId;
        _savedId = savedId;
        _saving = false;
        _corrected = false;
        _saved = jsonEncode(_recipe.toJson());
      });
      _say(savedId < 0
          ? 'Сохранено на телефоне — уедет, когда появится связь'
          : 'Сохранено новой версией');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _say('Не сохранилось: $error');
    }
  }

  void _brew() {
    // Рецепт целиком перед глазами — «Заварить» начинает сразу, без
    // повторного экрана подготовки.
    context.router.push(BrewRoute(recipe: _recipe, pack: widget.pack, autoStart: true));
  }


  void _say(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

/// Строка «поправлено под …» с отменой. Всё, что осталось от диффа.
class _CorrectionRow extends StatelessWidget {
  const _CorrectionRow({required this.label, required this.onUndo});

  final String label;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return QuietSurface(
      child: Row(
        children: [
          AppIcon(AppIcons.uiInfo, size: AppSizes.icon20, color: context.colors.primary),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Поправлено под «$label»', style: context.texts.bodySmall),
                Text('изменения помечены точкой', style: context.texts.labelSmall),
              ],
            ),
          ),
          TextButton(onPressed: onUndo, child: const Text('Отменить')),
        ],
      ),
    );
  }
}

/// Строка параметра: иконка, название, значение в поле для тапа.
class _ParamRow extends StatelessWidget {
  const _ParamRow({
    required this.kind,
    required this.name,
    required this.value,
    this.caption,
    this.icon,
    this.changed = false,
    this.readOnly = false,
    this.onTap,
    this.control,
  });

  final MetricKind kind;
  final String name;
  final String value;
  final String? caption;
  final String? icon;
  final bool changed;
  final bool readOnly;
  final VoidCallback? onTap;

  /// Чем значение правится, если тапом по числу этого не сделать: счётчик
  /// с плюсом и минусом вместо поля. Задано — [value] не показывается,
  /// число рисует само управление.
  final Widget? control;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.tapTarget),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      child: Row(
        children: [
          AppIcon(icon ?? kind.icon, size: AppSizes.icon20, color: kind.color(context)),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.texts.bodyMedium),
                if (caption != null)
                  Text(caption!, style: context.texts.labelSmall),
              ],
            ),
          ),
          if (control != null)
            control!
          else if (readOnly)
            Text(value, style: context.texts.bodyMedium?.copyWith(color: context.colors.secondary))
          else
            _ValueBox(value: value, changed: changed, onTap: onTap),
        ],
      ),
    );
  }
}

/// Значение параметра. Тап по числу открывает ввод — стрелок ± нет: на
/// четырёх параметрах подряд они превращали экран в калькулятор.
class _ValueBox extends StatelessWidget {
  const _ValueBox({required this.value, this.changed = false, this.onTap});

  final String value;
  final bool changed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.small,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: AppSpacing.s18),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s1,
            ),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: AppRadius.small,
              border: Border.all(color: context.palette.border),
            ),
            child: Text(
              value,
              style: context.texts.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
          if (changed)
            Positioned(
              top: -AppSpacing.s1 / 2,
              right: -AppSpacing.s1,
              child: Container(
                height: AppSpacing.s2,
                width: AppSpacing.s2,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Строка шага: свёрнутая — ручка, значок, название и величины; раскрытая —
/// ещё и то, чем её править.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.step,
    required this.type,
    required this.open,
    required this.changed,
    required this.onToggle,
    required this.onPickType,
    required this.onWaterChanged,
    required this.onEditTime,
    required this.onEditText,
    required this.onRemove,
  });

  final int index;
  final RecipeStep step;
  final StepType? type;
  final bool open;
  final bool changed;
  final VoidCallback onToggle;
  final VoidCallback onPickType;
  final ValueChanged<int> onWaterChanged;
  final VoidCallback onEditTime;
  final VoidCallback onEditText;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final icon = AppIcons.step(type?.iconKey ?? step.stepType);
    final accent = context.colors.primary;

    // Цветом воды помечены только те шаги, которые её льют. У паузы и ремарки
    // воды нет, и синий значок обещал бы то, чего на шаге не происходит.
    final iconColor =
        stepTakesWater(step) && step.water > 0 ? context.metrics.water : context.colors.onSurface;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s3),
      borderColor: open ? accent : null,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.s2),
                    child: AppIcon(
                      AppIcons.uiDrag,
                      size: AppSizes.icon20,
                      color: context.colors.secondary,
                    ),
                  ),
                ),
                AppIcon(icon, size: AppSizes.icon20, color: iconColor),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Text(
                    step.instruction.isEmpty ? (type?.name ?? 'Шаг') : step.instruction,
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: open ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(stepSummary(step), style: context.texts.labelSmall),
                if (changed) ...[
                  const SizedBox(width: AppSpacing.s2),
                  Container(
                    height: AppSpacing.s2,
                    width: AppSpacing.s2,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                ],
                const SizedBox(width: AppSpacing.s2),
                AppIcon(
                  open ? AppIcons.uiChevronUp : AppIcons.uiChevronDown,
                  size: AppSizes.icon20,
                  color: context.colors.secondary,
                ),
              ],
            ),
          ),
          if (open) ...[
            Divider(height: AppSpacing.s6, color: context.palette.border),
            Row(
              children: [
                Expanded(child: Text('Тип шага', style: context.texts.labelSmall)),
                TextButton(onPressed: onPickType, child: Text(type?.name ?? 'выбрать')),
              ],
            ),
            // Вода — только у тех типов, что её льют. У остальных поле
            // предлагало набрать число, которое всё равно уедет в мусор.
            if (stepTakesWater(step))
              _ParamRow(
                kind: MetricKind.water,
                // Не «Вода на шаге»: со счётчиком строка занимает 176 точек
                // справа, и на 360 подпись переехала бы на вторую строку.
                // Внутри карточки шага другой воды всё равно нет.
                name: 'Вода',
                value: '${step.water} г',
                control: AmountStepper(
                  value: step.water,
                  suffix: 'г',
                  onChanged: onWaterChanged,
                ),
              ),
            // У шага, который ждёт человека, длительность не отсчёт, а
            // выдумка: показываем, чем он кончается, и править там нечего.
            if (stepEndsByUser(step))
              _ParamRow(
                kind: MetricKind.time,
                icon: AppIcons.uiForward,
                name: 'Заканчивается',
                value: stepEnding(step).label,
                readOnly: true,
              )
            else
              _ParamRow(
                kind: MetricKind.time,
                name: 'Длительность',
                value: formatDuration(step.time),
                onTap: onEditTime,
              ),
            const SizedBox(height: AppSpacing.s2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    step.tip.isEmpty ? 'Подсказки нет' : 'Подсказка · ${step.tip}',
                    style: context.texts.labelSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onEditText,
                  icon: const AppIcon(AppIcons.uiEdit, size: AppSizes.icon20),
                  tooltip: 'Править',
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: AppIcon(
                    AppIcons.uiTrash,
                    size: AppSizes.icon20,
                    color: context.colors.error,
                  ),
                  tooltip: 'Убрать шаг',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Что шаг умеет ──────────────────────────────────────────────────────────
//
// Предикаты живут здесь функциями, а не геттерами в модели: RecipeStep
// собирает кодогенератор, и дописанное в него пропадёт на следующей сборке.
// Экран заваривания задаёт те же вопросы — правило должно быть одно, иначе
// конструктор обещает одно, а плеер делает другое.

/// Шаг заканчивается человеком, а не таймером.
///
/// Признак без флага — тоже человек: что воронка опустела, видит он, а
/// приложение об этом не узнаёт никак, и таймер там в лучшем случае
/// ориентир. Ровно так же эти два поля читает общий предикат `endsByHuman`
/// из `domain/step_ending.dart` — расходиться с ним нельзя, иначе шаг,
/// заведённый как «по кнопке», в плеере промотается сам.
bool stepEndsByUser(RecipeStep step) => step.untilUser || step.untilSign.isNotEmpty;

/// Шаг действительно льёт воду.
///
/// Правило то же, что у плеера: [BrewStep.fromResponse] приписывает воду
/// только четырём типам, а у остальных обнуляет. Считать здесь иначе значит
/// показывать итог, которого в чашке не будет.
bool stepTakesWater(RecipeStep step) =>
    BrewStepType.fromWire(step.stepType).addsWater;

/// Чем шаг кончается — тем же перечислением, что и форма своего типа шага:
/// формулировки в конструкторе и в форме должны совпадать дословно.
///
/// Признак отличает «по признаку» от «по кнопке»: и то и другое ждёт
/// человека, но во втором случае он ждёт не себя, а воронку.
StepEndsWith stepEnding(RecipeStep step) {
  if (step.untilSign.isNotEmpty) return StepEndsWith.none;
  return step.untilUser ? StepEndsWith.user : StepEndsWith.timer;
}

/// Убирает воду у шагов, которые её не льют.
///
/// Вызывается при открытии рецепта и после каждой смены типа: поля для такой
/// воды на экране нет, а значение из прежнего типа осталось бы навсегда.
void dropStrayWater(RecipeData recipe) {
  for (final step in recipe.steps) {
    if (!stepTakesWater(step)) step.water = 0;
  }
}

/// Правая часть свёрнутой строки шага: вода и время.
///
/// У шага, который ждёт человека, вместо времени стоит то, чем он кончается:
/// «0:09» там ничего не отсчитывало и читалось как обещание таймера.
String stepSummary(RecipeStep step) {
  final parts = [
    if (stepTakesWater(step) && step.water > 0) '${step.water} г',
    if (stepEndsByUser(step))
      stepEnding(step).label
    else if (step.time > 0)
      formatDuration(step.time),
  ];
  return parts.join(' · ');
}

// ── Разбор и показ чисел ───────────────────────────────────────────────────
//
// Вынесено из виджетов: это единственная часть экрана, которую можно проверить
// тестом без запуска приложения, и единственная, где ошибка стоит рецепта.

/// Дробное число по-русски: запятая, и целое без хвоста. 16.0 → «16».
String formatDecimal(double value) {
  final rounded = (value * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return rounded.round().toString();
  return rounded.toStringAsFixed(1).replaceAll('.', ',');
}

/// Секунды в «м:сс». Часов не бывает даже у колд брю: там шаг в часах, но
/// показывается он отдельным экраном ожидания, а не строкой рецепта.
String formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$rest';
}

/// Число из того, что напечатали. Запятая и точка равноправны: клавиатура
/// на разных прошивках даёт разный разделитель, и это не повод отказать.
double? parseNumber(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

/// «м:сс» или просто секунды. Пустое и мусор дают null — значение не меняется.
int? parseDuration(String text) {
  final value = text.trim();
  if (value.isEmpty) return null;

  if (!value.contains(':')) return int.tryParse(value);

  final parts = value.split(':');
  if (parts.length != 2) return null;

  final minutes = int.tryParse(parts[0].isEmpty ? '0' : parts[0]);
  final seconds = int.tryParse(parts[1].isEmpty ? '0' : parts[1]);
  if (minutes == null || seconds == null) return null;

  return minutes * 60 + seconds;
}

