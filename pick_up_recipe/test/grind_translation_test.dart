// Помол делениями вашей кофемолки (пункт 8).
//
// Формулировка владельца: «помол в большинстве мест должен быть числовой и в
// зависимости от значений кофемолки, а не средне тонкий и тп». Значения по
// кофемолкам приходят из grinder_translator вместе с профилем, перевод идёт
// в два шага: дескриптор → микроны → ближайшее деление шкалы.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/grind_translation.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/models/grinder_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/grind_descriptor_model.dart';

/// Справочник крупности целиком — тот же, что засеян миграцией.
const List<GrindDescriptor> reference = [
  GrindDescriptor(slug: 'extra_fine', name: 'Очень тонкий', microns: 200, sortOrder: 1),
  GrindDescriptor(slug: 'fine', name: 'Тонкий', microns: 400, sortOrder: 2),
  GrindDescriptor(slug: 'medium_fine', name: 'Средне-тонкий', microns: 600, sortOrder: 3),
  GrindDescriptor(slug: 'medium', name: 'Средний', microns: 800, sortOrder: 4),
  GrindDescriptor(slug: 'medium_coarse', name: 'Средне-крупный', microns: 1000, sortOrder: 5),
  GrindDescriptor(slug: 'coarse', name: 'Крупный', microns: 1200, sortOrder: 6),
  GrindDescriptor(slug: 'extra_coarse', name: 'Очень крупный', microns: 1400, sortOrder: 7),
];

/// Кусок настоящей шкалы Comandante C40 из базы grinder_translator.
const Grinder comandante = Grinder(
  id: 11,
  name: 'Comandante C40',
  modes: [
    GrinderMode(mode: '11.0', microns: 553.7),
    GrinderMode(mode: '13.0', microns: 583.1),
    GrinderMode(mode: '14.0', microns: 605.8),
    GrinderMode(mode: '20.0', microns: 819.5),
    GrinderMode(mode: '26.0', microns: 1118.9),
  ],
);

/// Feld47: шкала подписана словами, а не числами.
const Grinder feld = Grinder(
  id: 20,
  name: 'Feld47',
  modes: [
    GrinderMode(mode: '2 круг + 1', microns: 560.0),
    GrinderMode(mode: '2 круг + 3', microns: 610.0),
    GrinderMode(mode: '3 круг + 0', microns: 900.0),
  ],
);

/// Кофемолка выбрана, но её шкалы сервис пересчёта не отдал.
const Grinder withoutScale = Grinder(id: 25, name: 'Hero');

