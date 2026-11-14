// Конструктор рецепта целиком: уход с несохранёнными правками и перенос
// шагов. Оба пункта пришли снимком владельца 13.11.2026.
//
// «Уйти без сохранения» не уводило: «Уйти» звало maybePop, а тот спрашивал
// PopScope этого же экрана — экран уход держал и задавал вопрос заново.
// Проверяется настоящим маршрутизатором: беда была как раз в разговоре
// экрана с навигацией, и подставной её бы не увидел.
//
// Шаг брался только за значок ручки 20×20 посередине карточки. Теперь ручка —
// вся левая полоса карточки сверху донизу, а ещё шаг поднимается долгим
// нажатием на строку. Сам список лежит в прокрутке экрана: шаг, поднесённый к
// краю, прокручивает экран, а не вложенный список, которому крутить нечего.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/brew_methods/domain/brew_method.dart';
import 'package:pick_up_recipe/src/features/recipes/application/active_brew.dart';
import 'package:pick_up_recipe/src/features/recipes/application/step_types_state.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/grind_descriptor_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/step_type_model.dart';
import 'package:pick_up_recipe/src/general_widgets/app_kit.dart';
import 'package:pick_up_recipe/src/pages/recipe_builder_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Экран-заглушка, с которого открыли конструктор: уходу должно быть куда
/// уходить.
class _Stub extends StatelessWidget {
  const _Stub();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text(_origin)));
  }
}

const _originName = 'OriginRoute';
const _origin = 'Откуда пришли';

class _Router extends RootStackRouter {
  @override
  Map<String, PageFactory> get pagesMap => {
        _originName: (data) =>
            AutoRoutePage<dynamic>(routeData: data, child: const _Stub()),
        RecipeBuilderRoute.name: (data) {
          final args = data.argsAs<RecipeBuilderRouteArgs>();

          return AutoRoutePage<dynamic>(
            routeData: data,
            child: RecipeBuilderPage(
              recipe: args.recipe,
              pack: args.pack,
              method: args.method,
            ),
          );
        },
      };

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: const PageInfo(_originName), path: '/', initial: true),
        AutoRoute(page: RecipeBuilderRoute.page, path: '/recipe/edit'),
      ];
}

/// Метод передаётся экрану сразу: иначе он пошёл бы за справочником в сеть.
const _v60 = BrewMethod(id: 1, slug: 'hario_v60', name: 'V60', iconKey: 'v60');

RecipeStep _step(int seqNum) => RecipeStep(
      seqNum: seqNum,
      instruction: 'Шаг $seqNum',
      water: 20,
      time: 30,
      id: seqNum,
      stepType: 'pour',
      stepKey: '',
      tip: '',
      isOptional: false,
      untilUser: false,
      untilSign: '',
      warning: '',
    );

