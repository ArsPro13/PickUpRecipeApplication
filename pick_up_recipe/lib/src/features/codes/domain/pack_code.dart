// Код с упаковки: разбор, проверка и печатный вид.
//
// Ровно те же правила, что в pkg/shortcode на бэкенде (ADR 0004). Дублируются
// намеренно: опечатка при ручном вводе должна ловиться до похода на сервер,
// иначе человек ждёт ответ сети, чтобы узнать, что промахнулся клавишей.
//
// Расхождение с бэкендом ломает ручной ввод, поэтому алфавит и контрольная
// сумма проверяются тестом на тех же значениях, что и в Go.

abstract final class PackCode {
  /// Символы, из которых состоит код.
  ///
  /// Исключены 0 и O, 1 и I и L, U (путается с V), S (путается с 5).
  /// Осталось ровно 29 — и это не совпадение: длина алфавита должна быть
  /// простым числом, иначе контрольная сумма пропускает часть опечаток.
  static const String alphabet = '23456789ABCDEFGHJKMNPQRTVWXYZ';

  /// Длина кода вместе с контрольным символом.
  static const int length = 10;

  /// Снимает дефисы, пробелы и регистр.
  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final rune in input.toUpperCase().runes) {
      final symbol = String.fromCharCode(rune);
      if (symbol == '-' || symbol == ' ' || symbol == '_') continue;
      buffer.write(symbol);
    }
    return buffer.toString();
  }

  /// Печатный вид: `ABCD-2345-68`. Группами по четыре читается легче.
  static String format(String code) {
    final normalized = normalize(code);
    if (normalized.length <= 4) return normalized;
    if (normalized.length <= 8) {
      return '${normalized.substring(0, 4)}-${normalized.substring(4)}';
    }
    return '${normalized.substring(0, 4)}-${normalized.substring(4, 8)}'
        '-${normalized.substring(8, normalized.length.clamp(8, length))}';
  }

  /// Сходится ли контрольный символ.
  static bool isValid(String code) => validationError(normalize(code)) == null;

  /// Что именно не так с кодом. null — код в порядке.
  ///
  /// Текст для человека, а не код ошибки: он показывается прямо под полем.
  static String? validationError(String code) {
    if (code.isEmpty) return 'Введите код с упаковки';
    if (code.length != length) return 'В коде $length символов, а введено ${code.length}';

    for (final rune in code.runes) {
      final symbol = String.fromCharCode(rune);
      if (!alphabet.contains(symbol)) {
        return 'Символа «$symbol» в кодах не бывает — проверьте, не 0 ли это вместо O';
      }
    }

    if (code[code.length - 1] != _checksum(code.substring(0, code.length - 1))) {
      return 'Код набран с ошибкой — проверьте символы';
    }

    return null;
  }

  /// Контрольный символ: взвешенная сумма по модулю длины алфавита.
  static String _checksum(String base) {
    var sum = 0;
    for (var i = 0; i < base.length; i++) {
      final index = alphabet.indexOf(base[i]);
      if (index < 0) return '';
      sum += index * (i + 1);
    }
    return alphabet[sum % alphabet.length];
  }
}
