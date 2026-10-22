// Барабан даты: число, месяц и год — как дата на айфоне.
//
// Дата обжарки набиралась цифрами по маске дд.мм.гггг. Короче календаря, но
// клавиатура закрывала пол-экрана, а «31.04» маска пропускала до самой
// проверки. На барабане такой даты не набрать: тридцать первое в апреле
// бледное, и, если остановиться на нём, барабан сам отъедет на тридцатое.
// То же с будущим: обжарки завтрашним числом не бывает, и дни после
// сегодняшнего тоже бледные.
//
// Порядок колонок — порядок языка: «22 октября 2026», но «October 22 2026».
// Месяцы словами из того же словаря, что и даты во всём приложении.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/dates.dart';
import '../../l10n/app_localizations.dart';
import '../themes/app_tokens.dart';
import 'app_wheel.dart';

/// Сколько лет назад барабан ещё крутится. Пачку пятилетней обжарки не
/// заваривают, а год — колонка не закольцованная, и лишние годы — лишний путь.
const int _years = 6;

/// Открывает шторку с датой. null — закрыли, ничего не выбрав.
///
/// [latest] — самая поздняя дата, на которой можно остановиться. Время в ней
/// не учитывается: сравниваются только дни.
Future<DateTime?> showDateSheet(
  BuildContext context, {
  required String title,
  required DateTime latest,
  DateTime? initial,
}) {
  return showWheelSheet<DateTime>(
    context,
    builder: (context) => _DateSheet(
      title: title,
      latest: DateUtils.dateOnly(latest),
      initial: initial,
    ),
  );
}

class _DateSheet extends StatefulWidget {
  const _DateSheet({
    required this.title,
    required this.latest,
    required this.initial,
  });

  final String title;
  final DateTime latest;
  final DateTime? initial;

  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  late DateTime _picked =
      settleDate(widget.initial ?? widget.latest, latest: widget.latest);

  @override
  Widget build(BuildContext context) {
    return WheelSheetBody(
      title: widget.title,
      wheels: DateWheels(
        initial: _picked,
        latest: widget.latest,
        onChanged: (date) => _picked = date,
      ),
      onDone: () => Navigator.of(context).pop(_picked),
    );
  }
}

/// Ближайшая допустимая дата: число не больше дней в месяце, не позже
/// [latest] и не раньше первого года барабана.
///
/// Вынесено функцией ради теста: «31 апреля» и «завтра» — ровно то, что
/// барабан обязан не выпустить, и проверять это глазами нельзя.
DateTime settleDate(DateTime date, {required DateTime latest}) {
  final last = DateUtils.dateOnly(latest);
  final firstYear = last.year - _years + 1;

  final year = date.year.clamp(firstYear, last.year);
  final month = date.month;
  final day = math.min(date.day, DateUtils.getDaysInMonth(year, month));

  final settled = DateTime(year, month, day);
  return settled.isAfter(last) ? last : settled;
}

/// Три колонки даты.
class DateWheels extends StatefulWidget {
  const DateWheels({
    super.key,
    required this.initial,
    required this.latest,
    required this.onChanged,
  });

  /// Дата, на которой барабан открывается. Обязана быть допустимой — её
  /// готовит [settleDate].
  final DateTime initial;
  final DateTime latest;

  /// Отдаёт всегда допустимую дату, даже пока колонка ещё крутится через
  /// тридцать первое.
  final ValueChanged<DateTime> onChanged;

  @override
  State<DateWheels> createState() => _DateWheelsState();
}

class _DateWheelsState extends State<DateWheels> {
  late int _day = widget.initial.day;
  late int _month = widget.initial.month;
  late int _year = widget.initial.year;

  late final int _firstYear = widget.latest.year - _years + 1;

  late final FixedExtentScrollController _days =
      FixedExtentScrollController(initialItem: _day - 1);
  late final FixedExtentScrollController _months =
      FixedExtentScrollController(initialItem: _month - 1);
  late final FixedExtentScrollController _yearsWheel =
      FixedExtentScrollController(initialItem: _year - _firstYear);