RecipeData _recipe({int steps = 3}) => RecipeData(
      id: 1,
      device: 'hario_v60',
      date: '2026-09-09T01:00:00Z',
      packId: 7,
      grinderId: 1,
      grindStep: '18',
      grindSubStep: null,
      water: 20 * steps,
      time: 30 * steps,
      temperature: 93,
      load: 15,
      title: 'Базовый рецепт',
      notes: '',
      grindDescriptor: 'medium',
      agitationLevel: null,
      steps: [for (var i = 1; i <= steps; i++) _step(i)],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();
    ActiveBrews.load();

    await GetIt.instance.reset();
    GetIt.instance
        .registerSingleton<ApiClient>(ApiClient(onAuthError: () async {}));
  });

  /// Поднимает приложение и открывает конструктор поверх «Откуда пришли».
  ///
  /// Окно по умолчанию — телефон, на котором шаги ниже края; [height] выше —
  /// чтобы все шаги были видны без прокрутки.
  Future<void> openBuilder(
    WidgetTester tester, {
    int steps = 3,
    double height = 800,
  }) async {
    tester.view.physicalSize = Size(400, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = _Router();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stepTypesProvider.overrideWith((ref) => const StepTypeReference()),
          grindDescriptorsProvider
              .overrideWith((ref) => const <GrindDescriptor>[]),
        ],
        child: MaterialApp.router(
          theme: lightTheme,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router.config(),
        ),
      ),
    );
    await tester.pump();

    // Без await: push отдаёт результат экрана и ждёт, пока тот закроется.
    unawaited(router.push(
      RecipeBuilderRoute(recipe: _recipe(steps: steps), method: _v60),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeBuilderPage), findsOneWidget);
  }

  /// Правка, которую жалко потерять: раскрыть первый шаг и убрать его.
  Future<void> makeDirty(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Шаг 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Шаг 1'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Убрать шаг'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Убрать шаг'));
    await tester.pumpAndSettle();
    expect(find.text('Шаг 1'), findsNothing);
  }

  Future<void> pressSystemBack(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  group('уход с несохранёнными правками', () {
    testWidgets('стрелкой: «Уйти» уводит, а не спрашивает снова',
        (tester) async {
      await openBuilder(tester);
      await makeDirty(tester);

      await tester.tap(find.byTooltip('Назад'));
      await tester.pumpAndSettle();
      expect(find.text('Уйти без сохранения?'), findsOneWidget);

      await tester.tap(find.text('Уйти'));
      await tester.pumpAndSettle();

      expect(find.text('Уйти без сохранения?'), findsNothing,
          reason: 'человек ответил «Уйти» — второй раз не спрашивают');
      expect(find.byType(RecipeBuilderPage), findsNothing);
      expect(find.text(_origin), findsOneWidget);
    });

    testWidgets('кнопкой телефона: «Уйти» уводит', (tester) async {
      await openBuilder(tester);
      await makeDirty(tester);

      await pressSystemBack(tester);
      expect(find.text('Уйти без сохранения?'), findsOneWidget);

      await tester.tap(find.text('Уйти'));
      await tester.pumpAndSettle();

      expect(find.text('Уйти без сохранения?'), findsNothing);
      expect(find.byType(RecipeBuilderPage), findsNothing);
      expect(find.text(_origin), findsOneWidget);
    });

    testWidgets('«Остаться» оставляет правки, и уйти можно потом',
        (tester) async {
      await openBuilder(tester);
      await makeDirty(tester);

      await tester.tap(find.byTooltip('Назад'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Остаться'));
      await tester.pumpAndSettle();

      expect(find.byType(RecipeBuilderPage), findsOneWidget);
      expect(find.text('Шаг 1'), findsNothing,
          reason: 'правка — убранный шаг — никуда не делась');

      await pressSystemBack(tester);
      await tester.tap(find.text('Уйти'));
      await tester.pumpAndSettle();
      expect(find.text(_origin), findsOneWidget);
    });

    testWidgets('без правок уходит без вопроса', (tester) async {
      await openBuilder(tester);

      await tester.tap(find.byTooltip('Назад'));
      await tester.pumpAndSettle();

      expect(find.text('Уйти без сохранения?'), findsNothing);
      expect(find.text(_origin), findsOneWidget);
    });
  });

  group('перенос шага', () {
    Rect cardOf(WidgetTester tester, String label) => tester.getRect(find
        .ancestor(of: find.text(label), matching: find.byType(AppCard))
        .first);

    /// Шаги сверху вниз — как их видно на экране.
    List<String> visibleOrder(WidgetTester tester, int steps) {
      final labels = [
        for (var i = 1; i <= steps; i++)
          if (find.text('Шаг $i').evaluate().isNotEmpty) 'Шаг $i',
      ];
      labels.sort((a, b) => tester
          .getTopLeft(find.text(a))
          .dy
          .compareTo(tester.getTopLeft(find.text(b)).dy));
      return labels;
    }

    /// Расстояние между соседними шагами: на столько сдвигается шаг,
    /// перенесённый на одно место.
    double pitch(WidgetTester tester) =>
        cardOf(tester, 'Шаг 2').top - cardOf(tester, 'Шаг 1').top;

    /// Ведёт палец на [dy] и отпускает: сперва за порог, с которого жест
    /// считается переносом, потом остаток пути — мелкими шагами, как ведёт
    /// человек. Список двигает соседей по ходу, и одним прыжком через
    /// половину соседа он не понял бы, куда шаг несут.
    Future<void> carry(
        TestGesture gesture, WidgetTester tester, double dy) async {
      final first = dy.sign * 24;
      await gesture.moveBy(Offset(0, first));
      await tester.pump();
      final rest = dy - first;
      final parts = (rest.abs() / 6).ceil();
      for (var i = 0; i < parts; i++) {
        await gesture.moveBy(Offset(0, rest / parts));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    // Точки касания — над значком ручки и под ним, в 3 точках от края
    // карточки. Не в самом углу: угол срезан скруглением, и туда не попадает
    // ни одно касание. Значок занимает середину строки — раньше шаг брался
    // только за него.
    testWidgets('берётся за верх левой полосы, а не только за значок',
        (tester) async {
      await openBuilder(tester, height: 1400);
      final card = cardOf(tester, 'Шаг 1');

      final gesture =
          await tester.startGesture(card.topLeft + const Offset(22, 3));
      await carry(gesture, tester, pitch(tester));

      expect(visibleOrder(tester, 3), ['Шаг 2', 'Шаг 1', 'Шаг 3']);
    });

    testWidgets('берётся и за низ полосы', (tester) async {
      await openBuilder(tester, height: 1400);
      final card = cardOf(tester, 'Шаг 3');

      final gesture =
          await tester.startGesture(card.bottomLeft + const Offset(22, -3));
      await carry(gesture, tester, -2 * pitch(tester));

      expect(visibleOrder(tester, 3), ['Шаг 3', 'Шаг 1', 'Шаг 2']);
    });

    testWidgets('долгое нажатие на строку поднимает шаг', (tester) async {
      await openBuilder(tester, height: 1400);

      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Шаг 1')));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await carry(gesture, tester, pitch(tester));

      expect(visibleOrder(tester, 3), ['Шаг 2', 'Шаг 1', 'Шаг 3']);
    });

    testWidgets('быстрый свайп по строке шаг не переносит', (tester) async {
      await openBuilder(tester, height: 1400);

      // Мимо полосы и без удержания: это прокрутка экрана, а не перенос.
      await tester.dragFrom(
        tester.getCenter(find.text('Шаг 1')),
        Offset(0, pitch(tester) * 1.5),
      );
      await tester.pumpAndSettle();

      expect(visibleOrder(tester, 3), ['Шаг 1', 'Шаг 2', 'Шаг 3']);
    });

    testWidgets('шаг у края экрана прокручивает экран', (tester) async {
      const steps = 12;
      await openBuilder(tester, steps: steps);

      final scroll = tester.state<ScrollableState>(find
          .descendant(
            of: find.byType(RecipeBuilderPage),
            matching: find.byType(Scrollable),
          )
          .first);
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final bottom = scroll.position.pixels;
      expect(bottom, greaterThan(0), reason: 'шагов больше, чем влезает');

      final card = cardOf(tester, 'Шаг $steps');
      final viewport = tester.getRect(find.byWidget(scroll.widget));
      final gesture =
          await tester.startGesture(card.centerLeft + const Offset(4, 0));
      await gesture.moveBy(const Offset(0, -24));
      await tester.pump();
      // Несём к верхнему краю видимой части и держим там, пока экран не
      // доедет до начала.
      await gesture.moveTo(Offset(card.left + 4, viewport.top + 4));
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(scroll.position.pixels, lessThan(bottom),
          reason: 'экран обязан ехать вслед за шагом, поднесённым к краю');

      await gesture.up();
      await tester.pumpAndSettle();
      expect(visibleOrder(tester, steps).take(2), ['Шаг $steps', 'Шаг 1'],
          reason: 'последний шаг донесли до самого верха списка');
    });
  });

  group('где раскрытый шаг после переноса', () {
    test('несли его самого — едет вместе с ним', () {
      expect(openStepAfterMove(1, 1, 3), 3);
    });

    test('соседа унесли сверху вниз мимо него — сдвигается вверх', () {
      expect(openStepAfterMove(2, 0, 3), 1);
      expect(openStepAfterMove(2, 1, 2), 1);
    });

    test('соседа принесли снизу наверх мимо него — сдвигается вниз', () {
      expect(openStepAfterMove(2, 3, 0), 3);
      expect(openStepAfterMove(2, 3, 2), 3);
    });

    test('перенос в стороне его не трогает', () {
      expect(openStepAfterMove(0, 2, 3), 0);
      expect(openStepAfterMove(3, 0, 1), 3);
    });

    test('раскрытого не было — не появляется', () {
      expect(openStepAfterMove(null, 0, 2), isNull);
    });
  });
}
