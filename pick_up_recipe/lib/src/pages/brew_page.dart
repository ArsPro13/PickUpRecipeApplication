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
//
// ── Устройство экрана ───────────────────────────────────────────────────────
//
// Сверху неподвижная рамка: прогресс шага бежит по её периметру, внутри —
// крупный таймер. Ниже прокручивается список шагов, и список сам подводит
// текущий шаг к верхнему краю. Раньше на этом месте стояли четыре плитки
// показателей и полоса общего прогресса: во время заваривания смотрят на
// оставшееся время, а доза и помол нужны были минуту назад, при подготовке.

import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/app_router.dart';
import '../features/brew_methods/application/brew_methods_state.dart';
import '../features/grinders/application/grinder_state.dart';
import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/application/last_brew_cache.dart';
import '../features/recipes/application/screen_wake.dart';
import '../features/recipes/application/step_types_state.dart';
import '../features/recipes/domain/models/grind_descriptor_model.dart';
import '../features/recipes/domain/brew_engine.dart';
import '../features/recipes/domain/brew_step.dart';
import '../features/recipes/domain/brew_template.dart';
import '../features/recipes/domain/models/recipe_data_model.dart';
import '../general_widgets/app_bottom_nav.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

/// Собирает шаги плеера из рецепта, пришедшего с сервера.
///
/// Тип шага, подсказка и признак необязательности передаются полностью: без
/// них плеер получал одни `custom` — то есть список одинаковых значков без
/// подсказок, хотя сервер всё это отдаёт.
List<BrewStep> brewStepsOf(RecipeData recipe) {
  return [
    for (final step in recipe.steps)
      BrewStep.fromResponse(
        seqNum: step.seqNum,
        instruction: step.instruction,
        timeSec: step.time,
        waterMl: step.water,
        stepType: step.stepType,
        stepKey: step.stepKey,
        tip: step.tip,
        isOptional: step.isOptional,
        untilUser: step.untilUser,
        untilSign: step.untilSign,
        warning: step.warning,
      ),
  ];
}

@RoutePage()
class BrewPage extends ConsumerStatefulWidget {
  const BrewPage({
    super.key,
    required this.recipe,
    required this.pack,
    this.autoStart = false,
  });

  final RecipeData recipe;
  final PackData? pack;

  /// Начать сразу, без idle-состояния «Смолол, начинаем».
  ///
  /// true у входов с экранов, где рецепт целиком уже был перед глазами
  /// (базовый рецепт, конструктор): там «Заварить» и есть «начинаем», а
  /// повтор той же подготовки читался как лишний экран. У входов из списков
  /// подготовка остаётся: помол человек ещё не видел.
  final bool autoStart;

  @override
  ConsumerState<BrewPage> createState() => _BrewPageState();
}

