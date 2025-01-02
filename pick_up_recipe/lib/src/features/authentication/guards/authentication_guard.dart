import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/authentication/provider/authentication_state_notifier.dart';

import '../provider/authentication_state.dart';

class AuthGuard extends AutoRouteGuard {
  final WidgetRef ref;

  AuthGuard(this.ref);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    while (ref.read(authenticationStateNotifierProvider).status ==
        AuthState.isLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (ref.read(authenticationStateNotifierProvider).status ==
        AuthState.needsAuthentication) {
      router.push(const AuthenticationRoute());
    } else {
      resolver.next(true);
    }
  }
}
