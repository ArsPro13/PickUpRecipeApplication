// Дата человеческим языком — одна на всё приложение.
//
// Таблица месяцев лежала тремя копиями: в списке рецептов, на экране кофе и
// в выборе рецепта. Копии одинаковые, но русские, и на английском экране
// «9 сентября» стояло среди английских подписей. Порядок слов у языков тоже
// разный («9 сентября» против «September 9»), поэтому он живёт в переводе,
// а не в склейке строк здесь.

import '../l10n/app_localizations.dart';

/// Названия месяцев текущего языка по порядку, с января.
List<String> _months(AppLocalizations texts) => [
      texts.dateMonth1,
      texts.dateMonth2,
      texts.dateMonth3,
      texts.dateMonth4,
      texts.dateMonth5,
      texts.dateMonth6,
      texts.dateMonth7,
      texts.dateMonth8,
      texts.dateMonth9,
      texts.dateMonth10,
      texts.dateMonth11,
      texts.dateMonth12,
    ];

/// День и месяц: «9 сентября», «September 9».
String formatDayMonth(AppLocalizations texts, DateTime date) {
  return texts.dateDayMonth(
    date.day.toString(),
    _months(texts)[date.month - 1],
  );
}

/// День, месяц и год: «9 сентября 2025», «September 9, 2025».
String formatDayMonthYear(AppLocalizations texts, DateTime date) {
  return texts.dateDayMonthYear(
    date.day.toString(),
    _months(texts)[date.month - 1],
    date.year.toString(),
  );
}