class _BrewPageState extends ConsumerState<BrewPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final BrewEngine _engine = BrewEngine(steps: brewStepsOf(widget.recipe));

  /// Тикер перерисовки. Он не считает время — только просит движок отдать
  /// снимок, поэтому пропущенный кадр ничего не ломает.
  ///
  /// Кадровый, а не секундный: раз в секунду линия прогресса прыгала
  /// заметными ступеньками, и заваривание выглядело дёргающимся, хотя
  /// время считалось верно.
  late final Ticker _frames = createTicker((_) => _tick());

  /// Отложенный переход на оценку. Отдельно от тикера: тикер уже остановлен,
  /// когда этот заведён.
  Timer? _toRating;

  /// Живой снимок для тех, кому нужен каждый кадр. Линия по периметру рамки
  /// перерисовывается по нему напрямую, не перестраивая ни одного виджета:
  /// шестьдесят перестроек списка шагов в секунду — цена без выгоды.
  late final ValueNotifier<BrewSnapshot> _live =
      ValueNotifier<BrewSnapshot>(_engine.snapshot());

  BrewSnapshot get _snapshot => _live.value;

  /// Секунда, показанная крупным таймером. Виджеты перестраиваются, только
  /// когда она сменилась, — цифра всё равно меняется раз в секунду.
  int _shownSecond = -1;

  final ScrollController _steps = ScrollController();

  /// Шаг, к которому список уже подведён. Нужен, чтобы не дёргать прокрутку
  /// каждую секунду — только на смене шага.
  int? _scrolledTo;

  /// Когда приложение ушло в фон при идущем заваривании.
  DateTime? _wentBackground;

  /// Показать экран возврата (S09/S10): отсутствовали дольше, чем длится
  /// текущий шаг (порог из ответа C3).
  bool _showResume = false;

  /// Сколько нас не было — для заголовка «Прошло 4 минуты».
  Duration _awayFor = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Последний открытый рецепт переживает пропажу сети (ответ C5): офлайн
    // покажут его. Пишется при входе — дальше сети может уже не быть.
    LastBrewCache.save(widget.recipe, widget.pack);

    // Пока этот экран открыт, телефон не засыпает: рецепт с паузой в
    // пятьдесят секунд иначе гаснет ровно на ней.
    ScreenWake.keepAwake(true);

    if (widget.autoStart && _engine.steps.isNotEmpty) {
      _engine.start();
      _live.value = _engine.snapshot();
      _syncFrames();
    }
  }

  @override
  void dispose() {
    ScreenWake.keepAwake(false);
    WidgetsBinding.instance.removeObserver(this);
    _frames.dispose();
    _live.dispose();
    _toRating?.cancel();
    _steps.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _snapshot.isRunning) {
      _wentBackground = DateTime.now();
      return;
    }

    // Возвращение из фона — это просто ещё один запрос снимка: движок сам
    // знает, сколько прошло по настенным часам.
    if (state == AppLifecycleState.resumed) {
      final left = _wentBackground;
      _wentBackground = null;

      if (left != null) {
        final away = DateTime.now().difference(left);
        final threshold = _snapshot.stepDuration;

        // Ушёл на десять секунд из паузы в тридцать — вернулся молча; ушёл
        // на четыре минуты — экран спрашивает, что случилось (ответ C3).
        if (away > threshold && threshold > Duration.zero) {
          _awayFor = away;
          _showResume = true;
        }
      }
      _refresh();
    }
  }

  /// Кадр: снимок обновляется всегда, виджеты — только когда изменилось то,
  /// что они показывают.
  void _tick() {
    if (!mounted) return;

    final previous = _live.value;
    final next = _engine.snapshot();
    _live.value = next;

    final second = next.remainingInStep.inSeconds;
    if (next.stepIndex != previous.stepIndex ||
        next.status != previous.status ||
        second != _shownSecond) {
      // Смена шага — единственный момент, когда человек обязан заметить
      // экран. На кухне шумно, звук теряется, а телефон в кармане фартука
      // чувствуется. Вибрация только на смене шага и на финале: чаще —
      // и её начнут игнорировать.
      if (next.stepIndex != previous.stepIndex ||
          (next.isFinished && !previous.isFinished)) {
        HapticFeedback.mediumImpact();
      }

      _shownSecond = second;
      setState(() {});
      _followActiveStep();
    }

    // Кадры нужны только идущему завариванию: у ждущего шага и после финала
    // картинка стоит на месте.
    if (!next.isRunning) _stopFrames();

    // Пока открыт экран возврата, на оценку не уводим: человек ещё не
    // сказал, что заваривание вообще состоялось.
    if (next.isFinished && !_showResume) _scheduleRating();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _live.value = _engine.snapshot());
    _syncFrames();
    if (_snapshot.isFinished && !_showResume) _scheduleRating();
    _followActiveStep();
  }

  /// Уводит на оценку, когда рецепт доигран, — сам, без нажатия.
  ///
  /// Не мгновенно: последняя секунда истекает, когда человек ещё держит чайник
  /// над воронкой, и экран, подменившийся под рукой, читается как сбой. Две
  /// секунды «готово» — ровно то время, за которое чайник ставят на стол.
  ///
  /// Кнопка «Оценить» остаётся: она для тех, кто не хочет ждать эти две
  /// секунды, и для случая, когда заваривание закончили пропуском шагов.
  void _scheduleRating() {
    if (_toRating != null) return;
    _toRating = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _rate();
    });
  }

  /// Подводит текущий шаг к верхнему краю списка.
  ///
  /// Пройденные шаги уходят вверх, но остаются достижимыми прокруткой назад:
  /// человек может захотеть перечитать подсказку предыдущего шага.
  void _followActiveStep() {
    if (!_steps.hasClients || _snapshot.isFinished) return;
    if (_scrolledTo == _snapshot.stepIndex) return;

    _scrolledTo = _snapshot.stepIndex;
    final target = (_snapshot.stepIndex * _StepCard.height)
        .clamp(0.0, _steps.position.maxScrollExtent);

    _steps.animateTo(target, duration: AppDuration.base, curve: AppCurves.out);
  }

  /// Идёт ли заваривание прямо сейчас.
  ///
  /// «Идёт» — это и пауза тоже: человек, поставивший на паузу, чтобы долить
  /// чайник, заваривания не бросал.
  bool get _brewing => _engine.isStarted && !_snapshot.isFinished;

  /// Спрашивает, точно ли уходим с идущего заваривания.
  ///
  /// Кнопка «назад» на телефоне лежит там же, где палец держит корпус, и
  /// мокрой рукой нажимается сама. Без вопроса одно касание стирало отсчёт
  /// посреди пролива — вернуться в ту же секунду уже нельзя.
  Future<bool> _confirmLeave() async {
    if (!_brewing) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Прервать заваривание?'),
        content: const Text(
          'Отсчёт остановится, и вернуться к нему на этой же секунде не выйдет.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Остаться'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Прервать'),
          ),
        ],
      ),
    );

    return leave ?? false;
  }

  /// Уход стрелкой в шапке — через тот же вопрос, что и кнопкой телефона.
  Future<void> _leave() async {
    if (await _confirmLeave() && mounted) {
      await context.router.maybePop();
    }
  }

  void _toggle() {
    if (!_engine.isStarted) {
      _engine.start();
    } else if (_snapshot.status == BrewStatus.paused) {
      _engine.resume();
    } else {
      _engine.pause();
    }
    _refresh();
  }

  /// Кадры идут только у идущего заваривания.
  ///
  /// До старта, на паузе, у шага, который ждёт человека, и после финала
  /// перерисовывать нечего, а ждать человека можно долго — тикер всё это
  /// время сажал бы батарею впустую.
  void _syncFrames() {
    if (_snapshot.isRunning) {
      _startFrames();
    } else {
      _stopFrames();
    }
  }

  void _startFrames() {
    if (!_frames.isActive) _frames.start();
  }

  void _stopFrames() {
    if (_frames.isActive) _frames.stop();
  }

  void _skip() {
    _engine.skipCurrentStep();
    _refresh();
  }

  /// «Сделал»: шаг, который ждал человека, закончен — время идёт дальше.
  void _confirm() {
    _engine.confirmCurrentStep();
    _refresh();
  }

  /// Уводит на оценку. Заменяет экран, а не кладёт поверх: возвращаться
  /// к отыгранному таймеру некуда, а «назад» из оценки должно вести в список.
  void _rate() {
    context.router.replace(RatingRoute(recipe: widget.recipe, pack: widget.pack));
  }

  /// Правка рецепта. Отдельного экрана рецепта больше нет — этот и есть
  /// рецепт, поэтому «Править» живёт здесь, в шапке.
  void _edit() {
    context.router.push(
      RecipeBuilderRoute(recipe: widget.recipe, pack: widget.pack),
    );
  }

  /// Вернулись к брошенному завариванию (S09/S10).
  ///
  /// Короткий метод: «столько кофе уже не стоит на месте» и три исхода —
  /// заново, продолжить, считать законченным. Длинный (колд брю) — другой
  /// смысл: «прошло 13 часов» там не ошибка, а норма, и предлагать «начать
  /// заново» значит предложить ещё двенадцать часов.
  Widget _resume() {
    final long = widget.recipe.time > 3600;
    final finishedWhileAway = _engine.snapshot().isFinished;
    final steps = _engine.steps;
    final stepLabel = steps[_snapshot.stepIndex.clamp(0, steps.length - 1)].label;

    return Scaffold(
      appBar: AppBar(
        title: Text(_methodName(), style: context.texts.bodySmall),
      ),
      bottomNavigationBar: const AppBottomNav(),
      body: _ResumeScreen(
        awayFor: _awayFor,
        stepLabel: stepLabel,
        long: long,
        finished: finishedWhileAway,
        onRestart: () {
          _engine.reset();
          _stopFrames();
          setState(() {
            _showResume = false;
            _live.value = _engine.snapshot();
          });
        },
        onContinue: () {
          // Время шло по настенным часам, и движок уже всё посчитал:
          // продолжить — значит просто посмотреть на текущее состояние.
          setState(() => _showResume = false);
          _refresh();
        },
        onFinish: () {
          setState(() => _showResume = false);
          _rate();
        },
      ),
    );
  }

  /// Шаблон экрана: чем определяется конец шага у этого метода.
  BrewTemplate get _template {
    String waterMeaning = 'poured';
    String groupSlug = '';

    for (final group in ref.read(brewMethodsProvider).grouped) {
      for (final method in group.methods) {
        if (method.slug == widget.recipe.device) {
          waterMeaning = method.waterMeaning;
          groupSlug = group.slug;
        }
      }
    }

    return resolveBrewTemplate(
      widget.recipe,
      waterMeaning: waterMeaning,
      methodGroup: groupSlug,
    );
  }

  /// Состояние прибора к текущему шагу: «Клапан закрыт», «Перевёрнут».
  ///
  /// Считается по пройденным шагам: состояние ставит последний из них,
  /// у чьего типа в справочнике непустой device_state. Шаг живёт пять
  /// секунд, состояние — минуту, поэтому строка закреплена, а не мелькает.
  String _deviceState() {
    final reference = ref.watch(stepTypesProvider).valueOrNull;
    if (reference == null) return '';

    var state = '';
    final upTo = _snapshot.stepIndex.clamp(0, _engine.steps.length - 1);
    for (var i = 0; i <= upTo; i++) {
      final type = reference.bySlug(_engine.steps[i].type.wireName);
      if (type != null && type.deviceState.isNotEmpty) state = type.deviceState;
    }
    return state;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _engine.steps;

    if (steps.isEmpty) return _empty();

    if (_showResume) return _resume();

    // Следим за справочником: шаблон и состояние прибора приезжают с ним.
    ref.watch(brewMethodsProvider);

    final current = steps[_snapshot.stepIndex.clamp(0, steps.length - 1)];
    final params = _params();
    final template = _template;
    final deviceState = template == BrewTemplate.valve ? _deviceState() : '';

    // Отдельной переменной, чтобы обернуть готовый экран в PopScope, не
    // сдвигая двести строк разметки.
    final screen = Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _leave,
          icon: const AppIcon(AppIcons.uiBack, size: AppSizes.icon24),
          tooltip: 'Назад',
        ),
        // Название прибора крупно: его читают от кофемолки, боком, и
        // мелкая подпись для этого не годится. Номер шага уехал в строку
        // параметров — там он рядом с числами, которые сверяют вместе с ним.
        title: Text(
          _methodName(),
          style: context.texts.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _edit,
            icon: const AppIcon(AppIcons.uiEdit, size: AppSizes.icon24),
            tooltip: 'Править рецепт',
          ),
        ],
        // Строка не меняется вместе с состоянием: она отвечает на вопрос
        // «не сбился ли я», а он одинаков и до старта, и на третьем проливе.
        // Меняющаяся справка заставляет её перечитывать каждый раз.
        bottom: params.isEmpty
            ? null
            : _ParamsStrip(
                params: params,
                step: 'шаг ${_snapshot.stepIndex + 1} из ${steps.length}',
              ),
      ),
      bottomNavigationBar: const AppBottomNav(),
      body: Column(
        children: [
          if (deviceState.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s5,
                vertical: AppSpacing.s2,
              ),
              color: context.colors.secondaryContainer,
              child: Row(
                children: [
                  AppIcon(
                    AppIcons.uiInfo,
                    size: AppSizes.icon20,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    deviceState,
                    style: context.texts.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s5,
              AppSpacing.s2,
              AppSpacing.s5,
              AppSpacing.s2,
            ),
            child: _BrewFrame(
              step: current,
              snapshot: _snapshot,
              live: _live,
              params: params,
              template: template,
            ),
          ),
          Expanded(
            child: _StepList(
              controller: _steps,
              steps: steps,
              snapshot: _snapshot,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s5,
                AppSpacing.s2,
                AppSpacing.s5,
                AppSpacing.s4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: switch (_snapshot.status) {
                        // До старта кнопка подтверждает подготовку, а не
                        // запускает таймер: рамка над ней просит смолоть,
                        // и «Начать» отвечало бы не на тот вопрос.
                        BrewStatus.idle => params.hasPrep ? 'Смолол, начинаем' : 'Начать',
                        BrewStatus.running => 'Пауза',
                        BrewStatus.paused => 'Продолжить',
                        // Шаг ждёт человека — и главная кнопка отвечает на
                        // вопрос «куда нажимать, когда сделал». Раньше на
                        // этом месте стояла «Пауза» при стоящем таймере.
                        BrewStatus.awaitingUser => 'Сделал',
                        // Заваривание кончилось — дальше оценка, а не тупик.
                        // Кнопка «Готово», которая ничего не делает, была
                        // концом пути: рецепт заварен и забыт.
                        BrewStatus.finished => 'Оценить',
                      },
                      icon: switch (_snapshot.status) {
                        BrewStatus.finished => AppIcons.uiStar,
                        BrewStatus.running => AppIcons.uiPause,
                        BrewStatus.awaitingUser => AppIcons.uiCheck,
                        _ => AppIcons.uiPlay,
                      },
                      onPressed: switch (_snapshot.status) {
                        BrewStatus.finished => _rate,
                        BrewStatus.awaitingUser => _confirm,
                        _ => _toggle,
                      },
                    ),
                  ),
                  if (_engine.isStarted && !_snapshot.isFinished) ...[
                    const SizedBox(width: AppSpacing.s3),
                    AppButton(
                      // У усилия и признака конец шага определяет человек,
                      // а не секундомер, — и кнопка называет это действие,
                      // а не извиняется словом «пропустить».
                      label: brewSkipLabel(current),
                      icon: AppIcons.uiForward,
                      kind: AppButtonKind.secondary,
                      block: false,
                      onPressed: _skip,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return PopScope(
      // Пока заваривание идёт, кнопка телефона не уводит молча: сначала
      // вопрос. Доигранный рецепт отпускает сразу — терять там нечего.
      canPop: !_brewing,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leave();
      },
      child: screen,
    );
  }

  /// Числа рецепта для строки и для рамки до старта.
  ///
  /// Имя кофемолки подставляется, только если рецепт записан в её делениях:
  /// у человека мельниц может быть две, и подписать чужие щелчки именем
  /// основной — соврать в единственном месте, где число нельзя перепутать.
  BrewParams _params() {
    final grinders = ref.watch(grinderStateProvider).userGrinders;

    String? name;
    for (final owned in grinders) {
      if (owned.grinder.id == widget.recipe.grinderId) {
        name = owned.grinder.name;
        break;
      }
    }

    // Справочник крупности может не успеть приехать — тогда в подписи
    // останется slug из рецепта. Некрасиво, но честно; пустое место на
    // его месте читалось бы как «помол неизвестен».
    final reference = ref.watch(grindDescriptorsProvider).valueOrNull;

    return BrewParams.of(
      widget.recipe,
      grinderName: name,
      descriptorName: reference == null
          ? null
          : grindDescriptorName(reference, widget.recipe.grindDescriptor),
      inCup: _template == BrewTemplate.shot,
    );
  }

  /// Название метода человеческим языком, если рецепт его знает.
  String _methodName() {
    if (widget.recipe.title.isNotEmpty) return widget.recipe.title;
    return widget.pack?.packName ?? widget.recipe.device;
  }

  /// Рецепт без шагов проигрывать нечего.
  ///
  /// Так бывает у исторических записей и у рецепта, собранного конструктором
  /// с ошибкой. Раньше экран в этом случае показывал пустую полосу прогресса
  /// и кнопку «Начать», которая ничего не начинала.
  Widget _empty() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const AppIcon(AppIcons.uiBack, size: AppSizes.icon24),
          tooltip: 'Назад',
        ),
        title: const Text('Заваривание'),
      ),
      bottomNavigationBar: const AppBottomNav(),
      body: AppState(
        icon: AppIcons.stateError,
        title: 'В рецепте нет шагов',
        description: 'Проигрывать нечего. Соберите рецепт заново или выберите другой.',
        isError: true,
        primaryAction: AppButton(
          label: 'Назад',
          kind: AppButtonKind.secondary,
          onPressed: () => context.router.maybePop(),
        ),
      ),
    );
  }
}

