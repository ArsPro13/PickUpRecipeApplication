// Объём воды на экране заваривания — вариант 1 «Барабан в шторке».
//
// Нажали «250 мл» в строке параметров — шторка с барабаном. «Готово» на
// 500 мл — экран пересчитан: доза, клики, шаги, движок. «Вернуть» — снова
// рецепт как есть. После старта вода не нажимается: вода уже в воронке, и
// менять шаги под идущим таймером нельзя.
//
// Кофемолка человека здесь — та же, что в рецепте (Comandante C40, 27
// кликов): так деление, с которого считается новый помол, берётся прямо из
// рецепта, и справочник крупности тесту не нужен.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/grinders/application/grinder_state.dart';
import 'package:pick_up_recipe/src/features/grinders/data_sources/remote/grinder_service.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/models/grinder_model.dart';
import 'package:pick_up_recipe/src/features/recipes/application/step_types_state.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/grind_descriptor_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/step_type_model.dart';
import 'package:pick_up_recipe/src/general_widgets/water_scale_sheet.dart';
import 'package:pick_up_recipe/src/pages/brew_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comandante C40 со шкалой из grinders.db: деления кончаются на 31.
final Grinder c40 = Grinder(
  id: 11,
  name: 'Comandante C40',
  kind: GrinderKind.manual,
  modes: [
    for (final (mode, microns) in const [
      ('11', 554.0), ('12', 568.0), ('13', 583.0), ('14', 606.0), //
      ('15', 629.0), ('16', 662.0), ('17', 695.0), ('18', 738.0),
      ('19', 780.0), ('20', 820.0), ('21', 859.0), ('22', 910.0),
      ('23', 961.0), ('24', 1008.0), ('25', 1054.0), ('26', 1119.0),
      ('27', 1184.0), ('28', 1211.0), ('29', 1237.0), ('30', 1268.0),
      ('31', 1299.0),
    ])
      // Подписи делений — как их отдаёт сервер: «27.0», а не «27».
      GrinderMode(mode: '$mode.0', microns: microns),
  ],
);

/// Профиль человека: одна кофемолка, она же основная.
class _OwnGrinder implements GrinderService {
  @override
  Future<List<Grinder>> getAllGrinders() async => [c40];

  @override
  Future<List<UserGrinder>> getUserGrinders() async =>
      [UserGrinder(grinder: c40, isPrimary: true)];

  @override
  Future<List<UserGrinder>> setUserGrinders(
    List<Grinder> grinders, {
    int? primaryGrinderId,
  }) =>
      getUserGrinders();
}

class _Origin extends StatelessWidget {
  const _Origin();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Откуда пришли')));
}

const _originName = 'OriginRoute';

class _Router extends RootStackRouter {
  @override
  Map<String, PageFactory> get pagesMap => {
        _originName: (data) =>
            AutoRoutePage<dynamic>(routeData: data, child: const _Origin()),
        BrewRoute.name: (data) {
          final args = data.argsAs<BrewRouteArgs>();
          return AutoRoutePage<dynamic>(
            routeData: data,
            child: BrewPage(recipe: args.recipe, pack: args.pack),
          );
        },
      };

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: const PageInfo(_originName), path: '/', initial: true),
        AutoRoute(page: BrewRoute.page, path: '/brew'),
      ];
}

RecipeStep _step(int seq, String type, String label,
        {int water = 0, required int time}) =>
    RecipeStep(
      seqNum: seq,
      instruction: label,
      water: water,
      time: time,
      id: seq,
      stepType: type,
      stepKey: 's$seq',
      tip: '',
      isOptional: false,
      untilUser: false,
      untilSign: '',
      warning: '',
    );

