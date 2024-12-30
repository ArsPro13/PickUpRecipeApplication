import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/src/features/authentication/provider/authentication_state.dart';
import 'package:pick_up_recipe/src/pages/authentication_page.dart';

class AuthenticationStateNotifier extends StateNotifier<AuthenticationState> {
  AuthenticationStateNotifier()
      : super(AuthenticationState(mode: AuthPageMode.login));

  void switchMode(AuthPageMode newMode) {
    state = state.copyWith(mode: newMode);
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }
}

final authenticationStateNotifierProvider =
    StateNotifierProvider<AuthenticationStateNotifier, AuthenticationState>(
  (ref) => AuthenticationStateNotifier(),
);
