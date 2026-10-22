// Барабан для числа и барабан для выбора из списка.
//
// Числом крутят дозу, воду, температуру, воду шага и оценку SCA. Целое —
// одна колонка; доза с десятыми — две, целая часть и десятые через запятую,
// как вес в «Здоровье» на айфоне. Единица стоит рядом на полосе выбора и не
// крутится.
//
// Списком крутят помол: строки барабана — деления шкалы кофемолки человека,
// ровно те, что приходят с ней из справочника. Чисел, которых на шкале нет,
// на барабане нет тоже.

import 'package:flutter/material.dart';

import 'app_wheel.dart';

/// Открывает шторку с числом и возвращает выбранное.
///
/// null — закрыли шторку или нажали «Готово», ничего не повернув. Второе —
/// не прежнее число, а именно null: барабан держит не больше десятых, и
/// температура 93,5 у колонки целых открывается на 93. «Готово» без поворота
/// не должно молча округлить рецепт.
///
/// [acceptShown] — обратный случай: поле было пустым, барабан открылся на
/// примере, и «Готово» без поворота — это согласие с тем, что на нём видно.
Future<double?> showNumberSheet(
  BuildContext context, {
  required String title,
  required double value,
  required int min,
  required int max,
  String unit = '',
  bool tenths = false,
  bool acceptShown = false,
  String? caption,
}) {
  return showWheelSheet<double>(
    context,
    builder: (context) => _NumberSheet(
      title: title,
      caption: caption,
      value: value,
      min: min,
      max: max,
      unit: unit,
      tenths: tenths,
      acceptShown: acceptShown,
    ),
  );
}

/// Число, на котором барабан откроется: [value], приведённое к десятым или
/// целым и к границам барабана.
double wheelShownValue(double value,
    {required int min, required int max, bool tenths = false}) {
  final scaled = tenths ? (value * 10).round() : value.round() * 10;
  return scaled.clamp(min * 10, max * 10 + (tenths ? 9 : 0)) / 10;
}

class _NumberSheet extends StatefulWidget {
  const _NumberSheet({
    required this.title,
    required this.caption,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.tenths,
    required this.acceptShown,
  });

  final String title;
  final String? caption;
  final double value;
  final int min;
  final int max;
  final String unit;
  final bool tenths;
  final bool acceptShown;

  @override
  State<_NumberSheet> createState() => _NumberSheetState();
}

class _NumberSheetState extends State<_NumberSheet> {
  late double? _picked = widget.acceptShown
      ? wheelShownValue(widget.value,
          min: widget.min, max: widget.max, tenths: widget.tenths)
      : null;

  @override
  Widget build(BuildContext context) {
    return WheelSheetBody(
      title: widget.title,
      caption: widget.caption,
      wheels: NumberWheels(
        value: widget.value,
        min: widget.min,
        max: widget.max,
        unit: widget.unit,
        tenths: widget.tenths,
        onChanged: (value) => _picked = value,
      ),
      onDone: () => Navigator.of(context).pop(_picked),
    );
  }
}

/// Число на барабане: целые и, если нужно, десятые.
///
/// Отдельным виджетом, как и барабан длительности: его проверяют тестом без
/// шторки.
class NumberWheels extends StatefulWidget {
  const NumberWheels({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = '',
    this.tenths = false,
  });

  final double value;
  final int min;
  final int max;
  final String unit;

  /// Крутить ли десятые отдельной колонкой.
  final bool tenths;

  final ValueChanged<double> onChanged;

  @override
  State<NumberWheels> createState() => _NumberWheelsState();
}

class _NumberWheelsState extends State<NumberWheels> {
  /// Значение в десятых: 8,6 — это 86. Через целое, а не через double:
  /// 8.6 в двоичной записи — это 8,59999…, и целая часть с десятыми,
  /// вычисленные из неё напрямую, дали бы 8 и 5.
  late final int _initial = (wheelShownValue(widget.value,
              min: widget.min, max: widget.max, tenths: widget.tenths) *
          10)
      .round();

  late int _whole = (_initial ~/ 10).clamp(widget.min, widget.max);
  late int _tenth = widget.tenths ? _initial % 10 : 0;

  void _report() => widget.onChanged(_whole + _tenth / 10);

