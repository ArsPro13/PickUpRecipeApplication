// Версия в коде обязана совпадать с pubspec.yaml.
//
// Пакета для чтения версии на лету в проекте нет, и lib/core/app_version.dart
// держит её строкой — а строку легко забыть поднять вместе с pubspec. Тогда
// письма из обратной связи приходили бы с прошлой версией, и «у меня не
// работает» читалось бы как жалоба на уже исправленную сборку.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/core/app_version.dart';

void main() {
  test('appVersion совпадает с version из pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version =
        RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec);

    expect(version, isNotNull, reason: 'в pubspec.yaml нет строки version');
    expect(appVersion, version!.group(1),
        reason:
            'подняли версию в pubspec — поднимите и lib/core/app_version.dart');
  });
}