/// «Бразилия Можиана» на V60, как на стенде.
RecipeData moziana({String device = 'hario_v60'}) => RecipeData(
      id: 77,
      device: device,
      date: '2026-11-01T00:00:00Z',
      packId: 7,
      grinderId: 11,
      grindStep: '27',
      grindSubStep: null,
      water: 250,
      time: 160,
      temperature: 92,
      load: 15,
      title: 'Можиана, V60',
      notes: '',
      grindDescriptor: 'medium',
      agitationLevel: null,
      steps: [
        _step(1, 'bloom', 'Предсмачивание', water: 45, time: 30),
        _step(2, 'pour', 'Первый пролив', water: 105, time: 35),
        _step(3, 'wait', 'Пауза', time: 10),
        _step(4, 'pour', 'Второй пролив', water: 100, time: 35),
        _step(5, 'wait', 'Ждём пролива', time: 50),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();

    await GetIt.instance.reset();
    GetIt.instance
        .registerSingleton<ApiClient>(ApiClient(onAuthError: () async {}));
  });

  /// Экран заваривания до старта: рамка «Смелите кофе», таймер стоит.
  Future<void> pumpBrew(WidgetTester tester, RecipeData recipe) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = _Router();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stepTypesProvider.overrideWith((ref) => const StepTypeReference()),
          grindDescriptorsProvider
              .overrideWith((ref) => const <GrindDescriptor>[]),
          grinderStateProvider.overrideWith(
              (ref) => GrinderStateNotifier(_OwnGrinder())..loadUserGrinders()),
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

    unawaited(router.push(BrewRoute(recipe: recipe, pack: null)));
    await tester.pumpAndSettle();
  }

  Finder param(String name) => find.byKey(ValueKey('brew-param-$name'));

  Finder rich(String text) => find.textContaining(text, findRichText: true);

  /// Открывает шторку, ставит барабан на [water] и жмёт «Готово».
  Future<void> chooseWater(WidgetTester tester, int water) async {
    await tester.tap(param('water'));
    await tester.pumpAndSettle();

    final wheel =
        tester.widget<ListWheelScrollView>(find.byType(ListWheelScrollView));
    (wheel.controller! as FixedExtentScrollController)
        .jumpToItem(waterWheelValues(250).indexOf(water));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
  }

  group('объём воды', () {
    testWidgets('нажатие на воду открывает шторку с барабаном', (tester) async {
      await pumpBrew(tester, moziana());

      expect(find.text('250 мл'), findsOneWidget);
      await tester.tap(param('water'));
      await tester.pumpAndSettle();

      expect(find.text('Сколько воды'), findsOneWidget);
      expect(find.text('в рецепте 250 мл'), findsOneWidget);
      expect(find.byType(ListWheelScrollView), findsOneWidget);
      expect(find.text('как в рецепте'), findsOneWidget,
          reason: 'барабан открылся на воде рецепта');
      expect(find.text('Как в рецепте'), findsOneWidget);
    });

    testWidgets('сводка под барабаном меняется вместе с ним', (tester) async {
      await pumpBrew(tester, moziana());
      await tester.tap(param('water'));
      await tester.pumpAndSettle();

      final wheel =
          tester.widget<ListWheelScrollView>(find.byType(ListWheelScrollView));
      final controller = wheel.controller! as FixedExtentScrollController;
      controller.jumpToItem(waterWheelValues(250).indexOf(500));
      await tester.pumpAndSettle();

      expect(rich('30 г'), findsWidgets);
      expect(rich('31 клик'), findsWidgets);
      expect(rich('3:10'), findsOneWidget);
      expect(rich('440 мл'), findsOneWidget);

      // «Как в рецепте» ведёт барабан обратно к 250.
      await tester.tap(find.text('Как в рецепте'));
      await tester.pumpAndSettle();
      expect(find.text('как в рецепте'), findsOneWidget);
    });

    testWidgets('барабан не прыгает: шторка одной высоты при любой воде',
        (tester) async {
      await pumpBrew(tester, moziana());
      await tester.tap(param('water'));
      await tester.pumpAndSettle();

      final wheelFinder = find.byType(ListWheelScrollView);
      final controller = tester
          .widget<ListWheelScrollView>(wheelFinder)
          .controller! as FixedExtentScrollController;
      final at250 = tester.getRect(wheelFinder);

      // 500 — две строки сводки; 1000 — ещё и три предупреждения на экране
      // после «Готово». Шторка обязана остаться той же высоты.
      for (final water in [500, 1000, 120]) {
        controller.jumpToItem(waterWheelValues(250).indexOf(water));
        await tester.pumpAndSettle();
        expect(tester.getRect(wheelFinder), at250, reason: '$water мл');
      }
    });

    testWidgets('«Готово» на 500 мл пересчитывает экран', (tester) async {
      await pumpBrew(tester, moziana());
      await chooseWater(tester, 500);

      expect(find.text('Сколько воды'), findsNothing, reason: 'шторка ушла');
      expect(find.text('500 мл'), findsOneWidget);
      expect(find.text('30 г'), findsOneWidget);
      expect(find.text('31 клик'), findsOneWidget);
      expect(find.text('30 г · 31 клик'), findsOneWidget,
          reason: 'рамка «Смелите кофе» с новыми числами');
      expect(rich('Пересчитано на 500 мл · было 250'), findsOneWidget);
      expect(rich('было 27'), findsOneWidget, reason: 'старое деление');
      expect(find.text('шаг 1 из 5'), findsOneWidget);
    });

    testWidgets('750 мл в V60-02: пролив частями и край шкалы C40',
        (tester) async {
      await pumpBrew(tester, moziana());
      await chooseWater(tester, 750);

      // Каждый пролив — в две части, и движок пересобран под новые шаги.
      expect(find.text('шаг 1 из 9'), findsOneWidget);
      expect(rich('Не помещается в воронку 02'), findsOneWidget);
      expect(rich('В воронку 03 войдёт целиком'), findsOneWidget);
      expect(rich('Comandante C40: шкала кончается на 31'), findsOneWidget);
      expect(find.text('89 °C'), findsOneWidget);
    });

    testWidgets('«Вернуть» возвращает рецепт как есть', (tester) async {
      await pumpBrew(tester, moziana());
      await chooseWater(tester, 750);

      await tester.tap(find.text('Вернуть'));
      await tester.pumpAndSettle();

      expect(find.text('250 мл'), findsOneWidget);
      expect(find.text('15 г · 27 кликов'), findsOneWidget);
      expect(find.text('92 °C'), findsOneWidget);
      expect(find.text('шаг 1 из 5'), findsOneWidget);
      expect(rich('Пересчитано'), findsNothing);
    });

    testWidgets('после старта вода не нажимается', (tester) async {
      await pumpBrew(tester, moziana());
      await chooseWater(tester, 500);

      await tester.tap(find.text('Смолол, начинаем'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(rich('Пересчитано'), findsNothing,
          reason: 'после старта плашка уступает место шагам');
      expect(find.text('500 мл'), findsOneWidget,
          reason: 'заваривание идёт по пересчитанному рецепту');

      await tester.tap(param('water'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Сколько воды'), findsNothing);
    });

    testWidgets('прибор без профиля — вода не нажимается', (tester) async {
      await pumpBrew(tester, moziana(device: 'aeropress'));

      await tester.tap(param('water'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Сколько воды'), findsNothing);
      expect(find.text('250 мл'), findsOneWidget);
    });
  });
}
