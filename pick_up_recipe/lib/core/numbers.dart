// Числа рецепта: как их пишут и как их читают.
//
// Лежали в конструкторе рецепта, рядом с экраном, который ими пользовался.
// Теперь ими же подписывает своё число счётчик со стрелками — общий виджет,
// и тянуть в него страницу ради двух функций нельзя. Ни на что, кроме
// разбора и записи числа, эти две не смотрят, поэтому им здесь и место.

/// Дробное число по-русски: запятая, и целое без хвоста. 16.0 → «16».
String formatDecimal(double value) {
  final rounded = (value * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return rounded.round().toString();
  return rounded.toStringAsFixed(1).replaceAll('.', ',');
}

/// Число из того, что напечатали. Запятая и точка равноправны: клавиатура
/// на разных прошивках даёт разный разделитель, и это не повод отказать.
double? parseNumber(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}
