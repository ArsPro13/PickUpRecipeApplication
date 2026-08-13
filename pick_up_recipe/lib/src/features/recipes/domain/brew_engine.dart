// Движок проигрывания рецепта.
//
// Подключён: на нём работает `brew_page.dart`, проверен `brew_engine_test.dart`.
// Прежняя шапка предупреждала об обратном — что движок написан в стороне и не
// компилировался, — и это перестало быть правдой на этапе 4.
//
// ── Зачем он вообще ─────────────────────────────────────────────────────────
//
// Нынешний BrewPage крутит один AnimationController на всю длительность
// рецепта. Из этого следуют три проблемы, и все три решаются одним решением:
//
//   1. При сворачивании приложения и блокировке экрана AnimationController
//      встаёт. Для колд брю на 12 часов это неприменимо в принципе.
//   2. Пауза не сохраняет состояние: уход с экрана теряет прогресс.
//   3. Прогресс накапливается кадрами, поэтому пропущенные кадры — потерянное
//      время.
//
// Решение: **состояние вычисляется из абсолютных меток времени**, а не
// накапливается по кадрам. Движок не хранит «сколько уже прошло» — он хранит
// «когда началось» и «сколько суммарно стояли на паузе», а текущее состояние
// считает функцией от переданного момента времени.
//
// Отсюда следствия, которые и были целью:
//   • сворачивание приложения перестаёт быть особым случаем — время идёт само;
//   • таймер UI нужен только чтобы перерисовывать, а не чтобы считать;
//   • тесты не нуждаются в реальных таймерах: достаточно передать нужный
//     момент времени.
//
// Флаттера здесь нет намеренно: класс чистый, его можно тестировать через
// `dart test` без запуска приложения.

import 'brew_step.dart';

/// Что происходит с рецептом прямо сейчас.
enum BrewStatus {
  /// Ещё не начинали.
  idle,

  /// Идёт заваривание.
  running,

  /// Пауза. Время не идёт.
  paused,

  /// Все шаги пройдены.
  finished,
}

/// Снимок состояния на конкретный момент времени.
///
/// Именно это отдаётся в UI. Класс неизменяемый: два снимка можно сравнить,
/// чтобы понять, что перерисовывать.
class BrewSnapshot {
  const BrewSnapshot({
    required this.status,
    required this.stepIndex,
    required this.elapsedTotal,
    required this.elapsedInStep,
    required this.stepDuration,
    required this.totalDuration,
    required this.waterPouredG,
    required this.waterTotalG,
  });

  final BrewStatus status;

  /// Индекс текущего шага. Для idle — 0, для finished — последний шаг.
  final int stepIndex;

  final Duration elapsedTotal;
  final Duration elapsedInStep;
  final Duration stepDuration;
  final Duration totalDuration;

  /// Сколько воды должно быть налито к этому моменту. Внутри шага, который
  /// льёт воду, растёт постепенно — это нужно шкале воды (компонент N2).
  final double waterPouredG;
  final double waterTotalG;

  /// Прогресс текущего шага, 0..1.
  ///
  /// toDouble() здесь обязателен: num.clamp возвращает num, а не double,
  /// и без приведения это не скомпилируется.
  double get stepProgress {
    if (stepDuration.inMilliseconds <= 0) return 1;
    final value = elapsedInStep.inMilliseconds / stepDuration.inMilliseconds;
    return value.clamp(0.0, 1.0).toDouble();
  }

  /// Прогресс всего рецепта, 0..1.
  double get totalProgress {
    if (totalDuration.inMilliseconds <= 0) return 1;
    final value = elapsedTotal.inMilliseconds / totalDuration.inMilliseconds;
    return value.clamp(0.0, 1.0).toDouble();
  }

  /// Сколько осталось до конца текущего шага.
  Duration get remainingInStep {
    final left = stepDuration - elapsedInStep;
    return left.isNegative ? Duration.zero : left;
  }

