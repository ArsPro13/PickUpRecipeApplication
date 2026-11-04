// Шкалы кофемолок без сервера: встроенная копия, эталонная Comandante C40,
// деление между рисками шкалы.
//
// Владелец 04.11.2026: «почему не меняются клики при изменении объёма в
// случае воронки» и «я хочу, чтобы клики всё равно писались в числовых
// значениях». Обе жалобы — от того, что пересчёт не знал шкалы.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/builtin_grinder_scales.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/grinder_scales.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/models/grinder_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/scaling/recipe_scaler.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/scaling/scaling_profile.dart';

import 'scaling_all_methods_test.dart' show loadBaseMethods;

void main() {
  group('встроенная таблица', () {
    test('у каждой кофемолки справочника есть шкала', () {
      for (final MapEntry(key: id, value: name)
          in builtInGrinderNames.entries) {
        expect(builtInGrinderScales[name], isNotEmpty, reason: '$id $name');
      }
      expect(builtInGrinderNames, hasLength(50));
    });

    test('эталон — Comandante C40, шкала 11–31 клик', () {
      expect(referenceGrinder.id, 11);
      expect(referenceGrinder.name, 'Comandante C40');
      expect(referenceGrinder.modes.first.mode, '11.0');
      expect(referenceGrinder.modes.last.mode, '31.0');
    });

    test('шкала с сервера важнее встроенной', () {
      const server = Grinder(id: 11, name: 'Comandante C40', modes: [
        GrinderMode(mode: '20.0', microns: 820),
      ]);
      expect(server.knownModes, hasLength(1));
      expect(const Grinder(id: 11, name: 'Comandante C40').knownModes,
          hasLength(21));
    });

    test('незнакомая кофемолка — пустая шкала, а не чужая', () {
      expect(const Grinder(id: 99, name: 'Новая мельница').knownModes, isEmpty);
    });
  });

  group('деление на шкале', () {
    final c40 = referenceGrinder.modes;

    test('по подписи и по числу — одно деление', () {
      expect(divisionOnScale(c40, '14.0')?.microns, closeTo(605.8, 0.1));
      expect(divisionOnScale(c40, '14')?.microns, closeTo(605.8, 0.1));
      expect(divisionOnScale(c40, ' 14 ')?.mode, '14.0');
    });

    test('половина клика — крупность между соседями', () {
      final half = divisionOnScale(c40, '14,5')!;
      expect(half.mode, '14,5');
      expect(half.microns, closeTo((605.8 + 629.4) / 2, 1));
    });

    test('за краями шкалы и словами вне шкалы — ничего', () {
      expect(divisionOnScale(c40, '5'), isNull);
      expect(divisionOnScale(c40, '40'), isNull);
      expect(divisionOnScale(c40, 'тонко'), isNull);
    });

    test('деление чужой кофемолки — в микроны через её шкалу', () {
      expect(stepMicrons(12, '45'), 822, reason: 'DF64 45');
      expect(stepMicrons(99, '45'), isNull, reason: 'кофемолку не знаем');
      expect(stepMicrons(0, '45'), isNull, reason: 'заглушка справочного');
    });
  });

  group('пересчёт воронки по эталонной шкале', () {
    final v60 = loadBaseMethods().firstWhere((m) => m.slug == 'hario_v60');
    final profile = ScalingProfile.builtIn('hario_v60')!;

    test('без своей кофемолки клики C40 двигаются: 250 → 500 мл', () {
      final scaled = scaleRecipe(
        base: v60.recipe,
        water: 500,
        profile: profile,
        scale: referenceGrinder.modes,
        baseClick: '14',
        grinderId: referenceGrinder.id,
      );

      expect(scaled.grindStep, '16.0');
      expect(scaled.recipe.grinderId, 11);
      expect(scaled.recipe.grindStep, '16.0');
    });

    test('рецепт на половине клика тоже пересчитывается', () {
      final scaled = scaleRecipe(
        base: v60.recipe,
        water: 500,
        profile: profile,
        scale: referenceGrinder.modes,
        baseClick: '14,5',
        grinderId: referenceGrinder.id,
      );

      expect(scaled.grindStep, isNotNull);
      expect(scaled.grindRatio, greaterThan(1));
    });
  });
}
