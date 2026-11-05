// С идущего заваривания можно уйти — и оно не останавливается.
//
// До 6 ноября 2026 уход с экрана спрашивал «Прервать заваривание?» и стирал
// отсчёт, а вкладка нижней панели стирала его молча. Владелец: «пользователь
// может выйти из текущего рецепта, соответственно он не должен остановиться».
// Теперь уход ничего не спрашивает, заваривание остаётся в `ActiveBrews`, а
// экран, открытый снова, подхватывает его с того места, до которого дошли
// часы.
//
// Ломается это тихо, и каждый способ закрыт тестом ниже:
//   • уход всё-таки останавливает отсчёт (запись не пишется или стирается);
//   • возврат показывает рецепт заново, с первого шага, а не идущее;
//   • долгое отсутствие не спрашивает, что случилось с кофе в воронке;
//   • «Прервать» некуда нажать — или она срабатывает без вопроса;
//   • на долгом шаге экран молчит о том, что с него можно уйти;
//   • справочный рецепт метода, который не довели до оценки, не появляется
//     на «Рецептах» — своей копией он становился только при оценке.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/recipes/application/active_brew.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipes_list_state.dart';
import 'package:pick_up_recipe/src/features/recipes/application/step_types_state.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/brew_engine.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/brew_step.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/grind_descriptor_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/step_type_model.dart';
import 'package:pick_up_recipe/src/pages/brew_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Экран-заглушка: уходу должно быть куда уходить, а оценке и «Рецептам» —
/// где показаться. Настоящие подняли бы половину приложения вместе с сетью.
class _Stub extends StatelessWidget {
  const _Stub(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

const _originName = 'OriginRoute';
const _origin = 'Откуда пришли';
const _rating = 'Экран оценки';
const _recipes = 'Вкладка «Рецепты»';

/// Маршрутизатор на четыре экрана. Настоящий, а не подставной: проверяется
/// как раз разговор экрана заваривания с навигацией.
class _Router extends RootStackRouter {
  @override
  Map<String, PageFactory> get pagesMap => {
        _originName: (data) => AutoRoutePage<dynamic>(
              routeData: data,
              child: const _Stub(_origin),
            ),
        RatingRoute.name: (data) => AutoRoutePage<dynamic>(
              routeData: data,
              child: const _Stub(_rating),
            ),
        RecipesRoute.name: (data) => AutoRoutePage<dynamic>(
              routeData: data,
              child: const _Stub(_recipes),
            ),
        BrewRoute.name: (data) {
          final args = data.argsAs<BrewRouteArgs>();

          return AutoRoutePage<dynamic>(
            routeData: data,
            child: BrewPage(
              recipe: args.recipe,
              pack: args.pack,
              autoStart: args.autoStart,
            ),
          );
        },
      };

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: const PageInfo(_originName), path: '/', initial: true),
        AutoRoute(page: BrewRoute.page, path: '/brew'),
        AutoRoute(page: RatingRoute.page, path: '/rating'),
        AutoRoute(page: RecipesRoute.page, path: '/recipes'),
      ];
}

/// Сервер рецептов: запоминает, что экран просил сохранить, и отдаёт номер.
class _Recipes extends RecipeService {
  final evolved = <RecipeData>[];

  @override
  Future<int> evolveRecipe(RecipeData recipe) async {
    evolved.add(copyRecipe(recipe));
    return 901;
  }
}

PackData _pack() => PackData(
      packId: 7,
      userId: '1',
      packDate: '2026-11-01T10:00:00Z',
      packName: 'Гватемала',
      packDescriptors: const [],
      packCountry: 'Гватемала',
      packProcessingMethod: const [],
      packImage: '',
      packVariety: '',
      packScaScore: 84,
      isActive: true,
      roasterName: '',
    );

RecipeStep _step(
  int seqNum, {
  int time = 30,
  int water = 60,
  String type = 'pour',
  String label = '',
}) =>
    RecipeStep(
      seqNum: seqNum,
      instruction: label.isEmpty ? 'Шаг $seqNum' : label,
      water: water,
      time: time,
      id: seqNum,
      stepType: type,
      stepKey: '',
      tip: '',
      isOptional: false,
      untilUser: false,
      untilSign: '',
      warning: '',
    );

