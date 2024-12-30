import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/src/features/authentication/data_sources/remote/auth_service.dart';

import 'authentication_provider.dart';

class AuthenticationProviderImpl extends ChangeNotifier
    implements AutenticationProvider {
  final AuthService _authService = AuthService();

  @override
  Future<void> login(String email, String password) async {
    try {
      await _authService.authenticate(
        email,
        password,
      );
      statusOk = true;
    } catch (e) {
      statusOk = false;
      rethrow;
    }
  }

  @override
  Future<void> refresh() async {
    try {
      await _authService.refreshTokens();
      statusOk = true;
    } catch (e) {
      statusOk = false;
    }
  }

  @override
  Future<void> register(String email, String password) async {
    try {
      await _authService.register(
        email,
        password,
      );
      statusOk = true;
    } catch (e) {
      statusOk = false;
      rethrow;
    }
  }

  @override
  Future<void> verifyMail(String email, String code) async {
    try {
      await _authService.verifyMail(
        email,
        code,
      );
      statusOk = true;
    } catch (e) {
      statusOk = false;
      rethrow;
    }
  }

  @override
  Future<void> updateStatus(bool newStatus) async {
    statusOk = newStatus;
  }

  @override
  Future<void> checkStatus() async {}

  @override
  bool statusOk = false;
}

final authenticationProvider =
    ChangeNotifierProvider<AutenticationProvider>((ref) {
  return AuthenticationProviderImpl();
});
