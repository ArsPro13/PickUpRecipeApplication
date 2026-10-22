// Дата обжарки: барабаном — число, месяц и год, как дата на айфоне.
//
// Владелец назвал первое поле «покореженным», и по делу: в initState в него
// подставлялась сама подпись, поэтому в значении поля стояло английское слово
// вместо даты и оно же уезжало на сервер, где не разбиралось и подменялось
// сегодняшним числом. Вдобавок нажатие ловили сразу два обработчика — свой у
// поля и свой у обёртки, — и календарь открывался и тут же закрывался.
//
// Потом поле стало маской дд.мм.гггг: цифры набирались быстрее, чем календарь
// листался на три года назад. Но клавиатура закрывала пол-экрана, а «31.04»
// маска пропускала до самой проверки. Теперь — барабан: владелец попросил
// «как айфоновский», и на нём недопустимой даты не набрать вовсе.
//
// Значение в поле прежнее, дд.мм.гггг, и не переводится: ровно его читают
// parsePackDate и pack_request_model, и другой порядок частей молча подменил
// бы дату обжарки сегодняшней. Барабан — только способ это значение задать.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/general_widgets/app_icon.dart';
import 'package:pick_up_recipe/src/general_widgets/app_kit.dart';
import 'package:pick_up_recipe/src/general_widgets/date_wheel_sheet.dart';
import 'package:pick_up_recipe/src/themes/app_icons.dart';
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
  void _set(String text) {
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onEditingFinished?.call();
  }

  Future<void> _pick() async {
    // Клавиатура соседнего поля ушла бы под шторку и закрывала барабан.
    FocusScope.of(context).unfocus();

    final picked = await showDateSheet(
      context,
      title: widget.labelText,
      latest: DateTime.now(),
      initial: parsePackDate(widget.controller.text),
    );
    if (picked == null || !mounted) return;
    _set(packDateFormat.format(picked));
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
          // Поле только показывает дату: набирают её барабаном. Клавиатуры
          // здесь нет — нажатие на поле открывает шторку.
          readOnly: true,
          showCursor: false,
          enableInteractiveSelection: false,
          onTap: _pick,
          style: context.texts.bodyMedium,
          decoration: InputDecoration(
            hintText: texts.packFormDateHint,
            // Пустое поле — тоже ответ: тогда сервер поставит сегодняшнюю.
            // Крестик возвращает к нему, не открывая барабан.
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) => value.text.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.s3),
                      child: AppIcon(
                        AppIcons.uiChevronDown,
                        size: AppSizes.icon20,
                        color: context.colors.secondary,
                      ),
                    )
                  : IconButton(
                      onPressed: () => _set(''),
                      tooltip: texts.clear,
                      icon: AppIcon(
                        AppIcons.uiClose,
                        size: AppSizes.icon20,
                        color: context.colors.secondary,
                      ),
                    ),
            ),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            // Пустое поле — не ошибка: дату обжарки печатают не на всякой
            // пачке. Тогда сервер поставит сегодняшнее число. Барабан
            // неверной даты не даст, но поле заполняют и снаружи — разбором
            // снимка пачки.
            if (text.isEmpty) return null;
            return parsePackDate(text) == null
                ? texts.packFormDateInvalid
                : null;
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
            AppChip(
              label: texts.packFormToday,
              onTap: () => _set(packDateFormat.format(DateTime.now())),
            ),
          ],
        ),
      ],
    );
  }
}
