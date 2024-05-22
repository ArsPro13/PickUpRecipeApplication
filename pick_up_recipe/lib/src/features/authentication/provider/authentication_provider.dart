import 'package:flutter/material.dart';

abstract interface class AutenticationProvider extends ChangeNotifier {
  Future<void> register(String email, String passwordHash);
  Future<void> login(String email, String passwordHash);
  Future<void> refresh();
  Future<void> checkStatus();
  bool statusOk = false;
}