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
import 'package:pick_up_recipe/src/features/brew_methods/application/brew_methods_state.dart';
import 'package:pick_up_recipe/src/features/brew_methods/data_sources/remote/brew_method_service.dart';
import 'package:pick_up_recipe/src/features/brew_methods/domain/brew_method.dart';
import 'package:pick_up_recipe/src/features/grinders/application/grinder_state.dart';
import 'package:pick_up_recipe/src/features/grinders/data_sources/remote/grinder_service.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/models/grinder_model.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipes_list_state.dart';
import 'package:pick_up_recipe/src/features/recipes/application/step_types_state.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/grind_descriptor_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/step_type_model.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/scaling/recipe_scaler.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/scaling/scaling_profile.dart';
import 'package:pick_up_recipe/src/general_widgets/app_kit.dart';
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

/// Профиль без кофемолки: человек свою ещё не выбрал.
class _NoGrinder implements GrinderService {
  @override
  Future<List<Grinder>> getAllGrinders() async => [c40];

  @override
  Future<List<UserGrinder>> getUserGrinders() async => const [];

  @override
  Future<List<UserGrinder>> setUserGrinders(
    List<Grinder> grinders, {
    int? primaryGrinderId,
  }) =>
      getUserGrinders();
}

/// Сервер рецептов: запоминает версии, которые экран просил сохранить.
class _Recipes extends RecipeService {
  final evolved = <RecipeData>[];

  @override
  Future<int> evolveRecipe(RecipeData recipe) async {
    evolved.add(copyRecipe(recipe));
    return 901;
  }
}

