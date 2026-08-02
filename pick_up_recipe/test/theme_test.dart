// Тема собрана из design/tokens/tokens.css.
//
// Проверяются решения, а не оформление: цвета, которые владелец назвал явно
// (ответ D1), и контраст, из-за которого тёмный оттенок отличается от светлого.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';

/// Контраст по WCAG: (L1 + 0.05) / (L2 + 0.05).
double contrast(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

void main() {
  group('фирменный цвет', () {
    // Раньше primary был коричневым в светлой теме и СИНИМ в тёмной, а
    // «шаг завершён» — зелёным и синим соответственно. Решение владельца
    // по вопросу D1: коричневый в обеих, успех зелёный в обеих.
    test('коричневый в обеих темах', () {
      expect(lightTheme.colorScheme.primary, const Color(0xFF8E6341));
      expect(darkTheme.colorScheme.primary, const Color(0xFFC89264));
    });

    test('в тёмной теме он читается на фоне', () {
      // Сам #8E6341 на фоне #191617 даёт 3.4:1 — хватает крупным элементам,
      // но не тексту. Светлый оттенок той же гаммы поднимает контраст.
      final value = contrast(darkTheme.colorScheme.primary, darkTheme.colorScheme.surface);
      expect(value, greaterThan(4.5), reason: 'фирменным цветом пишут текст, а не только заливают');
    });

    test('успех зелёный в обеих темах', () {
      expect(lightTheme.extension<AppColors>()!.success, const Color(0xFF00932A));
      expect(darkTheme.extension<AppColors>()!.success, const Color(0xFF3FBF63));
    });
  });

  group('цвета показателей', () {
    // Это смысловые цвета предметной области, а не оформление: вода синяя
    // в любой теме, иначе метка «вода» перестанет узнаваться.
    test('одинаковы в обеих темах', () {
      expect(lightTheme.extension<MetricColors>(), darkTheme.extension<MetricColors>());
    });

    test('все четыре различимы между собой', () {
      const metrics = MetricColors.standard;
      final colors = [metrics.temperature, metrics.water, metrics.dose, metrics.grind];

      expect(colors.toSet(), hasLength(4));
    });
  });

  group('основной текст', () {
    for (final entry in {'светлая': lightTheme, 'тёмная': darkTheme}.entries) {
      test('читается на фоне: ${entry.key}', () {
        final value = contrast(entry.value.colorScheme.onSurface, entry.value.colorScheme.surface);
        expect(value, greaterThan(7), reason: 'основной текст — это AAA, а не «как-нибудь»');
      });
    }
  });

  group('типографика', () {
    test('семь ступеней, все заданы', () {
      for (final theme in [lightTheme, darkTheme]) {
        final texts = theme.textTheme;
        for (final style in [
          texts.displayLarge,
          texts.titleLarge,
          texts.titleMedium,
          texts.bodyLarge,
          texts.bodyMedium,
          texts.bodySmall,
          texts.labelSmall,
        ]) {
          expect(style?.fontSize, isNotNull);
          expect(style?.height, isNotNull, reason: 'межстрочный интервал — часть токена');
        }
      }
    });

    test('размеры убывают по ступеням', () {
      final texts = lightTheme.textTheme;
      final sizes = [
        texts.displayLarge!.fontSize!,
        texts.titleLarge!.fontSize!,
        texts.titleMedium!.fontSize!,
        texts.bodyLarge!.fontSize!,
        texts.bodyMedium!.fontSize!,
        texts.bodySmall!.fontSize!,
        texts.labelSmall!.fontSize!,
      ];

      for (var i = 1; i < sizes.length; i++) {
        expect(sizes[i], lessThan(sizes[i - 1]));
      }
    });
  });

  test('расширения темы доступны в обеих', () {
    for (final theme in [lightTheme, darkTheme]) {
      expect(theme.extension<MetricColors>(), isNotNull);
      expect(theme.extension<AppColors>(), isNotNull);
    }
  });
}
