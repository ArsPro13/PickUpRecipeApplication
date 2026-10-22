// Заваривание начинается с помола, откуда бы в него ни вошли.
//
// Раньше три входа — «Заварить» в конструкторе, кружок на карточке версии и
// кнопка базового рецепта — пускали таймер сразу: рецепт, мол, только что был
// перед глазами. Владелец: «если после изменения рецепта нажать заварить, то
// всё сразу начнётся, а я хочу, чтобы сначала можно было смолоть». Теперь
// любой вход открывает рамку «Смелите кофе» и ждёт «Смолол, начинаем».
//
// Проверяется исходник: экраны с этими кнопками в тесте целиком не поднять,
// а сам флаг виден в коде.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ни один экран не пускает таймер в обход помола', () {
    final found = <String>[];

    for (final entity in Directory('lib/src').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        if (lines[index].contains('autoStart: true')) {
          found.add('${entity.path}:${index + 1}');
        }
      }
    }

    expect(found, isEmpty, reason: found.join('\n'));
  });
}
