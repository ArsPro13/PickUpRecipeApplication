import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import '../provider/mocked_authentication_provider.dart';

class AuthGuard extends AutoRouteGuard {
  final WidgetRef ref;

  AuthGuard(this.ref);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    // todo: move to main initstate
    await ref.watch(authenticationProvider).checkStatus();
    bool isAuthenticated = ref.watch(authenticationProvider.notifier).statusOk;
    if (!isAuthenticated) {
      router.push(const AuthenticationRoute());
    } else {
      resolver.next(true);
    }
  }
}