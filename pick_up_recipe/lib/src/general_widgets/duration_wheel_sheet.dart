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

import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'app_kit.dart';
import 'app_surface.dart';

/// Сколько строк барабана видно разом. Пять: одна выбранная и по две
/// соседние сверху и снизу — меньше, и барабан перестаёт читаться барабаном.
const int _visibleRows = 5;

/// Потолок минут. Часовые шаги колд брю живут отдельным экраном ожидания,
/// а не строкой рецепта, и шестьдесят минут здесь — заведомо больше нужного.
const int _minutesCount = 60;
const int _secondsCount = 60;

/// Открывает шторку с барабаном и возвращает выбранные секунды.
/// null — закрыли, ничего не выбрав.
Future<int?> showDurationSheet(
  BuildContext context, {
  required int seconds,
  String title = 'Длительность',
}) {
  return showModalBottomSheet<int>(
    context: context,
    // Высота по содержимому: барабан на весь экран выглядел бы как отдельная
    // страница, с которой ещё надо понять, как вернуться.
    isScrollControlled: true,
    builder: (context) => _DurationSheet(seconds: seconds, title: title),
  );
}

class _DurationSheet extends StatefulWidget {
  const _DurationSheet({required this.seconds, required this.title});

  final int seconds;
  final String title;

  @override
  State<_DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<_DurationSheet> {
  late int _picked = widget.seconds;

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                Expanded(child: Text(widget.title, style: context.texts.bodyMedium)),
                Text('минуты и секунды', style: context.texts.labelSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            DurationWheels(
              seconds: widget.seconds,
              onChanged: (value) => setState(() => _picked = value),
            ),
            const SizedBox(height: AppSpacing.s5),
            AppButton(
              label: 'Готово',
              onPressed: () => Navigator.of(context).pop(_picked),
            ),
          ],
        ),
      ),
    );
  }
}

/// Два барабана — минуты и секунды — и подсвеченная строка выбора между ними.
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

  late final FixedExtentScrollController _minuteWheel =
      FixedExtentScrollController(initialItem: _minutes);
  late final FixedExtentScrollController _secondWheel =
      FixedExtentScrollController(initialItem: _seconds);

  @override
  void dispose() {
    _minuteWheel.dispose();
    _secondWheel.dispose();
    super.dispose();
  }

  void _report() => widget.onChanged(_minutes * 60 + _seconds);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                controller: _minuteWheel,
                count: _minutesCount,
                selected: _minutes,
                onChanged: (value) {
                  setState(() => _minutes = value);
                  _report();
                },
              ),
              Text(':', style: context.texts.titleMedium),
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
                // Секунды двумя знаками, минуты — одним: так же, как
                // длительность подписана в самом рецепте.
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
