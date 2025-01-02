import 'package:pick_up_recipe/src/pages/authentication_page.dart';

class AuthenticationPageState {
  final AuthPageMode mode;
  final String? email;

  AuthenticationPageState({
    required this.mode,
    this.email,
  });

  AuthenticationPageState copyWith({
    AuthPageMode? mode,
    String? email,
  }) {
    return AuthenticationPageState(
      mode: mode ?? this.mode,
      email: email ?? this.email,
    );
  }
}
