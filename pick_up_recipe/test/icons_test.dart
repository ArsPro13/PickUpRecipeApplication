// Набор иконок: 161 файл, собранный scripts/gen-app-icons.py из
// design/icons (с 14.11.2026 — Lucide и свои силуэты в его стиле; до того —
// спрайт макетов).
//
// 161 — с «копией» для кабинета (14.11.2026). До неё было 160: иконка Koar
// ушла вместе с прибором — устройства с таким названием не существует, метод
// убран из каталога 1 сентября 2026.
//
// Тест ловит расхождение двух наборов. Оно не даёт ни ошибки компиляции, ни
// падения: flutter_svg на отсутствующем файле рисует пустоту, и заметить это
// можно только глазами на нужном экране.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/themes/app_icons.dart';

void main() {
  group('иконки', () {
    test('в наборе 161 иконка, как в design/icons/set.json', () {
      // 71 прибор, 17 шагов, 27 вкусов, 6 показателей, 4 состояния и
      // 36 значков интерфейса (с 14.11.2026 — и «копия» для кабинета).
      expect(AppIcons.all, hasLength(161));
    });

    test('каждому методу каталога есть иконка', () {
      // Ключи — icon_key из миграций 20260729000200 и 20260813100000.
      // Разошедшийся ключ здесь означает пустой квадрат на плитке метода.
      for (final key in [
        'v60',
        'kalita',
        'switch',
        'batch',
        'french_press',
        'aeropress_inverted',
        'kono',
        'pulsar',
        'flair',
        'nine_barista',
        'toddy',
        'pour_over',
        'karlsbader',
        'bripe'
      ]) {
        expect(AppIcons.byKey('method-$key'), isNotNull, reason: key);
      }
    });

    test('каждый файл существует', () {
      final missing =
          AppIcons.all.where((path) => !File(path).existsSync()).toList();

      expect(
        missing,
        isEmpty,
        reason: 'перегенерируйте: node scripts/extract-icons.js',
      );
    });

    test('нет лишних файлов, которых нет в перечне', () {
      final onDisk = Directory('assets/icons')
          .listSync()
          .whereType<File>()
          .map((file) => file.path)
          .where((path) => path.endsWith('.svg'))
          .toSet();

      expect(onDisk.difference(AppIcons.all.toSet()), isEmpty);
    });

    test('каждая иконка одноцветная: только currentColor', () {
      for (final path in AppIcons.all) {
        final svg = File(path).readAsStringSync();
        expect(svg, contains('currentColor'), reason: path);
        // Заливка и обводка своим цветом сломали бы перекраску под тему.
        expect(svg.contains('fill="#'), isFalse, reason: path);
        expect(svg.contains('stroke="#'), isFalse, reason: path);
      }
    });

    test('сетка 24×24 у всех', () {
      for (final path in AppIcons.all) {
        expect(File(path).readAsStringSync(), contains('viewBox="0 0 24 24"'),
            reason: path);
      }
    });

    group('byKey', () {
      test('находит иконку по ключу справочника', () {
        expect(AppIcons.byKey('step-bloom'), AppIcons.stepBloom);
        expect(AppIcons.byKey('metric-water'), AppIcons.metricWater);
      });

      test('неизвестный ключ даёт null, а не пустой квадрат', () {
        expect(AppIcons.byKey('нет-такой'), isNull);
        expect(AppIcons.byKey(''), isNull);
        expect(AppIcons.byKey(null), isNull);
      });
    });
  });
}