void main() {
  group('дескриптор → деление кофемолки', () {
    test('слово превращается в ближайшее деление шкалы', () {
      final grind = grindReading(
        descriptorSlug: 'medium_fine',
        reference: reference,
        grinder: comandante,
      );

      expect(grind.value, '14');
      expect(grind.isDivision, isTrue);
      expect(grind.grinderName, 'Comandante C40');
    });

    test('пересчитанное помечается словом «примерно»', () {
      // Шкалы кофемолок сходятся только по средней крупности, и считать
      // переведённое число точным нельзя.
      final grind = grindReading(
        descriptorSlug: 'medium_fine',
        reference: reference,
        grinder: comandante,
      );

      expect(grind.isApproximate, isTrue);
      expect(grind.label, 'примерно 14');
    });

    test('своё деление точнее любого перевода', () {
      // Рецепт записан в делениях этой же кофемолки — пересчитывать нечего.
      final grind = grindReading(
        descriptorSlug: 'medium_fine',
        reference: reference,
        recipeGrinderId: comandante.id,
        recipeGrindStep: '17',
        grinder: comandante,
      );

      expect(grind.value, '17');
      expect(grind.isApproximate, isFalse);
      expect(grind.label, '17');
    });

    test('деления чужой кофемолки пересчитываются, а не показываются как есть', () {
      final grind = grindReading(
        descriptorSlug: 'medium',
        reference: reference,
        recipeGrinderId: 99,
        recipeGrindStep: '26',
        grinder: comandante,
      );

      expect(grind.value, '20');
      expect(grind.isApproximate, isTrue);
    });

    test('микроны самого рецепта важнее ступени справочника', () {
      // В рецепте бывает своя крупность точнее ступени: v60.json — тому
      // пример, дескриптор medium_fine, а микроны 700.
      final grind = grindReading(
        descriptorSlug: 'medium_fine',
        reference: reference,
        recipeMicrons: 1100,
        grinder: comandante,
      );

      expect(grind.value, '26');
    });

    test('хвост .0 не показывается, а половинки идут с запятой', () {
      expect(grinderDivisionLabel('14.0'), '14');
      expect(grinderDivisionLabel('7.5'), '7,5');
      expect(grinderDivisionLabel(' 20 '), '20');
    });
  });

  group('кофемолки нет', () {
    test('остаётся слово и приглашение выбрать кофемолку', () {
      final grind = grindReading(descriptorSlug: 'medium_fine', reference: reference);

      expect(grind.value, 'Средне-тонкий');
      expect(grind.isDivision, isFalse);
      expect(grind.needsGrinder, isTrue);
      expect(grind.caption, 'выберите кофемолку');
      expect(grind.hint, 'выберите кофемолку — покажем деление');
    });

    test('помол не прячется — слово честнее пустоты', () {
      final grind = grindReading(descriptorSlug: 'coarse', reference: reference);

      expect(grind.isEmpty, isFalse);
      expect(grind.label, 'Крупный');
    });

    test('без справочника остаётся slug рецепта, а не пустота', () {
      final grind = grindReading(descriptorSlug: 'medium_fine');

      expect(grind.value, 'medium_fine');
    });

    test('нет ни слова, ни шкалы — остаётся число рецепта со щелчками', () {
      final grind = grindReading(descriptorSlug: '', recipeGrindStep: '26');

      expect(grind.value, '26 щ.');
      expect(grind.needsGrinder, isTrue);
    });

    test('рецепт не знает о помоле ничего — показывать нечего', () {
      final grind = grindReading(descriptorSlug: '');

      expect(grind.isEmpty, isTrue);
      expect(grind.caption, isNull);
    });
  });

  group('деления текстовые', () {
    test('строка вроде «2 круг + 3» показывается как есть', () {
      final grind = grindReading(
        descriptorSlug: 'medium_fine',
        reference: reference,
        grinder: feld,
      );

      expect(grind.value, '2 круг + 3');
      expect(grind.label, 'примерно 2 круг + 3');
      expect(grind.isDivision, isTrue);
    });

    test('текстовая шкала не роняет разбор и на своём делении', () {
      final grind = grindReading(
        descriptorSlug: 'medium_fine',
        reference: reference,
        recipeGrinderId: feld.id,
        recipeGrindStep: '2 круг + 1',
        grinder: feld,
      );

      expect(grind.value, '2 круг + 1');
      expect(grind.isApproximate, isFalse);
    });
  });

  group('значения нет в справочнике', () {
    test('незнакомая ступень оставляет slug и не пересчитывается', () {
      final grind = grindReading(
        descriptorSlug: 'ultra_fine',
        reference: reference,
        grinder: comandante,
      );

      expect(grind.value, 'ultra_fine');
      expect(grind.isDivision, isFalse);
      expect(grind.isApproximate, isFalse);
    });

    test('кофемолка без шкалы показывает слово и никого никуда не зовёт', () {
      // Кофемолку человек уже выбрал; звать выбирать её ещё раз — врать.
      final grind = grindReading(
        descriptorSlug: 'medium_fine',
        reference: reference,
        grinder: withoutScale,
      );

      expect(grind.value, 'Средне-тонкий');
      expect(grind.needsGrinder, isFalse);
      expect(grind.caption, isNull);
      expect(grind.hint, isNull);
    });

    test('пустая шкала не выбирает деление', () {
      expect(nearestGrinderMode(const [], 600), isNull);
    });

    test('деления без крупности пропускаются', () {
      final mode = nearestGrinderMode(
        const [
          GrinderMode(mode: '', microns: 599),
          GrinderMode(mode: '9.0', microns: 0),
          GrinderMode(mode: '10.0', microns: 700),
        ],
        600,
      );

      expect(mode?.mode, '10.0');
    });

    test('микроны ступени берутся из справочника, чужой ступени — нет', () {
      expect(grindDescriptorMicrons(reference, 'medium'), 800);
      expect(grindDescriptorMicrons(reference, 'ultra_fine'), isNull);
      expect(grindDescriptorMicrons(reference, ''), isNull);
    });
  });
}