  /// Сколько осталось до конца рецепта.
  Duration get remainingTotal {
    final left = totalDuration - elapsedTotal;
    return left.isNegative ? Duration.zero : left;
  }

  bool get isRunning => status == BrewStatus.running;
  bool get isFinished => status == BrewStatus.finished;
}

/// Движок проигрывания рецепта.
///
/// Не владеет таймером и ничего не планирует сам. UI сам решает, как часто
/// спрашивать состояние: раз в секунду при активном экране, один раз при
/// возвращении из фона.
class BrewEngine {
  BrewEngine({
    required List<BrewStep> steps,
    DateTime Function()? clock,
  })  : _steps = List<BrewStep>.unmodifiable(steps),
        _clock = clock ?? DateTime.now;

  final List<BrewStep> _steps;

  /// Источник времени. Подменяется в тестах, чтобы не ждать по-настоящему.
  final DateTime Function() _clock;

  /// Момент старта. null — ещё не начинали.
  DateTime? _startedAt;

  /// Момент ухода на паузу. null — паузы сейчас нет.
  DateTime? _pausedAt;

  /// Сколько суммарно простояли на паузе. Вычитается из общего времени.
  Duration _pausedTotal = Duration.zero;

  /// Сколько времени «отдано» пропущенным шагам.
  ///
  /// Пропуск шага сдвигает шкалу вперёд — как будто он уже отыгран.
  /// Так пропуск не ломает связь между временем и номером шага.
  Duration _skippedTotal = Duration.zero;

  List<BrewStep> get steps => _steps;

  /// Суммарная длительность рецепта.
  Duration get totalDuration => _steps.fold(
        Duration.zero,
        (sum, step) => sum + step.duration,
      );

  /// Вся вода рецепта.
  double get waterTotalG =>
      _steps.fold<double>(0, (sum, step) => sum + step.waterG);

  bool get isStarted => _startedAt != null;

  /// Запускает заваривание. Повторный вызов ничего не делает —
  /// случайное второе нажатие не должно сбрасывать прогресс.
  void start() {
    if (_startedAt != null) return;
    _startedAt = _clock();
  }

  /// Ставит на паузу. Вне состояния running ничего не делает.
  void pause() {
    if (_startedAt == null || _pausedAt != null) return;
    _pausedAt = _clock();
  }

  /// Снимает с паузы, добавляя простой к накопленному.
  void resume() {
    final pausedAt = _pausedAt;
    if (pausedAt == null) return;
    _pausedTotal += _clock().difference(pausedAt);
    _pausedAt = null;
  }

  /// Пропускает текущий шаг, перематывая на его начало плюс длительность.
  ///
  /// Нужен необязательным шагам и тем, кто заваривает по-своему.
  void skipCurrentStep() {
    if (_startedAt == null) return;

    final snapshot = snapshotAt(_clock());
    if (snapshot.isFinished) return;

    _skippedTotal += snapshot.remainingInStep;
  }

  /// Полный сброс.
  void reset() {
    _startedAt = null;
    _pausedAt = null;
    _pausedTotal = Duration.zero;
    _skippedTotal = Duration.zero;
  }

  /// Восстанавливает движок после перезапуска приложения.
  ///
  /// Ради этого метода вся конструкция и держится на абсолютных метках:
  /// сохранив три значения, состояние можно поднять точно, даже если
  /// приложение было убито системой посреди заваривания.
  void restore({
    required DateTime startedAt,
    Duration pausedTotal = Duration.zero,
    Duration skippedTotal = Duration.zero,
    DateTime? pausedAt,
  }) {
    _startedAt = startedAt;
    _pausedTotal = pausedTotal;
    _skippedTotal = skippedTotal;
    _pausedAt = pausedAt;
  }