/// Постоянная строка параметров под шапкой.
///
/// Четыре числа, которые нельзя перепутать: доза, помол, вода, температура.
/// Порядок — порядок действий: сначала то, что взвешивают и мелют, потом то,
/// что наливают. `FittedBox` вместо переноса: строка обязана остаться одной
/// строкой, а на узком экране лучше уменьшить кегль, чем спрятать число.
class _ParamsStrip extends StatelessWidget implements PreferredSizeWidget {
  const _ParamsStrip({required this.params, required this.step});

  final BrewParams params;

  /// «шаг 2 из 5» — уехал сюда из шапки, к числам, с которыми его и сверяют.
  final String step;

  /// Кегль крупный намеренно: строку читают мельком, от кофемолки, боком —
  /// подпись в двенадцать пунктов для этого мелка. Тише содержимого она
  /// остаётся не размером, а цветом значков и отсутствием поверхности.
  static const double _height = 58;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, Color)>[
      if (params.dose != null) (AppIcons.metricDose, params.dose!, context.metrics.dose),
      if (params.grind != null) (AppIcons.metricGrind, params.grind!, context.metrics.grind),
      if (params.water != null) (AppIcons.metricWater, params.water!, context.metrics.water),
      if (params.temperature != null)
        (AppIcons.metricTemperature, params.temperature!, context.metrics.temperature),
    ];

    return Container(
      height: _height,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
      // Черта снизу, а не сверху: шапка в этом приложении прозрачная и лежит
      // на той же бумаге, что и содержимое, — линия нужна там, где строка
      // заканчивается и начинается заваривание.
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.palette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.s4),
                    AppIcon(items[i].$1, size: AppSizes.icon24, color: items[i].$3),
                    const SizedBox(width: AppSpacing.s1),
                    Text(
                      items[i].$2,
                      style: context.texts.titleMedium?.copyWith(
                        color: context.colors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Text(step, style: context.texts.bodySmall),
        ],
      ),
    );
  }
}

