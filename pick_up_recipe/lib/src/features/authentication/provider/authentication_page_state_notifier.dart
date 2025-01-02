import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/src/features/authentication/provider/authentication_page_state.dart';
import 'package:pick_up_recipe/src/pages/authentication_page.dart';

class AuthenticationPageStateNotifier
    extends StateNotifier<AuthenticationPageState> {
  AuthenticationPageStateNotifier()
      : super(AuthenticationPageState(mode: AuthPageMode.login));

  void switchMode(AuthPageMode newMode) {
    state = state.copyWith(mode: newMode);
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }
}

final authenticationPageStateNotifierProvider = StateNotifierProvider<
    AuthenticationPageStateNotifier, AuthenticationPageState>(
  (ref) => AuthenticationPageStateNotifier(),
);
