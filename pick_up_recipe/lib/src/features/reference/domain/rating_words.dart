// Слова экрана оценки: что предлагается нажать, не открывая колесо целиком.
//
// Наборы заданы дизайном и потому живут здесь списком слагов, а не
// выбираются из справочника по признаку: «кислотность» спрашивают пятью
// словами про фрукт, а не всеми ста четырьмя словами словаря.
//
// Подпись и цвет берутся из справочника с сервера — там их и правят. Список
// ниже нужен на случай, когда справочник не приехал: оценку ставят сразу
// после чашки, часто без сети, и экран без слов в этот момент бесполезен.
// Поэтому у каждого слага есть встроенная подпись на обоих языках.

class RatingWord {
  const RatingWord(this.slug, this.ru, this.en, this.category);

  final String slug;
  final String ru;
  final String en;

  /// Категория из палитры: ею красится метка, пока словарь не приехал.
  final String category;

  String label(bool english) => english ? en : ru;
}

/// Слова вкуса на самом экране. Остальные — за кнопкой «всё колесо».
///
/// Двенадцать, а не двадцать: столько помещается в три ряда, и это разные
/// семьи колеса, а не двенадцать оттенков ягоды.
const List<RatingWord> kFlavourWords = [
  RatingWord('berry', 'ягода', 'Berry', 'berry'),
  RatingWord('strawberry', 'клубника', 'Strawberry', 'berry'),
  RatingWord('blackcurrant', 'чёрная смородина', 'Blackcurrant', 'berry'),
  RatingWord('lemon', 'лимон', 'Lemon', 'citrus'),
  RatingWord('orange', 'апельсин', 'Orange', 'citrus'),
  RatingWord('apple', 'яблоко', 'Apple', 'fruit'),
  RatingWord('floral', 'цветочное', 'Floral', 'floral'),
  RatingWord('jasmine', 'жасмин', 'Jasmine', 'floral'),
  RatingWord('honey', 'мёд', 'Honey', 'sugars'),
  RatingWord('caramel', 'карамель', 'Caramel', 'sugars'),
  RatingWord('chocolate', 'шоколад', 'Chocolate', 'nutty'),
  RatingWord('herbal', 'травяное', 'Herbal', 'green'),
];

/// Чем бывает кислотность. Слова по фрукту, а не «резкая / мягкая»:
/// резкость — это та же шкала, а вопрос стоит про то, какая она на вкус.
const List<RatingWord> kAcidityWords = [
  RatingWord('lemon', 'лимон', 'Lemon', 'citrus'),
  RatingWord('apple', 'яблоко', 'Apple', 'fruit'),
  RatingWord('grape', 'виноград', 'Grape', 'fruit'),
  RatingWord('berry', 'ягода', 'Berry', 'berry'),
  RatingWord('orange', 'апельсин', 'Orange', 'citrus'),
];

/// Чем бывает сладость.
const List<RatingWord> kSweetnessWords = [
  RatingWord('honey', 'мёд', 'Honey', 'sugars'),
  RatingWord('caramel', 'карамель', 'Caramel', 'sugars'),
  RatingWord('fruit', 'фрукт', 'Fruit', 'fruit'),
  RatingWord('chocolate', 'шоколад', 'Chocolate', 'nutty'),
];

/// Тело — семь слов. «Лёгкое» и «плотное» сюда не входят: это концы линии
/// над ними, и спрашивать их ещё и словом значит спрашивать дважды.
///
/// Порядок — от того, какая поверхность, к тому, что она делает во рту:
/// сперва гладкое-маслянистое-шершавое-меловое, потом сушит-вяжущее.
const List<RatingWord> kBodyWords = [
  RatingWord('smooth', 'гладкое', 'Smooth', 'mouthfeel'),
  RatingWord('oily', 'маслянистое', 'Oily', 'mouthfeel'),
  RatingWord('rough', 'шершавое', 'Rough', 'mouthfeel'),
  RatingWord('chalky', 'меловое', 'Chalky', 'mouthfeel'),
  RatingWord('drying', 'сушит', 'Drying', 'mouthfeel'),
  RatingWord('astringent', 'вяжущее', 'Astringent', 'mouthfeel'),
  RatingWord('metallic', 'металлическое', 'Metallic', 'mouthfeel'),
];
