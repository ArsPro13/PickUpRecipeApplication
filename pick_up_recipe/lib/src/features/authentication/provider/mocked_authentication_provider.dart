import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'authentication_provider.dart';

class MockedAuthenticationProvider extends ChangeNotifier
    implements AutenticationProvider {
  String refreshToken = '';
  String accessToken = '';
  int actionsCounter = 0;

  @override
  bool statusOk = false;

  @override
  Future<void> login(String email, String passwordHash) async {
    await Future.delayed(const Duration(milliseconds: 800));
    refreshToken = 'aaaa';
    accessToken = 'bbbbb';
    ++actionsCounter;
    statusOk = true;
  }

  @override
  Future<void> refresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    refreshToken = 'ddddddd';
    accessToken = 'cccc';
    ++actionsCounter;
    statusOk = true;
  }

  @override
  Future<void> register(String email, String passwordHash) async {
    await Future.delayed(const Duration(milliseconds: 800));
    refreshToken = 'aaaa';
    accessToken = 'bbbbb';
    ++actionsCounter;
    statusOk = true;
  }

  @override
  Future<void> checkStatus() async {
    await Future.delayed(const Duration(milliseconds: 100));
    ++actionsCounter;
    statusOk = actionsCounter % 4 != 2;
  }
}

final authenticationProvider =
    ChangeNotifierProvider<AutenticationProvider>((ref) {
  return MockedAuthenticationProvider();
});
