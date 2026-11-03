// Правовой документ: markdown в блоки для листа документа.
//
// Документы пишутся узким подмножеством разметки — заголовки, абзацы,
// списки, таблицы, жирный, ссылки, `код` и «---». Тот же разбор в
// legal/build.py собирает из них страницу для браузера. Голым текстом лист
// показывал исходник: решётки, звёздочки, таблицы из вертикальных черт.
// Пакет-рендерер ради трёх документов тянуть незачем.
//
// Чего здесь нет, того нет и в шаблонах legal/templates: новая конструкция
// в шаблоне — повод дописать её и сюда, и в build.py.

/// Блок документа.
sealed class LegalBlock {
  const LegalBlock();
}

/// Заголовок «#», «##» или «###».
class LegalHeading extends LegalBlock {
  const LegalHeading(this.level, this.text);

  final int level;
  final String text;
}

/// Абзац. Строки исходника склеены пробелом: шаблоны переносятся по ширине
/// редактора, а не по смыслу. Перенос, заданный двумя пробелами в конце
/// строки (шапка и реквизиты), остаётся переносом — '\n'.
class LegalParagraph extends LegalBlock {
  const LegalParagraph(this.text);

  final String text;
}

/// Нумерованный или маркированный список. Строки продолжения пункта — с
/// отступом — склеены с ним.
class LegalList extends LegalBlock {
  const LegalList({required this.ordered, required this.items});

  final bool ordered;
  final List<String> items;
}

/// Таблица. Шапка из пустых ячеек («| | |») — таблица «ключ — значение».
class LegalTable extends LegalBlock {
  const LegalTable({required this.header, required this.rows});

  final List<String> header;
  final List<List<String>> rows;

  bool get keyValue => header.every((cell) => cell.isEmpty);
}

/// Черта «---».
class LegalRule extends LegalBlock {
  const LegalRule();
}

final _heading = RegExp(r'^(#{1,3})\s+(.*)$');
// «1. пункт», но не «1.1. Текст» — номер пункта документа списком не считается.
final _ordered = RegExp(r'^\d+\.\s+');
final _bullet = RegExp(r'^-\s+');
final _tableRule = RegExp(r'^\|[\s:|-]+\|?$');

bool _startsBlock(String line) {
  final trimmed = line.trim();
  return trimmed.isEmpty ||
      trimmed == '---' ||
      _heading.hasMatch(line) ||
      trimmed.startsWith('|') ||
      _ordered.hasMatch(line) ||
      _bullet.hasMatch(line);
}

/// Разбирает документ на блоки.
List<LegalBlock> parseLegalMarkdown(String source) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final blocks = <LegalBlock>[];
  var index = 0;

  while (index < lines.length) {
    final line = lines[index];
    final trimmed = line.trim();

    if (trimmed.isEmpty) {
      index++;
      continue;
    }

    if (trimmed == '---') {
      blocks.add(const LegalRule());
      index++;
      continue;
    }

    final heading = _heading.firstMatch(line);
    if (heading != null) {
      blocks.add(LegalHeading(heading.group(1)!.length, heading.group(2)!.trim()));
      index++;
      continue;
    }

    if (trimmed.startsWith('|')) {
      final rows = <String>[];
      while (index < lines.length && lines[index].trim().startsWith('|')) {
        rows.add(lines[index].trim());
        index++;
      }
      blocks.add(_table(rows));
      continue;
    }

    final marker = _ordered.hasMatch(line)
        ? _ordered
        : _bullet.hasMatch(line)
            ? _bullet
            : null;
    if (marker != null) {
      final items = <String>[];
      while (index < lines.length) {
        final current = lines[index];
        if (marker.hasMatch(current)) {
          items.add(current.replaceFirst(marker, '').trim());
        } else if (current.startsWith(' ') &&
            current.trim().isNotEmpty &&
            items.isNotEmpty) {
          items[items.length - 1] = '${items.last} ${current.trim()}';
        } else {
          break;
        }
        index++;
      }
      blocks.add(LegalList(ordered: identical(marker, _ordered), items: items));
      continue;
    }

    final chunk = <String>[line];
    index++;
    while (index < lines.length && !_startsBlock(lines[index])) {
      chunk.add(lines[index]);
      index++;
    }
    blocks.add(LegalParagraph(_joinParagraph(chunk)));
  }

  return blocks;
}

String _joinParagraph(List<String> lines) {
  final buffer = StringBuffer();
  for (var i = 0; i < lines.length; i++) {
    buffer.write(lines[i].trim());
    if (i < lines.length - 1) buffer.write(lines[i].endsWith('  ') ? '\n' : ' ');
  }
  return buffer.toString();
}

LegalTable _table(List<String> rows) {
  List<String> cells(String row) {
    var inner = row.trim();
    if (inner.startsWith('|')) inner = inner.substring(1);
    if (inner.endsWith('|')) inner = inner.substring(0, inner.length - 1);
    return inner.split('|').map((cell) => cell.trim()).toList();
  }

  final header = cells(rows.first);
  final body = rows.length > 1 && _tableRule.hasMatch(rows[1])
      ? rows.skip(2)
      : rows.skip(1);

  return LegalTable(header: header, rows: body.map(cells).toList());
}

/// Кусок строки: обычный, жирный или ссылка. Ссылка показывается текстом:
/// документы ссылаются друг на друга, а все они и так открываются с того
/// же экрана.
class LegalSpan {
  const LegalSpan(this.text, {this.bold = false, this.link = false});

  final String text;
  final bool bold;
  final bool link;
}

final _inline = RegExp(r'\*\*(.+?)\*\*|\[([^\]]+)\]\(([^)\s]+)\)|`([^`]+)`');

/// Разбирает строчную разметку: **жирный**, [ссылка](адрес), `код`.
List<LegalSpan> parseLegalInline(String text) {
  final spans = <LegalSpan>[];
  var last = 0;

  for (final match in _inline.allMatches(text)) {
    if (match.start > last) spans.add(LegalSpan(text.substring(last, match.start)));
    if (match.group(1) != null) {
      spans.add(LegalSpan(match.group(1)!, bold: true));
    } else if (match.group(2) != null) {
      spans.add(LegalSpan(match.group(2)!, link: true));
    } else {
      spans.add(LegalSpan(match.group(4)!));
    }
    last = match.end;
  }
  if (last < text.length) spans.add(LegalSpan(text.substring(last)));

  return spans;
}
