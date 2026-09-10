// «Прервать заваривание» обязано уводить с экрана.
//
// Экран заваривания завёрнут в PopScope, который не отпускает, пока идёт
// отсчёт. Вопрос «Прервать заваривание?» задавался, ответ «Прервать»
// принимался — и не менял ничего: уход шёл через maybePop, тот заново
// спрашивал у того же PopScope, отсчёт всё ещё шёл, и вместо ухода
// открывался тот же самый диалог. С экрана нельзя было уйти вовсе —
// ни кнопкой телефона, ни стрелкой в шапке.
//
// Поэтому проверяются оба пути ухода и оба ответа на вопрос: «Прервать»
// уводит и останавливает движок, «Остаться» оставляет заваривание идущим.

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
import 'package:pick_up_recipe/src/features/recipes/application/step_types_state.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/grind_descriptor_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/step_type_model.dart';
import 'package:pick_up_recipe/src/pages/brew_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Экран, с которого пришли на заваривание. Нужен, чтобы уходу было куда
/// уходить: в стопке из одного экрана «ушли» и «остались» выглядят одинаково.
class _Origin extends StatelessWidget {
  const _Origin();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Откуда пришли')));
  }
}

const _originName = 'OriginRoute';

/// Маршрутизатор на два экрана. Настоящий, а не подставной: проверяется как
/// раз разговор экрана с навигацией, и подменить в нём нечего.
class _TwoScreenRouter extends RootStackRouter {
  @override
  Map<String, PageFactory> get pagesMap => {
        _originName: (data) => AutoRoutePage<dynamic>(
              routeData: data,
              child: const _Origin(),
            ),
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

RecipeStep _step(int seqNum, {int time = 30, int water = 60}) => RecipeStep(
      seqNum: seqNum,
      instruction: 'Шаг $seqNum',
      water: water,
      time: time,
      id: seqNum,
      stepType: 'pour',
      stepKey: '',
      tip: '',
      isOptional: false,
      untilUser: false,
      untilSign: '',
      warning: '',
    );

RecipeData _recipe() => RecipeData(
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
      steps: [_step(1), _step(2), _step(3)],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();

    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<ApiClient>(ApiClient(onAuthError: () async {}));
  });

