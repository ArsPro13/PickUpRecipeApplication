// «Уйти без сохранения» обязано уводить с экрана.
//
// Конструктор завёрнут в PopScope, который не отпускает, пока правки не
// сохранены. Вопрос «Уйти без сохранения?» задавался, ответ «Уйти»
// принимался — и не менял ничего: уход шёл через maybePop, тот заново
// спрашивал у того же PopScope, правки всё ещё были несохранёнными, и вместо
// ухода открывался тот же самый вопрос. Владелец на видео нажимает «Уйти»
// и остаётся в конструкторе.
//
// Ровно та же беда была на заваривании — см. brew_abort_test.dart. Здесь
// проверяются обе двери, кнопка телефона и стрелка в шапке, и оба ответа:
// «Уйти» уводит, «Остаться» оставляет правки на месте.

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
import 'package:pick_up_recipe/src/general_widgets/amount_stepper.dart';
import 'package:pick_up_recipe/src/general_widgets/app_icon.dart';
import 'package:pick_up_recipe/src/pages/recipe_builder_page.dart';
import 'package:pick_up_recipe/src/themes/app_icons.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Экран, с которого пришли в конструктор. Нужен, чтобы уходу было куда
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
        AutoRoute(page: RecipeBuilderRoute.page, path: '/builder'),
      ];
}

RecipeStep _step(int seqNum) => RecipeStep(
      seqNum: seqNum,
      instruction: 'Шаг $seqNum',
      water: 125,
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

RecipeData _recipe() => RecipeData(
      id: 1,
      device: 'hario_v60',
      date: '2026-09-09T01:00:00Z',
      packId: 7,
      grinderId: 1,
      grindStep: '18',
      grindSubStep: null,
      water: 250,
      time: 60,
      temperature: 93,
      load: 15,
      title: 'Базовый рецепт',
      notes: '',
      grindDescriptor: 'medium',
      agitationLevel: null,
      steps: [_step(1), _step(2)],
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

  /// Поднимает конструктор поверх экрана «Откуда пришли».
  Future<void> pumpBuilder(WidgetTester tester) async {
    // Окно телефона, а не стандартные 800×600: строка параметра со счётчиком
    // занимает справа полторы сотни точек, и на широком окне разметка едет.
    tester.view.physicalSize = const Size(400, 900);
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
    unawaited(router.push(RecipeBuilderRoute(recipe: _recipe())));
    await tester.pumpAndSettle();
  }

  /// Двигает дозу стрелкой: одно нажатие — и правки есть что терять.
  ///
  /// Стрелка, а не окно с клавиатурой: окон для чисел на этом экране больше
  /// нет, их и просил убрать владелец. Доза — первый счётчик на экране, плюс
  /// в нём — правая из двух стрелок.
  Future<void> nudgeDose(WidgetTester tester) async {
    final plus = find.descendant(
      of: find.byType(AmountStepper).first,
      matching: find.byWidgetPredicate(
        (widget) => widget is AppIcon && widget.asset == AppIcons.uiPlus,
      ),
    );

    await tester.tap(plus);
    await tester.pumpAndSettle();
  }

  /// Ответ на вопрос: «Уйти» или «Остаться».
  Future<void> answer(WidgetTester tester, String button) async {
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
  }

  /// Системная кнопка «назад» — тем же сообщением, которым её шлёт телефон.
  Future<void> pressSystemBack(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  group('уход из конструктора', () {
    testWidgets('кнопкой телефона: «Уйти» уводит с экрана', (tester) async {
      await pumpBuilder(tester);
      await nudgeDose(tester);

      await pressSystemBack(tester);
      expect(find.text('Уйти без сохранения?'), findsOneWidget);

      await answer(tester, 'Уйти');

      expect(
        find.byType(RecipeBuilderPage),
        findsNothing,
        reason: 'ответили «Уйти», а конструктор остался',
      );
      expect(find.text('Откуда пришли'), findsOneWidget);
    });

    testWidgets('стрелкой в шапке: «Уйти» уводит с экрана', (tester) async {
      await pumpBuilder(tester);
      await nudgeDose(tester);

      await tester.tap(find.byTooltip('Назад'));
      await tester.pumpAndSettle();
      expect(find.text('Уйти без сохранения?'), findsOneWidget);

      await answer(tester, 'Уйти');

      expect(
        find.byType(RecipeBuilderPage),
        findsNothing,
        reason: 'стрелка в шапке спрашивает, но не уводит',
      );
      expect(find.text('Откуда пришли'), findsOneWidget);
    });

    testWidgets('вопрос задаётся один раз, а не по кругу', (tester) async {
      await pumpBuilder(tester);
      await nudgeDose(tester);

      await pressSystemBack(tester);
      await answer(tester, 'Уйти');

      expect(
        find.text('Уйти без сохранения?'),
        findsNothing,
        reason: 'после ответа «Уйти» тот же вопрос открылся заново',
      );
    });

    testWidgets('«Остаться» оставляет правки на месте', (tester) async {
      await pumpBuilder(tester);
      await nudgeDose(tester);

      await pressSystemBack(tester);
      await answer(tester, 'Остаться');

      expect(find.byType(RecipeBuilderPage), findsOneWidget);
      expect(find.text('Откуда пришли'), findsNothing);
      expect(find.text('16 г'), findsOneWidget, reason: 'подвинутая доза потерялась');
    });

    testWidgets('несохранившийся рецепт оставляет человека в конструкторе', (tester) async {
      // «Сохранить» уводит на полку — но только когда версия и правда уехала.
      // Сети в тесте нет, сервер отвечает отказом, и уйти с экрана значило бы
      // сказать «сохранено» о том, чего не сохранилось.
      await pumpBuilder(tester);
      await nudgeDose(tester);

      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      expect(find.byType(RecipeBuilderPage), findsOneWidget);
      expect(find.text('Откуда пришли'), findsNothing);
    });

    testWidgets('нетронутый рецепт уходит без вопроса', (tester) async {
      // Терять нечего — спрашивать не о чем: лишний вопрос на выходе из
      // просмотра надоедает быстрее, чем помогает.
      await pumpBuilder(tester);

      await pressSystemBack(tester);

      expect(find.text('Уйти без сохранения?'), findsNothing);
      expect(find.byType(RecipeBuilderPage), findsNothing);
      expect(find.text('Откуда пришли'), findsOneWidget);
    });
  });
}
