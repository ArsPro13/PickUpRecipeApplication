// Барабан минут и секунд.
//
// Длительность набиралась строкой «м:сс» в системном диалоге: разбор прощал
// половинки и мусор, но двоеточие человек печатал руками и видел клавиатуру
// там, где нужно выбрать одно из шестидесяти чисел. Барабан крутится так же,
// как в таймере телефона, и промахнуться в нём нечем.
//
// Открывается шторкой, а не диалогом: тип шага в этой же карточке выбирается
// шторкой, и два разных способа спросить читались бы как два разных экрана.
// Ручку-полоску и скругление шторке даёт тема.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'app_kit.dart';
import 'app_surface.dart';

/// Сколько строк барабана видно разом. Пять: одна выбранная и по две
/// соседние сверху и снизу — меньше, и барабан перестаёт читаться барабаном.
const int _visibleRows = 5;

/// Потолок часов. Барабан часов стоит здесь по прямой просьбе владельца:
/// «чтобы можно было ставить длинные шаги — это необходимо для долгих
/// способов заваривания на несколько часов». До этого потолком были
/// пятьдесят девять минут, и колд брю на двенадцать часов в рецепт было
/// не записать вовсе.
///
/// Сутки — граница здравого смысла: шаг длиннее суток не заваривание,
/// а описка в разряде.
const int _hoursCount = 24;
const int _minutesCount = 60;
const int _secondsCount = 60;

/// Открывает шторку с барабаном и возвращает выбранные секунды.
/// null — закрыли, ничего не выбрав.
///
/// [title] пуст по умолчанию: заголовок берётся из словаря уже внутри шторки —
/// значение по умолчанию у параметра обязано быть константой, а строка из
/// словаря ею быть не может.
Future<int?> showDurationSheet(
  BuildContext context, {
  required int seconds,
  String? title,
}) {
  return showModalBottomSheet<int>(
    context: context,
    // Высота по содержимому: барабан на весь экран выглядел бы как отдельная
    // страница, с которой ещё надо понять, как вернуться.
    isScrollControlled: true,
    // Палец на барабане крутит барабан, а не тащит шторку вниз.
    //
    // Шторка по умолчанию тянется за пальцем всей своей площадью, и её
    // распознаватель вертикального перетаскивания забирал жест у барабана:
    // тот не проворачивался вовсе, а шторка уезжала вниз — вместе с
    // выбранным. Барабан здесь и есть всё содержимое шторки, поэтому
    // перетаскивание за тело ей нечем оправдать.
    //
    // Ручка-полоска при этом остаётся и остаётся рабочей: при выключенном
    // enableDrag Flutter вешает перетаскивание на неё одну, а тема, которая
    // рисует ручку всем шторкам, при выключенном перетаскивании её бы
    // спрятала — поэтому showDragHandle просим явно.
    enableDrag: false,
    showDragHandle: true,
    builder: (context) => _DurationSheet(seconds: seconds, title: title),
  );
}

class _DurationSheet extends StatefulWidget {
  const _DurationSheet({required this.seconds, required this.title});

  final int seconds;

  /// Заголовок шторки. null — «Длительность» из словаря.
  final String? title;

  @override
  State<_DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<_DurationSheet> {
  late int _picked = widget.seconds;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          0,
          AppSpacing.s5,
          AppSpacing.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок один: что означает каждый барабан, теперь подписано
            // над самим барабаном. Прежняя строка «минуты и секунды» справа
            // от заголовка называла разряды, но не говорила, который где, —
            // владелец просил подписать «что слева минуты, справа секунды».
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.title ?? texts.builderDuration,
                style: context.texts.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            DurationWheels(
              seconds: widget.seconds,
              onChanged: (value) => setState(() => _picked = value),
            ),
            const SizedBox(height: AppSpacing.s5),
            AppButton(
              label: texts.builderDone,
              onPressed: () => Navigator.of(context).pop(_picked),
            ),
          ],
        ),
      ),
    );
  }
}

