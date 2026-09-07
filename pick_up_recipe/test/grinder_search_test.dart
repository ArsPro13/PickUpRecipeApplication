// Поиск по справочнику кофемолок.
//
// Кейс с фотографии владельца: в поиске «commondante», под ним «Такой
// кофемолки нет». Бренд называется Comandante, человек ошибся на две буквы —
// и точное вхождение подстроки честно не нашло ничего.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/grinder_search.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/models/grinder_model.dart';

/// Кусок настоящего справочника: имена взяты из миграции слово в слово,
/// вместе с двойными пробелами — их чинит поиск, а не данные.
const List<Grinder> catalog = [
  Grinder(id: 0, name: 'Base Grinder'),
  Grinder(id: 1, name: '1Zpresso JX', kind: GrinderKind.manual),
  Grinder(id: 6, name: 'Baratza Encore', kind: GrinderKind.electric),
  Grinder(id: 10, name: 'Comandante (Red clix)', kind: GrinderKind.manual),
  Grinder(id: 11, name: 'Comandante C40', kind: GrinderKind.manual),
  Grinder(id: 17, name: 'Eureka Mignon  жернова 50mm Filtro Pro', kind: GrinderKind.electric),
  Grinder(id: 31, name: 'Mahlkönig', kind: GrinderKind.electric),
  Grinder(id: 40, name: 'Timemore Chestnut C2', kind: GrinderKind.manual),
  Grinder(id: 48, name: 'Wilfa Svart Nymalt', kind: GrinderKind.electric),
];

List<String> names(String query) =>
    searchGrinders(selectableGrinders(catalog), query)
        .map((hit) => hit.grinder.name)
        .toList();