  @override
  void dispose() {
    _days.dispose();
    _months.dispose();
    _yearsWheel.dispose();
    super.dispose();
  }

  /// Допустимая дата из того, что стоит на колонках.
  DateTime get _value {
    final day = math.min(_day, DateUtils.getDaysInMonth(_year, _month));
    return settleDate(DateTime(_year, _month, day), latest: widget.latest);
  }

  void _changed() {
    setState(() {});
    widget.onChanged(_value);
  }

  /// Колонки встали — подвести их к допустимой дате.
  ///
  /// Не на каждом шаге колонки, а когда она остановилась: иначе барабан
  /// вырывался бы из-под пальца посреди прокрутки через тридцать первое.
  ///
  /// Сама поправка — следующей микрозадачей, а не прямо здесь. Конец
  /// прокрутки колонка объявляет, ещё не перейдя в покой, и поворот, начатый
  /// внутри этого объявления, она тут же и гасит, переходя в покой. Так
  /// застревало «25 октября» при сегодняшнем 22-м: дата уезжала верная, а
  /// барабан стоял на бледном числе.
  bool _settle(ScrollEndNotification _) {
    scheduleMicrotask(_settleNow);
    return false;
  }

  void _settleNow() {
    if (!mounted) return;
    final value = _value;
    if (value.day != _day) _turn(_days, _day - 1, value.day - 1, 31);
    if (value.month != _month) _turn(_months, _month - 1, value.month - 1, 12);
    if (value.year != _year) {
      _yearsWheel.animateToItem(
        value.year - _firstYear,
        duration: AppDuration.base,
        curve: AppCurves.out,
      );
    }
  }

  /// Поворачивает закольцованную колонку коротким путём.
  void _turn(FixedExtentScrollController wheel, int from, int to, int count) {
    if (!wheel.hasClients) return;
    var delta = to - from;
    if (delta > count ~/ 2) delta -= count;
    if (delta < -count ~/ 2) delta += count;
    wheel.animateToItem(
      wheel.selectedItem + delta,
      duration: AppDuration.base,
      curve: AppCurves.out,
    );
  }

  bool _dayAllowed(int index) {
    final day = index + 1;
    if (day > DateUtils.getDaysInMonth(_year, _month)) return false;
    return !DateTime(_year, _month, day).isAfter(widget.latest);
  }

  bool _monthAllowed(int index) =>
      !DateTime(_year, index + 1).isAfter(widget.latest);

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final months = monthNames(texts);
    // Колонка месяцев по самому длинному названию: «сентября» и «September»
    // не должны обрезаться, а лишняя ширина разносила бы число и год.
    final monthWidth = 36.0 +
        12 *
            months.fold<int>(
                0, (longest, name) => math.max(longest, name.length));

    final day = AppWheel(
      itemCount: 31,
      initialItem: _day - 1,
      controller: _days,
      looping: true,
      width: 60,
      labelOf: (index) => '${index + 1}',
      isEnabled: _dayAllowed,
      onChanged: (index) {
        _day = index + 1;
        _changed();
      },
    );
    final month = AppWheel(
      itemCount: 12,
      initialItem: _month - 1,
      controller: _months,
      looping: true,
      width: monthWidth,
      labelOf: (index) => months[index],
      isEnabled: _monthAllowed,
      onChanged: (index) {
        _month = index + 1;
        _changed();
      },
    );
    final year = AppWheel(
      itemCount: _years,
      initialItem: _year - _firstYear,
      controller: _yearsWheel,
      width: 80,
      labelOf: (index) => '${_firstYear + index}',
      onChanged: (index) {
        _year = _firstYear + index;
        _changed();
      },
    );

    // По-английски месяц впереди числа: «October 22», а не «22 October».
    final monthFirst = Localizations.localeOf(context).languageCode == 'en';

    return NotificationListener<ScrollEndNotification>(
      onNotification: _settle,
      child: AppWheelRow(
        children: monthFirst ? [month, day, year] : [day, month, year],
      ),
    );
  }
}
