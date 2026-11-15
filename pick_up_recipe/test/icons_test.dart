// Набор иконок: 161 файл, сгенерированный из спрайта макетов.
//
// С 1 сентября 2026 было 160: иконка Koar ушла вместе с прибором —
// устройства с таким названием не существует. 15.11.2026 добавилась «копия»
// для «повторить шаг» в кабинете: набор у кабинета и приложения один.
//
// С 14 по 15.11.2026 набор был на Lucide; владелец попросил вернуть
// прежний, и источник снова спрайт (ADR 0005, дополнение от 15.11.2026).
//
// Тест ловит расхождение двух наборов. Оно не даёт ни ошибки компиляции, ни
// падения: flutter_svg на отсутствующем файле рисует пустоту, и заметить это
// можно только глазами на нужном экране.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/themes/app_icons.dart';

void main() {
  group('иконки', () {
    test('в наборе 161 иконка, как в спрайте макетов', () {
      // 71 прибор каталога ночи 4, 17 шагов смешанного набора, 27 вкусов,
      // 6 показателей, 4 состояния и 36 значков интерфейса.
      expect(AppIcons.all, hasLength(161));
    });

    test('прибор и интерфейс — разной толщины, как рисовали', () {
      // Приборы и шаги нарисованы тонкой линией 1.15, остальное — 1.75
      // (design/tokens/icons.js). Одна толщина на всё — признак того, что
      // файлы собраны не из спрайта: так выглядел набор на Lucide.
      String widthOf(String path) => RegExp(r'stroke-width="([0-9.]+)"')
          .firstMatch(File(path).readAsStringSync())!
          .group(1)!;

      expect(widthOf(AppIcons.methodFrenchPress), '1.15');
      expect(widthOf(AppIcons.stepBloom), '1.15');
      expect(widthOf(AppIcons.uiHistory), '1.75');
      expect(widthOf(AppIcons.uiCopy), '1.75');
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
