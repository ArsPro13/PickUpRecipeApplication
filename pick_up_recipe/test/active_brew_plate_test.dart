// Плашка «Идёт заваривание» на «Рецептах» и «Пачках».
//
// Плашка — единственное место, где видно заваривание, с экрана которого ушли.
// Ломается она тихо: не показалась — и человек решил, что отсчёт пропал;
// показала не то состояние — и он пошёл к воронке, которая ещё настаивается;
// увела не к тому рецепту; крестик стёр идущий таймер без вопроса.

import 'package:auto_route/auto_route.dart';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/recipes/application/active_brew.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/brew_engine.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/brew_step.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/general_widgets/active_brew_plate.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Роутер, который никуда не ведёт, а записывает, куда его просили.
class _RecordingRouter extends RootStackRouter {
  final List<PageRouteInfo> pushed = [];

  @override
  List<AutoRoute> get routes => const [];

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    pushed.add(route);
    return null;
  }
}

RecipeStep _step(
  int seqNum, {
  int time = 30,
  String type = 'pour',
  String label = '',
  bool untilUser = false,
}) =>
    RecipeStep(
      seqNum: seqNum,
      instruction: label.isEmpty ? 'Шаг $seqNum' : label,
      water: type == 'pour' ? 60 : 0,
      time: time,
      id: seqNum,
      stepType: type,
      stepKey: '',
      tip: '',
      isOptional: false,
      untilUser: untilUser,
      untilSign: '',
      warning: '',
    );

RecipeData _recipe({
  int id = 42,
  String title = 'Харио V60',
  List<RecipeStep>? steps,
}) =>
    RecipeData(
      id: id,
      device: 'hario_v60',
      date: '2026-11-05T10:00:00Z',
      packId: 7,
      grinderId: 1,
      grindStep: '18',
      grindSubStep: null,
      water: 250,
      time: 90,
      temperature: 93,
      load: 15,
      title: title,
      notes: '',
      grindDescriptor: 'medium',
      agitationLevel: null,
      steps: steps ?? [_step(1), _step(2), _step(3)],
    );

/// Клевер: залить, закрыть — и ждать слова «сделал».
RecipeData _gated() => _recipe(
      id: 43,
      title: 'Клевер',
      steps: [
        _step(1),
        _step(2,
            time: 0,
            type: 'open_valve',
            label: 'Открыть клапан',
            untilUser: true),
        _step(3),
      ],
    );

PackData _pack() => PackData(
      packId: 7,
      userId: '1',
      packDate: '2026-11-01T10:00:00Z',
      packName: 'Бразилия Можиана',
      packDescriptors: const [],
      packCountry: 'Бразилия',
      packProcessingMethod: const [],
      packImage: '',
      packVariety: 'бурбон',
      packScaScore: 84,
      isActive: true,
      roasterName: 'Tasty',
    );

