// Плашка «Идёт заваривание» над списком.
//
// С экрана заваривания можно уйти, не останавливая его (6 ноября 2026), — и
// тогда должно быть место, где видно, что оно идёт, и откуда к нему вернуться.
// Владелец назвал это место сам: «чтобы рецепт появлялся на экране рецептов,
// даже если он не закончен». Плашка стоит там же, где «Оценка не дописана», и
// по той же причине: на главном экране, над списком, не уезжая при прокрутке.
//
// Таймер на плашке живой. Время считает движок по настенным часам, плашка
// раз в секунду только спрашивает у него снимок — как и сам экран заваривания.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../features/recipes/application/active_brew.dart';
import '../features/recipes/domain/brew_engine.dart';
import '../pages/brew_page.dart' show formatDuration;
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'app_icon.dart';
import 'app_kit.dart';
import 'brew_abort_dialog.dart';

/// Плашки идущих завариваний — по одной на каждое.
///
/// Обычно она одна. Две бывает, когда рядом с быстрой чашкой настаивается
/// колд брю: его двенадцать часов не должны ни мешать воронке, ни пропадать
/// из-за неё.
///
/// Смотрит прямо за `ActiveBrews.current`, а не через провайдер: запись пишет
/// экран заваривания, и второй источник правды между ними только разошёлся бы
/// с первым. Так же устроена плашка недописанной оценки.
class ActiveBrewPlate extends StatefulWidget {
  const ActiveBrewPlate({super.key});

  @override
  State<ActiveBrewPlate> createState() => _ActiveBrewPlateState();
}

class _ActiveBrewPlateState extends State<ActiveBrewPlate> {
  /// Записи вместе с поднятыми из них движками. Движок собирается один раз
  /// на запись, а не каждую секунду: разбирать шаги рецепта ради одной цифры
  /// таймера незачем.
  List<({ActiveBrew brew, BrewEngine engine})> _brews = const [];

  /// Секундный тик перерисовки. Заведён, только пока хоть одно заваривание
  /// идёт: на паузе и у шага, который ждёт человека, цифры стоят.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    ActiveBrews.current.addListener(_reload);
    _brews = _collect();
    _syncTicker();
  }

  @override
  void dispose() {
    ActiveBrews.current.removeListener(_reload);
    _ticker?.cancel();
    super.dispose();
  }

  /// Записи, которые удалось поднять. Побитая просто не показывается.
  List<({ActiveBrew brew, BrewEngine engine})> _collect() => [
        for (final brew in ActiveBrews.current.value)
          if (brew.toEngine() case final engine?) (brew: brew, engine: engine),
      ];

  void _reload() {
    if (!mounted) return;
    setState(() => _brews = _collect());
    _syncTicker();
  }

  void _syncTicker() {
    final running = _brews.any((it) => it.engine.snapshot().isRunning);

    if (!running) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }

    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      // Последнее идущее доиграло или встало у шага «сделал» — тикать больше
      // не о чем.
      _syncTicker();
    });
  }

  /// Крестик: идущее заваривание прерывается с вопросом, доигранное просто
  /// убирается — прерывать в нём уже нечего.
  Future<void> _close(ActiveBrew brew, BrewSnapshot snapshot) async {
    if (!snapshot.isFinished && !await confirmBrewAbort(context)) return;

    await ActiveBrews.remove(brew.key);
  }

  @override
  Widget build(BuildContext context) {
    if (_brews.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < _brews.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.s2),
            _Plate(
              brew: _brews[index].brew,
              snapshot: _brews[index].engine.snapshot(),
              steps: _brews[index].engine.steps.length,
              stepLabel: _stepLabel(_brews[index]),
              onClose: _close,
            ),
          ],
        ],
      ),
    );
  }

  /// Название шага, которого ждёт заваривание.
  ///
  /// Обычно это шаг, на котором оно стоит. Если же долгий шаг доиграл, пока
  /// человека не было, ждут уже не его, а следующего: «настаивание» на
  /// плашке «ждёт вас» читалось бы как «всё ещё настаивается».
  String _stepLabel(({ActiveBrew brew, BrewEngine engine}) item) {
    final steps = item.engine.steps;
    if (steps.isEmpty) return '';

    final snapshot = item.engine.snapshot();
    var index = snapshot.stepIndex.clamp(0, steps.length - 1);
    if (snapshot.isAwaitingUser &&
        index == item.brew.heldStep &&
        index < steps.length - 1) {
      index++;
    }

    return steps[index].label;
  }
}

