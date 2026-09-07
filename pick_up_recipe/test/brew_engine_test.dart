// Тесты движка проигрывания рецепта.
//
// Ни одного реального таймера здесь нет. Движок считает состояние функцией от
// переданного момента времени, поэтому «прошло 12 часов» — это просто другое
// значение в фальшивых часах. Именно это и позволяет проверить поведение
// колд брю, не заваривая его двенадцать часов.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/brew_engine.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/brew_step.dart';

/// Управляемые часы.
class FakeClock {
  DateTime now = DateTime.utc(2026, 1, 1, 12, 0, 0);

  DateTime call() => now;

  void advance(Duration by) => now = now.add(by);
}

/// Рецепт V60: предсмачивание, пролив, пауза, пролив, ожидание.
List<BrewStep> v60Steps() => const <BrewStep>[
      BrewStep(
        id: 's1',
        type: BrewStepType.bloom,
        label: 'Предсмачивание',
        duration: Duration(seconds: 30),
        waterG: 45,
      ),
      BrewStep(
        id: 's2',
        type: BrewStepType.pour,
        label: 'Первый пролив',
        duration: Duration(seconds: 30),
        waterG: 105,
      ),
      BrewStep(
        id: 's3',
        type: BrewStepType.wait,
        label: 'Пауза',
        duration: Duration(seconds: 10),
      ),
      BrewStep(
        id: 's4',
        type: BrewStepType.pour,
        label: 'Второй пролив',
        duration: Duration(seconds: 30),
        waterG: 100,
      ),
      BrewStep(
        id: 's5',
        type: BrewStepType.wait,
        label: 'Ждём пролива',
        duration: Duration(seconds: 45),
      ),
    ];

/// Рецепт, у которого последний шаг кончается по кнопке.
///
/// Нулевая длительность здесь не случайность: конструктор именно её и даёт
/// шагу «пока не скажете сделал» — сколько он продлится, решает человек.
List<BrewStep> untilUserSteps() => const <BrewStep>[
      BrewStep(
        id: 's1',
        type: BrewStepType.pour,
        label: 'Пролив',
        duration: Duration(seconds: 30),
        waterG: 250,
      ),
      BrewStep(
        id: 's2',
        type: BrewStepType.wait,
        label: 'Ждём пролива',
        duration: Duration.zero,
        untilUser: true,
        untilSign: 'воронка опустела',
      ),
    ];

/// Тот же шаг, но в середине: за ним есть чему ждать своей очереди.
List<BrewStep> middleGateSteps() => const <BrewStep>[
      BrewStep(
        id: 's1',
        type: BrewStepType.pour,
        label: 'Пролив',
        duration: Duration(seconds: 30),
        waterG: 250,
      ),
      BrewStep(
        id: 's2',
        type: BrewStepType.wait,
        label: 'Ждём пролива',
        duration: Duration.zero,
        untilUser: true,
      ),
      BrewStep(
        id: 's3',
        type: BrewStepType.serve,
        label: 'Снять воронку и разлить',
        duration: Duration(seconds: 20),
      ),
    ];

