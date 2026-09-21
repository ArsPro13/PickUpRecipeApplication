// Цвет дескриптора вкуса — один на всё приложение.
//
// Решение и его обоснование — в ADR 0007: цвет задаётся КАТЕГОРИЕЙ, а не
// словом. «Ежевика» и «черника» — один тон, «ягода» и «цитрус» — разные, и
// новое слово внутри известной категории получает цвет само. Хэш от слова
// запрещён: он утверждал бы, что близкие вкусы далеки.
//
// ЧТО ИЗМЕНИЛОСЬ ПРОТИВ ADR. Палитра там принадлежала приложению — «цвет
// зависит от темы клиента, отдавать hex с сервера значит зафиксировать
// светлую тему для всех». Половина довода осталась: у категории ЧЕТЫРЕ цвета,
// по паре на тему. Вторая отменена владельцем — цвета настраиваются в
// кабинете, и ждать релиза приложения ради оттенка никто не будет.
//
// Поэтому здесь ДВЕ палитры: встроенная (ровно значения ADR) и приехавшая с
// сервера. Рисуем серверной, если она есть, и встроенной, пока её нет. Это не
// перестраховка: справочник читается по сети, а оценку ставят в лесу.

import 'package:flutter/material.dart';

/// Категория флейвор-вила и её цвета.
///
/// Пара «чернила и заливка» на каждую тему: заливка бледная и несёт семью
/// вкуса, чернила плотные и несут категорию. Тег читается дважды — издалека
/// по пятну, вблизи по тексту и обводке.
class FlavorCategory {
  const FlavorCategory({
    required this.slug,
    required this.name,
    this.nameEn = '',
    required this.inkLight,
    required this.fillLight,
    required this.inkDark,
    required this.fillDark,
    this.sortOrder = 0,
  });

  final String slug;
  final String name;

  /// Имя категории по-английски: заголовок в колесе на английском телефоне.
  final String nameEn;

  final Color inkLight;
  final Color fillLight;
  final Color inkDark;
  final Color fillDark;
  final int sortOrder;

  Color ink(Brightness brightness) =>
      brightness == Brightness.dark ? inkDark : inkLight;

  Color fill(Brightness brightness) =>
      brightness == Brightness.dark ? fillDark : fillLight;

  String label(bool english) => english && nameEn.isNotEmpty ? nameEn : name;

  factory FlavorCategory.fromJson(Map<String, dynamic> json) {
    return FlavorCategory(
      slug: json['slug'] as String? ?? 'other',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      inkLight: _hex(json['ink_light'], _builtIn['other']!.inkLight),
      fillLight: _hex(json['fill_light'], _builtIn['other']!.fillLight),
      inkDark: _hex(json['ink_dark'], _builtIn['other']!.inkDark),
      fillDark: _hex(json['fill_dark'], _builtIn['other']!.fillDark),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  /// Разбор `#RRGGBB`. Кривое значение не роняет экран: цвет — оформление,
  /// и лучше показать нейтральный тег, чем белый экран с исключением.
  static Color _hex(Object? value, Color fallback) {
    if (value is! String) return fallback;
    final cleaned = value.replaceAll('#', '').trim();
    if (cleaned.length != 6) return fallback;
    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed == null) return fallback;
    return Color(0xFF000000 | parsed);
  }
}

/// Встроенная палитра — таблица ADR 0007 слово в слово.
///
/// Светлота у всех категорий одна: `L = 0.44` у чернил и `0.92` у заливки в
/// светлой теме, `0.84` и `0.27` в тёмной. Тег не может быть громче соседа
/// из-за тона — различие идёт по тону и цветности.
const Map<String, FlavorCategory> _builtIn = {
  'berry': FlavorCategory(slug: 'berry', name: 'Ягоды', nameEn: 'Berry',
      inkLight: Color(0xFF753F52), fillLight: Color(0xFFFBDBE4),
      inkDark: Color(0xFFF7B5CA), fillDark: Color(0xFF361E26), sortOrder: 1),
  'spice': FlavorCategory(slug: 'spice', name: 'Специи', nameEn: 'Spices',
      inkLight: Color(0xFF6E4644), fillLight: Color(0xFFF6DEDC),
      inkDark: Color(0xFFEDBDB9), fillDark: Color(0xFF322220), sortOrder: 2),
  'fruit': FlavorCategory(slug: 'fruit', name: 'Фрукты', nameEn: 'Fruit',
      inkLight: Color(0xFF77432B), fillLight: Color(0xFFFCDDD0),
      inkDark: Color(0xFFF8BBA0), fillDark: Color(0xFF362017), sortOrder: 3),
  'nutty': FlavorCategory(slug: 'nutty', name: 'Орехи и какао', nameEn: 'Nutty & cocoa',
      inkLight: Color(0xFF674C38), fillLight: Color(0xFFF0E1D7),
      inkDark: Color(0xFFE3C4AC), fillDark: Color(0xFF2F241C), sortOrder: 4),
  'sugars': FlavorCategory(slug: 'sugars', name: 'Сахара', nameEn: 'Sugars',
      inkLight: Color(0xFF6A4C25), fillLight: Color(0xFFF2E2CF),
      inkDark: Color(0xFFE7C49A), fillDark: Color(0xFF302416), sortOrder: 5),
  'roast': FlavorCategory(slug: 'roast', name: 'Обжарка', nameEn: 'Roast',
      inkLight: Color(0xFF575247), fillLight: Color(0xFFE7E4DF),
      inkDark: Color(0xFFCFCABE), fillDark: Color(0xFF282622), sortOrder: 6),
  'citrus': FlavorCategory(slug: 'citrus', name: 'Цитрус', nameEn: 'Citrus',
      inkLight: Color(0xFF54571C), fillLight: Color(0xFFE5E8CB),
      inkDark: Color(0xFFCBD094), fillDark: Color(0xFF272812), sortOrder: 7),
  'green': FlavorCategory(slug: 'green', name: 'Зелёное', nameEn: 'Green',
      inkLight: Color(0xFF2E5F3A), fillLight: Color(0xFFD4ECD8),
      inkDark: Color(0xFFA6DAAF), fillDark: Color(0xFF182C1C), sortOrder: 8),
  'fermented': FlavorCategory(slug: 'fermented', name: 'Ферментированное', nameEn: 'Fermented',
      inkLight: Color(0xFF514B7C), fillLight: Color(0xFFE3E1FD),
      inkDark: Color(0xFFC7C3FC), fillDark: Color(0xFF252338), sortOrder: 9),
  'floral': FlavorCategory(slug: 'floral', name: 'Цветочное', nameEn: 'Floral',
      inkLight: Color(0xFF67436D), fillLight: Color(0xFFF1DDF4),
      inkDark: Color(0xFFE4BAEA), fillDark: Color(0xFF2F2031), sortOrder: 10),
  // Тактильность на колесе не живёт: это не вкус, а ощущение. Свой серый
  // нужен, чтобы «вяжущее» не притворялось ягодой.
  'mouthfeel': FlavorCategory(slug: 'mouthfeel', name: 'Тактильность', nameEn: 'Mouthfeel',
      inkLight: Color(0xFF4C5560), fillLight: Color(0xFFE3E6EA),
      inkDark: Color(0xFFB8C0C8), fillDark: Color(0xFF242A30), sortOrder: 11),
  // Неизвестное слово — нейтральный тег. Случайный цвет запрещён: цвет здесь
  // утверждение о смысле, а для незнакомого слова такого утверждения нет.
  'other': FlavorCategory(slug: 'other', name: 'Прочее', nameEn: 'Other',
      inkLight: Color(0xFF525252), fillLight: Color(0xFFE4E4E4),
      inkDark: Color(0xFFCACACA), fillDark: Color(0xFF262626), sortOrder: 12),
};

/// Цвета одного тега: чем красить текст с обводкой и чем — подложку.
class DescriptorColors {
  const DescriptorColors({
    required this.category,
    required this.ink,
    required this.fill,
  });

