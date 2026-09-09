// Поиск по справочнику кофемолок.
//
// Справочник маленький — полсотни моделей, — но пишут их по-разному:
// «Comandante» ищут и как «команданте», и как «COMANDANTE», и как
// «commondante». Поиск точным вхождением подстроки на всё это отвечал
// «такой кофемолки нет», и выхода из пустого экрана не было.
//
// Имена в справочнике трогать нельзя: по ним внешний сервис
// grinder_translator сходится строгим равенством имени, а в самих именах
// есть двойные пробелы («Eureka Mignon  жернова 50mm Filtro Pro»). Поэтому
// приведение к общему виду живёт здесь, в поиске, а не в данных.
//
// Файл без импортов Flutter намеренно: это единственная нетривиальная логика
// экрана выбора, и она обязана проверяться обычным тестом — тем же приёмом,
// что и группировка списка рецептов.

import 'models/grinder_model.dart';

/// Техническая запись справочника: заглушка с нулевым идентификатором.
///
/// В базе она нужна — на неё ссылаются рецепты, у которых своей кофемолки
/// нет, — но человеку предлагать «Base Grinder» наравне с настоящими
/// моделями незачем.
const int baseGrinderId = 0;

/// Справочник без технической записи.
List<Grinder> selectableGrinders(List<Grinder> catalog) {
  return catalog.where((grinder) => grinder.id != baseGrinderId).toList();
}

/// Насколько запрос попал в имя. Порядок значений — порядок выдачи.
enum GrinderMatchRank {
  /// Имя или одно из его слов начинается с запроса.
  start,

  /// Запрос встречается внутри имени.
  inside,

  /// Совпало с точностью до опечаток.
  typo,
}

/// Найденная кофемолка вместе с местом совпадения.
class GrinderHit {
  const GrinderHit({
    required this.grinder,
    required this.rank,
    this.start = 0,
    this.end = 0,
  });

  final Grinder grinder;
  final GrinderMatchRank rank;

  /// Границы совпавшего куска в ИСХОДНОМ имени: `name.substring(start, end)`.
  /// Считаются по исходной строке, а не по нормализованной, чтобы подсветка
  /// легла на то написание, которое человек видит.
  final int start;
  final int end;

  bool get hasHighlight => end > start;
}

/// Общее написание строки: регистр, `ё`, кириллица против латиницы, знаки
/// препинания и лишние пробелы.
///
/// Латиница и кириллица сводятся к одному алфавиту без `c`: `c` и `к` — один
/// звук, и «Comandante» с «команданте» обязаны стать одной строкой. По той же
/// причине `ч` даёт `kh`, а не `ch`: иначе «Chestnut» и «Честнат» разошлись бы
/// на ровном месте.
String normalizeGrinderText(String raw) => _fold(raw).text;

/// Сколько опечаток прощается запросу такой длины.
///
/// Короткому запросу нельзя прощать ничего: на трёх буквах одна поправка
/// притягивает половину справочника, и подсказка перестаёт быть подсказкой.
/// Две поправки открываются только с восьмой буквы — там ошибиться дважды
/// («commondante») уже нормально.
int grinderTypoBudget(int length) => (length ~/ 4).clamp(0, 2);

/// Расстояние Дамерау — Левенштейна: вставка, удаление, замена и перестановка
/// соседних букв стоят по единице.
int grinderEditDistance(String a, String b) => _distance(a, b).full;

/// Поиск по справочнику.
///
/// Пустой запрос отдаёт справочник целиком в исходном порядке: экран в этом
/// случае показывает прежний вид со всеми моделями.
List<GrinderHit> searchGrinders(List<Grinder> catalog, String query) {
  return _search(catalog, query, 0);
}

/// Ближайшие по написанию — для строки «Вы имели в виду …».
///
/// Порог здесь на одну поправку шире, чем у поиска: строку показывают только
/// когда поиск не нашёл ничего, и лучше предложить неточный вариант, чем
/// оставить человека в пустом экране.
List<Grinder> grinderDidYouMean(List<Grinder> catalog, String query, {int limit = 3}) {
  if (normalizeGrinderText(query).isEmpty) return const [];
  return _search(catalog, query, 1).take(limit).map((hit) => hit.grinder).toList();
}

