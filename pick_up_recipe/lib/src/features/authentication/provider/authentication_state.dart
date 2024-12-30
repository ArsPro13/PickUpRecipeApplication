import 'package:pick_up_recipe/src/pages/authentication_page.dart';

class AuthenticationState {
  final AuthPageMode mode;
  final String? email;

  AuthenticationState({
    required this.mode,
    this.email,
  });

  AuthenticationState copyWith({
    AuthPageMode? mode,
    String? email,
  }) {
    return AuthenticationState(
      mode: mode ?? this.mode,
      email: email ?? this.email,
    );
  }
}
