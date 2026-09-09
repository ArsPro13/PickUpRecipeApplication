// Дата обжарки: набирается цифрами по маске дд.мм.гггг.
//
// Владелец назвал прежнее поле «покореженным», и по делу: в initState в него
// подставлялась сама подпись, поэтому в значении поля стояло английское слово
// вместо даты и оно же уезжало на сервер, где не разбиралось и подменялось
// сегодняшним числом. Вдобавок нажатие ловили сразу два обработчика — свой у
// поля и свой у обёртки, — и календарь открывался и тут же закрывался.
//
// Календаря здесь больше нет намеренно: цифры с маской короче и на телефоне
// набираются быстрее, чем календарь листается на три года назад.
//
// Маска — единственное на этом экране, что не переводится. Подпись поля,
// пример внутри него и пояснение снизу берутся из словаря, а порядок частей
// и точки остаются те же на любом языке: ровно их читают parsePackDate и
// pack_request_model, и «переведённый» формат молча подменил бы дату обжарки
// сегодняшней. Другой порядок для английского — решение владельца, не наше.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/general_widgets/app_kit.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';

/// Формат, в котором дата и показывается, и уезжает в запрос.
final DateFormat packDateFormat = DateFormat('dd.MM.yyyy');

/// Разбирает набранное. null — дата не набрана или набрана не полностью.
DateTime? parsePackDate(String text) {
  final trimmed = text.trim();
  if (trimmed.length != 10) return null;

  final parsed = packDateFormat.tryParseStrict(trimmed);
  // Обжарка в будущем — почти всегда описка в годе: 2062 вместо 2026.
  if (parsed == null || parsed.isAfter(DateTime.now())) return null;
  return parsed;
}

class DateInputField extends StatefulWidget {
  const DateInputField({
    super.key,
    required this.labelText,
    required this.controller,
    this.onEditingFinished,
  });

  final String labelText;
  final TextEditingController controller;
  final VoidCallback? onEditingFinished;

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted || _focusNode.hasFocus) return;
    widget.onEditingFinished?.call();
  }

  void _setToday() {
    final today = packDateFormat.format(DateTime.now());
    widget.controller.value = TextEditingValue(
      text: today,
      selection: TextSelection.collapsed(offset: today.length),
    );
    widget.onEditingFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.labelText, style: context.texts.labelSmall),
        const SizedBox(height: AppSpacing.s1),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [_DateMaskFormatter()],
          onFieldSubmitted: (_) => widget.onEditingFinished?.call(),
          style: context.texts.bodyMedium,
          // Пример внутри поля переводится, а маска — нет: разбор даты и
          // запрос к серверу читают ровно дд.ММ.гггг, и другой порядок частей
          // молча превратил бы дату обжарки в сегодняшнюю.
          decoration: InputDecoration(hintText: texts.packFormDateHint),
          validator: (value) {
            final text = value?.trim() ?? '';
            // Пустое поле — не ошибка: дату обжарки печатают не на всякой
            // пачке. Тогда сервер поставит сегодняшнее число.
            if (text.isEmpty) return null;
            return parsePackDate(text) == null ? texts.packFormDateInvalid : null;
          },
        ),
        const SizedBox(height: AppSpacing.s2),
        Row(
          children: [
            Expanded(
              child: Text(
                texts.packFormDateEmptyNote,
                style: context.texts.labelSmall,
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            AppChip(label: texts.packFormToday, onTap: _setToday),
          ],
        ),
      ],
    );
  }
}

/// Точки расставляются сами: человек набирает восемь цифр подряд.
class _DateMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;

    final masked = StringBuffer();
    for (var i = 0; i < capped.length; ++i) {
      if (i == 2 || i == 4) masked.write('.');
      masked.write(capped[i]);
    }

    final text = masked.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
