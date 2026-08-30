import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/core/offline/local_recipes.dart';
import 'package:pick_up_recipe/core/offline/offline_cache.dart';
import 'package:pick_up_recipe/core/offline/offline_exception.dart';
import 'package:pick_up_recipe/core/offline/outbox.dart';
import 'package:pick_up_recipe/src/features/authentication/data_sources/remote/auth_service.dart';

import 'authentication_state.dart';

class AuthenticationStateNotifier extends StateNotifier<AuthenticationState> {
  final AuthService _authService = AuthService();

  AuthenticationStateNotifier()
      : super(AuthenticationState(status: AuthState.needsAuthentication)) {
    // Сессия на телефоне есть — считаем её своей сразу и обновляем токены
    // фоном. Раньше запуск ждал ответа сервера: без сети это двенадцать
    // секунд молчания, после которых гвард сдавался и показывал вход —
    // экран, с которого без сети всё равно никуда не деться.
    //
    // Просроченный токен от этого не станет действующим: первый же запрос
    // получит 401, обновление не пройдёт, и человека попросят войти — но
    // по ответу сервера, а не по молчанию сети.
    if (_authService.hasStoredSession()) {
      state = state.copyWith(status: AuthState.isAuthenticated);
      refresh(silent: true);
    } else {
      refresh();
    }
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

  /// Обновляет пару токенов.
  ///
  /// [silent] — не поднимать «идёт загрузка»: так обновляются токены на
  /// старте, когда сессия уже признана своей, и мигать экраном ожидания
  /// незачем.
  Future<void> refresh({bool silent = false}) async {
    try {
      if (!silent) state = state.copyWith(status: AuthState.isLoading);
      await _authService.refreshTokens();
      state = state.copyWith(status: AuthState.isAuthenticated);
    } on OfflineException {
      // Сеть не ответила — это не отказ в доступе. Сессия остаётся своей:
      // иначе приложение, запущенное в лесу, встречает человека экраном
      // входа, а войти оттуда всё равно нельзя. Токен протух — узнаем при
      // первом же запросе, когда связь появится.
      state = state.copyWith(
        status: _authService.hasStoredSession()
            ? AuthState.isAuthenticated
            : AuthState.needsAuthentication,
      );
    } catch (e) {
      // Отказ сервера — настоящий: сессии нет.
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

    // Вместе с токенами уходит и всё сохранённое: на одном телефоне
    // заваривают вдвоём, и чужая полка после смены аккаунта — хуже пустой.
    await OfflineCache.clearAll();
    await LocalRecipes.clear();
    await Outbox.clear();

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