/// Три барабана — часы, минуты и секунды — и подсвеченная строка выбора.
///
/// Каждый подписан своим разрядом: без подписи два одинаковых столбика цифр
/// читаются одинаково, и владелец спрашивал, что из них минуты. Подпись
/// стоит над барабаном, а не одной строкой сбоку, чтобы отвечать на этот
/// вопрос там, где он возникает.
///
/// Отдельным виджетом, а не куском шторки: так его можно поставить и на
/// экран, где шторка лишняя, и проверить тестом без открытия шторки.
class DurationWheels extends StatefulWidget {
  const DurationWheels({
    super.key,
    required this.seconds,
    required this.onChanged,
  });

  final int seconds;

  /// Отдаёт выбранное в секундах при каждом повороте любого из барабанов.
  final ValueChanged<int> onChanged;

  @override
  State<DurationWheels> createState() => _DurationWheelsState();
}

class _DurationWheelsState extends State<DurationWheels> {
  /// Ширина двоеточия между барабанами. Задана числом, а не размером текста,
  /// потому что по ней же расставлены подписи разрядов строкой выше: обе
  /// строки делят ширину одинаково, иначе «мин» стоит не над минутами.
  static const double _colonWidth = AppSpacing.s5;

  late int _hours = (widget.seconds ~/ 3600).clamp(0, _hoursCount - 1);
  late int _minutes = (widget.seconds % 3600) ~/ 60;
  late int _seconds = widget.seconds % 60;

  late final FixedExtentScrollController _hourWheel =
      FixedExtentScrollController(initialItem: _hours);
  late final FixedExtentScrollController _minuteWheel =
      FixedExtentScrollController(initialItem: _minutes);
  late final FixedExtentScrollController _secondWheel =
      FixedExtentScrollController(initialItem: _seconds);

  @override
  void dispose() {
    _hourWheel.dispose();
    _minuteWheel.dispose();
    _secondWheel.dispose();
    super.dispose();
  }

  void _report() => widget.onChanged(_hours * 3600 + _minutes * 60 + _seconds);

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _captions([
          texts.builderHoursShort,
          texts.builderMinutesShort,
          texts.builderSecondsShort,
        ]),
        const SizedBox(height: AppSpacing.s1),
        SizedBox(
          height: AppSizes.tapTarget * _visibleRows,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Дорожка под выбранной строкой: без неё непонятно, какое из пяти
              // чисел сейчас выбрано, — крайние читаются наравне со средним.
              IgnorePointer(
                child: Container(
                  height: AppSizes.tapTarget,
                  decoration: sunkenDecoration(context, borderRadius: AppRadius.medium),
                ),
              ),
              Row(
                children: [
                  _wheel(
                    controller: _hourWheel,
                    count: _hoursCount,
                    selected: _hours,
                    onChanged: (value) {
                      setState(() => _hours = value);
                      _report();
                    },
                  ),
                  _colon(context),
                  _wheel(
                    controller: _minuteWheel,
                    count: _minutesCount,
                    selected: _minutes,
                    pad: true,
                    onChanged: (value) {
                      setState(() => _minutes = value);
                      _report();
                    },
                  ),
                  _colon(context),
                  _wheel(
                    controller: _secondWheel,
                    count: _secondsCount,
                    selected: _seconds,
                    pad: true,
                    onChanged: (value) {
                      setState(() => _seconds = value);
                      _report();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Подписи разрядов над барабанами — тем же делением ширины, что и сами
  /// барабаны: столбцы `Expanded`, между ними двоеточие своей ширины.
  Widget _captions(List<String> labels) {
    return Row(
      children: [
        for (final (index, label) in labels.indexed) ...[
          if (index > 0) const SizedBox(width: _colonWidth),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: context.texts.labelSmall,
            ),
          ),
        ],
      ],
    );
  }

  Widget _colon(BuildContext context) {
    return SizedBox(
      width: _colonWidth,
      child: Center(child: Text(':', style: context.texts.titleMedium)),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required int selected,
    required ValueChanged<int> onChanged,
    bool pad = false,
  }) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: AppSizes.tapTarget,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (context, index) {
            final chosen = index == selected;
            return Center(
              child: Text(
                // Минуты и секунды двумя знаками, часы — одним: так же, как
                // длительность подписана в самом рецепте («1:05:00»).
                pad ? index.toString().padLeft(2, '0') : '$index',
                style: (chosen ? context.texts.bodyLarge : context.texts.bodyMedium)?.copyWith(
                  color: chosen ? context.colors.primary : context.colors.secondary,
                  fontWeight: chosen ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