// ── Внутреннее ──────────────────────────────────────────────────────────────

List<GrinderHit> _search(List<Grinder> catalog, String query, int bonus) {
  final needle = normalizeGrinderText(query);
  if (needle.isEmpty) {
    return [
      for (final grinder in catalog)
        GrinderHit(grinder: grinder, rank: GrinderMatchRank.start),
    ];
  }

  final budget = grinderTypoBudget(needle.length) + bonus;
  final found = <_Scored>[];

  for (var order = 0; order < catalog.length; order++) {
    final grinder = catalog[order];
    final folded = _fold(grinder.name);
    final name = folded.text;
    if (name.isEmpty) continue;

    final starts = _wordStarts(name);

    // Начало слова — самое сильное совпадение: так ищут по названию модели.
    var matched = false;
    for (var i = 0; i < starts.length; i++) {
      if (!name.startsWith(needle, starts[i])) continue;
      found.add(_Scored(
        _hit(grinder, GrinderMatchRank.start, folded, starts[i], starts[i] + needle.length),
        i,
        order,
      ));
      matched = true;
      break;
    }
    if (matched) continue;

    final inside = name.indexOf(needle);
    if (inside >= 0) {
      found.add(_Scored(
        _hit(grinder, GrinderMatchRank.inside, folded, inside, inside + needle.length),
        inside,
        order,
      ));
      continue;
    }

    if (budget <= 0) continue;

    // Опечатки меряются от начала каждого слова и до любого его продолжения:
    // «commondante» обязано найти «Comandante C40», не споткнувшись о хвост
    // имени, которого в запросе не было.
    var best = budget + 1;
    var bestAt = 0;
    var bestLength = 0;
    for (final at in starts) {
      final until = at + needle.length + budget;
      final candidate = name.substring(at, until < name.length ? until : name.length);
      final measured = _distance(needle, candidate);
      if (measured.prefix < best) {
        best = measured.prefix;
        bestAt = at;
        bestLength = measured.prefixLength;
      }
    }
    if (best <= budget) {
      found.add(_Scored(
        _hit(grinder, GrinderMatchRank.typo, folded, bestAt, bestAt + bestLength),
        best,
        order,
      ));
    }
  }

  found.sort((a, b) {
    final byRank = a.hit.rank.index.compareTo(b.hit.rank.index);
    if (byRank != 0) return byRank;
    final byScore = a.score.compareTo(b.score);
    if (byScore != 0) return byScore;
    return a.order.compareTo(b.order);
  });

  return found.map((scored) => scored.hit).toList();
}

class _Scored {
  const _Scored(this.hit, this.score, this.order);

  final GrinderHit hit;

  /// Чем меньше, тем выше внутри своей ступени: номер слова для начала,
  /// место вхождения для середины, число опечаток для исправленных.
  final int score;

  /// Место в справочнике — последний разделитель, чтобы выдача не прыгала.
  final int order;
}

/// Переносит границы совпадения из нормализованной строки в исходную.
GrinderHit _hit(Grinder grinder, GrinderMatchRank rank, _Folded folded, int from, int to) {
  final limit = folded.source.length;
  if (to <= from || from >= limit) {
    return GrinderHit(grinder: grinder, rank: rank);
  }
  final last = (to > limit ? limit : to) - 1;
  return GrinderHit(
    grinder: grinder,
    rank: rank,
    start: folded.source[from],
    end: folded.source[last] + 1,
  );
}

List<int> _wordStarts(String text) {
  final starts = <int>[0];
  for (var i = 1; i < text.length; i++) {
    if (text[i - 1] == ' ' && text[i] != ' ') starts.add(i);
  }
  return starts;
}

/// Нормализованная строка вместе с картой «символ → место в исходной».
class _Folded {
  const _Folded(this.text, this.source);

  final String text;

  /// Для каждого символа [text] — индекс символа исходной строки, из которого
  /// он получился. Одна буква может дать две (`ж` → `zh`), поэтому длины
  /// строк не совпадают и без карты подсветку не поставить.
  final List<int> source;
}