void main() {
  group('нормализация', () {
    test('регистр и лишние пробелы снимаются', () {
      expect(normalizeGrinderText('  COMANDANTE   C40 '), 'komandante k40');
    });

    test('двойной пробел имени справочника схлопывается', () {
      // Имена в базе трогать нельзя: по ним сходится grinder_translator.
      expect(
        normalizeGrinderText('Hario Coffee  Grinder'),
        normalizeGrinderText('Hario Coffee Grinder'),
      );
    });

    test('кириллица и латиница сходятся в одну строку', () {
      expect(normalizeGrinderText('команданте'), normalizeGrinderText('Comandante'));
      expect(normalizeGrinderText('Честнут'), normalizeGrinderText('Chestnut'));
      expect(normalizeGrinderText('Вильфа'), normalizeGrinderText('Wilfa'));
    });

    test('ё считается за е', () {
      expect(normalizeGrinderText('жёрнова'), normalizeGrinderText('жернова'));
    });

    test('умляут снимается — Mahlkönig набирают без точек', () {
      expect(normalizeGrinderText('Mahlkonig'), normalizeGrinderText('Mahlkönig'));
    });

    test('скобки и плюсы становятся границей слова, а не буквой', () {
      expect(normalizeGrinderText('Comandante (Red clix)'), 'komandante red kliks');
      expect(normalizeGrinderText('Baratza Virtuoso+'), 'baratza virtuoso');
    });
  });

  group('расстояние между словами', () {
    test('совпадение — ноль', () {
      expect(grinderEditDistance('komandante', 'komandante'), 0);
    });

    test('пропущенная буква стоит единицу', () {
      expect(grinderEditDistance('komandate', 'komandante'), 1);
    });

    test('лишняя буква стоит единицу', () {
      expect(grinderEditDistance('kommandante', 'komandante'), 1);
    });

    test('перестановка соседних стоит единицу, а не две', () {
      expect(grinderEditDistance('komadnante', 'komandante'), 1);
    });

    test('замена буквы стоит единицу', () {
      expect(grinderEditDistance('komondante', 'komandante'), 1);
    });

    test('две ошибки с фотографии — ровно две', () {
      expect(
        grinderEditDistance(
          normalizeGrinderText('commondante'),
          normalizeGrinderText('Comandante'),
        ),
        2,
      );
    });
  });

  group('порог по длине', () {
    test('короткому запросу опечатки не прощаются', () {
      // На трёх буквах одна поправка притягивает половину справочника.
      expect(grinderTypoBudget(1), 0);
      expect(grinderTypoBudget(3), 0);
    });

    test('со средней длины прощается одна', () {
      expect(grinderTypoBudget(4), 1);
      expect(grinderTypoBudget(7), 1);
    });

    test('с восьмой буквы прощаются две, но не больше', () {
      expect(grinderTypoBudget(8), 2);
      expect(grinderTypoBudget(11), 2);
      expect(grinderTypoBudget(40), 2);
    });

    test('короткий запрос всё равно находит вхождением', () {
      // Порог нулевой, но «c40» — честная подстрока имени.
      expect(names('c40'), contains('Comandante C40'));
    });
  });

  group('кейс с фотографии', () {
    test('«commondante» находит Comandante и ставит первым', () {
      final found = names('commondante');

      expect(found, isNotEmpty);
      expect(found.first, startsWith('Comandante'));
    });

    test('те же четыре написания дают тот же ответ', () {
      for (final query in ['commondante', 'komandante', 'команданте', 'COMANDANTE']) {
        final found = names(query);
        expect(found, isNotEmpty, reason: query);
        expect(found.first, startsWith('Comandante'), reason: query);
      }
    });

    test('ввод с одним пробелом находит имя с двойным', () {
      expect(
        names('Eureka Mignon жернова'),
        contains('Eureka Mignon  жернова 50mm Filtro Pro'),
      );
    });

    test('«zzz» не находит ничего и не подсказывает лишнего', () {
      expect(names('zzz'), isEmpty);
      expect(grinderDidYouMean(selectableGrinders(catalog), 'zzz'), isEmpty);
    });

    test('близкий промах предлагает вариант вместо тупика', () {
      // Порог поиска пройден не был, но человек явно метил в Baratza.
      final near = grinderDidYouMean(selectableGrinders(catalog), 'bara');

      expect(near.map((g) => g.name), contains('Baratza Encore'));
    });
  });

  group('порядок выдачи', () {
    test('начало слова идёт раньше вхождения в середину', () {
      final found = names('chestnut');

      expect(found.first, 'Timemore Chestnut C2');
    });

    test('точное совпадение обгоняет исправленную опечатку', () {
      final found = searchGrinders(selectableGrinders(catalog), 'comandante c4');

      expect(found.first.grinder.name, 'Comandante C40');
      expect(found.first.rank, GrinderMatchRank.start);
      expect(found.last.rank.index, greaterThanOrEqualTo(found.first.rank.index));
    });

    test('исправленные опечатки идут последними', () {
      final found = searchGrinders(selectableGrinders(catalog), 'commondante');

      expect(found.every((hit) => hit.rank == GrinderMatchRank.typo), isTrue);
    });
  });

  group('справочник', () {
    test('пустой запрос отдаёт весь справочник в прежнем порядке', () {
      final found = names('');

      expect(found.length, selectableGrinders(catalog).length);
      expect(found.first, '1Zpresso JX');
    });

    test('техническая запись с нулевым идентификатором в выбор не попадает', () {
      // Из справочника она не убирается — на неё ссылаются рецепты.
      expect(catalog.any((g) => g.id == baseGrinderId), isTrue);
      expect(selectableGrinders(catalog).any((g) => g.id == baseGrinderId), isFalse);
      expect(names('base'), isEmpty);
    });

    test('число моделей в подписи склоняется по справочнику', () {
      expect(grinderCountWord(50), 'моделей');
      expect(grinderCountWord(51), 'модель');
      expect(grinderCountWord(2), 'модели');
      expect(grinderCountWord(11), 'моделей');
      expect(grinderCountWord(0), 'моделей');
    });
  });

  group('подсветка', () {
    test('совпавший кусок указан в координатах исходного имени', () {
      final hit = searchGrinders(selectableGrinders(catalog), 'coman').first;

      expect(hit.hasHighlight, isTrue);
      expect(
        hit.grinder.name.substring(hit.start, hit.end).toLowerCase(),
        'coman',
      );
    });

    test('кириллический запрос подсвечивает латинское написание', () {
      final hit = searchGrinders(selectableGrinders(catalog), 'команданте').first;

      expect(hit.grinder.name.substring(hit.start, hit.end), 'Comandante');
    });

    test('буква, дающая две латинских, не сдвигает границы', () {
      final hit = searchGrinders(selectableGrinders(catalog), 'жернова').first;

      expect(hit.grinder.name.substring(hit.start, hit.end), 'жернова');
    });
  });
}
