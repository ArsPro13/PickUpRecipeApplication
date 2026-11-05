// На каждую насыщенность, которую просит код, вложен свой файл шрифта.
//
// Flutter не падает, когда нужного начертания нет: берёт ближайшее, а
// полужирный рисует сам, утолщая контур обычного. Выглядит это как
// размытые буквы, и заметить причину трудно — так таймер и названия шагов
// рисовались из единственного Roboto-Regular, пока шрифт не поменяли.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';

/// Файлы семейства из pubspec.yaml: насыщенность → путь.
Map<int, String> declaredFonts(String family) {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final start = pubspec.indexOf('- family: $family');
  if (start < 0) return {};

  final next = pubspec.indexOf('- family:', start + 1);
  final block = pubspec.substring(start, next < 0 ? pubspec.length : next);

  return {
    for (final match
        in RegExp(r'- asset:\s*(\S+)\s+weight:\s*(\d+)').allMatches(block))
      int.parse(match.group(2)!): match.group(1)!,
  };
}

/// Насыщенности, которые встречаются в коде приложения.
Set<int> usedWeights() {
  final weights = <int>{};
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));

  for (final file in files) {
    final found =
        RegExp(r'FontWeight\.w(\d00)').allMatches(file.readAsStringSync());
    weights.addAll(found.map((match) => int.parse(match.group(1)!)));
  }

  return weights;
}

void main() {
  test('шрифт приложения объявлен в pubspec.yaml', () {
    expect(declaredFonts(AppFonts.family), isNotEmpty,
        reason: 'семейство ${AppFonts.family} не найдено в секции fonts');
  });

  test('на каждую насыщенность из кода есть файл', () {
    final declared = declaredFonts(AppFonts.family);
    final missing = usedWeights().difference(declared.keys.toSet());

    expect(missing, isEmpty,
        reason: 'код просит насыщенность, которой нет среди файлов: '
            'Flutter подменит её ближайшей или утолщит обычную');
  });

  group('цифры равной ширины', () {
    // Вместе с равной шириной включается единица пошире — а тот же набор
    // меняет в шрифте буквы «а», «g», «t», «y». Поэтому он только для строк
    // из одних цифр: в «250 ml» буквы стали бы другими, чем рядом.
    test('таймеру и числам — да', () {
      for (final text in ['0:11', '1:02:40', '250', '08', '1,5']) {
        expect(AppFonts.tabularFor(text), AppFonts.tabular, reason: text);
      }
    });

    test('строкам с буквами — нет', () {
      for (final text in [
        '15 г',
        '47 кликов',
        '250 ml',
        'января',
        'готово в 08:40',
        'A',
      ]) {
        expect(AppFonts.tabularFor(text), isNull, reason: text);
      }
    });
  });

  test('объявленные файлы лежат на месте', () {
    for (final path in declaredFonts(AppFonts.family).values) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
