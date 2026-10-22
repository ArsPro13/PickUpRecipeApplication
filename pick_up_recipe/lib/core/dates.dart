// Дата человеческим языком — одна на всё приложение.
//
// Таблица месяцев лежала тремя копиями: в списке рецептов, на экране кофе и
// в выборе рецепта. Копии одинаковые, но русские, и на английском экране
// «9 сентября» стояло среди английских подписей. Порядок слов у языков тоже
// разный («9 сентября» против «September 9»), поэтому он живёт в переводе,
// а не в склейке строк здесь.

import '../l10n/app_localizations.dart';

/// Названия месяцев текущего языка по порядку, с января — в той форме, в
/// какой они стоят после числа: «22 октября». Ими же подписан барабан даты.
List<String> monthNames(AppLocalizations texts) => [
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
    monthNames(texts)[date.month - 1],
  );
}

/// День, месяц и год: «9 сентября 2025», «September 9, 2025».
String formatDayMonthYear(AppLocalizations texts, DateTime date) {
  return texts.dateDayMonthYear(
    date.day.toString(),
    monthNames(texts)[date.month - 1],
    date.year.toString(),
  );
}

/// Короткие названия месяцев: «окт», «Oct». Для подписей, где рядом с датой
/// стоит ещё и время и места на полное название нет.
List<String> shortMonthNames(AppLocalizations texts) => [
      texts.dateMonthShort1,
      texts.dateMonthShort2,
      texts.dateMonthShort3,
      texts.dateMonthShort4,
      texts.dateMonthShort5,
      texts.dateMonthShort6,
      texts.dateMonthShort7,
      texts.dateMonthShort8,
      texts.dateMonthShort9,
      texts.dateMonthShort10,
      texts.dateMonthShort11,
      texts.dateMonthShort12,
    ];

/// Дата со временем коротко: «22 окт, 16:55», «Oct 22, 16:55».
///
/// Год — только не нынешний, как и у полной даты: «22 окт 2025, 16:55».
/// Время всегда двадцатичетырёхчасовое: у подписи на снимке нет места под
/// «PM», а сутки по часам читаются одинаково на любом языке.
String formatDayMonthTime(AppLocalizations texts, DateTime date,
    {DateTime? now}) {
  final month = shortMonthNames(texts)[date.month - 1];
  final time = '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  return date.year == (now ?? DateTime.now()).year
      ? texts.dateStamp(date.day.toString(), month, time)
      : texts.dateStampYear(
          date.day.toString(), month, date.year.toString(), time);
}