/// Вернулись к брошенному завариванию: три исхода, а не два (S09/S10).
class _ResumeScreen extends StatelessWidget {
  const _ResumeScreen({
    required this.awayFor,
    required this.stepLabel,
    required this.long,
    required this.finished,
    required this.onRestart,
    required this.onContinue,
    required this.onFinish,
  });

  final Duration awayFor;
  final String stepLabel;

  /// Метод на часы: колд брю, колд дрип. «Начать заново» тут не предлагаем.
  final bool long;

  /// Заваривание доиграло, пока нас не было.
  final bool finished;

  final VoidCallback onRestart;
  final VoidCallback onContinue;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final away = _awayLabel(awayFor);

    if (long) {
      // Колд брю: «прошло 13 часов» — норма. Не «вы бросили», а «уже готово».
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s4,
          AppSpacing.s5,
          AppSpacing.s8,
        ),
        children: [
          QuietSurface(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(AppIcons.uiCheck, size: AppSizes.icon20, color: context.colors.primary),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Text(
                    finished
                        ? 'Настаивание закончилось, пока приложение было закрыто. '
                            'Доделайте оставшиеся шаги — дальше кофе только горчит.'
                        : 'Настаивание идёт: прошло $away. Экран можно закрывать — '
                            'время считается по часам, а не по таймеру на экране.',
                    style: context.texts.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          AppButton(
            label: finished ? 'К оставшимся шагам' : 'Продолжить',
            icon: AppIcons.uiPlay,
            onPressed: onContinue,
          ),
          const SizedBox(height: AppSpacing.s3),
          AppButton(
            label: 'Считать законченным',
            kind: AppButtonKind.secondary,
            onPressed: onFinish,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s8,
      ),
      children: [
        AppState(
          icon: AppIcons.stepWait,
          title: 'Прошло $away',
          description: 'Вы остановились на шаге «$stepLabel». Столько кофе уже '
              'не стоит на месте: вода остыла, воронка проливается.',
        ),
        const SizedBox(height: AppSpacing.s5),
        _ResumeOption(
          icon: AppIcons.uiRefresh,
          title: 'Начать заново',
          note: 'Обычно правильный выбор: 15 г кофе дешевле испорченной чашки',
          onTap: onRestart,
        ),
        _ResumeOption(
          icon: AppIcons.uiPlay,
          title: 'Продолжить с этого места',
          note: 'Если вы всё это время лили и просто выключили экран',
          onTap: onContinue,
        ),
        _ResumeOption(
          icon: AppIcons.uiCheck,
          title: 'Считать законченным',
          note: 'Заварилось, но до оценки руки не дошли — оценим сейчас',
          onTap: onFinish,
        ),
      ],
    );
  }

  static String _awayLabel(Duration away) {
    if (away.inHours > 0) {
      final hours = away.inHours;
      final minutes = away.inMinutes.remainder(60);
      return minutes == 0 ? '$hours ч' : '$hours ч $minutes мин';
    }
    if (away.inMinutes > 0) {
      final minutes = away.inMinutes;
      final word = switch (minutes % 10) {
        1 when minutes % 100 != 11 => 'минута',
        2 || 3 || 4 when minutes % 100 < 12 || minutes % 100 > 14 => 'минуты',
        _ => 'минут',
      };
      return '$minutes $word';
    }
    return '${away.inSeconds} с';
  }
}

class _ResumeOption extends StatelessWidget {
  const _ResumeOption({
    required this.icon,
    required this.title,
    required this.note,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: InkWell(
        borderRadius: AppRadius.medium,
        onTap: onTap,
        child: QuietSurface(
          child: Row(
            children: [
              AppIcon(icon, size: AppSizes.icon20, color: context.colors.primary),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.texts.bodyMedium),
                    const SizedBox(height: AppSpacing.s1),
                    Text(note, style: context.texts.labelSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Рамка заваривания: прогресс шага по периметру и крупный таймер внутри.
///
/// Линия стартует с середины верхней грани, а не из угла: у середины есть
/// смысл — это двенадцать часов на циферблате, — а у угла его нет.
///
/// До старта та же рамка занята подготовкой: пока таймер не пошёл, показывать
/// ему нечего, а «сколько молоть и на чём» — единственный вопрос момента.
/// Отдельного экрана под это не заводится: главное место экрана отдаётся
/// главному вопросу и возвращается обратно, как только заваривание началось.
///
/// Шаблон меняет содержимое рамки, а не экран целиком: у «часов» вместо
/// отсчёта — время готовности, у «выстрела» секундомер считает вверх,
/// у «признака» время — ориентир, а не срок.
class _BrewFrame extends StatelessWidget {
  const _BrewFrame({
    required this.step,
    required this.snapshot,
    required this.live,
    required this.params,
    this.template = BrewTemplate.pour,
  });

  final BrewStep step;
  final BrewSnapshot snapshot;

  /// Покадровый снимок — только для линии прогресса: она перерисовывается
  /// без перестройки виджетов, поэтому едет плавно и ничего не стоит.
  final ValueListenable<BrewSnapshot> live;

  final BrewParams params;
  final BrewTemplate template;

  bool get _isPrep => snapshot.status == BrewStatus.idle && params.hasPrep;

  /// «Часы»: шаг длиннее получаса — показываем не отсчёт, а «готово в».
  bool get _clockStep =>
      template == BrewTemplate.long && step.duration > const Duration(minutes: 30);

  @override
  Widget build(BuildContext context) {
    final icon = _isPrep
        ? AppIcons.stepGrind
        : AppIcons.byKey('step-${step.type.wireName.replaceAll('_', '-')}') ??
            AppIcons.stepCustom;

    final hint = _isPrep ? params.prepHint : _subtitle();

    return AspectRatio(
      aspectRatio: 350 / 200,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.secondaryContainer,
          borderRadius: AppRadius.large,
          boxShadow: context.shadows.level2,
        ),
        child: CustomPaint(
          painter: _FrameProgressPainter(
            live: live,
            track: _isPrep ? context.colors.primary : context.palette.border,
            run: context.colors.primary,
            idle: snapshot.status == BrewStatus.idle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(
                  icon,
                  size: AppSizes.icon32,
                  color: _isPrep ? context.metrics.grind : context.metrics.water,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  _isPrep ? 'Смелите кофе' : step.label,
                  style: context.texts.titleLarge,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s1),
                // Доза и помол крупным кеглем таймера: до старта именно они
                // и есть то, что читают с расстояния вытянутой руки.
                if (_waitingLabel() case final waiting?)
                  Text(
                    waiting,
                    style: context.texts.headlineSmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _centralValue(),
                      style: context.texts.displayLarge?.copyWith(
                        height: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                if (hint != null) ...[
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    hint,
                    style: context.texts.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Что стоит в центре рамки, когда таймера там нет.
  ///
  /// У шага «пока не скажете сделал» длительности не существует, и ноль на
  /// главном месте экрана читается как сбой приложения. Если у шага задан
  /// признак окончания — показываем признак: он и есть ответ на вопрос
  /// «когда это кончится».
  ///
  /// null — ждать нечего, в центре будет число.
  String? _waitingLabel() {
    if (_isPrep || !step.endsByUser) return null;
    if (snapshot.status == BrewStatus.finished) return null;

    // Пока таймер-ориентир такого шага ещё идёт, в центре остаётся он:
    // время человеку тоже нужно.
    if (!snapshot.isAwaitingUser && step.duration > Duration.zero) return null;

    return step.untilSign.isNotEmpty ? step.untilSign : 'ждём вас';
  }

  /// Крупное число в центре рамки. Что это за число — решает шаблон.
  String _centralValue() {
    if (_isPrep) return params.prepValue!;

    final idle = snapshot.status == BrewStatus.idle;

    // «Выстрел»: секундомер вверх — следят за первой каплей на 5–7 секунде,
    // и «осталось 19» об этом не говорит ничего.
    if (template == BrewTemplate.shot && !idle) {
      return formatDuration(snapshot.elapsedInStep);
    }

    // «Часы»: к экрану вернутся через полдня, и важно не «осталось 11:58:03»,
    // а «готово в 08:40» — это число сверяют с будильником.
    if (_clockStep && !idle && snapshot.status != BrewStatus.finished) {
      final readyAt = DateTime.now().add(snapshot.remainingInStep);
      final hh = readyAt.hour.toString().padLeft(2, '0');
      final mm = readyAt.minute.toString().padLeft(2, '0');
      return 'в $hh:$mm';
    }

    return formatDuration(idle ? step.duration : snapshot.remainingInStep);
  }

  String _subtitle() {
    final water = snapshot.waterTotalG <= 0
        ? null
        : 'налито ${snapshot.waterPouredG.round()} из ${snapshot.waterTotalG.round()} г';

    // «Выстрел»: цель — вес напитка, вода тут не «наливается».
    if (template == BrewTemplate.shot && snapshot.waterTotalG > 0) {
      return switch (snapshot.status) {
        BrewStatus.idle => 'цель — ${snapshot.waterTotalG.round()} г в чашке',
        BrewStatus.finished => 'готово · ${snapshot.waterTotalG.round()} г в чашке',
        _ => 'цель — ${snapshot.waterTotalG.round()} г в чашке · первые капли на 5–7 с',
      };
    }

    // «По признаку»: секундомер — ориентир, конец шага слышно и видно.
    if (template == BrewTemplate.cue && snapshot.status == BrewStatus.running) {
      return water == null ? 'время — ориентир, смотрите на признак' : 'время — ориентир · $water';
    }

    // «Часы»: под «готово в 08:40» — когда это будет по-человечески.
    if (_clockStep && snapshot.status == BrewStatus.running) {
      return 'готово через ${_ResumeScreen._awayLabel(snapshot.remainingInStep)}';
    }

    final head = switch (snapshot.status) {
      BrewStatus.idle => 'шаг ещё не начат',
      BrewStatus.running => 'осталось',
      BrewStatus.paused => 'на паузе',
      BrewStatus.awaitingUser => 'нажмите «Сделал», когда закончите',
      BrewStatus.finished => 'готово',
    };

    // У ждущего шага подпись — указание, куда нажимать; дописывать к нему
    // граммы значит утопить указание в цифрах.
    if (snapshot.isAwaitingUser) return head;

    return water == null ? head : '$head · $water';
  }
}

/// Дорожка и бегущая линия по периметру рамки.
///
/// Перерисовывается от `live` напрямую (`super.repaint`), а не от перестройки
/// виджета: линия обязана ехать покадрово, а список шагов над ней — нет.
class _FrameProgressPainter extends CustomPainter {
  _FrameProgressPainter({
    required this.live,
    required this.track,
    required this.run,
    required this.idle,
  }) : super(repaint: live);

  final ValueListenable<BrewSnapshot> live;
  final Color track;
  final Color run;

  /// До старта дорожка пуста: показывать нечего, а линия в нуле выглядела бы
  /// как «уже началось».
  final bool idle;

  double get progress => idle ? 0 : live.value.stepProgress;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = AppRadius.l;
    const inset = AppStroke.thick;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
      const Radius.circular(radius),
    );

    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = track,
    );

    if (progress <= 0) return;

    // Периметр обходится с середины верхней грани по часовой стрелке.
    // Path.addRRect начинает с левого верхнего угла, поэтому путь строится
    // руками: сдвинуть готовый контур нечем.
    final path = _perimeterFromTopCenter(rect, radius);
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, metric) => sum + metric.length);

    var remaining = total * progress.clamp(0.0, 1.0);
    final line = Path();

    for (final metric in metrics) {
      if (remaining <= 0) break;
      final take = math.min(remaining, metric.length);
      line.addPath(metric.extractPath(0, take), Offset.zero);
      remaining -= take;
    }

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = run,
    );
  }

  Path _perimeterFromTopCenter(RRect rect, double radius) {
    final left = rect.left;
    final top = rect.top;
    final right = rect.right;
    final bottom = rect.bottom;
    final centerX = (left + right) / 2;

    return Path()
      ..moveTo(centerX, top)
      ..lineTo(right - radius, top)
      ..arcToPoint(Offset(right, top + radius), radius: Radius.circular(radius))
      ..lineTo(right, bottom - radius)
      ..arcToPoint(Offset(right - radius, bottom), radius: Radius.circular(radius))
      ..lineTo(left + radius, bottom)
      ..arcToPoint(Offset(left, bottom - radius), radius: Radius.circular(radius))
      ..lineTo(left, top + radius)
      ..arcToPoint(Offset(left + radius, top), radius: Radius.circular(radius))
      ..lineTo(centerX, top);
  }

  @override
  bool shouldRepaint(_FrameProgressPainter oldDelegate) {
    // Прогресс сюда не входит намеренно: за него отвечает `repaint`, и
    // сравнивать его здесь значило бы ждать перестройки виджета.
    return oldDelegate.run != run ||
        oldDelegate.track != track ||
        oldDelegate.idle != idle;
  }
}

/// Список шагов под неподвижной рамкой.
class _StepList extends StatelessWidget {
  const _StepList({
    required this.controller,
    required this.steps,
    required this.snapshot,
  });

  final ScrollController controller;
  final List<BrewStep> steps;
  final BrewSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    // Растушёвка сверху говорит, что там что-то есть: без неё список выглядит
    // начинающимся с текущего шага, и назад никто не прокручивает.
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black],
        stops: [0, 0.06],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s2,
          AppSpacing.s5,
          AppSpacing.s5,
        ),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final phase = brewPhaseOf(steps[index]);
          final newPhase = index == 0 || brewPhaseOf(steps[index - 1]) != phase;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок фазы ставится только на её первом шаге, и только
              // если фаз в рецепте больше одной: у трёхшагового дрип-пакета
              // разделители были бы длиннее самих шагов.
              if (newPhase && _hasPhases(steps)) _PhaseLabel(phase),
              _StepCard(step: steps[index], index: index, snapshot: snapshot),
            ],
          );
        },
      ),
    );
  }
}

