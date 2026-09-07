// Цифры в профиле обязаны сходиться с тем, что видно на соседних вкладках.
//
// Проверяется тестом, а не пересчитыванием карточек глазами: расхождение здесь
// не ломает экран, а тихо врёт — «7 рецептов» при шести стопках заметит только
// тот, кто станет считать, и после этого не поверит уже ни одной цифре.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations_ru.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/profile/application/profile_stats.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipes_list_state.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';

RecipeData recipe(
  int packId,
  String device,
  String date,
) {
  return RecipeData(
    id: date.hashCode,
    device: device,
    date: date,
    packId: packId,
    grinderId: 1,
    grindStep: '18',
    grindSubStep: null,
    water: 250,
    time: 150,
    temperature: 93,
    load: 15,
    title: '',
    notes: '',
    grindDescriptor: '',
    agitationLevel: null,
    steps: const [],
  );
}

PackData pack({
  int packId = 1,
  String country = 'Бразилия',
  String variety = 'бурбон',
}) {
  return PackData(
    packId: packId,
    userId: '1',
    packDate: '2026-09-01T10:00:00Z',
    packName: 'Пачка $packId',
    packDescriptors: const [],
    packCountry: country,
    packProcessingMethod: const [],
    packImage: '',
    packVariety: variety,
    packScaScore: 84,
    isActive: true,
  );
}

void main() {
  group('счёт в профиле', () {
    test('рецептов столько же, сколько стопок на вкладке', () {
      final groups = groupRecipes([
        recipe(1, 'hario_v60', '2026-07-20T08:00:00Z'),
        recipe(1, 'hario_v60', '2026-07-28T08:00:00Z'),
        recipe(2, 'chemex', '2026-08-01T08:00:00Z'),
      ]);

      final stats = buildProfileStats(groups, [pack()]);

      expect(groups.length, 2);
      expect(stats.recipes, 2, reason: 'рецепт — это пара «кофе + прибор»');
      expect(stats.versions, 3, reason: 'версий столько, сколько карточек в стопках');
    });

    test('пачки, страны и сорта считаются по непустым полям', () {
      final stats = buildProfileStats(const [], [
        pack(packId: 1, country: 'Бразилия', variety: 'бурбон'),
        pack(packId: 2, country: 'Бразилия', variety: 'типика'),
        pack(packId: 3, country: '', variety: ''),
      ]);

      expect(stats.packs, 3);
      expect(stats.countries, 1, reason: 'одна страна на две пачки — это одна страна');
      expect(stats.varieties, 2);
    });

    test('любимый прибор — тот, под который рецептов больше', () {
      final groups = groupRecipes(
        [
          recipe(1, 'hario_v60', '2026-07-20T08:00:00Z'),
          recipe(2, 'hario_v60', '2026-07-21T08:00:00Z'),
          recipe(3, 'chemex', '2026-08-01T08:00:00Z'),
        ],
        methodNames: {'hario_v60': 'Hario V60', 'chemex': 'Chemex'},
      );

      final stats = buildProfileStats(groups, const []);

      expect(stats.favourite?.name, 'Hario V60');
      expect(stats.favourite?.recipes, 2);
    });

    test('пять правок одного рецепта не делают прибор любимым', () {
      // Иначе «любимый» означал бы «с которым больше всего мучились».
      final groups = groupRecipes(
        [
          recipe(1, 'hario_v60', '2026-07-20T08:00:00Z'),
          recipe(1, 'hario_v60', '2026-07-21T08:00:00Z'),
          recipe(1, 'hario_v60', '2026-07-22T08:00:00Z'),
          recipe(2, 'chemex', '2026-08-01T08:00:00Z'),
          recipe(3, 'chemex', '2026-08-02T08:00:00Z'),
        ],
        methodNames: {'hario_v60': 'Hario V60', 'chemex': 'Chemex'},
      );

      final stats = buildProfileStats(groups, const []);

      expect(stats.favourite?.name, 'Chemex');
      expect(stats.versions, 5);
    });

    test('при ничьей любимого нет — предпочтения человек не высказывал', () {
      final groups = groupRecipes(
        [
          recipe(1, 'hario_v60', '2026-07-20T08:00:00Z'),
          recipe(2, 'chemex', '2026-08-01T08:00:00Z'),
        ],
        methodNames: {'hario_v60': 'Hario V60', 'chemex': 'Chemex'},
      );

      expect(buildProfileStats(groups, const []).favourite, isNull);
    });

    test('первый рецепт — самый ранний по дате, а не первый в списке', () {
      final groups = groupRecipes([
        recipe(2, 'chemex', '2026-08-01T08:00:00Z'),
        recipe(1, 'hario_v60', '2026-07-20T08:00:00Z'),
        recipe(1, 'hario_v60', '2026-07-28T08:00:00Z'),
      ]);

      expect(buildProfileStats(groups, const []).firstRecipeDate, '2026-07-20T08:00:00Z');
    });

    test('пустой профиль — это пусто, а не четыре нуля', () {
      final stats = buildProfileStats(const [], const []);

      expect(stats.isEmpty, isTrue);
      expect(stats.favourite, isNull);
      expect(stats.firstRecipeDate, isNull);
    });

    test('пачки без рецептов — уже не пусто', () {
      expect(buildProfileStats(const [], [pack()]).isEmpty, isFalse);
    });

    // Формы числительных считает ICU, а не экран. Проверяется всё равно
    // здесь: правило то же самое, спрашивают его у другого исполнителя.
    test('числительные согласуются со счётом', () {
      final ru = AppLocalizationsRu();

      expect(ru.profileRecipes(1), 'рецепт');
      expect(ru.profileRecipes(2), 'рецепта');
      expect(ru.profileRecipes(5), 'рецептов');
      expect(ru.profileRecipes(11), 'рецептов');
      expect(ru.profileRecipes(21), 'рецепт');
      expect(ru.profileRecipes(112), 'рецептов');
    });

    test('очередь перед выходом склоняется, а не «2 дел ждут»', () {
      final ru = AppLocalizationsRu();

      expect(ru.profileLogoutPending(1), contains('1 дело ждёт'));
      expect(ru.profileLogoutPending(2), contains('2 дела ждут'));
      expect(ru.profileLogoutPending(5), contains('5 дел ждут'));
    });
  });
}
