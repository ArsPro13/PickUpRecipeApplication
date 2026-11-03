// Названия приборов на языке экрана и порядок по алфавиту.
//
// Владелец: «если в приложении русский язык, у всех девайсов должно быть
// русское название и сортировка по названию, а если английское более
// популярное — пускай будет в скобках». Русские названия со скобками
// приходят из справочника; здесь проверяется, что экран берёт нужное и
// сортирует по тому, что показывает.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/brew_methods/application/brew_methods_state.dart';
import 'package:pick_up_recipe/src/features/brew_methods/domain/brew_method.dart';
import 'package:pick_up_recipe/src/features/brew_methods/domain/method_names.dart';
import 'package:pick_up_recipe/src/features/codes/application/coffee_state.dart';

BrewMethod method(String slug, String ru, String en, {String it = ''}) =>
    BrewMethod(
      id: slug.hashCode,
      slug: slug,
      name: ru,
      nameEn: en,
      nameIt: it,
      iconKey: slug,
      groupId: 1,
    );

void main() {
  group('название на языке экрана', () {
    test('русский — name, английский — name_en, итальянский — name_it', () {
      final chemex = method('chemex', 'Кемекс (Chemex)', 'Chemex');
      final moka =
          method('moka', 'Гейзерная кофеварка (мока)', 'Moka pot', it: 'Moka');

      expect(chemex.nameFor('ru'), 'Кемекс (Chemex)');
      expect(chemex.nameFor('en'), 'Chemex');
      expect(chemex.nameFor('it'), 'Chemex',
          reason: 'итальянского нет — бренд одинаков, берём английское');
      expect(moka.nameFor('it'), 'Moka');
    });

    test('справочник без переводов — русское название на любом языке', () {
      // Так отвечает сервер, выкаченный до 03.11.2026.
      final old = BrewMethod.fromJson(const {
        'id': 1,
        'slug': 'aeropress',
        'name': 'Аэропресс',
        'icon_key': 'aeropress',
      });

      expect(old.nameFor('en'), 'Аэропресс',
          reason: 'лучше по-русски, чем пустое место');
    });

    test('переводы приходят из справочника', () {
      final fresh = BrewMethod.fromJson(const {
        'id': 2,
        'slug': 'french_press',
        'name': 'Френч-пресс',
        'name_en': 'French press',
        'name_it': '',
        'icon_key': 'french_press',
      });

      expect(fresh.nameFor('ru'), 'Френч-пресс');
      expect(fresh.nameFor('en'), 'French press');

      final group = BrewMethodGroup.fromJson(const {
        'id': 2,
        'slug': 'immersion',
        'name': 'Иммерсия',
        'name_en': 'Immersion',
        'name_it': 'Infusione',
        'icon_key': 'french_press',
      });
      expect(group.nameFor('it'), 'Infusione');
    });

    test('неизвестный язык — английское', () {
      expect(localizedMethodName('de', name: 'Сифон', en: 'Siphon'), 'Siphon');
    });
  });

  group('алфавит', () {
    test('регистр не важен, «ё» стоит вместе с «е»', () {
      final names = ['Эспрессо', 'ёмкость', 'Аэропресс', 'Ёж', 'еда']
        ..sort(compareMethodNames);

      expect(names, ['Аэропресс', 'еда', 'Ёж', 'ёмкость', 'Эспрессо']);
    });

    test('группа сортируется по названию на языке экрана', () {
      final group = GroupedMethods(name: 'Пуровер', methods: [
        method('hario_v60', 'Харио V60 (Hario V60)', 'Hario V60'),
        method('chemex', 'Кемекс (Chemex)', 'Chemex'),
        method('drip_bag', 'Дрип-пакет', 'Drip bag'),
      ]);

      expect(group.methodsByName('ru').map((m) => m.slug),
          ['drip_bag', 'chemex', 'hario_v60']);
      expect(group.methodsByName('en').map((m) => m.slug),
          ['chemex', 'drip_bag', 'hario_v60']);
    });

    test('на странице кофе — сначала с рецептом, внутри — по алфавиту', () {
      final (groups, _) = buildCoffeeMethods(
        [
          GroupedMethods(name: 'Пуровер', nameEn: 'Pour-over', methods: [
            method('hario_v60', 'Харио V60 (Hario V60)', 'Hario V60'),
            method('chemex', 'Кемекс (Chemex)', 'Chemex'),
            method('drip_bag', 'Дрип-пакет', 'Drip bag'),
            method('april', 'Эйприл (April Brewer)', 'April Brewer'),
          ]),
        ],
        const [],
      );

      final pourOver = groups.single;
      expect(pourOver.nameFor('en'), 'Pour-over');
      expect(pourOver.methodsFor('ru').map((m) => m.slug),
          ['drip_bag', 'chemex', 'hario_v60', 'april']);
      expect(pourOver.methodsFor('en').map((m) => m.slug),
          ['april', 'chemex', 'drip_bag', 'hario_v60']);
    });
  });
}