/// Есть ли в рецепте больше одной фазы.
bool _hasPhases(List<BrewStep> steps) {
  final phases = <String>{for (final step in steps) brewPhaseOf(step)};
  return phases.length > 1;
}

/// Разделитель фазы: подпись и линия до края.
class _PhaseLabel extends StatelessWidget {
  const _PhaseLabel(this.phase);

  final String phase;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s2, bottom: AppSpacing.s2),
      child: Row(
        children: [
          Text(
            phase.toUpperCase(),
            style: context.texts.labelSmall?.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(child: Divider(color: context.palette.border, height: 1)),
        ],
      ),
    );
  }
}

/// Карточка шага: значок, подпись, время, вода и подсказка.
class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.index, required this.snapshot});

  /// Высота карточки вместе с отступом. Нужна прокрутке, чтобы подвести
  /// текущий шаг к верхнему краю, не измеряя список.
  ///
  /// Все карточки одной высоты намеренно: у шага может не быть ни воды, ни
  /// подсказки, и от «сжатых» строк список превращается в лесенку. Высота
  /// посчитана по самой полной карточке — подпись, метки и подсказка.
  static const double height = 116;

  final BrewStep step;
  final int index;
  final BrewSnapshot snapshot;

  bool get _isActive => snapshot.stepIndex == index && !snapshot.isFinished;
  bool get _isDone => snapshot.stepIndex > index || snapshot.isFinished;

  @override
  Widget build(BuildContext context) {
    final icon = AppIcons.byKey('step-${step.type.wireName.replaceAll('_', '-')}') ??
        AppIcons.stepCustom;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: AnimatedOpacity(
        duration: AppDuration.base,
        curve: AppCurves.out,
        opacity: _isDone ? 0.5 : 1,
        child: AnimatedContainer(
          duration: AppDuration.base,
          curve: AppCurves.out,
          height: height - AppSpacing.s2,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          decoration: BoxDecoration(
            color: context.colors.secondaryContainer,
            borderRadius: AppRadius.large,
            border: Border.all(
              color: _isActive ? context.colors.primary : Colors.transparent,
            ),
            boxShadow: _isActive ? context.shadows.level2 : context.shadows.level1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  AppIcon(
                    // Пройденный шаг помечается галочкой: тот же значок в
                    // зелёном читается как «идёт», а не как «сделано».
                    _isDone ? AppIcons.uiCheck : icon,
                    size: AppSizes.icon24,
                    color: _isDone
                        ? context.palette.success
                        : (_isActive ? context.metrics.water : context.colors.onSurface),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Text(
                      step.label,
                      style: context.texts.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Место справа отвечает на вопрос «сколько это длится».
                  // У шага, который ждёт человека, длительности нет, и «0:00»
                  // отвечало на этот вопрос неправдой — поэтому там стоит то,
                  // чем шаг кончится.
                  if (brewStepEndNote(step) case final note when note.isNotEmpty)
                    Text(
                      note,
                      style: context.texts.labelSmall?.copyWith(
                        color: context.colors.primary,
                      ),
                    )
                  else
                    Text(
                      _isActive
                          ? formatDuration(snapshot.remainingInStep)
                          : formatDuration(step.duration),
                      style: _isActive ? context.texts.bodySmall : context.texts.labelSmall,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s2),
              SizedBox(
                height: AppSizes.icon24,
                child: Row(
                  children: [
                    if (step.showsWater) ...[
                      MetricTag(kind: MetricKind.water, label: '${step.waterG.round()} г'),
                      const SizedBox(width: AppSpacing.s2),
                    ],
                    if (step.isOptional) ...[
                      const AppChip(label: 'не обязательно'),
                      const SizedBox(width: AppSpacing.s2),
                    ],
                    // Три механики конца шага — таймер, действие человека и
                    // признак — выглядели одинаково, хотя ведут себя
                    // по-разному. Отсюда вопрос «почему таймер стоит».
                    _EndMark(step: step),
                  ],
                ),
              ),
              if (step.warning.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s1),
                _WarningNote(text: step.warning),
              ] else if (step.tip.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s1),
                Row(
                  children: [
                    AppIcon(
                      AppIcons.stepNote,
                      size: AppSizes.icon16,
                      color: context.colors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.s1),
                    Expanded(
                      child: Text(
                        step.tip,
                        style: context.texts.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Фаза заваривания, к которой относится шаг.
///
/// Семь шагов Origami читаются как семь дел; те же семь, разбитые на три
/// фазы, — как три. Фаза выводится из типа шага: справочник её не хранит,
/// а порядок в рецепте всегда один и тот же — подготовка, заваривание, финал.
String brewPhaseOf(BrewStep step) {
  return switch (step.type) {
    BrewStepType.grind || BrewStepType.addIce => 'подготовка',
    BrewStepType.serve || BrewStepType.dilute || BrewStepType.removeFilter => 'финал',
    _ => 'заваривание',
  };
}

/// Надпись второй кнопки: чем закончить текущий шаг.
///
/// Раньше выбиралась по шаблону всего рецепта — и на шаге «пока не скажете
/// сделал» получалось «Пропустить», то есть слово, обещающее выбросить шаг,
/// а не подтвердить его. Шаблон отвечает за рецепт целиком, а на вопрос
/// «что я делаю прямо сейчас» отвечает шаг.
String brewSkipLabel(BrewStep step) {
  // На ждущем шаге «Сделал» уже стоит на главной кнопке, и второй остаётся
  // честный пропуск: шаг не сделан, а выброшен.
  if (step.endsByUser) return 'Пропустить';

  // Признак видно и слышно — «случилось» это про него.
  if (step.untilSign.isNotEmpty) return 'Случилось';

  return switch (step.type) {
    // Усилие руки: конец шага определяет рука, а не секундомер.
    BrewStepType.press ||
    BrewStepType.invert ||
    BrewStepType.flip =>
      'Сделал',
    _ => 'Пропустить',
  };
}

/// Коротко, на место таймера: чем кончается шаг, у которого нет длительности.
///
/// Пусто — показывать нечего: у шага есть время, и оно там и стоит.
String brewStepEndNote(BrewStep step) {
  if (step.showsDuration) return '';
  if (step.untilSign.isNotEmpty) return 'по признаку';
  if (step.endsByUser) return 'по кнопке';
  return '';
}

/// Чем шаг кончится: таймером, действием человека или признаком.
///
/// Молча ничего не показываем только у обычного шага по таймеру — там метка
/// была бы шумом: время и так стоит справа.
class _EndMark extends StatelessWidget {
  const _EndMark({required this.step});

  final BrewStep step;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (step) {
      _ when step.untilSign.isNotEmpty => (AppIcons.uiEye, step.untilSign),
      _ when step.untilUser => (AppIcons.uiCheck, 'пока не скажете «сделал»'),
      _ => (null, ''),
    };

    if (icon == null) return const SizedBox.shrink();

    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s2,
          vertical: AppSpacing.s1 / 2,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.rounded,
          color: context.colors.primary.withValues(alpha: 0.12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: AppSizes.icon16, color: context.colors.primary),
            const SizedBox(width: AppSpacing.s1),
            Flexible(
              child: Text(
                label,
                style: context.texts.labelSmall?.copyWith(color: context.colors.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Предупреждение обжарщика — пометкой на полях.
///
/// Красная плашка на шаге пугает и читается как ошибка приложения; полоска
/// на поле — как заметка на полях книги, которой она и является.
class _WarningNote extends StatelessWidget {
  const _WarningNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppStroke.thick,
          height: AppSizes.icon16,
          margin: const EdgeInsets.only(right: AppSpacing.s2),
          color: context.colors.tertiary,
        ),
        Expanded(
          child: Text(
            text,
            style: context.texts.labelSmall?.copyWith(color: context.colors.tertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Числа рецепта, которые нужны до старта и во время заваривания.
///
/// Собраны одним объектом, потому что показывают их два места сразу — строка
/// под шапкой и рамка до старта, — и расходиться им нельзя. Разбор вынесен
/// сюда же: это единственная часть экрана, которую можно проверить тестом.
///
/// Пустое поле означает «рецепт этого не знает»: у исторических записей нет
/// ни температуры, ни дескриптора помола, и подставлять вместо них
/// придуманное число хуже, чем не показывать ничего.
class BrewParams {
  const BrewParams({
    this.dose,
    this.grind,
    this.water,
    this.temperature,
    this.prepValue,
    this.prepHint,
  });

  /// Доза кофе: «15 г».
  final String? dose;

  /// Помол делениями кофемолки: «26 щ.».
  final String? grind;

  /// Вода: «250 мл».
  final String? water;

  /// Температура: «93 °C».
  final String? temperature;

  /// Крупная строка рамки до старта: «15 г · 26» или «15 г · 26 щ.».
  ///
  /// Без имени кофемолки «щ.» дописывается прямо сюда: подпись под этой
  /// строкой в таком случае пуста, и объяснять число будет нечему.
  final String? prepValue;

  /// Подпись под ней: «щелчков Comandante · средне-тонкий».
  final String? prepHint;

  /// Ни одного числа — строку и подготовку показывать не из чего.
  bool get isEmpty => dose == null && grind == null && water == null && temperature == null;

  /// Есть что молоть: доза или помол известны.
  bool get hasPrep => prepValue != null;

  /// Собирает параметры из рецепта.
  ///
  /// [grinderName] — имя кофемолки, в делениях которой записан помол. Его
  /// подставляют, только если это та самая кофемолка: помол в щелчках чужой
  /// мельницы — не то же число, и подписать его чужим именем значит соврать.
  ///
  /// [descriptorName] — крупность помола словом из справочника. В рецепте
  /// лежит slug (`medium_fine`), и без справочника на экране оказывалась
  /// английская строка посреди русского интерфейса.
  static BrewParams of(
    RecipeData recipe, {
    String? grinderName,
    String? descriptorName,
    bool inCup = false,
  }) {
    final dose = recipe.load > 0 ? '${formatAmount(recipe.load)} г' : null;
    final step = recipe.grindStep.trim();
    final grind = step.isEmpty ? null : '$step щ.';
    // У эспрессо-семейства вода — вес напитка в чашке, и «мл» тут врали бы
    // дважды: и единицей, и смыслом (water_meaning = in_cup).
    final water = recipe.water > 0 ? '${recipe.water} ${inCup ? 'г' : 'мл'}' : null;
    final temperature = recipe.temperature == null
        ? null
        : '${formatAmount(recipe.temperature!)} °C';

    final descriptor = (descriptorName ?? recipe.grindDescriptor).trim();
    final named = grinderName != null && grinderName.trim().isNotEmpty;

    // С именем кофемолки число щелчков объясняет подпись под ним, без имени
    // оно обязано объяснить себя само — поэтому там остаётся «щ.».
    final grindInPrep = named ? (step.isEmpty ? null : step) : grind;
    final prepValue = _join([dose, grindInPrep]);
    final prepHint = _join([
      if (named && step.isNotEmpty) 'щелчков ${grinderName.trim()}',
      if (descriptor.isNotEmpty) descriptor,
    ]);

    return BrewParams(
      dose: dose,
      grind: grind,
      water: water,
      temperature: temperature,
      prepValue: prepValue,
      prepHint: prepHint,
    );
  }
}

String? _join(List<String?> parts) {
  final kept = parts.whereType<String>().where((it) => it.isNotEmpty).toList();
  return kept.isEmpty ? null : kept.join(' · ');
}

/// Число без лишнего хвоста: 15 вместо 15.0, но 15,5 остаётся 15,5.
String formatAmount(double value) {
  final rounded = (value * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return rounded.round().toString();
  return rounded.toStringAsFixed(1).replaceAll('.', ',');
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
