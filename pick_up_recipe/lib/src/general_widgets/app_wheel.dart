// Барабан — один на всё приложение.
//
// Числа набирались клавиатурой: доза, вода, температура и помол — диалогом
// с полем, дата обжарки — маской дд.мм.гггг, оценка SCA — цифрами. Владелец
// попросил крутить их барабаном, «как в айфоне, но в моих цветах», и первый
// барабан приложения — длительность шага — на это не тянул: два плоских
// списка по краям шторки, пустая полоса между ними, и выбранное отличалось
// от соседей одним цветом.
//
// Айфоновским барабан делают три вещи, и все они здесь: строки посажены на
// цилиндр (перспектива, сжатие к краям), дальние строки гаснут, а числа стоят
// тесно посередине на одной общей полосе выбора. Цвета свои: полоса тонирована
// фирменным цветом, им же и жирнее написано выбранное.
//
// Лупы над выбранной строкой нет. Она увеличивает строку от середины своей
// колонки, а колонки здесь во всю ширину — и выбранное число уезжало вбок от
// соседних строк, налезая на двоеточие и на единицу.
//
// Колонка — [AppWheel], полоса под колонками — [AppWheelRow], шторка вокруг —
// [showWheelSheet] с [WheelSheetBody]. Каждый конкретный выбор (длительность,
// число, помол, дата) собирается из этих деталей и ничего своего не рисует.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'app_kit.dart';

/// Высота строки барабана. Она же — шаг прокрутки на одну позицию.
const double kWheelItemExtent = 40;

/// Высота барабана: как у айфоновского, чуть больше пяти строк.
const double kWheelHeight = 216;

/// Насколько строка у края ужата по высоте. Сжатие и даёт цилиндр: без него
/// барабан — это плоский список с затенёнными краями.
const double _squeeze = 1.25;

/// Отношение диаметра цилиндра к высоте барабана — то же, что у айфона.
const double _diameterRatio = 1.07;

/// Насколько гаснут строки вне полосы выбора.
const double _dimmed = 0.45;

/// Отступ подписи от края колонки — и от середины полосы, к которой колонки
/// прижимают числа: между числом и двоеточием должен оставаться воздух.
const double _edgeRoom = AppSpacing.s2;

/// Одна колонка барабана.
///
/// Колонка, как на айфоне, ловит палец по всей своей ширине, а цифры в ней
/// прижаты к середине полосы, к соседней колонке. Узкие колонки по размеру
/// чисел выглядели так же, но крутились только под самими цифрами: палец на
/// слове «кликов» или на краю полосы не делал ничего, и барабан казался
/// сломанным. Без [width] колонка занимает всё, что ей дал ряд.
class AppWheel extends StatefulWidget {
  const AppWheel({
    super.key,
    required this.itemCount,
    required this.initialItem,
    required this.labelOf,
    required this.onChanged,
    this.controller,
    this.width,
    this.looping = false,
    this.alignment = Alignment.center,
    this.labelBox = 1,
    this.isEnabled,
  });

  final int itemCount;

  /// С какой строки барабан открывается. Если [controller] передан снаружи,
  /// эта строка обязана совпадать с его `initialItem`.
  final int initialItem;

  /// Подпись строки по её номеру.
  final String Function(int index) labelOf;

  /// Номер выбранной строки — при каждом повороте и при нажатии на строку.
  final ValueChanged<int> onChanged;

  /// Снаружи — когда колонку надо повернуть кодом: дата поправляет число,
  /// которого нет в выбранном месяце.
  final FixedExtentScrollController? controller;

  /// Ширина колонки. null — сколько дал ряд.
  final double? width;

  /// По кругу: после 59 снова 00, как у айфоновских минут и секунд.
  final bool looping;

  /// Где в отведённом месте стоит подпись строки.
  final Alignment alignment;

  /// Какая доля ширины, считая слева, отведена подписи. Половина — и число,
  /// прижатое вправо, кончается ровно на середине: справа от неё встаёт
  /// неподвижная единица, а колонка по-прежнему крутится во всю ширину.
  final double labelBox;

  /// Можно ли встать на строку. Нельзя — строка бледнее остальных, как
  /// 31-е число в апреле на айфоне: крутить через неё можно, остановиться —
  /// нет, барабан вернут на ближайшую допустимую.
  final bool Function(int index)? isEnabled;

  @override
  State<AppWheel> createState() => _AppWheelState();
}

class _AppWheelState extends State<AppWheel> {
  late final FixedExtentScrollController _own =
      FixedExtentScrollController(initialItem: widget.initialItem);

  FixedExtentScrollController get _controller => widget.controller ?? _own;

  late int _selected = widget.initialItem;

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  /// Номер строки в пределах одного круга. У закольцованной колонки сырой
  /// номер растёт без конца — после 59 идёт 60, и это снова 00.
  int _wrap(int raw) {
    if (!widget.looping) return raw;
    final count = widget.itemCount;
    return ((raw % count) + count) % count;
  }

  void _changed(int raw) {
    final index = _wrap(raw);
    if (index == _selected) return;
    // Щелчок на каждой строке — тот самый айфоновский треск колеса: по нему
    // считают позиции, не глядя на экран.
    HapticFeedback.selectionClick();
    setState(() => _selected = index);
    widget.onChanged(index);
  }

