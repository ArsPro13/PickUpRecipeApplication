// Барабан минут и секунд.
//
// Длительность набиралась строкой «м:сс» в системном диалоге: разбор прощал
// половинки и мусор, но двоеточие человек печатал руками и видел клавиатуру
// там, где нужно выбрать одно из шестидесяти чисел. Барабан крутится так же,
// как в таймере телефона, и промахнуться в нём нечем.
//
// Сам барабан — общий, из app_wheel.dart: минуты и секунды стоят рядом и
// крутятся по кругу, как на айфоне, — после 59 снова 00.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'app_wheel.dart';

/// Потолок минут. Часовые шаги колд брю живут отдельным экраном ожидания,
/// а не строкой рецепта, и шестьдесят минут здесь — заведомо больше нужного.
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
  return showWheelSheet<int>(
    context,
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

    return WheelSheetBody(
      title: widget.title ?? texts.builderDuration,
      caption: texts.builderMinutesSeconds,
      wheels: DurationWheels(
        seconds: widget.seconds,
        onChanged: (value) => setState(() => _picked = value),
      ),
      onDone: () => Navigator.of(context).pop(_picked),
    );
  }
}

/// Два барабана — минуты и секунды — на общей полосе выбора.
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
  late int _minutes = (widget.seconds ~/ 60).clamp(0, _minutesCount - 1);
  late int _seconds = widget.seconds % 60;

  void _report() => widget.onChanged(_minutes * 60 + _seconds);

  @override
  Widget build(BuildContext context) {
    // Каждая колонка — половина полосы, числа прижаты к двоеточию
    // посередине: так их видно одним числом «3:00», а крутить можно,
    // поставив палец куда угодно на свою половину.
    return AppWheelRow(
      marks: const [WheelMark.center(':')],
      children: [
        Expanded(
          child: AppWheel(
            itemCount: _minutesCount,
            initialItem: _minutes,
            looping: true,
            alignment: Alignment.centerRight,
            // Минуты одним знаком, секунды двумя: так же, как длительность
            // подписана в самом рецепте.
            labelOf: (index) => '$index',
            onChanged: (value) {
              _minutes = value;
              _report();
            },
          ),
        ),
        Expanded(
          child: AppWheel(
            itemCount: _secondsCount,
            initialItem: _seconds,
            looping: true,
            alignment: Alignment.centerLeft,
            labelOf: (index) => index.toString().padLeft(2, '0'),
            onChanged: (value) {
              _seconds = value;
              _report();
            },
          ),
        ),
      ],
    );
  }
}
