// Страж паритета локалей.
//
// Каркас локализации сам по себе ничего не гарантирует: генератор молча
// подставляет русскую строку вместо забытого перевода, и приложение на
// английском выглядит рабочим ровно до того места, где кто-то не дописал
// вторую строку. Увидеть это глазами нельзя — английский экран открывают
// раз в месяц.
//
// Поэтому правило «строку добавили в обе локали» проверяется здесь, а не
// остаётся пожеланием в описании задачи. Тест читает .arb как обычный JSON:
// сгенерированный код для этого не нужен и только скрыл бы расхождение.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Разбирает .arb целиком: и строки, и метаданные `@ключ`.
Map<String, dynamic> _arb(String locale) {
  final source = File('lib/l10n/app_$locale.arb').readAsStringSync();

  return jsonDecode(source) as Map<String, dynamic>;
}

/// Только сами строки: `@@locale` и метаданные `@ключ` переводу не подлежат.
Map<String, String> _messages(Map<String, dynamic> arb) {
  return {
    for (final entry in arb.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
  };
}

/// Имена подстановок в строке: и `{count}`, и голова ICU-конструкции
/// `{count, plural, ...}`. Сравнивать надо именно имена — русский и
/// английский текст вокруг них разный, а подстановки обязаны совпасть,
/// иначе перевод упадёт при первом вызове.
Set<String> _placeholders(String message) {
  // Скобка, открывающая ветку множественного числа, подстановки не начинает:
  // в `one{recipe}` в ней стоит английское слово. Иначе любая ветка из одного
  // слова читалась бы как подстановка — и паритет не сходился бы никогда: в
  // русской ветке на том же месте кириллица, а её этот разбор не видит.
  final branches = RegExp(r'(?:zero|one|two|few|many|other|=\d+)\s*\{');
  final pattern = RegExp(r'\{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*[,}]');

  return pattern
      .allMatches(message.replaceAll(branches, ''))
      .map((match) => match.group(1)!)
      .toSet();
}

void main() {
  final ruArb = _arb('ru');
  final ru = _messages(ruArb);
  final en = _messages(_arb('en'));

  group('локали', () {
    test('в русском файле есть строки', () {
      expect(ru, isNotEmpty, reason: 'шаблон пуст — сравнивать не с чем');
    });

    test('набор ключей совпадает', () {
      expect(
        en.keys.toSet().difference(ru.keys.toSet()),
        isEmpty,
        reason: 'английские строки без русского оригинала',
      );
      expect(
        ru.keys.toSet().difference(en.keys.toSet()),
        isEmpty,
        reason: 'строку добавили по-русски и забыли перевести',
      );
    });

    test('английский файл без кириллицы', () {
      final cyrillic = RegExp('[а-яёА-ЯЁ]');

      for (final entry in en.entries) {
        expect(
          cyrillic.hasMatch(entry.value),
          isFalse,
          reason: 'ключ ${entry.key}: русский текст оставлен под видом перевода',
        );
      }
    });

    test('подстановки совпадают в паре', () {
      for (final key in ru.keys) {
        if (!en.containsKey(key)) continue;

        expect(
          _placeholders(en[key]!),
          _placeholders(ru[key]!),
          reason: 'ключ $key: подстановки разошлись',
        );
      }
    });

    test('ветка множественного числа — не подстановка', () {
      expect(_placeholders('{count, plural, one{recipe} other{recipes}}'), {'count'});
      expect(
        _placeholders('{n, plural, one{{n} type} other{{n} types}} из {total}'),
        {'n', 'total'},
      );
    });

    test('у каждой подстановки описан тип', () {
      for (final entry in ru.entries) {
        final names = _placeholders(entry.value);
        if (names.isEmpty) continue;

        final described = (ruArb['@${entry.key}'] as Map<String, dynamic>?)?['placeholders']
            as Map<String, dynamic>?;

        expect(
          described?.keys.toSet() ?? <String>{},
          containsAll(names),
          reason: 'ключ ${entry.key}: генератор не соберёт подстановку без '
              'её описания в @${entry.key}',
        );
      }
    });
  });
}
