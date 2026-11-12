// Старт заваривания: повтор рецепта не заводит новую версию.
//
// Экран заваривания сам сохраняет рецепт в момент старта — справочный ложится
// копией под пачку, пересчитанный на другой объём — следующей версией. До
// 9 ноября 2026 он делал это каждый раз: человек, который каждое утро
// заваривает одно и то же, получал каждое утро ещё одну одинаковую карточку.
// А свой рецепт, заваренный «как есть», не оставлял следа вовсе — дата на
// карточке так и стояла датой сохранения.
//
// Здесь проверяется сам экран: что уходит на сервер по «Смолол, начинаем» в
// каждом из случаев. Как сервис ищет уже сохранённую версию и как отметка
// едет через очередь — в recipe_repeat_test.dart.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/core/offline/recipe_drafts.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/grinders/application/grinder_state.dart';
import 'package:pick_up_recipe/src/features/grinders/data_sources/remote/grinder_service.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/models/grinder_model.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/recipes/application/active_brew.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipes_list_state.dart';
import 'package:pick_up_recipe/src/features/recipes/application/step_types_state.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/grind_descriptor_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/step_type_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/scaling/recipe_scaler.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/scaling/scaling_profile.dart';
import 'package:pick_up_recipe/src/general_widgets/app_kit.dart';
import 'package:pick_up_recipe/src/pages/brew_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comandante C40 — кофемолка человека, она же в рецепте: деление, с которого
/// считается новый помол, берётся прямо из рецепта.
final Grinder _c40 = Grinder(
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
      GrinderMode(mode: '$mode.0', microns: microns),
  ],
);

class _OwnGrinder implements GrinderService {
  @override
  Future<List<Grinder>> getAllGrinders() async => [_c40];

  @override
  Future<List<UserGrinder>> getUserGrinders() async =>
      [UserGrinder(grinder: _c40, isPrimary: true)];

  @override
  Future<List<UserGrinder>> setUserGrinders(
    List<Grinder> grinders, {
    int? primaryGrinderId,
  }) =>
      getUserGrinders();
}

/// Сервер рецептов: знает, что уже сохранено, и записывает, о чём его
/// просили, — сохранить версию и отметить заваривание.
///
/// Поиск такой же версии (`findSameVersion`, `saveBrewedVersion`) здесь
/// настоящий: подменены только три похода в сеть, на которых он стоит.
class _Recipes extends RecipeService {
  _Recipes({List<RecipeData> saved = const []}) : saved = [...saved];

  /// Версии человека, которые уже лежат на сервере.
  final List<RecipeData> saved;

  /// Что экран попросил сохранить новой версией.
  final evolved = <RecipeData>[];

  /// По каким рецептам отмечено заваривание.
  final brewed = <int>[];

  @override
  Future<List<RecipeData>?> getByParams({
    int? packId,
    int? grinderId,
    int? grindStep,
    int? grindSubStep,
    String? device,
    String? startDate,
    String? endDate,
    int? offset,
    int? limit,
    String? sortBy,
    bool allVersions = false,
  }) async =>
      [
        for (final recipe in saved)
          if ((packId == null || recipe.packId == packId) &&
              (device == null || recipe.device == device))
            recipe,
      ];

  @override
  Future<int> evolveRecipe(RecipeData recipe) async {
    evolved.add(copyRecipe(recipe));
    return 901;
  }

  @override
  Future<void> recordBrew(int recipeId, {DateTime? startedAt}) async {
    brewed.add(recipeId);
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
        {int water = 0, required int time, String tip = ''}) =>
    RecipeStep(
      seqNum: seq,
      instruction: label,
      water: water,
      time: time,
      id: seq,
      stepType: type,
      stepKey: 's$seq',
      tip: tip,
      isOptional: false,
      untilUser: false,
      untilSign: '',
      warning: '',
    );

/// Свой сохранённый рецепт: «Бразилия Можиана» на V60.
RecipeData moziana() => RecipeData(
      id: 77,
      device: 'hario_v60',
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
        _step(1, 'bloom', 'Предсмачивание',
            water: 45, time: 30, tip: 'Лей от центра.'),
        _step(2, 'pour', 'Первый пролив', water: 105, time: 35),
        _step(3, 'wait', 'Пауза', time: 10),
        _step(4, 'pour', 'Второй пролив', water: 100, time: 35),
        _step(5, 'wait', 'Ждём пролива', time: 50),
      ],
    );

/// Справочный рецепт метода: общий, пачки у него нет.
RecipeData baseV60() => moziana()
  ..id = 1
  ..packId = 0
  ..title = 'Базовый рецепт: Hario V60'
  ..date = '2026-09-21T19:36:00Z';