  /// Поднимает заваривание поверх экрана «Откуда пришли» и оставляет отсчёт
  /// идущим.
  ///
  /// Без pumpAndSettle нигде: пока заваривание идёт, экран перерисовывается
  /// каждый кадр и успокоиться не может в принципе.
  Future<_TwoScreenRouter> pumpBrewing(WidgetTester tester) async {
    // Окно телефона, а не стандартные 800×600: рамка заваривания держит
    // пропорцию, и на широком окне разметка не помещается по высоте.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = _TwoScreenRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Справочники экран берёт с сервера. В тесте они пусты: проверяется
          // уход с экрана, а не то, что на нём написано.
          stepTypesProvider.overrideWith((ref) => const StepTypeReference()),
          grindDescriptorsProvider.overrideWith((ref) => const <GrindDescriptor>[]),
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

    // Без await: push отдаёт результат экрана и ждёт, пока тот закроется, —
    // то есть ровно того, что и проверяется ниже.
    unawaited(router.push(BrewRoute(recipe: _recipe(), pack: null)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Экран открывается рамкой «Смелите кофе»: отсчёт не начинается сам ни с
    // какого входа. Часть входов раньше открывала заваривание уже идущим —
    // владелец на видео попадал с карточки кофе прямо на предсмачивание и
    // молол кофе, пока шёл первый шаг: «нету шага „смолол, начинаем“, надо
    // вернуть». Проверяется это здесь, а не отдельным тестом: рамка стоит на
    // пути у каждого захода в заваривание, и мимо неё не пройти незамеченной.
    expect(
      find.text('Смелите кофе'),
      findsOneWidget,
      reason: 'заваривание открылось, минуя помол',
    );

    // И главное: секунды не текут, пока стоит рамка. Первый шаг рецепта —
    // тридцатисекундный, и через три секунды он показывал бы 0:27.
    await tester.pump(const Duration(seconds: 3));
    expect(
      find.text('0:27'),
      findsNothing,
      reason: 'первый шаг начал отсчёт до того, как кофе смололи',
    );

    // Дальше проверяется уход с идущего заваривания, поэтому его надо
    // начать — тем же нажатием, каким его начинает человек.
    await tester.tap(find.text('Смолол, начинаем'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    return router;
  }

  /// Ответ на вопрос: «Прервать» или «Остаться».
  Future<void> answer(WidgetTester tester, String button) async {
    await tester.tap(find.text(button));
    await tester.pump();
    // Диалог уезжает, и только тогда экран получает ответ.
    await tester.pump(const Duration(milliseconds: 400));
    // Столько же на уход самого экрана заваривания.
    await tester.pump(const Duration(milliseconds: 400));
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
  }

  group('прерывание заваривания', () {
    testWidgets('кнопкой телефона: «Прервать» уводит с экрана', (tester) async {
      await pumpBrewing(tester);
      expect(find.byType(BrewPage), findsOneWidget);

      await pressSystemBack(tester);
      expect(find.text('Прервать заваривание?'), findsOneWidget);

      await answer(tester, 'Прервать');

      expect(
        find.byType(BrewPage),
        findsNothing,
        reason: 'ответили «Прервать», а экран заваривания остался',
      );
      expect(find.text('Откуда пришли'), findsOneWidget);
    });

    testWidgets('стрелкой в шапке: «Прервать» уводит с экрана', (tester) async {
      await pumpBrewing(tester);

      await tester.tap(find.byTooltip('Назад'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Прервать заваривание?'), findsOneWidget);

      await answer(tester, 'Прервать');

      expect(
        find.byType(BrewPage),
        findsNothing,
        reason: 'стрелка в шапке спрашивает, но не уводит',
      );
      expect(find.text('Откуда пришли'), findsOneWidget);
    });

    testWidgets('вопрос задаётся один раз, а не по кругу', (tester) async {
      await pumpBrewing(tester);

      await pressSystemBack(tester);
      await answer(tester, 'Прервать');

      expect(
        find.text('Прервать заваривание?'),
        findsNothing,
        reason: 'после ответа «Прервать» тот же вопрос открылся заново',
      );
    });

    testWidgets('«Остаться» оставляет заваривание идущим', (tester) async {
      await pumpBrewing(tester);

      await pressSystemBack(tester);
      await answer(tester, 'Остаться');

      expect(find.byType(BrewPage), findsOneWidget);
      expect(find.text('Прервать заваривание?'), findsNothing);
      // Главная кнопка предлагает паузу — значит отсчёт идёт, а не встал.
      expect(find.widgetWithText(ElevatedButton, 'Пауза'), findsOneWidget);
    });

    testWidgets('«Остаться» не снимает заваривание с паузы', (tester) async {
      await pumpBrewing(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Пауза'));
      await tester.pump();
      expect(find.widgetWithText(ElevatedButton, 'Продолжить'), findsOneWidget);

      await pressSystemBack(tester);
      await answer(tester, 'Остаться');

      expect(
        find.widgetWithText(ElevatedButton, 'Продолжить'),
        findsOneWidget,
        reason: 'заваривание стояло на паузе — там же должно и остаться',
      );
    });

    testWidgets('прерванное заваривание не уводит на оценку', (tester) async {
      await pumpBrewing(tester);

      await pressSystemBack(tester);
      await answer(tester, 'Прервать');

      // Оценка — конец заваривания, а не его прерывания. Ждём с запасом:
      // переход на неё отложенный.
      await tester.pump(const Duration(seconds: 5));

      expect(find.text('Откуда пришли'), findsOneWidget);
      expect(find.byType(BrewPage), findsNothing);
    });
  });
}