  /// Состояние, которое нужно сохранить, чтобы потом вызвать [restore].
  Map<String, dynamic> toPersistableState() => <String, dynamic>{
        'started_at': _startedAt?.toIso8601String(),
        'paused_at': _pausedAt?.toIso8601String(),
        'paused_total_ms': _pausedTotal.inMilliseconds,
        'skipped_total_ms': _skippedTotal.inMilliseconds,
      };

  /// Текущее состояние по часам движка.
  BrewSnapshot snapshot() => snapshotAt(_clock());

  /// Состояние на произвольный момент времени.
  ///
  /// Главный метод. Ничего не мутирует, поэтому его можно звать сколько угодно
  /// часто и из любого места — в том числе с прошлым моментом времени.
  BrewSnapshot snapshotAt(DateTime now) {
    final startedAt = _startedAt;

    if (startedAt == null) {
      return BrewSnapshot(
        status: BrewStatus.idle,
        stepIndex: 0,
        elapsedTotal: Duration.zero,
        elapsedInStep: Duration.zero,
        stepDuration: _steps.isEmpty ? Duration.zero : _steps.first.duration,
        totalDuration: totalDuration,
        waterPouredG: 0,
        waterTotalG: waterTotalG,
      );
    }

    final elapsed = _elapsedAt(now, startedAt);
    final total = totalDuration;

    if (elapsed >= total) {
      return BrewSnapshot(
        status: BrewStatus.finished,
        stepIndex: _steps.isEmpty ? 0 : _steps.length - 1,
        elapsedTotal: total,
        elapsedInStep: _steps.isEmpty ? Duration.zero : _steps.last.duration,
        stepDuration: _steps.isEmpty ? Duration.zero : _steps.last.duration,
        totalDuration: total,
        waterPouredG: waterTotalG,
        waterTotalG: waterTotalG,
      );
    }

    var remaining = elapsed;
    var index = 0;
    var waterBefore = 0.0;

    while (index < _steps.length && remaining >= _steps[index].duration) {
      remaining -= _steps[index].duration;
      waterBefore += _steps[index].waterG;
      index++;
    }

    final step = _steps[index];
    final withinStep = step.duration.inMilliseconds <= 0
        ? 1.0
        : (remaining.inMilliseconds / step.duration.inMilliseconds)
            .clamp(0.0, 1.0)
            .toDouble();

    return BrewSnapshot(
      status: _pausedAt == null ? BrewStatus.running : BrewStatus.paused,
      stepIndex: index,
      elapsedTotal: elapsed,
      elapsedInStep: remaining,
      stepDuration: step.duration,
      totalDuration: total,
      // Вода внутри шага растёт постепенно: этого требует шкала воды.
      waterPouredG: waterBefore + step.waterG * withinStep.clamp(0.0, 1.0),
      waterTotalG: waterTotalG,
    );
  }

  /// Сколько прошло «полезного» времени: настенное минус паузы плюс пропуски.
  Duration _elapsedAt(DateTime now, DateTime startedAt) {
    final wall = now.difference(startedAt);

    // Время, накопленное текущей незавершённой паузой, тоже нужно вычесть,
    // иначе на паузе таймер продолжал бы бежать.
    final pausedAt = _pausedAt;
    final ongoingPause =
        pausedAt == null ? Duration.zero : now.difference(pausedAt);

    final elapsed = wall - _pausedTotal - ongoingPause + _skippedTotal;
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// Моменты, когда нужно показать локальное уведомление.
  ///
  /// Возвращает абсолютные метки конца каждого шага. UI планирует по ним
  /// уведомления один раз при старте — тогда шаг сменится вовремя даже при
  /// свёрнутом приложении, а для колд брю на 12 часов это единственный
  /// работающий способ.
  List<DateTime> notificationTimes() {
    final startedAt = _startedAt;
    if (startedAt == null) return const <DateTime>[];

    final times = <DateTime>[];
    var offset = Duration.zero;

    for (final step in _steps) {
      offset += step.duration;
      times.add(startedAt.add(offset + _pausedTotal - _skippedTotal));
    }

    return times;
  }
}
