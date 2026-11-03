// Разбор правовых документов для листа в приложении.
//
// Образец — кусок настоящей политики: шапка с переносом двумя пробелами
// (они записаны через \u0020: редакторы срезают пробелы в конце строк),
// пункты с номерами вида «1.1.», таблица без шапки (реквизиты), таблица с
// шапкой, список с продолжением строки и черта.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/legal/domain/legal_markdown.dart';

const _sample = '''# Политика в отношении обработки персональных данных

**Версия: 2026-11-03**\u0020\u0020
Сервис: «Recipe to Cup» (recipetocup.ru)

---

## 1. Общие положения

1.1. Настоящая Политика определяет порядок обработки и защиты
персональных данных.

| | |
|---|---|
| ИНН | 710522424871 |
| Электронная почта | coffee@recipetocup.ru |

| Данные | Когда собираются | Зачем |
|---|---|---|
| Пароль | при регистрации | хранится **только в виде хеша** |

1. Регистрация и аутентификация пользователя.
2. Предоставление функциональности Сервиса: подбор, хранение и корректировка
   рецептов заваривания.

См. [Политику]({{site}}/legal/privacy).
''';

void main() {
  final blocks = parseLegalMarkdown(_sample);

  test('заголовки разных уровней', () {
    final headings = blocks.whereType<LegalHeading>().toList();
    expect(headings.map((h) => h.level), [1, 2]);
    expect(headings.first.text, 'Политика в отношении обработки персональных данных');
  });

  test('два пробела в конце строки — перенос, обычный перенос — пробел', () {
    final paragraphs = blocks.whereType<LegalParagraph>().toList();
    expect(paragraphs.first.text,
        '**Версия: 2026-11-03**\nСервис: «Recipe to Cup» (recipetocup.ru)');
    expect(paragraphs[1].text,
        '1.1. Настоящая Политика определяет порядок обработки и защиты персональных данных.');
  });

  test('«1.1. Текст» — абзац, а не список', () {
    expect(blocks.whereType<LegalParagraph>().any((p) => p.text.startsWith('1.1.')), isTrue);
  });

  test('черта', () {
    expect(blocks.whereType<LegalRule>(), hasLength(1));
  });

  test('таблица без шапки — «ключ — значение»', () {
    final table = blocks.whereType<LegalTable>().first;
    expect(table.keyValue, isTrue);
    expect(table.rows, [
      ['ИНН', '710522424871'],
      ['Электронная почта', 'coffee@recipetocup.ru'],
    ]);
  });

  test('таблица с шапкой', () {
    final table = blocks.whereType<LegalTable>().last;
    expect(table.keyValue, isFalse);
    expect(table.header, ['Данные', 'Когда собираются', 'Зачем']);
    expect(table.rows.single.first, 'Пароль');
  });

  test('пункт списка склеивается со строкой продолжения', () {
    final list = blocks.whereType<LegalList>().single;
    expect(list.ordered, isTrue);
    expect(list.items, [
      'Регистрация и аутентификация пользователя.',
      'Предоставление функциональности Сервиса: подбор, хранение и корректировка рецептов заваривания.',
    ]);
  });

  test('строчная разметка: жирный и ссылка — без звёздочек и скобок', () {
    final spans = parseLegalInline('хранится **только в виде хеша**, см. [Политику](https://x/legal/privacy).');
    expect(spans.map((s) => s.text).join(), 'хранится только в виде хеша, см. Политику.');
    expect(spans.where((s) => s.bold).single.text, 'только в виде хеша');
    expect(spans.where((s) => s.link).single.text, 'Политику');
  });
}
