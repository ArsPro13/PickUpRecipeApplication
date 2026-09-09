// Черновик оценки: то, что человек успел натыкать, обязано пережить выход.
//
// Проверяется тестом, а не руками, ровно по той же причине, что и очередь
// отправки: ошибка здесь не ломает экран, а молча теряет половину оценки —
// и заметить это можно только на выпитой чашке, которую уже не переоценить.

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/recipes/application/rating_draft.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/taste_map.dart';
import 'package:shared_preferences/shared_preferences.dart';

RecipeData recipe({int id = 42, int packId = 7}) => RecipeData(
      id: id,
      device: 'hario_v60',
      date: '2026-09-05T10:00:00Z',
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
      grindDescriptor: 'medium',
      agitationLevel: null,
      steps: [
        RecipeStep(
          seqNum: 1,
          instruction: 'Предсмачивание',
          water: 45,
          time: 30,
          id: 1,
          stepType: 'bloom',
          stepKey: '',
          tip: '',
          isOptional: false,
          untilUser: false,
          untilSign: '',
          warning: '',
        ),
      ],
    );

PackData pack({int packId = 7}) => PackData(
      packId: packId,
      userId: '1',
      packDate: '2026-09-01T10:00:00Z',
      packName: 'Бразилия',
      packDescriptors: const [],
      packCountry: 'Бразилия',
      packProcessingMethod: const [],
      packImage: '',
      packVariety: 'бурбон',
      packScaScore: 84,
      isActive: true,
      roasterName: 'Tasty',
    );

RatingDraft draft({
  TastePoint point = const TastePoint(0.5, -0.6),
  int stars = 4,
  Map<String, double> axes = const {'acidity': 7},
  DateTime? savedAt,
}) {
  return RatingDraft(
    recipe: recipe(),
    pack: pack(),
    point: point,
    stars: stars,
    axes: axes,
    savedAt: savedAt ?? DateTime.now(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations ru;
  late AppLocalizations en;

  setUpAll(() async {
    ru = await AppLocalizations.delegate.load(const Locale('ru'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();
    RatingDrafts.current.value = null;
  });

  group('черновик оценки', () {
    test('сохранённое поднимается обратно целиком', () async {
      await RatingDrafts.save(draft());

      final restored = await RatingDrafts.load();

      expect(restored, isNotNull);
      expect(restored!.point, const TastePoint(0.5, -0.6));
      expect(restored.stars, 4);
      expect(restored.axes, {'acidity': 7});
      expect(restored.recipe.id, 42);
      expect(restored.pack?.packId, 7);
    });

    test('рецепт сохраняется рецептом, а не обломком', () async {
      // С плашки открывается тот же экран оценки, и без сети сходить за
      // рецептом будет некуда: шаги обязаны доехать вместе с черновиком.
      await RatingDrafts.save(draft());

      final restored = await RatingDrafts.load();

      expect(restored!.recipe.steps.single.instruction, 'Предсмачивание');
      expect(restored.recipe.temperature, 93);
      expect(restored.recipe.device, 'hario_v60');
    });

    test('пустой черновик не пишется: открыть и закрыть экран — не оценка', () async {
      await RatingDrafts.save(
        draft(point: TastePoint.center, stars: 0, axes: const {}),
      );

      expect(await RatingDrafts.load(), isNull);
      expect(RatingDrafts.current.value, isNull);
    });

    test('одних звёзд хватает, чтобы черновик был', () async {
      await RatingDrafts.save(
        draft(point: TastePoint.center, stars: 3, axes: const {}),
      );

      expect((await RatingDrafts.load())!.stars, 3);
    });

    test('протухший черновик не показывается и стирается', () async {
      await RatingDrafts.save(
        draft(savedAt: DateTime.now().subtract(RatingDrafts.lifetime + const Duration(days: 1))),
      );

      expect(await RatingDrafts.load(), isNull, reason: 'неделю спустя чашку уже не вспомнить');
      expect(
        EncryptedSharedPreferences.getInstance().getString('rating_draft_v1'),
        anyOf(isNull, isEmpty),
        reason: 'протухшее не должно лежать в хранилище',
      );
    });

    test('черновик младше срока — живой', () async {
      await RatingDrafts.save(
        draft(savedAt: DateTime.now().subtract(RatingDrafts.lifetime - const Duration(hours: 1))),
      );

      expect(await RatingDrafts.load(), isNotNull);
    });

    test('после отправки оценки продолжать нечего', () async {
      await RatingDrafts.save(draft());
      await RatingDrafts.clear();

      expect(await RatingDrafts.load(), isNull);
      expect(RatingDrafts.current.value, isNull);
    });

    test('битое хранилище равно пустому, а не падению', () async {
      await EncryptedSharedPreferences.getInstance()
          .setString('rating_draft_v1', 'не json вовсе');

      expect(await RatingDrafts.load(), isNull);
    });

    test('плашка узнаёт о черновике без перечитывания хранилища', () async {
      // Черновик пишет экран оценки, а показывает его вкладка «Пачки»:
      // без живого сигнала плашка появлялась бы только после перезапуска.
      final seen = <RatingDraft?>[];
      void listener() => seen.add(RatingDrafts.current.value);
      RatingDrafts.current.addListener(listener);

      await RatingDrafts.save(draft());
      await RatingDrafts.clear();

      RatingDrafts.current.removeListener(listener);
      expect(seen.length, 2);
      expect(seen.first?.stars, 4);
      expect(seen.last, isNull);
    });

    test('подпись плашки говорит, что именно осталось недосказанным', () async {
      expect(
        draft(point: const TastePoint(0, -0.9), stars: 4, axes: const {'acidity': 7})
            .summaryFor(ru),
        'сильно слабо · 4 из 5 · 1 ось',
      );
      expect(
        draft(point: TastePoint.center, stars: 0, axes: const {'acidity': 7, 'aroma': 6})
            .summaryFor(ru),
        '2 оси',
      );
    });

    test('на английском телефоне подпись плашки английская, со своим счётом осей', () async {
      // Счёт осей — ICU, а не рука: у русского три формы, у английского две,
      // и собранное вручную «1 axes» выдавало бы подделку под перевод.
      expect(
        draft(point: const TastePoint(0, -0.9), stars: 4, axes: const {'acidity': 7})
            .summaryFor(en),
        'very weak · 4 of 5 · 1 axis',
      );
      expect(
        draft(point: TastePoint.center, stars: 0, axes: const {'acidity': 7, 'aroma': 6})
            .summaryFor(en),
        '2 axes',
      );
    });
  });
}
