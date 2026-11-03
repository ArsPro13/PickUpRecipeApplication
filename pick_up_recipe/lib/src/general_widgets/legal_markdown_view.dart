// Правовой документ в листе: блоки разметки — виджетами.
//
// Таблицы на телефоне не рисуются сеткой: три колонки по трети экрана —
// это слово на строку. Строка таблицы становится карточкой: первая ячейка —
// заголовком, остальные — «заголовок столбца: значение». Таблица без шапки
// («ключ — значение», реквизиты оператора) — строками «Ключ: значение».

import 'package:flutter/material.dart';

import '../features/legal/domain/legal_markdown.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

class LegalMarkdownView extends StatelessWidget {
  const LegalMarkdownView(this.source, {super.key});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in parseLegalMarkdown(source)) _block(context, block),
      ],
    );
  }

  Widget _block(BuildContext context, LegalBlock block) {
    final body = context.texts.bodySmall;
    final strong = body?.copyWith(fontWeight: FontWeight.w600);

    return switch (block) {
      LegalHeading(:final level, :final text) => Padding(
          padding: EdgeInsets.only(
            top: level == 1 ? 0 : AppSpacing.s4,
            bottom: AppSpacing.s2,
          ),
          child: Text.rich(_spans(
            context,
            text,
            switch (level) {
              1 => context.texts.titleMedium,
              2 => context.texts.titleSmall,
              _ => strong,
            },
          )),
        ),
      LegalParagraph(:final text) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s3),
          child: Text.rich(_spans(context, text, body)),
        ),
      LegalList(:final ordered, :final items) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: AppSpacing.s6,
                        child: Text(ordered ? '${i + 1}.' : '•', style: body),
                      ),
                      Expanded(
                          child: Text.rich(_spans(context, items[i], body))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      LegalTable() => _table(context, block, body, strong),
      LegalRule() => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.s3),
          child: Divider(height: 1),
        ),
    };
  }

  Widget _table(
    BuildContext context,
    LegalTable table,
    TextStyle? body,
    TextStyle? strong,
  ) {
    final label = body?.copyWith(color: context.colors.onSurfaceVariant);
    final rows = <Widget>[];

    for (var r = 0; r < table.rows.length; r++) {
      final row = table.rows[r];

      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
        child: table.keyValue
            ? Text.rich(TextSpan(style: body, children: [
                TextSpan(text: '${row.first}: ', style: label),
                ..._inline(context, row.skip(1).join(' ')),
              ]))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(_spans(context, row.first, strong)),
                  for (var c = 1;
                      c < row.length && c < table.header.length;
                      c++)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s1),
                      child: Text.rich(TextSpan(style: body, children: [
                        TextSpan(text: '${table.header[c]}: ', style: label),
                        ..._inline(context, row[c]),
                      ])),
                    ),
                ],
              ),
      ));
      if (r < table.rows.length - 1) rows.add(const Divider(height: 1));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }

  TextSpan _spans(BuildContext context, String text, TextStyle? style) =>
      TextSpan(style: style, children: _inline(context, text));

  List<InlineSpan> _inline(BuildContext context, String text) => [
        for (final span in parseLegalInline(text))
          TextSpan(
            text: span.text,
            style: span.bold
                ? const TextStyle(fontWeight: FontWeight.w600)
                : span.link
                    ? TextStyle(color: context.colors.primary)
                    : null,
          ),
      ];
}
