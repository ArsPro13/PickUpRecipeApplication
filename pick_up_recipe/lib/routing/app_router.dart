import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../src/features/authentication/guards/authentication_guard.dart';
import '../src/features/brew_methods/domain/brew_method.dart';
import '../src/features/packs/domain/models/pack_model.dart';
import '../src/features/recipes/domain/models/correction_model.dart';
import '../src/features/recipes/domain/models/recipe_data_model.dart';
// Тип результата формы своего шага: сгенерированный маршрут собирает её
// страницей AutoRoutePage<UserStepType>, и тип нужен здесь, в библиотеке
// маршрутов, частью которой генерат и является.
import '../src/features/recipes/domain/models/user_step_type_model.dart';
import '../src/pages/auth_login_page.dart';
import '../src/pages/auth_register_page.dart';
import '../src/pages/auth_verify_page.dart';
import '../src/pages/auth_welcome_page.dart';
import '../src/pages/brew_page.dart';
import '../src/pages/choosing_recipe_page.dart';
import '../src/pages/code_scanner_page.dart';
import '../src/pages/feedback_page.dart';
import '../src/pages/coffee_page.dart';
import '../src/pages/rating_conflict_page.dart';
import '../src/pages/grinder_select_page.dart';
import '../src/pages/packs_page.dart';
import '../src/pages/password_reset_page.dart';
import '../src/pages/profile_page.dart';
import '../src/pages/rating_page.dart';
import '../src/pages/custom_step_page.dart';
import '../src/pages/recipe_builder_page.dart';
import '../src/pages/recipes_for_coffee_page.dart';
import '../src/pages/recipes_page.dart';
import '../src/pages/recognition_camera_page.dart';
import '../src/pages/root_page.dart';
import '../src/pages/scan_page.dart';

part './app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page|Screen,Route')
class AppRouter extends _$AppRouter {
  AppRouter(this.ref) : super();

  WidgetRef ref;

  @override
  List<AutoRoute> get routes => [
        // Корень — «Рецепты» (решение владельца от 2 ноября 2026; до этого
        // были «Мои пачки»). Гостя нет (ответ на вопрос 9), поэтому гвард
        // стоит на всём, кроме самого экрана входа.
        AutoRoute(
          page: RootRoute.page,
          path: '/',
          initial: true,
          guards: [AuthGuard(ref)],
          children: [
            AutoRoute(page: RecipesRoute.page, path: 'recipes', initial: true),
            AutoRoute(page: PacksRoute.page, path: 'packs'),
            AutoRoute(page: ScanRoute.page, path: 'scan'),
            AutoRoute(page: ProfileRoute.page, path: 'profile'),
          ],
        ),

        // Диплинк по коду с упаковки: /r/{code} ведёт прямо на страницу кофе
        // (ADR 0004). Путь короткий намеренно — он печатается на пачке вместе
        // с доменом, и каждый символ там на счету.
        //
        // Объявление у страницы кофе ОДНО. Раньше рядом стояло второе, на
        // '/coffee', и оно молча отключало это: auto_route складывает маршруты
        // в словарь по имени страницы (RouteCollection.fromList), и второй
        // CoffeeRoute затирал первый. Ссылка https://recipetocup.ru/r/<код>
        // не находила маршрута вовсе — «Can not resolve initial route» на
        // холодном старте и тишина на тёплом. Изнутри приложения экран
        // открывается аргументами (CoffeeRoute(code: …) или (packId: …)), и
        // путь ему не нужен.
        //
        // usesPathAsKey — чтобы вторая ссылка на ДРУГОЙ кофе открыла его, а
        // не осталась на первом. Без него ключ страницы — имя маршрута, и
        // auto_route, получив /r/<код Б> при открытом /r/<код А>, считал это
        // тем же экраном: человек жал «Открыть в приложении» в виджете
        // магазина и видел кофе, открытый в прошлый раз.
        AutoRoute(
            page: CoffeeRoute.page,
            path: '/r/:code',
            usesPathAsKey: true,
            guards: [AuthGuard(ref)]),

        AutoRoute(
            page: RecipesForCoffeeRoute.page,
            path: '/coffee/methods',
            guards: [AuthGuard(ref)]),
        AutoRoute(
            page: GrinderSelectRoute.page,
            path: '/grinder',
            guards: [AuthGuard(ref)]),
        AutoRoute(
            page: CustomStepRoute.page,
            path: '/recipe/custom-step',
            guards: [AuthGuard(ref)]),
        AutoRoute(
            page: BrewRoute.page, path: '/brew', guards: [AuthGuard(ref)]),
        AutoRoute(
            page: RatingRoute.page, path: '/rating', guards: [AuthGuard(ref)]),
        AutoRoute(
            page: RatingConflictRoute.page,
            path: '/rating_conflict',
            guards: [AuthGuard(ref)]),
        AutoRoute(
            page: RecipeBuilderRoute.page,
            path: '/recipe/edit',
            guards: [AuthGuard(ref)]),
        AutoRoute(
            page: ChoosingRecipeRoute.page,
            path: '/choose-recipe',
            guards: [AuthGuard(ref)]),
        AutoRoute(
            page: RecognitionCameraRoute.page,
            path: '/pack-photo',
            guards: [AuthGuard(ref)]),
        // Живая камера для QR с пачки. Отдельным экраном, а не на вкладке:
        // камера, открытая сама при каждом переключении вкладок, — это
        // разрешение, индикатор записи и батарея на пустом месте.
        AutoRoute(
            page: CodeScannerRoute.page,
            path: '/scan/camera',
            guards: [AuthGuard(ref)]),
        // Обратная связь — из профиля, строкой «Написать нам».
        AutoRoute(
            page: FeedbackRoute.page,
            path: '/feedback',
            guards: [AuthGuard(ref)]),

        // Вход разбит на отдельные экраны, а не на режимы одной страницы:
        // у каждого своя шапка с «назад», и вернуться из регистрации в
        // приветствие должно быть тем же жестом, что и везде.
        AutoRoute(page: AuthWelcomeRoute.page, path: '/auth'),
        AutoRoute(page: AuthLoginRoute.page, path: '/auth/login'),
        AutoRoute(page: AuthRegisterRoute.page, path: '/auth/register'),
        AutoRoute(page: AuthVerifyRoute.page, path: '/auth/verify'),
        AutoRoute(page: PasswordResetRoute.page, path: '/auth/reset'),
      ];
}
