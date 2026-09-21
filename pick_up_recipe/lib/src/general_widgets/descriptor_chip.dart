// Тег дескриптора вкуса — единственное место, где они рисуются.
//
// До этого теги рисовались в трёх местах и каждое красило по-своему: цвет
// приходил параметром из вызывающего кода, то есть его не было вовсе. Теперь
// цвет берётся из палитры по КАТЕГОРИИ слова (ADR 0007), а палитра приезжает
// с сервера и правится в кабинете.
//
// Два вида одного тега:
//   • читаемый — бледная заливка семьи и плотные чернила поверх. Так он
//     стоит на карточке пачки, где ничего не выбирают;
//   • выбираемый — прозрачный с цветной обводкой, выбранный залит цветом
//     категории целиком. Так он стоит на экране оценки, где набор и есть
//     ответ: заливка видна с метра, и пересчитывать галочки не нужно.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/reference/application/reference_state.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

class DescriptorChip extends ConsumerWidget {
  const DescriptorChip({
    super.key,
    required this.word,
    this.selected = false,
    this.onTap,
    this.dense = false,
    this.categorySlug,
    this.lookup,
  });

  /// Слово как его написал человек или обжарщик: «ягода», «Молочный шоколад».
  final String word;

  final bool selected;

  /// Пусто — тег только читается.
  final VoidCallback? onTap;

  /// Плотный вид для сеток, где слов много.
  final bool dense;

  /// Категория напрямую — для слов, которых нет в общем словаре
  /// (тактильность на экране оценки). Пусто — категория ищется по слову.
  final String? categorySlug;

  /// Чем искать цвет, если подпись — не то слово, что лежит в словаре.
  /// На английском экране метка называется Blueberry, а в словаре она
  /// `blueberry`: без слага цвет искался бы по переводу и не нашёлся.
  final String? lookup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteNowProvider);
    final brightness = Theme.of(context).brightness;

    // Слово ищется в словаре: оттуда и категория, и ступень. Категория
    // параметром — запасной ответ для слов, которых в словаре нет: своих
    // («+3» на карточке) и любых, пока справочник не приехал.
    final colors = palette.colorsOf(lookup ?? word, brightness);
    final known = colors.category.slug != 'other' || categorySlug == null;
    final category = known ? colors.category : palette.bySlug(categorySlug!);
    final Color ink = known ? colors.ink : category.ink(brightness);
    final Color fill = known ? colors.fill : category.fill(brightness);

    final selectable = onTap != null;
    final Color background;
    final Color border;
    final Color text;

    if (!selectable) {
      background = fill;
      border = fill;
      text = ink;
    } else if (selected) {
      background = ink;
      border = ink;
      // Текст на плотных чернилах — светлая заливка той же семьи: белый на
      // всех одиннадцати тонах читается по-разному, а своя заливка держит
      // контраст ровно.
      text = fill;
    } else {
      background = Colors.transparent;
      border = ink;
      text = context.colors.onSurface;
    }

    final label = Text(
      word,
      style: (dense ? context.texts.labelSmall : context.texts.bodySmall)?.copyWith(
        color: text,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    final body = Container(
      constraints: BoxConstraints(minHeight: dense ? 32 : AppSizes.tapTarget - AppSpacing.s4),
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.s2 : AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.small,
        border: Border.all(color: border, width: AppStroke.thick),
      ),
      alignment: Alignment.center,
      child: label,
    );

    if (!selectable) return body;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.small,
        child: body,
      ),
    );
  }
}

/// Лента тегов без выбора: карточка пачки, строка рецепта.
class DescriptorTags extends StatelessWidget {
  const DescriptorTags({super.key, required this.words, this.limit});

  final List<String> words;

  /// Сколько показать. Остальные сворачиваются в «+N»: на карточке пачки
  /// место конечно, а восемь тегов в три строки ломают высоту списка.
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final shown = limit == null || words.length <= limit!
        ? words
        : words.sublist(0, limit!);
    final rest = words.length - shown.length;

    return Wrap(
      spacing: AppSpacing.s2,
      runSpacing: AppSpacing.s2,
      children: [
        for (final word in shown) DescriptorChip(word: word, dense: true),
        if (rest > 0)
          DescriptorChip(word: '+$rest', dense: true, categorySlug: 'other'),
      ],
    );
  }
}
