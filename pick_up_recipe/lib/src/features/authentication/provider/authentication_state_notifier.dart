import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/src/features/authentication/data_sources/remote/auth_service.dart';

import 'authentication_state.dart';

class AuthenticationStateNotifier extends StateNotifier<AuthenticationState> {
  final AuthService _authService = AuthService();

  AuthenticationStateNotifier()
      : super(AuthenticationState(status: AuthState.needsAuthentication)) {
    refresh();
  }

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(status: AuthState.isLoading);
      await _authService.authenticate(
        email,
        password,
      );
      state = state.copyWith(status: AuthState.isAuthenticated);
    } catch (e) {
      state = state.copyWith(status: AuthState.needsAuthentication);
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      state = state.copyWith(status: AuthState.isLoading);
      await _authService.refreshTokens();
      state = state.copyWith(status: AuthState.isAuthenticated);
    } catch (e) {
      state = state.copyWith(status: AuthState.needsAuthentication);
    }
  }

  Future<void> register(String email, String password) async {
    try {
      await _authService.register(
        email,
        password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Повторная отправка кода подтверждения.
  Future<void> resendVerificationCode(String email) =>
      _authService.resendVerificationCode(email);

  /// Письмо для сброса пароля.
  Future<void> requestPasswordReset(String email) =>
      _authService.requestPasswordReset(email);

  /// Сброс пароля по коду из письма.
  Future<void> resetPassword(String email, String code, String password) =>
      _authService.resetPassword(email, code, password);

  /// Выход: токены стираются, состояние возвращается к «нужен вход».
  ///
  /// Раньше выхода не было вовсе — а он нужен уже потому, что на одном
  /// телефоне заваривают вдвоём.
  Future<void> logout() async {
    await _authService.logout();
    state = state.copyWith(status: AuthState.needsAuthentication);
  }

  Future<void> verifyMail(String email, String code) async {
    try {
      await _authService.verifyMail(
        email,
        code,
      );
    } catch (e) {
      rethrow;
    }
  }
}

final authenticationStateNotifierProvider =
    StateNotifierProvider<AuthenticationStateNotifier, AuthenticationState>(
  (ref) => AuthenticationStateNotifier(),
);