/// Три пролива по тридцать секунд — долгих шагов нет.
RecipeData _recipe({List<RecipeStep>? steps}) => RecipeData(
      id: 1,
      device: 'hario_v60',
      date: '2026-09-09T01:00:00Z',
      packId: 7,
      grinderId: 1,
      grindStep: '18',
      grindSubStep: null,
      water: 250,
      time: 150,
      temperature: 93,
      load: 15,
      title: 'Базовый рецепт',
      notes: '',
      grindDescriptor: 'medium',
      agitationLevel: null,
      steps: steps ?? [_step(1), _step(2), _step(3)],
    );

/// Френч-пресс: залить — и четыре минуты настаивания.
RecipeData _steeping() => _recipe(steps: [
      _step(1, time: 30, water: 250, label: 'Залить воду'),
      _step(2, time: 240, water: 0, type: 'wait', label: 'Настаивание'),
      _step(3, time: 20, water: 0, type: 'press', label: 'Опустить поршень'),
    ]);

/// Запись о заваривании, которое начали [ago] назад и с экрана которого
/// ушли [left] назад (null — с экрана не уходили).
ActiveBrew _started(
  RecipeData recipe, {
  required Duration ago,
  Duration? left,
  bool paused = false,
}) {
  final now = DateTime.now();
  final engine = BrewEngine(
    steps: brewStepsOf(recipe),
    clock: () => now.subtract(ago),
  )..start();
  if (paused) engine.pause();

  return ActiveBrew(
    recipe: recipe,
    pack: null,
    engine: engine.toPersistableState(),
    leftAt: left == null ? null : now.subtract(left),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();
    // Записи живут ещё и в памяти — прошлый тест не должен достаться этому.
    ActiveBrews.load();

    await GetIt.instance.reset();
    GetIt.instance
        .registerSingleton<ApiClient>(ApiClient(onAuthError: () async {}));
  });

  /// Поднимает приложение на экране «Откуда пришли».
  Future<_Router> pumpApp(WidgetTester tester, {RecipeService? recipes}) async {
    // Окно телефона, а не стандартные 800×600: рамка заваривания держит
    // пропорцию, и на широком окне разметка не помещается по высоте.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = _Router();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Справочники экран берёт с сервера. В тесте они пусты: проверяется
          // уход с экрана, а не то, что на нём написано.
          stepTypesProvider.overrideWith((ref) => const StepTypeReference()),
          grindDescriptorsProvider
              .overrideWith((ref) => const <GrindDescriptor>[]),
          if (recipes != null) recipeServiceProvider.overrideWithValue(recipes),
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

    return router;
  }

  /// Открывает экран заваривания поверх «Откуда пришли».
  ///
  /// Без pumpAndSettle нигде: пока заваривание идёт, экран перерисовывается
  /// каждый кадр и успокоиться не может в принципе.
  Future<void> openBrew(
    WidgetTester tester,
    _Router router,
    RecipeData recipe, {
    bool autoStart = false,
    PackData? pack,
  }) async {
    // Без await: push отдаёт результат экрана и ждёт, пока тот закроется.
    unawaited(router
        .push(BrewRoute(recipe: recipe, pack: pack, autoStart: autoStart)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Идущее заваривание поверх экрана «Откуда пришли».
  Future<_Router> pumpBrewing(WidgetTester tester, {RecipeData? recipe}) async {
    final router = await pumpApp(tester);
    await openBrew(tester, router, recipe ?? _recipe(), autoStart: true);

    return router;
  }

  /// Системная кнопка «назад» — тем же сообщением, которым её шлёт телефон.
  Future<void> pressSystemBack(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> tapAndWait(WidgetTester tester, Finder target) async {
    await tester.tap(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Finder button(String label) => find.widgetWithText(ElevatedButton, label);

  BrewStatus? statusOf(RecipeData recipe) =>
      ActiveBrews.find(recipe)?.toEngine()?.snapshot().status;

  group('уход с идущего заваривания', () {
    testWidgets('кнопкой телефона: уходит без вопроса, отсчёт идёт',
        (tester) async {
      await pumpBrewing(tester);
      expect(find.byType(BrewPage), findsOneWidget);

      await pressSystemBack(tester);

      expect(find.text('Прервать заваривание?'), findsNothing,
          reason: 'уход ничего не стирает — и спрашивать о нём не о чем');
      expect(find.byType(BrewPage), findsNothing);
      expect(find.text(_origin), findsOneWidget);
      expect(statusOf(_recipe()), BrewStatus.running,
          reason: 'ушли с экрана — заваривание обязано идти дальше');
    });

    testWidgets('стрелкой в шапке: уходит без вопроса, отсчёт идёт',
        (tester) async {
      await pumpBrewing(tester);

      await tapAndWait(tester, find.byTooltip('Назад'));

      expect(find.text('Прервать заваривание?'), findsNothing);
      expect(find.byType(BrewPage), findsNothing);
      expect(statusOf(_recipe()), BrewStatus.running);
    });

    testWidgets('пауза переживает уход паузой', (tester) async {
      await pumpBrewing(tester);

      await tester.tap(button('Пауза'));
      await tester.pump();
      await pressSystemBack(tester);

      expect(statusOf(_recipe()), BrewStatus.paused,
          reason: 'заваривание стояло на паузе — там же должно и остаться');
    });

    testWidgets('с экрана ушли — в записи стоит, когда', (tester) async {
      await pumpBrewing(tester);
      expect(ActiveBrews.find(_recipe())?.leftAt, isNull,
          reason: 'экран открыт — «ушли» ещё не случилось');

      await pressSystemBack(tester);

      expect(ActiveBrews.find(_recipe())?.leftAt, isNotNull);
    });

    testWidgets('рецепт, который не начинали, записи не оставляет',
        (tester) async {
      final router = await pumpApp(tester);
      await openBrew(tester, router, _recipe());

      await pressSystemBack(tester);

      expect(ActiveBrews.current.value, isEmpty,
          reason: 'открыли и закрыли — плашке «идёт заваривание» не о чем');
    });
  });

  group('возврат к идущему завариванию', () {
    testWidgets('экран показывает шаг, до которого дошли часы', (tester) async {
      // Начали сорок секунд назад: первый пролив на тридцать уже позади.
      await ActiveBrews.put(
          _started(_recipe(), ago: const Duration(seconds: 40)));
      final router = await pumpApp(tester);

      await openBrew(tester, router, _recipe());

      expect(find.text('шаг 2 из 3'), findsOneWidget,
          reason: 'экран открыл рецепт заново, а не идущее заваривание');
      expect(button('Пауза'), findsOneWidget,
          reason: 'главная кнопка предлагает паузу — значит, отсчёт идёт');
    });

    testWidgets('ушли и вернулись — тот же отсчёт, а не новый', (tester) async {
      final router = await pumpBrewing(tester);
      final startedAt = ActiveBrews.find(_recipe())!.engine['started_at'];

      await pressSystemBack(tester);
      await openBrew(tester, router, _recipe());

      expect(button('Пауза'), findsOneWidget);
      expect(ActiveBrews.find(_recipe())!.engine['started_at'], startedAt);
      expect(ActiveBrews.find(_recipe())?.leftAt, isNull,
          reason: 'экран снова перед глазами — отметка «ушли» снята');
    });

    testWidgets('пауза остаётся паузой', (tester) async {
      await ActiveBrews.put(_started(
        _recipe(),
        ago: const Duration(seconds: 10),
        paused: true,
        left: const Duration(seconds: 5),
      ));
      final router = await pumpApp(tester);

      await openBrew(tester, router, _recipe());

      expect(button('Продолжить'), findsOneWidget);
      expect(find.text('шаг 1 из 3'), findsOneWidget);
    });

    testWidgets('отлучились ненадолго — возвращаемся молча', (tester) async {
      await ActiveBrews.put(_started(
        _recipe(),
        ago: const Duration(seconds: 20),
        left: const Duration(seconds: 10),
      ));
      final router = await pumpApp(tester);

      await openBrew(tester, router, _recipe());

      expect(find.text('Начать заново'), findsNothing);
      expect(button('Пауза'), findsOneWidget);
    });

    testWidgets('отлучились дольше шага — экран спрашивает, что случилось',
        (tester) async {
      // Ушли на пятой секунде первого пролива и вернулись через минуту.
      await ActiveBrews.put(_started(
        _recipe(),
        ago: const Duration(seconds: 65),
        left: const Duration(seconds: 60),
      ));
      final router = await pumpApp(tester);

      await openBrew(tester, router, _recipe());

      expect(find.text('Начать заново'), findsOneWidget);
      expect(find.text('Продолжить с этого места'), findsOneWidget);
      expect(find.text('Считать законченным'), findsOneWidget);
    });

    testWidgets('«Начать заново» стирает запись', (tester) async {
      await ActiveBrews.put(_started(
        _recipe(),
        ago: const Duration(seconds: 65),
        left: const Duration(seconds: 60),
      ));
      final router = await pumpApp(tester);
      await openBrew(tester, router, _recipe());

      await tapAndWait(tester, find.text('Начать заново'));

      expect(ActiveBrews.find(_recipe()), isNull);
      expect(find.byType(BrewPage), findsOneWidget);
    });

    testWidgets('доигранное без нас уходит на оценку и запись стирает',
        (tester) async {
      // Часы прошли весь рецепт, но с экрана при этом не уходили — так
      // бывает, когда приложение убили на экране заваривания.
      await ActiveBrews.put(
          _started(_recipe(), ago: const Duration(seconds: 200)));
      final router = await pumpApp(tester);

      await openBrew(tester, router, _recipe());
      // Две секунды «готово» — и экран сам уводит на оценку.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(_rating), findsOneWidget);
      expect(ActiveBrews.find(_recipe()), isNull,
          reason: 'оценили — плашке «идёт заваривание» больше не о чем');
    });
  });

  // С долгого шага экран сам зовёт уйти — и по возвращении не должен за это
  // отчитывать вопросом «начать заново?».
  group('ушли на долгом шаге', () {
    /// Запись о френч-прессе: начали [ago] назад, ушли с экрана [left] назад.
    Future<void> leave({required Duration ago, required Duration left}) async {
      final brew = _started(_steeping(), ago: ago);
      await ActiveBrews.put(brew);
      await ActiveBrews.markLeft(brew.key, DateTime.now().subtract(left));
    }

    testWidgets('вернулись, пока настаивается, — отсчёт идёт как шёл',
        (tester) async {
      await leave(
        ago: const Duration(seconds: 100),
        left: const Duration(seconds: 60),
      );
      final router = await pumpApp(tester);

      await openBrew(tester, router, _steeping());

      expect(find.text('шаг 2 из 3'), findsOneWidget);
      expect(button('Пауза'), findsOneWidget);
      expect(find.text('Начать заново'), findsNothing);
    });

    testWidgets('вернулись после настаивания — следующий шаг ждёт «Продолжить»',
        (tester) async {
      // Начали десять минут назад, ушли на второй минуте настаивания:
      // по часам рецепт давно отыгран.
      await leave(
        ago: const Duration(minutes: 10),
        left: const Duration(minutes: 8),
      );
      final router = await pumpApp(tester);

      await openBrew(tester, router, _steeping());

      expect(find.text('Начать заново'), findsNothing,
          reason: 'ушли по подсказке экрана — и получили за это упрёк');
      expect(find.text('шаг 3 из 3'), findsOneWidget,
          reason: 'поршень без человека никто не опускал');
      expect(button('Продолжить'), findsOneWidget,
          reason: 'начать шаг человек должен сам');
      expect(statusOf(_steeping()), BrewStatus.paused);
      expect(ActiveBrews.find(_steeping())?.heldStep, isNull,
          reason: 'экран открыт — присматривать за шагами снова есть кому');
    });

    testWidgets('«Продолжить» пускает следующий шаг с начала', (tester) async {
      await leave(
        ago: const Duration(minutes: 10),
        left: const Duration(minutes: 8),
      );
      final router = await pumpApp(tester);
      await openBrew(tester, router, _steeping());

      await tester.tap(button('Продолжить'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(button('Пауза'), findsOneWidget);
      final snapshot = ActiveBrews.find(_steeping())!.toEngine()!.snapshot();
      expect(snapshot.stepIndex, 2);
      expect(snapshot.elapsedInStep.inSeconds, lessThan(3));
    });

    testWidgets('свернули приложение на настаивании и вернулись после него',
        (tester) async {
      await ActiveBrews.put(
          _started(_steeping(), ago: const Duration(seconds: 40)));
      final router = await pumpApp(tester);
      await openBrew(tester, router, _steeping());

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(ActiveBrews.find(_steeping())?.heldStep, 1,
          reason: 'свёрнутое приложение система может убить — что заваривание '
              'ждёт в конце настаивания, должно лежать в записи');

      // Настаивание кончилось, пока приложение было свёрнуто: сдвигаем
      // запись в прошлое, как будто прошло десять минут.
      final held = ActiveBrews.find(_steeping())!;
      final shifted = _started(_steeping(), ago: const Duration(minutes: 10));
      await ActiveBrews.put(ActiveBrew(
        recipe: held.recipe,
        pack: held.pack,
        engine: shifted.engine,
        leftAt: DateTime.now().subtract(const Duration(minutes: 9)),
        heldStep: held.heldStep,
      ));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Начать заново'), findsNothing);
      expect(find.text('шаг 3 из 3'), findsOneWidget);
      expect(button('Продолжить'), findsOneWidget);
    });
  });

  // Справочный рецепт метода общий: пачки у него нет, и своим он становился
  // только при оценке. Заваривание, которое до неё не довели, на «Рецептах»
  // не появлялось вовсе. Владелец: «чтобы рецепт появлялся на экране
  // рецептов, даже если он не закончен».
  group('справочный рецепт', () {
    /// Рецепт метода из справочника: пачка 0.
    RecipeData reference() => _recipe()..packId = 0;

    /// Он же, сохранённый своей копией под пачку, — как его отдаст список.
    RecipeData own() => _recipe()
      ..id = 901
      ..date = '2026-11-06T01:00:00Z';

    testWidgets('со стартом становится рецептом этой пачки', (tester) async {
      final recipes = _Recipes();
      final router = await pumpApp(tester, recipes: recipes);
      await openBrew(tester, router, reference(), pack: _pack());
      expect(recipes.evolved, isEmpty,
          reason: 'открыли и посмотрели — сохранять ещё нечего');

      await tapAndWait(tester, button('Смолол, начинаем'));

      expect(recipes.evolved, hasLength(1));
      expect(recipes.evolved.single.packId, 7,
          reason: 'копия без пачки — это второй справочный рецепт, и сервер '
              'её не примет');
      expect(ActiveBrews.find(reference(), _pack())?.savedVersionId, 901);
    });

    testWidgets('свой рецепт, заваренный как есть, не сохраняется заново',
        (tester) async {
      final recipes = _Recipes();
      final router = await pumpApp(tester, recipes: recipes);
      await openBrew(tester, router, _recipe(), pack: _pack());

      await tapAndWait(tester, button('Смолол, начинаем'));

      expect(recipes.evolved, isEmpty);
    });

    testWidgets('прервали и начали снова — копия одна', (tester) async {
      final recipes = _Recipes();
      final router = await pumpApp(tester, recipes: recipes);
      await openBrew(tester, router, reference(), pack: _pack());
      await tapAndWait(tester, button('Смолол, начинаем'));

      await tester.tap(button('Пауза'));
      await tester.pump();
      await tapAndWait(tester, find.byKey(const ValueKey('brew-abort')));
      await tapAndWait(tester, find.widgetWithText(TextButton, 'Прервать'));
      await tapAndWait(tester, button('Смолол, начинаем'));

      expect(recipes.evolved, hasLength(1));
      expect(ActiveBrews.find(reference(), _pack())?.savedVersionId, 901,
          reason: 'второе заваривание оценит ту же копию, а не заведёт новую');
    });

    testWidgets('оценку получает своя копия, а не общий рецепт',
        (tester) async {
      // Заваривание доиграло; копия сохранена при старте под номером 901.
      await ActiveBrews.put(ActiveBrew(
        recipe: reference(),
        pack: _pack(),
        engine: _started(reference(), ago: const Duration(seconds: 200)).engine,
        savedVersionId: 901,
      ));
      final router = await pumpApp(tester, recipes: _Recipes());

      await openBrew(tester, router, reference(), pack: _pack());
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(_rating), findsOneWidget);
      final rated = (router.current.args as RatingRouteArgs).recipe;
      expect(rated.id, 901);
      expect(rated.packId, 7,
          reason: 'с пачкой 0 экран оценки принял бы копию за справочный '
              'рецепт и завёл бы ещё одну');
    });

    testWidgets('карточка сохранённой копии ведёт к тому же таймеру',
        (tester) async {
      // Заваривают справочный рецепт; его копия уже стоит на «Рецептах», и
      // нажали на неё, а не на плашку.
      await ActiveBrews.put(ActiveBrew(
        recipe: reference(),
        pack: _pack(),
        engine: _started(reference(), ago: const Duration(seconds: 40)).engine,
        savedVersionId: 901,
      ));
      final router = await pumpApp(tester, recipes: _Recipes());

      await openBrew(tester, router, own(), pack: _pack());

      expect(find.text('шаг 2 из 3'), findsOneWidget,
          reason: 'экран открыл рецепт заново рядом с идущим завариванием');
      expect(button('Пауза'), findsOneWidget);
      expect(ActiveBrews.current.value, hasLength(1),
          reason: 'у одного заваривания — одна плашка');
      expect(ActiveBrews.find(own(), _pack()), isNotNull);
    });
  });

  group('прерывание', () {
    testWidgets('«Прервать» появляется на паузе вместо «Пропустить»',
        (tester) async {
      await pumpBrewing(tester);
      expect(find.byKey(const ValueKey('brew-abort')), findsNothing);
      expect(button('Пропустить'), findsOneWidget);

      await tester.tap(button('Пауза'));
      await tester.pump();

      expect(find.byKey(const ValueKey('brew-abort')), findsOneWidget);
      expect(button('Пропустить'), findsNothing);
    });

    testWidgets('«Прервать» спрашивает — и возвращает рецепт к старту',
        (tester) async {
      await pumpBrewing(tester);
      await tester.tap(button('Пауза'));
      await tester.pump();

      await tapAndWait(tester, find.byKey(const ValueKey('brew-abort')));
      expect(find.text('Прервать заваривание?'), findsOneWidget);

      await tapAndWait(tester, find.widgetWithText(TextButton, 'Прервать'));

      expect(find.text('Прервать заваривание?'), findsNothing);
      expect(find.byType(BrewPage), findsOneWidget,
          reason:
              'прерывают, чтобы начать заново, — уводить с рецепта незачем');
      expect(button('Смолол, начинаем'), findsOneWidget);
      expect(ActiveBrews.find(_recipe()), isNull,
          reason: 'прервали — отсчёта больше нет ни на экране, ни на плашке');
    });

    testWidgets('«Не прерывать» оставляет заваривание на паузе',
        (tester) async {
      await pumpBrewing(tester);
      await tester.tap(button('Пауза'));
      await tester.pump();

      await tapAndWait(tester, find.byKey(const ValueKey('brew-abort')));
      await tapAndWait(tester, find.widgetWithText(TextButton, 'Не прерывать'));

      expect(button('Продолжить'), findsOneWidget);
      expect(statusOf(_recipe()), BrewStatus.paused);
    });

    testWidgets('прерванное заваривание не уводит на оценку', (tester) async {
      await pumpBrewing(tester);
      await tester.tap(button('Пауза'));
      await tester.pump();
      await tapAndWait(tester, find.byKey(const ValueKey('brew-abort')));
      await tapAndWait(tester, find.widgetWithText(TextButton, 'Прервать'));

      // Оценка — конец заваривания, а не его прерывания. Ждём с запасом:
      // переход на неё отложенный.
      await tester.pump(const Duration(seconds: 5));

      expect(find.text(_rating), findsNothing);
      expect(find.byType(BrewPage), findsOneWidget);
    });
  });

  group('долгий шаг', () {
    final hint = find.byKey(const ValueKey('brew-leave-hint'));

    testWidgets('на настаивании экран говорит, что можно выйти',
        (tester) async {
      // Залили сорок секунд назад — идёт настаивание на четыре минуты.
      await ActiveBrews.put(
          _started(_steeping(), ago: const Duration(seconds: 40)));
      final router = await pumpApp(tester);

      await openBrew(tester, router, _steeping());

      expect(hint, findsOneWidget);
      expect(find.text('Можно выйти из рецепта'), findsOneWidget);
    });

    testWidgets('на коротком проливе подсказки нет', (tester) async {
      await pumpBrewing(tester, recipe: _steeping());

      expect(hint, findsNothing,
          reason: 'идёт пролив — звать человека с экрана значит сбить');
    });

    testWidgets('до старта подсказки нет', (tester) async {
      final router = await pumpApp(tester);
      await openBrew(tester, router, _steeping());

      expect(hint, findsNothing);
    });

    testWidgets('на паузе подсказки нет: часы стоят, уходить не от чего',
        (tester) async {
      await ActiveBrews.put(
          _started(_steeping(), ago: const Duration(seconds: 40)));
      final router = await pumpApp(tester);
      await openBrew(tester, router, _steeping());

      await tester.tap(button('Пауза'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(hint, findsNothing);
    });

    testWidgets('подсказка уводит на «Рецепты», заваривание идёт',
        (tester) async {
      await ActiveBrews.put(
          _started(_steeping(), ago: const Duration(seconds: 40)));
      final router = await pumpApp(tester);
      await openBrew(tester, router, _steeping());

      await tapAndWait(tester, hint);

      expect(find.text(_recipes), findsOneWidget);
      expect(find.byType(BrewPage), findsNothing);
      expect(statusOf(_steeping()), BrewStatus.running);
    });
  });
}