/// Справочник методов с одним эспрессо: «вода» у него — вес в чашке.
class _Catalog extends BrewMethodsNotifier {
  _Catalog() : super(BrewMethodService()) {
    state = const BrewMethodsState(
      status: BrewMethodsStatus.ready,
      grouped: [
        GroupedMethods(name: 'Давление', slug: 'pressure', methods: [
          BrewMethod(
            id: 1,
            slug: 'espresso',
            name: 'Эспрессо',
            iconKey: 'espresso',
            waterMeaning: 'in_cup',
          ),
        ]),
      ],
    );
  }
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

/// Деления барабана V60 — те, что откроет шторка.
List<int> v60Wheel() =>
    scaleWheelValues(moziana(), ScalingProfile.builtIn('hario_v60')!);

/// Двойной эспрессо: 18 г в корзину, 36 г в чашке.
RecipeData doubleShot() => RecipeData(
      id: 78,
      device: 'espresso',
      date: '2026-11-01T00:00:00Z',
      packId: 7,
      grinderId: 11,
      grindStep: '27',
      grindSubStep: null,
      water: 36,
      time: 67,
      temperature: 93,
      load: 18,
      title: 'Эспрессо',
      notes: '',
      grindDescriptor: 'fine',
      agitationLevel: null,
      steps: [
        _step(1, 'grind', 'Смолоть в корзину', time: 20),
        _step(2, 'custom', 'Разровнять и утрамбовать', time: 15),
        _step(3, 'pour', 'Пролив', water: 36, time: 27),
        _step(4, 'serve', 'Подавать', time: 5),
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
  Future<void> pumpBrew(
    WidgetTester tester,
    RecipeData recipe, {
    RecipeService? recipes,
    GrinderService? grinders,
    bool catalog = false,
  }) async {
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
          grinderStateProvider.overrideWith((ref) =>
              GrinderStateNotifier(grinders ?? _OwnGrinder())
                ..loadUserGrinders()),
          recipeServiceProvider.overrideWithValue(recipes ?? _Recipes()),
          if (catalog) brewMethodsProvider.overrideWith((ref) => _Catalog()),
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
        .jumpToItem(v60Wheel().indexOf(water));
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
      controller.jumpToItem(v60Wheel().indexOf(500));
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
        controller.jumpToItem(v60Wheel().indexOf(water));
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

    testWidgets('старт пересчитанного рецепта — новая версия, одна',
        (tester) async {
      final recipes = _Recipes();
      await pumpBrew(tester, moziana(), recipes: recipes);
      await chooseWater(tester, 500);
      // Подписи «Начнёте — сохранится новой версией рецепта» больше нет:
      // владелец назвал её бесполезной (04.11). Версия при этом сохраняется.
      expect(rich('сохранится новой версией'), findsNothing);

      await tester.tap(find.text('Смолол, начинаем'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(recipes.evolved, hasLength(1));
      final version = recipes.evolved.single;
      expect(version.water, 500);
      expect(version.load, 30);
      expect(version.grindStep, '31.0', reason: 'новое деление C40');
      expect(version.steps.first.water, 90, reason: 'предсмачивание ×2');

      // Пауза и снова старт — та же правка, второй версии нет.
      // «Пауза» — и шаг рецепта, и главная кнопка; жмём кнопку.
      Finder button(String label) =>
          find.ancestor(of: find.text(label), matching: find.byType(AppButton));
      await tester.tap(button('Пауза'));
      await tester.pump();
      await tester.tap(button('Продолжить'));
      await tester.pump();
      expect(recipes.evolved, hasLength(1));
    });

    // Владелец 04.11: «почему не меняются клики при изменении объёма в
    // случае воронки». Клики стояли, когда пересчёт не знал шкалы: рецепт
    // записан делениями чужой кофемолки без слова крупности, кофемолка не
    // выбрана, сервис шкал молчал.
    testWidgets('рецепт с чужой кофемолки без слова: клики свои и двигаются',
        (tester) async {
      // Обжарщик записал 45 делений DF64 и слово крупности не выбрал.
      // Раньше экран писал «45 кликов» — чужие, как будто ваши, — и
      // пересчёт их не трогал.
      final recipe = moziana()
        ..grinderId = 12
        ..grindStep = '45'
        ..grindDescriptor = '';
      await pumpBrew(tester, recipe);

      expect(rich('20 кликов'), findsWidgets, reason: 'DF64 45 ≈ C40 20');
      expect(rich('45 клик'), findsNothing);

      await chooseWater(tester, 500);
      expect(rich('22 клика'), findsWidgets);
      expect(rich('было 20'), findsWidgets);
    });

    testWidgets('без своей кофемолки — клики Comandante C40, и они двигаются',
        (tester) async {
      await pumpBrew(tester, moziana(), grinders: _NoGrinder());

      expect(rich('27 кликов'), findsWidgets);
      expect(rich('выберите свою'), findsWidgets);

      await chooseWater(tester, 500);
      expect(rich('31 клик'), findsWidgets);
      expect(rich('было 27'), findsWidgets);
    });

    testWidgets('рецепт как есть — новой версии нет', (tester) async {
      final recipes = _Recipes();
      await pumpBrew(tester, moziana(), recipes: recipes);

      await tester.tap(find.text('Смолол, начинаем'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(recipes.evolved, isEmpty);
    });

    testWidgets('эспрессо: барабан в граммах, больше — ещё шот',
        (tester) async {
      await pumpBrew(tester, doubleShot(), catalog: true);
      Finder water(String text) =>
          find.descendant(of: param('water'), matching: find.text(text));
      expect(water('36 г'), findsOneWidget, reason: 'вес в чашке');

      await tester.tap(param('water'));
      await tester.pumpAndSettle();
      expect(find.text('в рецепте 36 г'), findsOneWidget);

      final wheel =
          tester.widget<ListWheelScrollView>(find.byType(ListWheelScrollView));
      (wheel.controller! as FixedExtentScrollController).jumpToItem(1);
      await tester.pumpAndSettle();
      expect(rich('2 шота'), findsOneWidget);
      expect(rich('по 18 г'), findsOneWidget);

      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();

      expect(water('72 г'), findsOneWidget);
      expect(find.text('2 × 18 г'), findsWidgets);
      expect(find.text('шаг 1 из 8'), findsOneWidget,
          reason: 'тот же шот ещё раз — шаги дважды');
      expect(rich('Пересчитано на 72 г · было 36'), findsOneWidget);
      expect(rich('было 27'), findsNothing,
          reason: 'помол прежний — подписывать «было» нечего');
    });

    testWidgets('френч-пресс: в шторке клики, а не слово «прежний»',
        (tester) async {
      // У иммерсии помол по смыслу метода прежний, и шторка писала «помол
      // прежний». Владелец 04.11: клики — числом, «чтобы была конкретика».
      await pumpBrew(tester, moziana(device: 'french_press'));
      await tester.tap(param('water'));
      await tester.pumpAndSettle();

      final values = scaleWheelValues(moziana(device: 'french_press'),
          ScalingProfile.builtIn('french_press')!);
      final wheel =
          tester.widget<ListWheelScrollView>(find.byType(ListWheelScrollView));
      (wheel.controller! as FixedExtentScrollController)
          .jumpToItem(values.indexOf(500));
      await tester.pumpAndSettle();

      expect(rich('27 кликов'), findsWidgets);
      expect(rich('прежний'), findsNothing);
    });

    testWidgets('прибор без профиля — вода не нажимается', (tester) async {
      // Прибор, которого нет в таблице: появился на сервере позже, чем
      // вышло приложение.
      await pumpBrew(tester, moziana(device: 'unknown_device'));

      await tester.tap(param('water'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Сколько воды'), findsNothing);
      expect(find.text('250 мл'), findsOneWidget);
    });
  });
}
