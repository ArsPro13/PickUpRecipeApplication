// Всплывающих сообщений внизу экрана в приложении нет.
//
// Владелец: «убери отовсюду эти тупые уведомления внизу». Сообщение о смене
// кофемолки висело поверх вкладки «Рецепты» и переезжало за человеком в
// профиль, а «Сохранено» в конструкторе гасло раньше, чем его успевали
// прочесть. Теперь экраны отвечают на месте: кнопка «Сохранено» с галочкой,
// строка ошибки под строкой рецепта, плашка над списком кофемолок.
//
// Тест читает исходники, а не запускает экраны: новое сообщение внизу можно
// добавить на любой из двух десятков экранов, и поднимать их все ради одного
// вызова незачем — вызов виден в коде и так.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ни один экран не показывает сообщений внизу', () {
    final banned = RegExp(r'showSnackBar|SnackBar\(|showMaterialBanner');
    final found = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index].trim();
        if (line.startsWith('//')) continue;
        if (banned.hasMatch(line)) found.add('${entity.path}:${index + 1}');
      }
    }

    expect(found, isEmpty, reason: found.join('\n'));
  });
}
