// Набор иконок: 160 файлов, сгенерированных из спрайта макетов.
//
// Было 161: иконка Koar ушла вместе с прибором — устройства с таким
// названием не существует, метод убран из каталога 1 сентября 2026.
//
// Тест ловит расхождение двух наборов. Оно не даёт ни ошибки компиляции, ни
// падения: flutter_svg на отсутствующем файле рисует пустоту, и заметить это
// можно только глазами на нужном экране.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/themes/app_icons.dart';

void main() {
  group('иконки', () {
    test('в наборе 160 иконок, как в спрайте макетов', () {
      // 72 прибора каталога ночи 4, 17 шагов смешанного набора и интерфейс.
      expect(AppIcons.all, hasLength(160));
    });

    test('каждому методу каталога есть иконка', () {
      // Ключи — icon_key из миграций 20260729000200 и 20260813100000.
      // Разошедшийся ключ здесь означает пустой квадрат на плитке метода.
      for (final key in ['v60', 'kalita', 'switch', 'batch', 'french_press',
        'aeropress_inverted', 'kono', 'pulsar', 'flair', 'nine_barista',
        'toddy', 'pour_over', 'karlsbader', 'bripe']) {
        expect(AppIcons.byKey('method-$key'), isNotNull, reason: key);
      }
    });

    test('каждый файл существует', () {
      final missing = AppIcons.all.where((path) => !File(path).existsSync()).toList();

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
        expect(File(path).readAsStringSync(), contains('viewBox="0 0 24 24"'), reason: path);
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