  /// Нажатие на соседнюю строку подводит к ней барабан — тем же движением,
  /// что и палец, и коротким путём: у закольцованной колонки с 58 до 01
  /// едут вперёд через ноль, а не назад через весь круг.
  void _tapped(int index) {
    final current = _controller.selectedItem;
    var delta = index - _wrap(current);
    if (widget.looping) {
      final half = widget.itemCount ~/ 2;
      if (delta > half) delta -= widget.itemCount;
      if (delta < -half) delta += widget.itemCount;
    }
    if (delta == 0) return;
    _controller.animateToItem(
      current + delta,
      duration: AppDuration.base,
      curve: AppCurves.out,
    );
  }

  Widget _row(BuildContext context, int index) {
    final chosen = index == _selected;
    final enabled = widget.isEnabled?.call(index) ?? true;

    // Строка — во всю ширину колонки. Колесо даёт строке свободную ширину
    // и ставит её по центру, и подпись, занявшая половину, оказывалась не
    // слева, а посередине — «кликов» налезало на число.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tapped(index),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: widget.labelBox,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _edgeRoom),
            child: Align(
              alignment: widget.alignment,
              child: Text(
                widget.labelOf(index),
                maxLines: 1,
                style: context.texts.titleMedium?.copyWith(
                  color: !enabled
                      ? context.colors.onSurface.withValues(alpha: 0.3)
                      : chosen
                          ? context.colors.primary
                          : context.colors.onSurface,
                  fontWeight: chosen ? FontWeight.w600 : FontWeight.w400,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.itemCount;

    return SizedBox(
      width: widget.width,
      height: kWheelHeight,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: kWheelItemExtent,
        diameterRatio: _diameterRatio,
        squeeze: _squeeze,
        overAndUnderCenterOpacity: _dimmed,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: _changed,
        childDelegate: widget.looping
            ? ListWheelChildLoopingListDelegate(
                children: [
                  for (var index = 0; index < count; index++)
                    _row(context, index),
                ],
              )
            : ListWheelChildBuilderDelegate(
                childCount: count,
                builder: _row,
              ),
      ),
    );
  }
}

/// Неподвижная подпись на полосе выбора — двоеточие, запятая, «г», «кликов».
///
/// Лежит поверх колонок и пальцу не мешает: жест проходит сквозь неё к
/// барабану. Ставится от середины полосы — там, куда колонки прижимают свои
/// числа.
class WheelMark {
  /// Ровно посередине полосы: «:» между минутами и секундами, «,» между
  /// граммами и десятыми.
  const WheelMark.center(this.text) : after = null;

  /// Справа от середины, отступив [after] точек: единица после числа.
  const WheelMark.after(this.text, double this.after);

  final String text;
  final double? after;
}

/// Колонки барабана на общей полосе выбора.
///
/// Полоса одна через все колонки, а не своя под каждой: выбранное читается
/// одной строкой — «3 : 00», «22 октября 2026», — а не тремя отдельными
/// числами. Края барабана растворяются в шторке, и цилиндр не обрывается
/// линией посреди строки.
class AppWheelRow extends StatelessWidget {
  const AppWheelRow({
    super.key,
    required this.children,
    this.marks = const [],
  });

  /// Колонки [AppWheel]: во всю ширину — в [Expanded], или своей ширины.
  final List<Widget> children;

  /// Неподвижные подписи поверх колонок.
  final List<WheelMark> marks;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kWheelHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final middle = constraints.maxWidth / 2;

          return Stack(
            alignment: Alignment.center,
            children: [
              IgnorePointer(
                child: Container(
                  height: kWheelItemExtent,
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.14),
                    borderRadius: AppRadius.medium,
                  ),
                ),
              ),
              ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [0, 0.2, 0.8, 1],
                ).createShader(bounds),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: children,
                ),
              ),
              for (final mark in marks)
                if (mark.after == null)
                  IgnorePointer(child: Center(child: WheelLabel(mark.text)))
                else
                  Positioned(
                    left: middle + mark.after!,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Center(child: WheelLabel(mark.text)),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

/// Неподвижная подпись на полосе выбора: двоеточие, «г», «°C», «кликов».
///
/// Не крутится вместе с числом — так же, как «мин» и «с» в таймере айфона:
/// единица одна на всю колонку, и повторять её в каждой строке — шум.
class WheelLabel extends StatelessWidget {
  const WheelLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
      child: Text(
        text,
        style: context.texts.titleMedium?.copyWith(
          color: context.colors.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Открывает шторку с барабаном.
///
/// Шторка, а не диалог: тип шага в той же карточке выбирается шторкой, и два
/// разных способа спросить читались бы как два разных экрана.
Future<T?> showWheelSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
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
    builder: builder,
  );
}

/// Содержимое шторки: заголовок, барабан и «Готово».
class WheelSheetBody extends StatelessWidget {
  const WheelSheetBody({
    super.key,
    required this.title,
    required this.wheels,
    required this.onDone,
    this.caption,
    this.footer,
  });

  final String title;

  /// Мелкая подпись справа от заголовка: «минуты и секунды», имя кофемолки.
  final String? caption;

  final Widget wheels;

  /// Что стоит под барабаном до «Готово»: «Сегодня» у даты обжарки.
  final Widget? footer;

  final VoidCallback onDone;

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
                Expanded(
                  child: Text(title, style: context.texts.bodyMedium),
                ),
                // Подпись прижата вправо и не шире половины шторки: длинное
                // имя кофемолки обрежется, а не вытолкнет заголовок.
                if (caption != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width / 2,
                    ),
                    child: Text(
                      caption!,
                      style: context.texts.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            wheels,
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.s2),
              footer!,
            ],
            const SizedBox(height: AppSpacing.s4),
            AppButton(
              label: AppLocalizations.of(context).builderDone,
              onPressed: onDone,
            ),
          ],
        ),
      ),
    );
  }
}
