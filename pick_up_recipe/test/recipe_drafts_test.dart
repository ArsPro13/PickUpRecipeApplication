// Изменённый, но не сохранённый рецепт не должен пропадать.
//
// Всё держится на отпечатке: по нему черновик один на рецепт, по нему же
// сохранённая версия свой черновик гасит. Ошибка здесь выглядит не как
// сломанный экран, а как сохранённая версия с пометкой «не сохранён» — то есть
// как враньё на карточке; глазами такое ловится через неделю.

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/core/offline/recipe_drafts.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipes_list_state.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/pages/recipes_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

RecipeStep step({int id = 1, int water = 45, String instruction = 'Предсмачивание'}) {
  return RecipeStep(
    seqNum: 1,
    instruction: instruction,
    water: water,
    time: 30,
    id: id,
    stepType: 'bloom',
    stepKey: '',
    tip: '',
    isOptional: false,
    untilUser: false,
    untilSign: '',
    warning: '',
  );
}

RecipeData recipe({
  int id = 1,
  int packId = 7,
  String device = 'hario_v60',
  String date = '2026-09-05T10:00:00Z',
  int water = 250,
  String grindStep = '18',
  List<RecipeStep>? steps,
}) {
  return RecipeData(
    id: id,
    device: device,
    date: date,
    packId: packId,
    grinderId: 1,
    grindStep: grindStep,
    grindSubStep: null,
    water: water,
    time: 150,
    temperature: 93,
    load: 15,
    title: '',
    notes: '',
    grindDescriptor: 'medium',
    agitationLevel: null,
    steps: steps ?? [step()],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();
  });

  group('отпечаток рецепта', () {
    test('идентификатор и дата рецепт не описывают', () {
      // Та же правка, доехав до сервера, получает и новый id, и новое время —
      // и остаётся тем же рецептом.
      expect(
        recipeFingerprint(recipe(id: 1, date: '2026-09-05T10:00:00Z')),
        recipeFingerprint(recipe(id: 777, date: '2026-09-06T21:00:00Z')),
      );
    });

    test('идентификаторы шагов проставляет база — их тоже не считаем', () {
      expect(
        recipeFingerprint(recipe(steps: [step(id: 1)])),
        recipeFingerprint(recipe(steps: [step(id: 555)])),
      );
    });

    test('изменённые числа дают другой отпечаток', () {
      final base = recipeFingerprint(recipe());

      expect(recipeFingerprint(recipe(water: 260)), isNot(base));
      expect(recipeFingerprint(recipe(grindStep: '20')), isNot(base));
      expect(recipeFingerprint(recipe(steps: [step(water: 60)])), isNot(base));
      expect(recipeFingerprint(recipe(packId: 8)), isNot(base));
      expect(recipeFingerprint(recipe(device: 'chemex')), isNot(base));
    });
  });

  group('черновики', () {
    test('заваривание запоминает рецепт', () async {
      await RecipeDrafts.remember(recipe(water: 260));

      expect(RecipeDrafts.all().single.water, 260);
    });

    test('повторный вход в тот же рецепт не плодит второй черновик', () async {
      await RecipeDrafts.remember(recipe(water: 260));
      await RecipeDrafts.remember(recipe(water: 260, id: 99, date: '2026-09-06T08:00:00Z'));

      expect(RecipeDrafts.all().length, 1);
    });

    test('другая правка — другой черновик', () async {
      await RecipeDrafts.remember(recipe(water: 260));
      await RecipeDrafts.remember(recipe(water: 270));

      expect(RecipeDrafts.all().length, 2);
      expect(RecipeDrafts.all().first.water, 270, reason: 'свежий сверху');
    });

    test('черновиков копится не больше предела', () async {
      for (var i = 0; i < RecipeDrafts.limit + 5; i++) {
        await RecipeDrafts.remember(recipe(water: 200 + i));
      }

      expect(RecipeDrafts.all().length, RecipeDrafts.limit);
      expect(RecipeDrafts.all().first.water, 200 + RecipeDrafts.limit + 4);
    });

    test('догнавший сохранённую версию черновик перестаёт быть черновиком', () async {
      await RecipeDrafts.remember(recipe(water: 260));

      // Сервер завёл версию: свой идентификатор, своё время, свои id шагов.
      await RecipeDrafts.forgetKnown([
        recipe(water: 260, id: 777, date: '2026-09-06T21:00:00Z', steps: [step(id: 900)]),
      ]);

      expect(RecipeDrafts.all(), isEmpty);
    });

    test('чужая сохранённая версия черновик не трогает', () async {
      await RecipeDrafts.remember(recipe(water: 260));
      await RecipeDrafts.forgetKnown([recipe(water: 250)]);

      expect(RecipeDrafts.all().length, 1);
    });

    test('битое хранилище равно пустому, а не падению', () async {
      await EncryptedSharedPreferences.getInstance()
          .setString('recipe_drafts_v1', 'не json вовсе');

      expect(RecipeDrafts.all(), isEmpty);
      expect(RecipeDrafts.keys(), isEmpty);
    });
  });

  group('черновики в списке', () {
    test('незаконченная правка подмешивается к серверным версиям', () {
      final merged = withUnsentRecipes(
        [recipe(id: 5)],
        const [],
        drafts: [recipe(id: 5, water: 260)],
      );

      expect(merged.length, 2);
      expect(merged.first.water, 260, reason: 'самое свежее и самое неготовое — сверху');
    });

    test('сохранённая версия свой черновик в список не пускает', () {
      final merged = withUnsentRecipes(
        [recipe(id: 777, water: 260, date: '2026-09-06T21:00:00Z')],
        const [],
        drafts: [recipe(id: 5, water: 260)],
      );

      expect(merged.length, 1, reason: 'иначе одна и та же версия стояла бы дважды');
    });

    test('неотправленная версия тоже гасит свой черновик', () {
      final unsent = [recipe(id: -1001, water: 260)];

      final merged = withUnsentRecipes(
        [recipe(id: 5)],
        unsent,
        drafts: [recipe(id: 5, water: 260)],
      );

      expect(merged.length, 2);
      expect(merged.map((it) => it.id), [-1001, 5]);
    });

    test('черновик чужой пачки в отфильтрованный список не попадает', () {
      final merged = withUnsentRecipes(
        [recipe(id: 5)],
        const [],
        drafts: [recipe(id: 5, packId: 8, water: 260)],
        packId: 7,
      );

      expect(merged.length, 1);
    });

    test('пометку получает черновик, а сохранённая версия — нет', () {
      final draft = recipe(id: 5, water: 260);
      final groups = groupRecipes(
        [draft, recipe(id: 5)],
        draftKeys: {recipeFingerprint(draft)},
      );

      final versions = groups.single.versions;
      expect(versions.where((it) => it.draft).length, 1);
      expect(versions.firstWhere((it) => it.draft).recipe.water, 260);
      expect(versions.firstWhere((it) => !it.draft).recipe.water, 250);
    });

    test('без черновиков пометки не появляется ни у кого', () {
      final groups = groupRecipes([recipe(id: 5), recipe(id: 6, water: 260)]);

      expect(groups.single.versions.every((it) => !it.draft), isTrue);
    });

    test('черновик считается версией — ровно как он и нарисован', () {
      // Стопка рисует по карточке на версию, точки под ней — по версии, и
      // подпись «N версии» берётся отсюда же. Считать черновик как-то иначе
      // значило бы разойтись с тем, что видно на экране.
      final draft = recipe(id: 5, water: 260, date: '2026-09-06T21:00:00Z');
      final groups = groupRecipes(
        [draft, recipe(id: 5)],
        draftKeys: {recipeFingerprint(draft)},
      );

      expect(groups.single.versions.length, 2);
      expect(groups.single.depth, 1);
      expect(groups.single.latest.draft, isTrue, reason: 'самое свежее — сверху стопки');
    });

    test('черновик не плодит лишних меток на карточке пачки', () {
      final draft = recipe(id: 5, water: 260, date: '2026-09-06T21:00:00Z');
      final groups = groupRecipes(
        [draft, recipe(id: 5)],
        methodNames: const {'hario_v60': 'Hario V60'},
        draftKeys: {recipeFingerprint(draft)},
      );

      expect(methodsOfPack(groups, 7).map((it) => it.name), ['Hario V60']);
    });
  });

  group('подсказка жестом', () {
    test('дёргается первая стопка, в которой есть что листать', () {
      expect(
        shouldHintSwipe(
          first: true,
          versions: 2,
          animationsDisabled: false,
          alreadyShown: false,
        ),
        isTrue,
      );
    });

    test('одна версия — жеста нет, и намекать не на что', () {
      expect(
        shouldHintSwipe(
          first: true,
          versions: 1,
          animationsDisabled: false,
          alreadyShown: false,
        ),
        isFalse,
      );
    });

    test('дёргается только первая группа, а не весь список разом', () {
      expect(
        shouldHintSwipe(
          first: false,
          versions: 3,
          animationsDisabled: false,
          alreadyShown: false,
        ),
        isFalse,
      );
    });

    test('движение выключено в системе — не двигаемся вовсе', () {
      // Смысл в этом случае держит подпись у точек: движение не может быть
      // единственным носителем смысла (design/motion.md).
      expect(
        shouldHintSwipe(
          first: true,
          versions: 2,
          animationsDisabled: true,
          alreadyShown: false,
        ),
        isFalse,
      );
    });

    test('один раз за сессию, а не при каждом взгляде на список', () {
      expect(
        shouldHintSwipe(
          first: true,
          versions: 2,
          animationsDisabled: false,
          alreadyShown: true,
        ),
        isFalse,
      );
    });
  });
}
