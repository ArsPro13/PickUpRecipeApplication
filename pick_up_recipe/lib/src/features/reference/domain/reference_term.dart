// Строка справочника подсказок: страна, регион, способ обработки, сорт.
//
// Два имени, а не одно: на английском экране «Эфиопия» читается как ошибка
// ввода. Слаг нужен админке, человеку он не показывается никогда.

import 'dart:ui' show Locale;

class ReferenceTerm {
  const ReferenceTerm({
    required this.slug,
    required this.name,
    this.nameEn = '',
  });

  final String slug;
  final String name;
  final String nameEn;

  /// Имя на языке интерфейса. Пустой перевод — не ошибка: словарь наполняют
  /// руками, и английского может не быть; тогда показывается русское.
  String label(bool english) =>
      english && nameEn.isNotEmpty ? nameEn : name;

  factory ReferenceTerm.fromJson(Map<String, dynamic> json) => ReferenceTerm(
        slug: json['slug'] as String? ?? '',
        name: json['name'] as String? ?? '',
        nameEn: json['name_en'] as String? ?? '',
      );
}

/// Слова справочника на языке экрана — готовый список для поля с подсказками.
///
/// Язык берётся у экрана, а не у настройки: настройка бывает «как в системе»,
/// и тогда сама она языка не знает.
List<String> termLabels(List<ReferenceTerm> terms, Locale locale) {
  final english = locale.languageCode != 'ru';
  return [
    for (final term in terms)
      if (term.label(english).isNotEmpty) term.label(english),
  ];
}