/// Одно идущее заваривание: что с ним сейчас, сколько осталось и крестик.
class _Plate extends StatelessWidget {
  const _Plate({
    required this.brew,
    required this.snapshot,
    required this.steps,
    required this.stepLabel,
    required this.onClose,
  });

  final ActiveBrew brew;
  final BrewSnapshot snapshot;

  /// Сколько шагов в рецепте — для «шаг 2 из 5».
  final int steps;
  final String stepLabel;
  final Future<void> Function(ActiveBrew brew, BrewSnapshot snapshot) onClose;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    final (icon, title) = switch (snapshot.status) {
      BrewStatus.paused => (AppIcons.uiPause, texts.activeBrewPaused),
      BrewStatus.awaitingUser => (AppIcons.uiCheck, texts.activeBrewWaiting),
      BrewStatus.finished => (AppIcons.uiStar, texts.activeBrewFinished),
      _ => (AppIcons.uiPlay, texts.activeBrewRunning),
    };

    // Под заголовком — какое это заваривание и где оно сейчас. У шага,
    // который ждёт человека, вместо номера стоит само действие: «шаг 3 из 5»
    // не говорит, чего именно от него ждут.
    final where = switch (snapshot.status) {
      BrewStatus.finished => null,
      BrewStatus.awaitingUser => stepLabel,
      _ => texts.brewStepOf(snapshot.stepIndex + 1, steps),
    };
    final subtitle = [
      activeBrewName(brew),
      if (where != null && where.isNotEmpty) where,
    ].join(' · ');

    // Время — только пока оно что-то значит: у идущего шага и на паузе.
    final timed = snapshot.status == BrewStatus.running ||
        snapshot.status == BrewStatus.paused;
    final time = formatDuration(snapshot.remainingInStep);

    return AppCard(
      key: ValueKey('active-brew-${brew.key.hashCode}'),
      padding: const EdgeInsets.only(
        left: AppSpacing.s4,
        top: AppSpacing.s3,
        bottom: AppSpacing.s3,
      ),
      // Обводка цветом действия: плашка — не справка, а вход в идущий таймер.
      borderColor: context.colors.primary,
      onTap: () => context.router.push(
        BrewRoute(recipe: brew.recipe, pack: brew.pack),
      ),
      child: Row(
        children: [
          AppIcon(icon, size: AppSizes.icon20, color: context.colors.primary),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.texts.bodyMedium),
                // До двух строк, без многоточия на первой: «Бразилия
                // Можиана · Харио V60 (Hario V60) · шаг 2 из 6» в одну не
                // влезает, а обрезанный хвост — это как раз номер шага.
                Text(
                  subtitle,
                  style: context.texts.labelSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (timed) ...[
            const SizedBox(width: AppSpacing.s2),
            Text(
              time,
              key: const ValueKey('active-brew-time'),
              style: context.texts.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                // На паузе время стоит — и цветом не зовёт.
                color: snapshot.isRunning
                    ? context.colors.primary
                    : context.colors.secondary,
                // Цифры равной ширины: секунды меняются, а крестик рядом
                // стоять должен на месте.
                fontFeatures: AppFonts.tabularFor(time),
              ),
            ),
          ],
          IconButton(
            onPressed: () => onClose(brew, snapshot),
            tooltip: snapshot.isFinished ? texts.remove : texts.brewAbort,
            icon: AppIcon(
              AppIcons.uiClose,
              size: AppSizes.icon16,
              color: context.colors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Как назвать заваривание одной строкой: «Бразилия Можиана · Клевер».
///
/// Кофе и прибор, если известны оба: два заваривания подряд отличаются либо
/// одним, либо другим. Название рецепта чаще всего и есть название прибора;
/// пусто — остаётся его slug, это хуже имени и лучше пустой строки.
String activeBrewName(ActiveBrew brew) {
  final coffee = brew.pack?.packName.trim() ?? '';
  final title = brew.recipe.title.trim();
  final method = title.isNotEmpty ? title : brew.recipe.device;

  if (coffee.isEmpty || coffee == method) return method;
  return '$coffee · $method';
}
