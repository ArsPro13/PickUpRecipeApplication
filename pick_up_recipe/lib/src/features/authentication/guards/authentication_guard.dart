import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/authentication/provider/authentification_provider_impl.dart';

class AuthGuard extends AutoRouteGuard {
  final WidgetRef ref;

  AuthGuard(this.ref);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    bool isAuthenticated = ref.watch(authenticationProvider.notifier).statusOk;

    if (!isAuthenticated) {
      router.push(const AuthenticationRoute());
    } else {
      resolver.next(true);
    }
  }
}