  final FlavorCategory category;
  final Color ink;
  final Color fill;
}

/// Палитра целиком: категории и указатель «слово → категория и ступень».
class FlavorPalette {
  const FlavorPalette({
    required this.categories,
    required this.wordIndex,
  });

  /// Встроенная палитра без словаря: ею рисуют, пока справочник не приехал.
  factory FlavorPalette.builtIn() =>
      const FlavorPalette(categories: _builtIn, wordIndex: {});

  final Map<String, FlavorCategory> categories;

  /// Слово в нижнем регистре → категория и ступень. Строится из справочника
  /// дескрипторов: у пачки слова лежат свободным текстом, и связать их с
  /// категорией больше нечем.
  final Map<String, DescriptorTone> wordIndex;

  /// Категория слова. Неизвестное — «прочее», и это честный ответ.
  FlavorCategory categoryOf(String word) {
    final key = word.trim().toLowerCase();
    final slug = wordIndex[key]?.category ??
        (categories.containsKey(key) ? key : 'other');
    return categories[slug] ?? _builtIn['other']!;
  }

  FlavorCategory bySlug(String slug) =>
      categories[slug] ?? _builtIn[slug] ?? _builtIn['other']!;

  /// Цвета слова с учётом ступени.
  ///
  /// Тон и светлота берутся у категории и не трогаются: светлота держит
  /// контраст текста, тон держит смысл. Ступень меняет ТОЛЬКО цветность —
  /// «ягода» тише «ежевики», но рядом видно, что это одна семья.
  DescriptorColors colorsOf(String word, Brightness brightness) {
    final key = word.trim().toLowerCase();
    final tone = wordIndex[key];
    final category = categoryOf(word);
    final intensity = tone?.intensity ?? 2;
    return DescriptorColors(
      category: category,
      ink: _withChroma(category.ink(brightness), intensity),
      fill: _withChroma(category.fill(brightness), intensity),
    );
  }

  /// Палитра с сервера поверх встроенной.
  ///
  /// Именно поверх, а не вместо: сервер может не знать про категорию, которую
  /// приложение уже умеет рисовать, — и тогда её тег не должен посереть.
  FlavorPalette merge(
    List<FlavorCategory> fromServer,
    Map<String, DescriptorTone> index,
  ) {
    final merged = Map<String, FlavorCategory>.from(categories);
    for (final category in fromServer) {
      merged[category.slug] = category;
    }
    return FlavorPalette(
      categories: merged,
      wordIndex: index.isEmpty ? wordIndex : index,
    );
  }
}

/// Категория слова и его ступень внутри неё.
class DescriptorTone {
  const DescriptorTone(this.category, this.intensity);

  final String category;
  final int intensity;
}

/// Цветность по ступени: семья бледнее, редкое слово гуще.
///
/// Множители, а не готовые цвета: категорий двенадцать, ступеней три, и
/// тридцать шесть значений в настройке кабинета никто не сведёт друг с
/// другом. Серые категории множитель не замечают — у них цветности нет.
Color _withChroma(Color base, int intensity) {
  const factors = {1: 0.58, 2: 1.0, 3: 1.42};
  final factor = factors[intensity] ?? 1.0;
  if (factor == 1.0) return base;
  final hsl = HSLColor.fromColor(base);
  return hsl.withSaturation((hsl.saturation * factor).clamp(0.0, 1.0)).toColor();
}
