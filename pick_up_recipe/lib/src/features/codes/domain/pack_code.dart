// Код с упаковки: разбор, проверка и печатный вид.
//
// Ровно те же правила, что в pkg/shortcode на бэкенде (ADR 0004). Дублируются
// намеренно: опечатка при ручном вводе должна ловиться до похода на сервер,
// иначе человек ждёт ответ сети, чтобы узнать, что промахнулся клавишей.
//
// Расхождение с бэкендом ломает ручной ввод, поэтому алфавит и контрольная
// сумма проверяются тестом на тех же значениях, что и в Go.

/// Что именно не так с набранным кодом.
enum PackCodeProblemKind {
  /// Поле пустое.
  empty,

  /// Символов не столько, сколько в коде.
  length,

  /// Есть символ, которого в алфавите кодов нет.
  unknownSymbol,

  /// Контрольный символ не сошёлся — где-то опечатка.
  checksum,
}

/// Разбор ошибки ввода: код причины и то, без чего её не объяснить.
///
/// Код, а не фраза: язык экрана домену неизвестен, а объяснение у каждого
/// языка своё. Перевод кода в текст живёт рядом с экраном —
/// lib/src/pages/pack_code_texts.dart.
class PackCodeProblem {
  const PackCodeProblem(this.kind, {this.entered = 0, this.symbol = ''});

  final PackCodeProblemKind kind;

  /// Сколько символов набрано. Только для [PackCodeProblemKind.length].
  final int entered;

  /// Символ, которого нет в алфавите. Только для
  /// [PackCodeProblemKind.unknownSymbol].
  final String symbol;
}

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
  static bool isValid(String code) => problem(normalize(code)) == null;

  /// Что именно не так с кодом. null — код в порядке.
  ///
  /// Причина разбирается до знака, а не сводится к «код неверный»: человеку
  /// важно знать, дописывать ли символы, искать ли опечатку или он спутал
  /// ноль с буквой.
  static PackCodeProblem? problem(String code) {
    if (code.isEmpty) return const PackCodeProblem(PackCodeProblemKind.empty);
    if (code.length != length) {
      return PackCodeProblem(PackCodeProblemKind.length, entered: code.length);
    }

    for (final rune in code.runes) {
      final symbol = String.fromCharCode(rune);
      if (!alphabet.contains(symbol)) {
        return PackCodeProblem(PackCodeProblemKind.unknownSymbol, symbol: symbol);
      }
    }

    if (code[code.length - 1] != _checksum(code.substring(0, code.length - 1))) {
      return const PackCodeProblem(PackCodeProblemKind.checksum);
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
