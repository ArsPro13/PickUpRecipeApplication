import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/authentication/provider/authentication_state_notifier.dart';

import '../provider/authentication_state.dart';

/// Пускает дальше только авторизованных. Гостя нет (ответ на вопрос 9).
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this.ref);

  final WidgetRef ref;

  /// Сколько ждём восстановления сессии, прежде чем считать, что её нет.
  ///
  /// Без предела цикл ожидания вечный: сеть может не ответить никогда, и тогда
  /// приложение остаётся на пустом экране — переход так и не разрешился ни в
  /// одну сторону.
  static const Duration _sessionTimeout = Duration(seconds: 10);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    final deadline = DateTime.now().add(_sessionTimeout);

    while (ref.read(authenticationStateNotifierProvider).status == AuthState.isLoading &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    if (ref.read(authenticationStateNotifierProvider).status == AuthState.isAuthenticated) {
      resolver.next(true);
      return;
    }

    // redirect, а не push: push оставляет переход неразрешённым, и навигатор
    // застревает — под экраном входа остаётся пустой корень, а если экран
    // входа почему-то не открылся, человек видит пустоту и всё.
    //
    // redirect и уводит на вход, и закрывает исходный переход: когда экран
    // входа отпустят, обещание выполнится, и человек попадёт туда, куда шёл.
    resolver.redirect(const AuthWelcomeRoute());
  }
}