/// Пачка, с которой пришли к справочному рецепту.
PackData ethiopia() => PackData(
      packId: 11,
      userId: '7',
      packDate: '2026-10-22T10:00:00Z',
      packName: 'Эфиопия Иргачеффе',
      packDescriptors: const [],
      packCountry: 'Эфиопия',
      packProcessingMethod: const [],
      packImage: '',
      packVariety: '',
      packScaScore: 86,
      isActive: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();
    // Идущие заваривания живут ещё и в памяти: начатое в прошлом тесте не
    // должно достаться экрану этого.
    ActiveBrews.load();

    await GetIt.instance.reset();
    GetIt.instance
        .registerSingleton<ApiClient>(ApiClient(onAuthError: () async {}));
  });

  /// Экран заваривания до старта.
  Future<void> pumpBrew(
    WidgetTester tester,
    RecipeData recipe, {
    required _Recipes recipes,
    PackData? pack,
    StepTypeReference stepTypes = const StepTypeReference(),
  }) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = _Router();

    await tester.pumpWidget(
      ProviderScope(
        // Новый ключ на каждое открытие: второй экран в том же тесте обязан
        // получить свои провайдеры, а не достаться от первого.
        key: UniqueKey(),
        overrides: [
          stepTypesProvider.overrideWith((ref) => stepTypes),
          grindDescriptorsProvider
              .overrideWith((ref) => const <GrindDescriptor>[]),
          grinderStateProvider.overrideWith(
              (ref) => GrinderStateNotifier(_OwnGrinder())..loadUserGrinders()),
          recipeServiceProvider.overrideWithValue(recipes),
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

    unawaited(router.push(BrewRoute(recipe: recipe, pack: pack)));
    await tester.pumpAndSettle();
  }

  /// «Смолол, начинаем» — и время на то, чтобы экран сходил на сервер.
  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.text('Смолол, начинаем'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Ставит воду барабаном шторки и жмёт «Готово».
  Future<void> chooseWater(WidgetTester tester, int water) async {
    await tester.tap(find.byKey(const ValueKey('brew-param-water')));
    await tester.pumpAndSettle();

    final values =
        scaleWheelValues(moziana(), ScalingProfile.builtIn('hario_v60')!);
    final wheel =
        tester.widget<ListWheelScrollView>(find.byType(ListWheelScrollView));
    (wheel.controller! as FixedExtentScrollController)
        .jumpToItem(values.indexOf(water));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
  }

  group('старт заваривания', () {
    testWidgets('свой рецепт как есть: версия та же, заваривание отмечено',
        (tester) async {
      final recipes = _Recipes(saved: [moziana()]);
      await pumpBrew(tester, moziana(), recipes: recipes);

      await start(tester);

      expect(recipes.evolved, isEmpty,
          reason: 'повтор рецепта не должен рождать новую версию');
      expect(recipes.brewed, [77],
          reason: 'дата последнего заваривания меняется у самого рецепта');
    });

    testWidgets('пауза и «Продолжить» второй раз заваривание не отмечают',
        (tester) async {
      final recipes = _Recipes(saved: [moziana()]);
      await pumpBrew(tester, moziana(), recipes: recipes);
      await start(tester);

      // «Пауза» — и шаг рецепта, и главная кнопка; жмём кнопку.
      Finder button(String label) =>
          find.ancestor(of: find.text(label), matching: find.byType(AppButton));
      await tester.tap(button('Пауза'));
      await tester.pump();
      await tester.tap(button('Продолжить'));
      await tester.pump();

      expect(recipes.brewed, [77],
          reason: 'заваривание одно, сколько бы раз его ни ставили на паузу');
    });

    testWidgets('справочный рецепт впервые: копия под пачку, отметка на ней',
        (tester) async {
      final recipes = _Recipes();
      await pumpBrew(tester, baseV60(), recipes: recipes, pack: ethiopia());

      await start(tester);

      expect(recipes.evolved, hasLength(1));
      expect(recipes.evolved.single.packId, 11,
          reason: 'копия ложится под пачку, с которой пришли');
      expect(recipes.brewed, [901],
          reason: 'заваривают свою копию, а не общий справочный рецепт');
    });

    testWidgets('справочный рецепт повторно: берётся вчерашняя копия',
        (tester) async {
      // Вчера по этому же рецепту уже заваривали — копия лежит на сервере.
      final yesterday = baseV60()
        ..id = 170
        ..packId = 11
        ..date = '2026-11-08T07:10:00Z'
        ..hasEstimation = true;
      final recipes = _Recipes(saved: [yesterday]);
      await pumpBrew(tester, baseV60(), recipes: recipes, pack: ethiopia());

      await start(tester);

      expect(recipes.evolved, isEmpty,
          reason: 'вторая такая же копия — это и была лишняя карточка');
      expect(recipes.brewed, [170]);
      expect(ActiveBrews.find(baseV60(), ethiopia())?.savedVersionId, 170,
          reason: 'оценка после заваривания уйдёт вчерашней копии');
    });

    testWidgets('справочный рецепт под другую пачку — это другая копия',
        (tester) async {
      // Копия лежит под соседней пачкой: тем же зерном её не назвать.
      final other = baseV60()
        ..id = 170
        ..packId = 12;
      final recipes = _Recipes(saved: [other]);
      await pumpBrew(tester, baseV60(), recipes: recipes, pack: ethiopia());

      await start(tester);

      expect(recipes.evolved.single.packId, 11);
      expect(recipes.brewed, [901]);
    });

    testWidgets('пересчёт на уже сохранённый объём — та же версия',
        (tester) async {
      // Первый раз пересчитали на 500 мл: это правка, она сохраняется.
      final first = _Recipes(saved: [moziana()]);
      await pumpBrew(tester, moziana(), recipes: first);
      await chooseWater(tester, 500);
      await start(tester);

      expect(first.evolved, hasLength(1));
      expect(first.brewed, [901]);

      // Наутро открыли исходные 250 мл и пересчитали на те же 500.
      await ActiveBrews.clear();
      final saved500 = copyRecipe(first.evolved.single)
        ..id = 169
        ..date = '2026-11-03T17:47:00Z';
      final second = _Recipes(saved: [saved500, moziana()]);
      await pumpBrew(tester, moziana(), recipes: second);
      await chooseWater(tester, 500);
      await start(tester);

      expect(second.evolved, isEmpty,
          reason: 'такая версия уже есть — вторую заводить незачем');
      expect(second.brewed, [169]);
    });

    testWidgets('правку заварили не сохранив: исходной версии не приписано',
        (tester) async {
      // В списке «Рецептов» лежит сохранённая версия 77 на 250 мл…
      final recipes = _Recipes(saved: [moziana()]);
      // …а на экран пришли из конструктора с правкой: номер тот же, вода
      // другая, «Сохранить» не нажимали.
      final edited = moziana()
        ..water = 260
        ..steps[3].water = 110;
      await pumpBrew(tester, edited, recipes: recipes);

      final container =
          ProviderScope.containerOf(tester.element(find.byType(BrewPage)));
      await container.read(recipesListProvider.notifier).load();
      await tester.pump();

      await start(tester);

      expect(recipes.evolved, isEmpty,
          reason: 'сохранять за человека то, что он не сохранил, экран не '
              'станет');
      expect(recipes.brewed, isEmpty,
          reason: 'заваривали не версию 77, а её несохранённую правку');

      final draft = RecipeDrafts.all().single;
      expect(draft.water, 260);
      expect(DateTime.parse(draft.date).year, DateTime.now().toUtc().year,
          reason: 'черновик поднимается наверх списка с сегодняшней датой');
    });

    testWidgets('справочный рецепт без пачки отметить не на чем',
        (tester) async {
      final recipes = _Recipes();
      await pumpBrew(tester, baseV60(), recipes: recipes);

      await start(tester);

      expect(recipes.evolved, isEmpty);
      expect(recipes.brewed, isEmpty);
    });
  });

  group('шаг на экране заваривания', () {
    /// Справочник, каким его правит владелец в кабинете: у «Паузы» описание
    /// и значок из другой части набора.
    const reference = StepTypeReference(types: [
      StepType(
        id: 14,
        slug: 'wait',
        name: 'Пауза',
        shortName: 'пауза',
        iconKey: 'ui-refresh',
        groupId: 4,
        description: 'Дайте воде пройти сквозь кофе.',
      ),
      StepType(
        id: 2,
        slug: 'bloom',
        name: 'Предсмачивание',
        shortName: 'смачив.',
        iconKey: 'bloom',
        groupId: 1,
        description: 'Смочите весь кофе.',
      ),
    ]);

    testWidgets('шаг без своей подсказки подписан описанием из справочника',
        (tester) async {
      await pumpBrew(tester, moziana(),
          recipes: _Recipes(), stepTypes: reference);

      // «Пауза» и «Ждём пролива» — оба шага типа wait без подсказки.
      expect(find.text('Дайте воде пройти сквозь кофе.'), findsWidgets);
    });

    testWidgets('своя подсказка рецепта главнее описания', (tester) async {
      await pumpBrew(tester, moziana(),
          recipes: _Recipes(), stepTypes: reference);

      expect(find.text('Лей от центра.'), findsOneWidget);
      expect(find.text('Смочите весь кофе.'), findsNothing,
          reason: 'у предсмачивания в рецепте своя подсказка');
    });

    testWidgets('без справочника шаги остаются как были', (tester) async {
      await pumpBrew(tester, moziana(), recipes: _Recipes());

      expect(find.text('Лей от центра.'), findsOneWidget);
      expect(find.text('Дайте воде пройти сквозь кофе.'), findsNothing);
    });
  });
}