/// Запись о заваривании, начатом [ago] назад.
ActiveBrew _started(
  RecipeData recipe, {
  Duration ago = Duration.zero,
  bool paused = false,
  bool withPack = true,
}) {
  final now = DateTime.now();
  final engine = BrewEngine(
    steps: brewStepsOf(recipe),
    clock: () => now.subtract(ago),
  )..start();
  if (paused) engine.pause();

  return ActiveBrew(
    recipe: recipe,
    pack: withPack ? _pack() : null,
    engine: engine.toPersistableState(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();
    ActiveBrews.load();
  });

  Future<_RecordingRouter> pumpPlate(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = _RecordingRouter();

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StackRouterScope(
          controller: router,
          stateHash: 0,
          child: const Scaffold(
            body: Column(children: [ActiveBrewPlate()]),
          ),
        ),
      ),
    );
    await tester.pump();

    return router;
  }

  final time = find.byKey(const ValueKey('active-brew-time'));

  testWidgets('заваривания нет — плашки нет', (tester) async {
    await pumpPlate(tester);

    expect(find.text('Идёт заваривание'), findsNothing);
    expect(tester.getSize(find.byType(ActiveBrewPlate)).height, 0,
        reason: 'пустая плашка не должна отнимать место у списка');
  });

  testWidgets('идущее заваривание: чьё, какой шаг и сколько осталось',
      (tester) async {
    await ActiveBrews.put(
        _started(_recipe(), ago: const Duration(seconds: 40)));
    await pumpPlate(tester);

    expect(find.text('Идёт заваривание'), findsOneWidget);
    expect(
        find.text('Бразилия Можиана · Харио V60 · шаг 2 из 3'), findsOneWidget);
    // Сорок секунд из шестидесяти: до конца второго пролива — около двадцати.
    expect(tester.widget<Text>(time).data, matches(RegExp(r'^0:(19|20)$')));
  });

  testWidgets('плашка появляется, когда заваривание началось', (tester) async {
    await pumpPlate(tester);
    expect(find.text('Идёт заваривание'), findsNothing);

    await ActiveBrews.put(_started(_recipe()));
    await tester.pump();

    expect(find.text('Идёт заваривание'), findsOneWidget);
  });

  testWidgets('пауза: время стоит и названо паузой', (tester) async {
    await ActiveBrews.put(_started(
      _recipe(),
      ago: const Duration(seconds: 10),
      paused: true,
    ));
    await pumpPlate(tester);

    expect(find.text('Заваривание на паузе'), findsOneWidget);
    expect(tester.widget<Text>(time).data, '0:30',
        reason: 'пауза поставлена на старте — до конца шага все тридцать');
  });

  testWidgets('шаг ждёт человека: названо действие, а не номер шага',
      (tester) async {
    await ActiveBrews.put(_started(_gated(), ago: const Duration(minutes: 5)));
    await pumpPlate(tester);

    expect(find.text('Заваривание ждёт вас'), findsOneWidget);
    expect(find.text('Бразилия Можиана · Клевер · Открыть клапан'),
        findsOneWidget);
    expect(time, findsNothing, reason: 'ждут человека, а не секундомер');
  });

  testWidgets('долгий шаг доигран без нас: ждёт вас — и назван следующий шаг',
      (tester) async {
    // Френч-пресс: ушли на настаивании и задержались.
    final frenchPress = _recipe(
      id: 44,
      title: 'Френч-пресс',
      steps: [
        _step(1),
        _step(2, time: 240, type: 'wait', label: 'Настаивание'),
        _step(3, type: 'stir', label: 'Снять корку'),
      ],
    );
    final brew = _started(frenchPress, ago: const Duration(minutes: 10));
    await ActiveBrews.put(brew);
    await ActiveBrews.markLeft(
      brew.key,
      DateTime.now().subtract(const Duration(minutes: 8)),
    );
    await pumpPlate(tester);

    expect(find.text('Заваривание ждёт вас'), findsOneWidget);
    expect(find.text('Бразилия Можиана · Френч-пресс · Снять корку'),
        findsOneWidget,
        reason: '«настаивание» читалось бы как «всё ещё настаивается»');
    expect(find.text('Заваривание закончилось'), findsNothing,
        reason: 'корку без человека никто не снял');
  });

  testWidgets('доигранное без нас: закончилось, времени нет', (tester) async {
    await ActiveBrews.put(_started(_recipe(), ago: const Duration(minutes: 5)));
    await pumpPlate(tester);

    expect(find.text('Заваривание закончилось'), findsOneWidget);
    expect(find.text('Бразилия Можиана · Харио V60'), findsOneWidget);
    expect(time, findsNothing);
  });

  testWidgets('без пачки подписан одним прибором', (tester) async {
    await ActiveBrews.put(_started(_recipe(), withPack: false));
    await pumpPlate(tester);

    expect(find.text('Харио V60 · шаг 1 из 3'), findsOneWidget);
  });

  testWidgets('нажатие ведёт к этому же рецепту', (tester) async {
    await ActiveBrews.put(_started(_recipe()));
    final router = await pumpPlate(tester);

    await tester.tap(find.text('Идёт заваривание'));
    await tester.pump();

    final route = router.pushed.single;
    expect(route.routeName, BrewRoute.name);
    final args = route.args as BrewRouteArgs;
    expect(args.recipe.id, 42);
    expect(args.pack?.packName, 'Бразилия Можиана');
    expect(args.autoStart, isFalse,
        reason: 'экран сам подхватит идущее — запускать заново нельзя');
  });

  testWidgets('два заваривания — две плашки', (tester) async {
    await ActiveBrews.put(_started(_gated(), ago: const Duration(minutes: 5)));
    await ActiveBrews.put(_started(_recipe()));
    await pumpPlate(tester);

    expect(find.text('Идёт заваривание'), findsOneWidget);
    expect(find.text('Заваривание ждёт вас'), findsOneWidget);
  });

  group('крестик', () {
    testWidgets('идущее заваривание прерывает только после вопроса',
        (tester) async {
      await ActiveBrews.put(_started(_recipe()));
      await pumpPlate(tester);

      await tester.tap(find.byTooltip('Прервать'));
      await tester.pumpAndSettle();

      expect(find.text('Прервать заваривание?'), findsOneWidget);
      expect(ActiveBrews.find(_recipe()), isNotNull,
          reason: 'пока не ответили — отсчёт идёт');

      await tester.tap(find.widgetWithText(TextButton, 'Прервать'));
      await tester.pumpAndSettle();

      expect(ActiveBrews.find(_recipe()), isNull);
      expect(find.text('Идёт заваривание'), findsNothing);
    });

    testWidgets('«Не прерывать» оставляет заваривание идти', (tester) async {
      await ActiveBrews.put(_started(_recipe()));
      await pumpPlate(tester);

      await tester.tap(find.byTooltip('Прервать'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Не прерывать'));
      await tester.pumpAndSettle();

      expect(ActiveBrews.find(_recipe()), isNotNull);
      expect(find.text('Идёт заваривание'), findsOneWidget);
    });

    testWidgets('доигранное убирает сразу: прерывать в нём нечего',
        (tester) async {
      await ActiveBrews.put(
          _started(_recipe(), ago: const Duration(minutes: 5)));
      await pumpPlate(tester);

      await tester.tap(find.byTooltip('Убрать'));
      await tester.pumpAndSettle();

      expect(find.text('Прервать заваривание?'), findsNothing);
      expect(ActiveBrews.find(_recipe()), isNull);
    });
  });
}