void main() {
  late FakeClock clock;
  late BrewEngine engine;

  setUp(() {
    clock = FakeClock();
    engine = BrewEngine(steps: v60Steps(), clock: clock.call);
  });

  group('до старта', () {
    test('состояние idle', () {
      final snapshot = engine.snapshot();

      expect(snapshot.status, BrewStatus.idle);
      expect(snapshot.stepIndex, 0);
      expect(snapshot.elapsedTotal, Duration.zero);
      expect(snapshot.waterPouredG, 0);
    });

    test('суммарные величины считаются без старта', () {
      expect(engine.totalDuration, const Duration(seconds: 145));
      expect(engine.waterTotalG, 250);
    });

    test('время не идёт само по себе', () {
      clock.advance(const Duration(minutes: 5));

      expect(engine.snapshot().status, BrewStatus.idle);
      expect(engine.snapshot().elapsedTotal, Duration.zero);
    });
  });

  group('проигрывание', () {
    test('после старта состояние running', () {
      engine.start();

      expect(engine.snapshot().status, BrewStatus.running);
    });

    test('шаг определяется по прошедшему времени', () {
      engine.start();

      clock.advance(const Duration(seconds: 10));
      expect(engine.snapshot().stepIndex, 0, reason: 'внутри предсмачивания');

      clock.advance(const Duration(seconds: 25)); // всего 35
      expect(engine.snapshot().stepIndex, 1, reason: 'первый пролив');

      clock.advance(const Duration(seconds: 30)); // всего 65
      expect(engine.snapshot().stepIndex, 2, reason: 'пауза');

      clock.advance(const Duration(seconds: 20)); // всего 85
      expect(engine.snapshot().stepIndex, 3, reason: 'второй пролив');
    });

    test('в конце состояние finished', () {
      engine.start();
      clock.advance(const Duration(seconds: 145));

      final snapshot = engine.snapshot();

      expect(snapshot.status, BrewStatus.finished);
      expect(snapshot.totalProgress, 1.0);
      expect(snapshot.waterPouredG, 250);
      expect(snapshot.remainingTotal, Duration.zero);
    });

    test('после конца состояние не уезжает дальше', () {
      engine.start();
      clock.advance(const Duration(hours: 3));

      final snapshot = engine.snapshot();

      expect(snapshot.status, BrewStatus.finished);
      expect(snapshot.elapsedTotal, engine.totalDuration);
      expect(snapshot.totalProgress, 1.0);
    });

    test('повторный старт не сбрасывает прогресс', () {
      engine.start();
      clock.advance(const Duration(seconds: 40));

      engine.start(); // случайное второе нажатие

      expect(engine.snapshot().elapsedTotal, const Duration(seconds: 40));
    });
  });

  group('вода', () {
    test('внутри шага растёт постепенно', () {
      engine.start();
      clock.advance(const Duration(seconds: 15)); // половина предсмачивания

      expect(engine.snapshot().waterPouredG, closeTo(22.5, 0.01));
    });

    test('после шага равна сумме предыдущих', () {
      engine.start();
      clock.advance(const Duration(seconds: 30));

      expect(engine.snapshot().waterPouredG, closeTo(45, 0.01));
    });

    test('на шаге без воды не растёт', () {
      engine.start();
      clock.advance(const Duration(seconds: 65)); // середина паузы

      expect(engine.snapshot().waterPouredG, closeTo(150, 0.01));
    });
  });

  group('пауза', () {
    test('останавливает время', () {
      engine.start();
      clock.advance(const Duration(seconds: 20));

      engine.pause();
      final atPause = engine.snapshot().elapsedTotal;

      clock.advance(const Duration(minutes: 10));

      expect(engine.snapshot().status, BrewStatus.paused);
      expect(engine.snapshot().elapsedTotal, atPause,
          reason: 'на паузе время стоять должно');
    });

    test('возобновление продолжает с того же места', () {
      engine.start();
      clock.advance(const Duration(seconds: 20));

      engine.pause();
      clock.advance(const Duration(minutes: 10));
      engine.resume();

      expect(engine.snapshot().elapsedTotal, const Duration(seconds: 20));

      clock.advance(const Duration(seconds: 10));
      expect(engine.snapshot().elapsedTotal, const Duration(seconds: 30));
    });

    test('несколько пауз складываются', () {
      engine.start();

      clock.advance(const Duration(seconds: 10));
      engine.pause();
      clock.advance(const Duration(minutes: 5));
      engine.resume();

      clock.advance(const Duration(seconds: 10));
      engine.pause();
      clock.advance(const Duration(minutes: 5));
      engine.resume();

      expect(engine.snapshot().elapsedTotal, const Duration(seconds: 20));
    });

    test('повторная пауза не удваивает простой', () {
      engine.start();
      clock.advance(const Duration(seconds: 10));

      engine.pause();
      engine.pause();
      clock.advance(const Duration(minutes: 5));
      engine.resume();

      expect(engine.snapshot().elapsedTotal, const Duration(seconds: 10));
    });

    test('возобновление без паузы ничего не ломает', () {
      engine.start();
      clock.advance(const Duration(seconds: 10));

      engine.resume();

      expect(engine.snapshot().elapsedTotal, const Duration(seconds: 10));
      expect(engine.snapshot().status, BrewStatus.running);
    });
  });

  group('пропуск шага', () {
    test('перематывает на следующий', () {
      engine.start();
      clock.advance(const Duration(seconds: 5));

      engine.skipCurrentStep();

      expect(engine.snapshot().stepIndex, 1);
    });

    test('не ломает связь времени и номера шага', () {
      engine.start();
      clock.advance(const Duration(seconds: 5));
      engine.skipCurrentStep();

      clock.advance(const Duration(seconds: 30));

      expect(engine.snapshot().stepIndex, 2, reason: 'пролив пройден целиком');
    });
  });

  // Главное свойство движка: он держится на абсолютных метках времени,
  // поэтому сворачивание приложения перестаёт быть особым случаем.
  group('работа в фоне', () {
    test('пока приложение свёрнуто, время продолжает идти', () {
      engine.start();

      // Приложение ушло в фон, кадры не рисуются, но часы идут.
      clock.advance(const Duration(seconds: 90));

      final snapshot = engine.snapshot();
      expect(snapshot.elapsedTotal, const Duration(seconds: 90));
      // Границы шагов: 30 / 60 / 70 / 100 / 145. Момент 90 с приходится
      // на четвёртый шаг, то есть индекс 3.
      expect(snapshot.stepIndex, 3);
    });

    test('колд брю на 12 часов доигрывается', () {
      final coldBrew = BrewEngine(
        clock: clock.call,
        steps: const <BrewStep>[
          BrewStep(
            id: 's1',
            type: BrewStepType.pour,
            label: 'Залить водой',
            duration: Duration(seconds: 90),
            waterG: 600,
          ),
          BrewStep(
            id: 's2',
            type: BrewStepType.wait,
            label: 'Настаивание',
            duration: Duration(hours: 12),
          ),
        ],
      );

      coldBrew.start();
      clock.advance(const Duration(hours: 6));

      expect(coldBrew.snapshot().status, BrewStatus.running);
      expect(coldBrew.snapshot().stepIndex, 1);

      clock.advance(const Duration(hours: 7));

      expect(coldBrew.snapshot().status, BrewStatus.finished);
    });
  });

  group('восстановление после перезапуска', () {
    test('состояние поднимается по сохранённым меткам', () {
      engine.start();
      clock.advance(const Duration(seconds: 20));
      engine.pause();
      clock.advance(const Duration(minutes: 3));
      engine.resume();
      clock.advance(const Duration(seconds: 10));

      final saved = engine.toPersistableState();
      final expected = engine.snapshot().elapsedTotal;

      // Приложение убито системой и запущено заново.
      final restored = BrewEngine(steps: v60Steps(), clock: clock.call)
        ..restore(
          startedAt: DateTime.parse(saved['started_at'] as String),
          pausedTotal: Duration(milliseconds: saved['paused_total_ms'] as int),
          skippedTotal: Duration(milliseconds: saved['skipped_total_ms'] as int),
        );

      expect(restored.snapshot().elapsedTotal, expected);
      expect(restored.snapshot().stepIndex, engine.snapshot().stepIndex);
    });

    test('подтверждённые шаги и ожидание переживают перезапуск', () {
      final middle = BrewEngine(steps: middleGateSteps(), clock: clock.call);
      middle.start();
      clock.advance(const Duration(seconds: 30));
      clock.advance(const Duration(minutes: 5)); // стояли у ворот
      middle.confirmCurrentStep();
      clock.advance(const Duration(seconds: 5));

      final saved = middle.toPersistableState();

      // Приложение свернули, система его убила, человек вернулся.
      final restored = BrewEngine(steps: middleGateSteps(), clock: clock.call)
        ..restore(
          startedAt: DateTime.parse(saved['started_at'] as String),
          pausedTotal: Duration(milliseconds: saved['paused_total_ms'] as int),
          skippedTotal: Duration(milliseconds: saved['skipped_total_ms'] as int),
          waitingTotal: Duration(milliseconds: saved['waiting_total_ms'] as int),
          confirmedSteps: (saved['confirmed_steps'] as List).cast<int>(),
        );

      expect(restored.snapshot().stepIndex, 2,
          reason: 'ворота, которые уже открыли, не закрываются обратно');
      expect(restored.snapshot().elapsedTotal, middle.snapshot().elapsedTotal);
      expect(restored.snapshot().status, BrewStatus.running);
    });

    test('без подтверждения ворота остаются закрытыми', () {
      final middle = BrewEngine(steps: middleGateSteps(), clock: clock.call);
      middle.start();
      clock.advance(const Duration(seconds: 30));

      final saved = middle.toPersistableState();
      expect(saved['confirmed_steps'], isEmpty);

      final restored = BrewEngine(steps: middleGateSteps(), clock: clock.call)
        ..restore(startedAt: DateTime.parse(saved['started_at'] as String));

      clock.advance(const Duration(minutes: 3));
      expect(restored.snapshot().status, BrewStatus.awaitingUser);
    });

    test('сохранённое состояние сериализуемо', () {
      engine.start();
      final saved = engine.toPersistableState();

      expect(saved['started_at'], isA<String>());
      expect(saved['paused_total_ms'], isA<int>());
      expect(saved['skipped_total_ms'], isA<int>());
      expect(saved['waiting_total_ms'], isA<int>());
      expect(saved['confirmed_steps'], isA<List<int>>());
    });
  });

  // Шаг «пока не скажете сделал» кончается не по секундомеру, а по человеку.
  // Движок этого не знал: конструктор даёт такому шагу нулевую длительность,
  // и последний шаг проглатывался мгновенно — заваривание уходило на оценку
  // само, хотя человек ещё держал воронку.
  group('шаг «пока не скажете сделал»', () {
    late BrewEngine gated;

    setUp(() {
      gated = BrewEngine(steps: untilUserSteps(), clock: clock.call);
    });

    test('последний шаг по кнопке не заканчивает заваривание сам', () {
      gated.start();

      clock.advance(const Duration(seconds: 32));
      expect(gated.snapshot().isFinished, isFalse,
          reason: 'через две секунды после таймера ждём человека, а не оценку');

      clock.advance(const Duration(minutes: 10));
      expect(gated.snapshot().isFinished, isFalse,
          reason: 'и через десять минут тоже: шаг кончает человек');
    });

    test('на таком шаге состояние — ожидание человека', () {
      gated.start();
      clock.advance(const Duration(seconds: 40));

      final snapshot = gated.snapshot();

      expect(snapshot.status, BrewStatus.awaitingUser);
      expect(snapshot.isAwaitingUser, isTrue);
      expect(snapshot.stepIndex, 1, reason: 'стоим на ждущем шаге, а не за ним');
      expect(snapshot.remainingInStep, Duration.zero);
      expect(snapshot.waterPouredG, 250, reason: 'вода предыдущих шагов уже налита');
    });

    test('«сделал» заканчивает заваривание', () {
      gated.start();
      clock.advance(const Duration(seconds: 40));

      gated.confirmCurrentStep();

      expect(gated.snapshot().isFinished, isTrue);
    });

    test('шаг по кнопке в середине держит следующий', () {
      final middle = BrewEngine(steps: middleGateSteps(), clock: clock.call);
      middle.start();

      clock.advance(const Duration(seconds: 30));
      expect(middle.snapshot().stepIndex, 1, reason: 'дошли до ворот');

      clock.advance(const Duration(minutes: 3));
      expect(middle.snapshot().stepIndex, 1,
          reason: 'следующий шаг не начинается, пока не сказали «сделал»');
      expect(middle.snapshot().status, BrewStatus.awaitingUser);

      middle.confirmCurrentStep();
      expect(middle.snapshot().stepIndex, 2);
    });

    test('долгое ожидание не съедает следующие шаги', () {
      final middle = BrewEngine(steps: middleGateSteps(), clock: clock.call);
      middle.start();

      clock.advance(const Duration(seconds: 30));
      clock.advance(const Duration(minutes: 10)); // человек ушёл за молоком
      middle.confirmCurrentStep();

      expect(middle.snapshot().remainingInStep, const Duration(seconds: 20),
          reason: 'последний шаг начинается с нуля, а не догоняет ожидание');

      clock.advance(const Duration(seconds: 5));
      expect(middle.snapshot().remainingInStep, const Duration(seconds: 15));

      clock.advance(const Duration(seconds: 15));
      expect(middle.snapshot().isFinished, isTrue);
    });

    test('пропуск уводит с ждущего шага дальше', () {
      final middle = BrewEngine(steps: middleGateSteps(), clock: clock.call);
      middle.start();
      clock.advance(const Duration(seconds: 30));

      middle.skipCurrentStep();

      expect(middle.snapshot().stepIndex, 2,
          reason: 'до конца ждущего шага ноль секунд — перематывать нечего');
      expect(middle.snapshot().status, BrewStatus.running);
    });

    test('пропуск последнего ждущего шага заканчивает заваривание', () {
      gated.start();
      clock.advance(const Duration(seconds: 40));

      gated.skipCurrentStep();

      expect(gated.snapshot().isFinished, isTrue);
    });

    test('«сделал» на обычном шаге ничего не двигает', () {
      engine.start();
      clock.advance(const Duration(seconds: 10));

      engine.confirmCurrentStep();

      expect(engine.snapshot().stepIndex, 0);
      expect(engine.snapshot().elapsedTotal, const Duration(seconds: 10));
    });

    test('«сделал» до старта ничего не ломает', () {
      gated.confirmCurrentStep();

      expect(gated.snapshot().status, BrewStatus.idle);
    });

    test('ждущий шаг с таймером сначала отсчитывает, потом ждёт', () {
      final timed = BrewEngine(
        clock: clock.call,
        steps: const <BrewStep>[
          BrewStep(
            id: 's1',
            type: BrewStepType.press,
            label: 'Отжим',
            duration: Duration(seconds: 20),
            untilUser: true,
          ),
        ],
      );
      timed.start();

      clock.advance(const Duration(seconds: 10));
      expect(timed.snapshot().status, BrewStatus.running,
          reason: 'таймер шага ещё идёт — он ориентир');

      clock.advance(const Duration(seconds: 15));
      expect(timed.snapshot().status, BrewStatus.awaitingUser);

      timed.confirmCurrentStep();
      expect(timed.snapshot().isFinished, isTrue);
    });

    test('сброс закрывает ворота обратно', () {
      gated.start();
      clock.advance(const Duration(seconds: 40));
      gated.confirmCurrentStep();

      gated.reset();
      gated.start();
      clock.advance(const Duration(seconds: 40));

      expect(gated.snapshot().status, BrewStatus.awaitingUser);
    });

    test('уведомления обрываются на неподтверждённом шаге', () {
      final middle = BrewEngine(steps: middleGateSteps(), clock: clock.call);
      middle.start();

      // Когда начнётся шаг за воротами, не знает никто: это решит человек.
      expect(middle.notificationTimes(), hasLength(2));
    });
  });

  group('сброс', () {
    test('возвращает в idle', () {
      engine.start();
      clock.advance(const Duration(seconds: 40));

      engine.reset();

      expect(engine.snapshot().status, BrewStatus.idle);
      expect(engine.snapshot().elapsedTotal, Duration.zero);
      expect(engine.isStarted, isFalse);
    });
  });

  group('уведомления', () {
    test('до старта список пуст', () {
      expect(engine.notificationTimes(), isEmpty);
    });

    test('после старта отдаются моменты конца каждого шага', () {
      engine.start();

      final times = engine.notificationTimes();

      expect(times, hasLength(5));
      expect(times.first, clock.now.add(const Duration(seconds: 30)));
      expect(times.last, clock.now.add(const Duration(seconds: 145)));
    });

    test('пауза сдвигает моменты вперёд', () {
      engine.start();
      final before = engine.notificationTimes().last;

      engine.pause();
      clock.advance(const Duration(minutes: 5));
      engine.resume();

      expect(engine.notificationTimes().last,
          before.add(const Duration(minutes: 5)));
    });
  });

  group('разбор шага с сервера', () {
    test('исторический шаг без типа становится custom', () {
      final step = BrewStep.fromResponse(
        seqNum: 0,
        instruction: 'Предсмачивание',
        timeSec: 30,
        waterMl: 45,
      );

      expect(step.type, BrewStepType.custom);
      expect(step.id, 's0');
      expect(step.label, 'Предсмачивание', reason: 'подпись сохраняется дословно');
    });

    test('шаг формата v1 разбирается по типу', () {
      final step = BrewStep.fromResponse(
        seqNum: 0,
        instruction: 'Предсмачивание',
        timeSec: 30,
        waterMl: 45,
        stepType: 'bloom',
        stepKey: 's1',
        tip: 'Лей от центра',
      );

      expect(step.type, BrewStepType.bloom);
      expect(step.id, 's1');
      expect(step.waterG, 45);
      expect(step.tip, 'Лей от центра');
    });

    test('неизвестный тип не роняет разбор', () {
      final step = BrewStep.fromResponse(
        seqNum: 0,
        instruction: 'Телепортация',
        timeSec: 5,
        waterMl: 0,
        stepType: 'teleport',
      );

      expect(step.type, BrewStepType.custom);
    });

    test('вода не приписывается шагу, который её не льёт', () {
      final step = BrewStep.fromResponse(
        seqNum: 0,
        instruction: 'Размешать',
        timeSec: 10,
        waterMl: 30, // противоречие в исторических данных
        stepType: 'stir',
      );

      expect(step.waterG, 0);
    });
  });

  group('типы шагов', () {
    test('воду добавляют только четыре типа', () {
      expect(BrewStepType.bloom.addsWater, isTrue);
      expect(BrewStepType.pour.addsWater, isTrue);
      expect(BrewStepType.addIce.addsWater, isTrue);
      expect(BrewStepType.dilute.addsWater, isTrue);

      expect(BrewStepType.wait.addsWater, isFalse);
      expect(BrewStepType.stir.addsWater, isFalse);
      expect(BrewStepType.press.addsWater, isFalse);
    });

    test('шаг по кнопке кончается человеком, а не таймером', () {
      const gate = BrewStep(
        id: 's1',
        type: BrewStepType.wait,
        label: 'Ждём пролива',
        duration: Duration.zero,
        untilUser: true,
      );
      const timed = BrewStep(
        id: 's2',
        type: BrewStepType.pour,
        label: 'Пролив',
        duration: Duration(seconds: 30),
        waterG: 100,
      );

      expect(gate.endsByUser, isTrue);
      expect(timed.endsByUser, isFalse);
    });

    test('длительность показывают, только когда она есть', () {
      const gate = BrewStep(
        id: 's1',
        type: BrewStepType.wait,
        label: 'Ждём пролива',
        duration: Duration.zero,
        untilUser: true,
      );
      const timed = BrewStep(
        id: 's2',
        type: BrewStepType.pour,
        label: 'Пролив',
        duration: Duration(seconds: 30),
        waterG: 100,
      );

      // Ноль на месте таймера читается как сбой приложения, а не как
      // «столько, сколько нужно вам».
      expect(gate.showsDuration, isFalse);
      expect(timed.showsDuration, isTrue);
    });

    test('воду показывают только там, где она есть', () {
      const pour = BrewStep(
        id: 's1',
        type: BrewStepType.pour,
        label: 'Пролив',
        duration: Duration(seconds: 30),
        waterG: 100,
      );
      const stir = BrewStep(
        id: 's2',
        type: BrewStepType.stir,
        label: 'Размешать',
        duration: Duration(seconds: 5),
        waterG: 30, // противоречие в исторических данных
      );

      expect(pour.showsWater, isTrue);
      expect(stir.showsWater, isFalse);
    });

    test('предупреждения нужны действиям с горячей водой', () {
      expect(BrewStepType.invert.needsWarning, isTrue);
      expect(BrewStepType.flip.needsWarning, isTrue);
      expect(BrewStepType.press.needsWarning, isTrue);
      expect(BrewStepType.wait.needsWarning, isFalse);
    });
  });
}
