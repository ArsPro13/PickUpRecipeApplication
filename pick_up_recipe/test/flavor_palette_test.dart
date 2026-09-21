// Цвет слова вкуса: категория задаёт тон, ступень — цветность.
//
// Проверяется то, из-за чего цвет вообще переехал в одно место: раньше он
// приходил параметром из вызывающего кода, и «ягода» на карточке пачки и
// «ягода» на экране оценки могли оказаться разного цвета.

import 'dart:ui';

import 'package:flutter/material.dart' show HSLColor;
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/reference/domain/flavor_palette.dart';

void main() {
  FlavorPalette palette({Map<String, DescriptorTone> index = const {}}) =>
      FlavorPalette.builtIn().merge(const [], index);

  group('палитра', () {
    test('слово из словаря красится цветом своей категории', () {
      final subject = palette(index: {
        'клубника': const DescriptorTone('berry', 3),
      });

      expect(subject.categoryOf('клубника').slug, 'berry');
      expect(subject.categoryOf('Клубника').slug, 'berry',
          reason: 'регистр набора не меняет семью вкуса');
    });

    test('незнакомое слово — нейтральный тег, а не случайный цвет', () {
      expect(palette().categoryOf('шуруп').slug, 'other');
    });

    test('ступень меняет цветность, но не тон и не светлоту', () {
      final subject = palette(index: {
        'ягода': const DescriptorTone('berry', 1),
        'ежевика': const DescriptorTone('berry', 3),
      });

      final family = subject.colorsOf('ягода', Brightness.light);
      final single = subject.colorsOf('ежевика', Brightness.light);

      final familyHsl = HSLColor.fromColor(family.ink);
      final singleHsl = HSLColor.fromColor(single.ink);

      expect(familyHsl.saturation, lessThan(singleHsl.saturation),
          reason: 'семья тише отдельного слова');
      // Допуск в градус — цена округления до восьми бит на канал, а не
      // расхождение тона: цвет всё равно хранится как #RRGGBB.
      expect(familyHsl.hue, closeTo(singleHsl.hue, 1.5),
          reason: 'тон у одной семьи общий — иначе это разные категории');
      expect(familyHsl.lightness, closeTo(singleHsl.lightness, 0.02),
          reason: 'светлота держит контраст текста и меняться не должна');
    });

    test('слово с пачки короче справочного — красится по началу', () {
      final subject = palette(index: {
        'тростниковый сахар': const DescriptorTone('sugars', 3),
      });

      expect(subject.categoryOf('тростник').slug, 'sugars',
          reason: 'на пачке пишут короче, чем в справочнике');
    });

    test('короткое слово по началу не угадывается', () {
      final subject = palette(index: {
        'сок': const DescriptorTone('fruit', 2),
      });

      expect(subject.categoryOf('сокращение').slug, 'other',
          reason: 'три буквы — уже лотерея, а цвет здесь утверждение о смысле');
    });

    test('тема меняет пару цветов, а не категорию', () {
      final subject = palette(index: {
        'ягода': const DescriptorTone('berry', 2),
      });

      final light = subject.colorsOf('ягода', Brightness.light);
      final dark = subject.colorsOf('ягода', Brightness.dark);

      expect(light.category.slug, dark.category.slug);
      expect(light.ink, isNot(dark.ink));
      expect(light.fill, isNot(dark.fill));
    });

    test('серверная палитра ложится поверх встроенной, а не вместо', () {
      const server = FlavorCategory(
        slug: 'berry',
        name: 'Ягоды',
        inkLight: Color(0xFF111111),
        fillLight: Color(0xFFEEEEEE),
        inkDark: Color(0xFFDDDDDD),
        fillDark: Color(0xFF222222),
      );

      final subject = FlavorPalette.builtIn().merge([server], const {});

      expect(subject.bySlug('berry').inkLight, const Color(0xFF111111));
      expect(subject.bySlug('citrus').inkLight, isNot(const Color(0xFF111111)),
          reason: 'категория, которой сервер не знает, не должна посереть');
    });
  });
}
