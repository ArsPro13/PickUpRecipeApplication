// Название прибора на языке экрана.
//
// Справочник отдаёт три названия: name — русское (если прибор знают по
// английскому имени, оно в скобках: «Кемекс (Chemex)»), name_en и name_it.
// Пустой перевод — следующий по цепочке: итальянское → английское →
// русское. Новый прибор, которому ещё не дописали перевод, лучше показать
// по-русски, чем пустым местом.
//
// Язык передаёт экран (`Localizations.localeOf(context).languageCode`), а не
// состояние: справочник грузится один раз, а язык меняют в профиле на ходу,
// и названия обязаны смениться вместе с ним, без перезагрузки списков.

/// Название из трёх вариантов справочника.
String localizedMethodName(
  String language, {
  required String name,
  String en = '',
  String it = '',
}) {
  return switch (language) {
    'ru' => name,
    'it' => it.isNotEmpty ? it : (en.isNotEmpty ? en : name),
    _ => en.isNotEmpty ? en : name,
  };
}

/// Порядок названий в списке: регистр не важен, «ё» стоит вместе с «е».
///
/// Простое сравнение строк ставит «ё» после «я» и заглавные перед строчными
/// — «Ёмкость» оказалась бы в самом конце, а «aeropress» после «Toddy».
int compareMethodNames(String a, String b) {
  final byKey = _sortKey(a).compareTo(_sortKey(b));
  return byKey != 0 ? byKey : a.compareTo(b);
}

String _sortKey(String name) =>
    name.toLowerCase().replaceAll('ё', 'е').trimLeft();