_Folded _fold(String raw) {
  final buffer = StringBuffer();
  final source = <int>[];
  var pendingSpace = false;

  for (var i = 0; i < raw.length; i++) {
    final symbol = raw[i].toLowerCase();
    final mapped = _alphabet[symbol] ?? (_isKept(symbol) ? symbol : ' ');

    // Мягкий и твёрдый знаки выпадают вовсе: «Вильфа» и «Wilfa» — одно слово.
    if (mapped.isEmpty) continue;

    if (mapped == ' ') {
      // Пробел ставится только перед следующей буквой: так двойные пробелы
      // имён справочника и концевые знаки исчезают сами.
      pendingSpace = buffer.isNotEmpty;
      continue;
    }

    if (pendingSpace) {
      buffer.write(' ');
      source.add(i);
      pendingSpace = false;
    }
    for (var k = 0; k < mapped.length; k++) {
      buffer.write(mapped[k]);
      source.add(i);
    }
  }

  return _Folded(buffer.toString(), source);
}

bool _isKept(String symbol) {
  final code = symbol.codeUnitAt(0);
  const zero = 0x30;
  const nine = 0x39;
  const a = 0x61;
  const z = 0x7A;
  return (code >= zero && code <= nine) || (code >= a && code <= z);
}

/// Один алфавит для обеих раскладок.
///
/// Латинские `c`, `q`, `w`, `x` сводятся к тому, во что превращается
/// кириллица, — иначе «Comandante» и «команданте» остались бы разными
/// строками. Умляуты сняты: Mahlkönig набирают без точек.
///
/// Кириллица здесь — не текст интерфейса, а буквы раскладки: таблица нужна,
/// чтобы поиск прощал набор латиницей вместо кириллицы и наоборот. В словарь
/// она не выносится ни на каком языке — от перевода поиск сломается.
const Map<String, String> _alphabet = {
  'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'e',
  'ж': 'zh', 'з': 'z', 'и': 'i', 'й': 'i', 'к': 'k', 'л': 'l', 'м': 'm',
  'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
  'ф': 'f', 'х': 'h', 'ц': 'ts', 'ч': 'kh', 'ш': 'sh', 'щ': 'skh',
  'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya',
  'c': 'k', 'q': 'k', 'w': 'v', 'x': 'ks',
  'ä': 'a', 'ö': 'o', 'ü': 'u', 'ß': 'ss',
  'á': 'a', 'é': 'e', 'è': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ñ': 'n',
};

class _Measured {
  const _Measured(this.full, this.prefix, this.prefixLength);

  /// Расстояние до строки целиком.
  final int full;

  /// Наименьшее расстояние до какого-нибудь её начала.
  final int prefix;

  /// Длина того начала, на котором минимум достигнут.
  final int prefixLength;
}

_Measured _distance(String a, String b) {
  final m = a.length;
  final n = b.length;
  if (m == 0) return _Measured(n, 0, 0);
  if (n == 0) return _Measured(m, m, 0);

  var beforePrevious = List<int>.filled(n + 1, 0);
  var previous = List<int>.generate(n + 1, (j) => j);
  var current = List<int>.filled(n + 1, 0);

  for (var i = 1; i <= m; i++) {
    current[0] = i;
    for (var j = 1; j <= n; j++) {
      final same = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1);
      var value = previous[j] + 1;
      final insert = current[j - 1] + 1;
      if (insert < value) value = insert;
      final replace = previous[j - 1] + (same ? 0 : 1);
      if (replace < value) value = replace;
      if (i > 1 &&
          j > 1 &&
          a.codeUnitAt(i - 1) == b.codeUnitAt(j - 2) &&
          a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1)) {
        final swap = beforePrevious[j - 2] + 1;
        if (swap < value) value = swap;
      }
      current[j] = value;
    }
    final scratch = beforePrevious;
    beforePrevious = previous;
    previous = current;
    current = scratch;
  }

  var prefix = previous[0];
  var prefixLength = 0;
  for (var j = 1; j <= n; j++) {
    if (previous[j] < prefix) {
      prefix = previous[j];
      prefixLength = j;
    }
  }

  return _Measured(previous[n], prefix, prefixLength);
}
