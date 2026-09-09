// Код с упаковки разбирается одинаково на клиенте и на бэкенде.
//
// Правила дублированы в pkg/shortcode (Go) и в PackCode (Dart) намеренно:
// опечатка ручного ввода должна ловиться до похода в сеть. Расхождение между
// двумя реализациями ломает ручной ввод молча, поэтому здесь проверяются те же
// инварианты, что и в Go-тестах.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/features/codes/domain/pack_code.dart';
import 'package:pick_up_recipe/src/pages/pack_code_texts.dart';

void main() {
  late AppLocalizations ru;
  late AppLocalizations en;

  setUpAll(() async {
    ru = await AppLocalizations.delegate.load(const Locale('ru'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('алфавит', () {
    test('29 символов, длина простая', () {
      expect(PackCode.alphabet.length, 29);
      for (var divisor = 2; divisor < PackCode.alphabet.length; divisor++) {
        expect(
          PackCode.alphabet.length % divisor,
          isNot(0),
          reason: 'при составной длине контрольная сумма пропускает часть опечаток',
        );
      }
    });

    test('нет символов, которые путаются при чтении', () {
      for (final symbol in ['0', 'O', '1', 'I', 'L', 'U', 'S']) {
        expect(PackCode.alphabet.contains(symbol), isFalse, reason: symbol);
      }
    });
  });

  group('normalize', () {
    test('снимает дефисы, пробелы и регистр', () {
      expect(PackCode.normalize('abcd-2345 68'), 'ABCD234568');
      expect(PackCode.normalize('ABCD_2345_68'), 'ABCD234568');
    });

    test('похожие символы не подменяются', () {
      // Угадывать за человека, что он имел в виду под «O» — ноль или букву,
      // значит иногда молча открывать чужой код.
      expect(PackCode.normalize('O0'), 'O0');
    });
  });

  group('format', () {
    test('группы по четыре', () {
      expect(PackCode.format('ABCD234568'), 'ABCD-2345-68');
    });

    test('незаконченный ввод не ломается', () {
      expect(PackCode.format('AB'), 'AB');
      expect(PackCode.format('ABCD2'), 'ABCD-2');
      expect(PackCode.format('ABCD2345'), 'ABCD-2345');
    });
  });

  group('проверка', () {
    // Демо-код из ADR 0004. Контрольный символ у него -68, а не -67:
    // это та самая опечатка, которую поймала проверка при написании ADR.
    const demo = 'ABCD234568';

    test('демо-код из ADR проходит', () {
      expect(PackCode.problem(demo), isNull);
      expect(PackCode.isValid('abcd-2345-68'), isTrue);
    });

    test('код с опечаткой в контрольном символе отвергается', () {
      expect(PackCode.isValid('ABCD234567'), isFalse);
    });

    test('замена одного символа ловится', () {
      for (var position = 0; position < demo.length - 1; position++) {
        for (final replacement in PackCode.alphabet.split('')) {
          if (replacement == demo[position]) continue;

          final broken = demo.replaceRange(position, position + 1, replacement);
          expect(
            PackCode.isValid(broken),
            isFalse,
            reason: 'позиция $position, символ $replacement',
          );
        }
      }
    });

    test('перестановка соседних символов ловится', () {
      for (var position = 0; position < demo.length - 2; position++) {
        if (demo[position] == demo[position + 1]) continue;

        final swapped = demo.replaceRange(
          position,
          position + 2,
          demo[position + 1] + demo[position],
        );
        expect(PackCode.isValid(swapped), isFalse, reason: 'позиция $position');
      }
    });

    // Разбор причины — часть поведения, а не украшение: человеку важно знать,
    // дописывать ли символы, искать ли опечатку или он спутал ноль с буквой.
    test('причина разбирается, а не сводится к «код неверный»', () {
      expect(PackCode.problem('')?.kind, PackCodeProblemKind.empty);
      expect(PackCode.problem('ABCD')?.kind, PackCodeProblemKind.length);
      expect(PackCode.problem('ABCD')?.entered, 4);
      expect(PackCode.problem('ABCD23456O')?.kind, PackCodeProblemKind.unknownSymbol);
      expect(PackCode.problem('ABCD23456O')?.symbol, 'O');
      expect(PackCode.problem('ABCD234567')?.kind, PackCodeProblemKind.checksum);
    });
  });

  // Вынос строк в словарь не должен переписать объяснения: по-русски человек
  // обязан прочитать ровно то же, что читал до правки.
  group('объяснения для человека', () {
    test('по-русски слово в слово как было', () {
      expect(PackCode.problem('')?.text(ru), 'Введите код с упаковки');
      expect(PackCode.problem('ABCD')?.text(ru), 'В коде 10 символов, а введено 4');
      expect(
        PackCode.problem('ABCD23456O')?.text(ru),
        'Символа «O» в кодах не бывает — проверьте, не 0 ли это вместо O',
      );
      expect(
        PackCode.problem('ABCD234567')?.text(ru),
        'Код набран с ошибкой — проверьте символы',
      );
    });

    test('на английском телефоне кириллицы нет', () {
      final cyrillic = RegExp('[а-яёА-ЯЁ]');

      for (final code in ['', 'ABCD', 'ABCD23456O', 'ABCD234567']) {
        final line = PackCode.problem(code)!.text(en);
        expect(cyrillic.hasMatch(line), isFalse, reason: '«$code» → $line');
      }
    });
  });
}