  /// Где после десятых встаёт единица: правее середины на отступ и цифру.
  static const double _unitAfterTenths = 24;

  /// Где после целого встаёт единица: число кончается на середине.
  static const double _unitAfterWhole = 2;

  @override
  Widget build(BuildContext context) {
    // Одно число без единицы — оценка SCA — стоит ровно посередине.
    final alone = !widget.tenths && widget.unit.isEmpty;

    final whole = AppWheel(
      itemCount: widget.max - widget.min + 1,
      initialItem: _whole - widget.min,
      alignment: alone ? Alignment.center : Alignment.centerRight,
      // Без десятых колонка целых — вся полоса, а число кончается на её
      // середине: справа встаёт единица, и крутить можно и по ней.
      labelBox: widget.tenths || alone ? 1 : 0.5,
      labelOf: (index) => '${widget.min + index}',
      onChanged: (index) {
        _whole = widget.min + index;
        _report();
      },
    );

    return AppWheelRow(
      marks: [
        if (widget.tenths) const WheelMark.center(','),
        if (widget.unit.isNotEmpty)
          WheelMark.after(
            widget.unit,
            widget.tenths ? _unitAfterTenths : _unitAfterWhole,
          ),
      ],
      children: [
        Expanded(child: whole),
        if (widget.tenths)
          Expanded(
            child: AppWheel(
              itemCount: 10,
              initialItem: _tenth,
              looping: true,
              alignment: Alignment.centerLeft,
              labelOf: (index) => '$index',
              onChanged: (index) {
                _tenth = index;
                _report();
              },
            ),
          ),
      ],
    );
  }
}

/// Открывает шторку со списком и возвращает номер выбранной строки.
///
/// null — закрыли или не крутили: так же, как у числа, «Готово» без поворота
/// ничего не меняет.
///
/// [unitOf] — подпись рядом с выбранной строкой. Она меняется вместе с ней:
/// «1 клик», «2 клика», «5 кликов» — у русского три формы, и одна на всю
/// колонку была бы неверна у двух из трёх строк.
Future<int?> showChoiceSheet(
  BuildContext context, {
  required String title,
  required List<String> labels,
  required int initial,
  String Function(int index)? unitOf,
  String? caption,
}) {
  return showWheelSheet<int>(
    context,
    builder: (context) => _ChoiceSheet(
      title: title,
      caption: caption,
      labels: labels,
      initial: initial,
      unitOf: unitOf,
    ),
  );
}

class _ChoiceSheet extends StatefulWidget {
  const _ChoiceSheet({
    required this.title,
    required this.caption,
    required this.labels,
    required this.initial,
    required this.unitOf,
  });

  final String title;
  final String? caption;
  final List<String> labels;
  final int initial;
  final String Function(int index)? unitOf;

  @override
  State<_ChoiceSheet> createState() => _ChoiceSheetState();
}

class _ChoiceSheetState extends State<_ChoiceSheet> {
  late int _shown = widget.initial.clamp(0, widget.labels.length - 1);
  int? _picked;

  /// Есть ли у шкалы слово рядом с числом. У «2 круг + 3» его нет — тогда
  /// подпись стоит посередине полосы целиком.
  late final bool _withUnit = widget.unitOf != null &&
      [
        for (var index = 0; index < widget.labels.length; index++)
          widget.unitOf!(index),
      ].any((unit) => unit.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final unit = widget.unitOf?.call(_shown) ?? '';

    return WheelSheetBody(
      title: widget.title,
      caption: widget.caption,
      wheels: AppWheelRow(
        // Слово стоит на месте и меняет форму вместе с числом под ним.
        marks: [
          if (_withUnit && unit.isNotEmpty) WheelMark.after(unit, 2),
        ],
        children: [
          Expanded(
            child: AppWheel(
              itemCount: widget.labels.length,
              initialItem: _shown,
              alignment: _withUnit ? Alignment.centerRight : Alignment.center,
              labelBox: _withUnit ? 0.5 : 1,
              labelOf: (index) => widget.labels[index],
              onChanged: (index) => setState(() {
                _shown = index;
                _picked = index;
              }),
            ),
          ),
        ],
      ),
      onDone: () => Navigator.of(context).pop(_picked),
    );
  }
}
