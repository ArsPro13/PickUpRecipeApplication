// Поле ввода в том виде, в каком оно нарисовано: метка над вдавленной
// строкой, иконка слева, ошибка под самим полем.
//
// В покое у строки тонкая рамка цветом границы, на фокусе и на ошибке —
// цветная и вдвое толще. Когда-то рамки в покое не было вовсе: обводка у
// каждого поля превращала форму в решётку, и это было главным замечанием к
// прошлой вёрстке, где каждый TextFormField рисовал себе рамку сам. Но без
// рамки пустое поле не отличалось от фона, и строку приходилось искать
// глазами. Разница в толщине и цвете снимает оба возражения: поле видно, а
// взгляд всё равно ведёт туда, где сейчас курсор.
//
// Ошибка живёт у того поля, в котором произошла: общая красная строка внизу
// формы не говорит, что именно править.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'app_icon.dart';
import 'app_surface.dart';

class AppField extends StatefulWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.hint,
    this.helper,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.valid = false,
  });

  final String label;
  final TextEditingController controller;

  /// Иконка слева. Пусто — строка начинается с текста.
  final String? icon;

  final String? hint;

  /// Подсказка под полем. Прячется, когда есть ошибка: два текста подряд
  /// человек не читает, а важнее из них ошибка.
  final String? helper;

  final String? error;

  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  /// Показать галочку справа: поле заполнено верно.
  final bool valid;

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  final FocusNode _focus = FocusNode();

  /// Прокрутка строки внутри поля. Своя, а не внутренняя у TextField:
  /// до внутренней снаружи не дотянуться, а отматывать её нужно нам.
  final ScrollController _line = ScrollController();

  late bool _hidden = widget.obscure;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _line.dispose();
    super.dispose();
  }

  /// Ушли из поля — показываем начало строки.
  ///
  /// Пока в поле пишут, оно отмотано к курсору, то есть к концу: длинная
  /// почта видна как «...@example.com». После перехода в следующее поле это
  /// уже не курсор, а всё, что осталось от введённого, и по хвосту домена
  /// человек не узнаёт, тот ли адрес он набрал. Начало строки отвечает на
  /// вопрос «что здесь введено», конец — нет.
  ///
  /// Обратно ничего не прибивается: вернулся фокус — EditableText сам
  /// отматывает строку к курсору, и дописывать с конца по-прежнему видно.
  void _onFocusChanged() {
    setState(() {});

    if (_focus.hasFocus || !_line.hasClients) return;

    _line.jumpTo(_line.position.minScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    final texts = AppLocalizations.of(context);

    // В покое — тонкая рамка цветом границы. Раньше её не было вовсе, и
    // пустое поле сливалось с фоном: на экране «Свой тип шага» строку
    // «Название» приходилось искать глазами (пункт №12). Цвет границы едва
    // заметен, поэтому несколько полей подряд не превращаются в решётку —
    // ровно того боялись, когда рамку отсюда убирали.
    //
    // Фокус и ошибка остались прежними: цветом и удвоенной толщиной. Важно,
    // что они по-прежнему заметнее покоя, — это проверяет app_field_test.
    final (borderColor, borderWidth) = switch ((hasError, _focus.hasFocus)) {
      (true, _) => (context.colors.error, AppStroke.thick),
      (false, true) => (context.colors.primary, AppStroke.thick),
      _ => (context.palette.border, AppStroke.thin),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: context.texts.bodySmall),
        const SizedBox(height: AppSpacing.s1),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s1,
          ),
          // Вдавленная поверхность: поле утоплено, а не наклеено сверху.
          // Раньше тень лежала снаружи и поле выглядело приподнятым —
          // ровно наоборот тому, что нарисовано в макете.
          decoration: sunkenDecoration(
            context,
            borderRadius: AppRadius.medium,
            outline: borderColor,
            outlineWidth: borderWidth,
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                AppIcon(
                  widget.icon!,
                  size: AppSizes.icon20,
                  color: context.colors.secondary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: AppSpacing.s3),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  scrollController: _line,
                  enabled: widget.enabled,
                  obscureText: _hidden,
                  autocorrect: false,
                  enableSuggestions: !widget.obscure,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  inputFormatters: widget.inputFormatters,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: context.texts.bodyMedium,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: context.texts.bodyMedium?.copyWith(
                      color: context.colors.secondary.withValues(alpha: 0.6),
                    ),
                    // Всё оформление снаружи: рамка, заливка и отступы уже
                    // заданы контейнером, второй раз их рисовать нечем.
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                  ),
                ),
              ),
              if (widget.obscure)
                _IconAction(
                  icon: _hidden ? AppIcons.uiEye : AppIcons.uiEyeOff,
                  label: _hidden
                      ? texts.packFormShowPassword
                      : texts.packFormHidePassword,
                  onTap: () => setState(() => _hidden = !_hidden),
                )
              else if (widget.valid)
                AppIcon(
                  AppIcons.uiCheck,
                  size: AppSizes.icon20,
                  color: context.palette.success,
                ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(
                  AppIcons.uiWarning,
                  size: AppSizes.icon16,
                  color: context.colors.error,
                ),
                const SizedBox(width: AppSpacing.s1),
                Expanded(
                  child: Text(
                    widget.error!,
                    style: context.texts.labelSmall?.copyWith(color: context.colors.error),
                  ),
                ),
              ],
            ),
          )
        else if (widget.helper != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s1),
            child: Text(widget.helper!, style: context.texts.labelSmall),
          ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.label, required this.onTap});

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: AppSizes.icon24,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s1),
          child: AppIcon(icon, size: AppSizes.icon20, color: context.colors.secondary),
        ),
      ),
    );
  }
}

/// Правило пароля: точка и текст, зелёная галочка когда выполнено.
///
/// Правил ровно столько, сколько требует сервер. На макете их было два, но
/// второе — «есть цифра или знак» — было предположением: authsvc.ValidatePassword
/// проверяет только длину, и показывать несуществующее требование значит
/// отказывать человеку в пароле, который сервер бы принял.
class PasswordRule extends StatelessWidget {
  const PasswordRule({super.key, required this.text, required this.met});

  final String text;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: AppSizes.icon16,
          height: AppSizes.icon16,
          child: met
              ? AppIcon(AppIcons.uiCheck, size: AppSizes.icon16, color: context.palette.success)
              : Center(
                  child: Container(
                    width: AppSpacing.s1 + 2,
                    height: AppSpacing.s1 + 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.secondary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.s2),
        Text(
          text,
          style: context.texts.labelSmall?.copyWith(
            color: met ? context.palette.success : context.colors.secondary,
          ),
        ),
      ],
    );
  }
}

/// Код из письма: шесть отдельных ячеек.
///
/// Тот же приём, что у кода с пачки: видно, сколько осталось набрать, и
/// опечатка правится одним касанием, а не выделением куска строки.
///
/// Под ячейками лежит одно невидимое поле — так работает вставка из буфера
/// и автоподстановка кода из СМС и почты, чего шесть отдельных полей не умеют.
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
    this.hasError = false,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;
  final bool hasError;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted?.call(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;

    return Stack(
      children: [
        Row(
          children: [
            for (var i = 0; i < widget.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s2),
              Expanded(child: _cell(context, code, i)),
            ],
          ],
        ),
        // Невидимое поле поверх ячеек: ловит клавиатуру, вставку и
        // автоподстановку кода.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              showCursor: false,
              style: const TextStyle(height: 0.01),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, String code, int index) {
    final filled = index < code.length;
    final isCurrent = index == code.length && _focus.hasFocus;

    final borderColor = switch ((widget.hasError, filled || isCurrent)) {
      (true, _) => context.colors.error,
      (false, true) => context.colors.primary,
      _ => Colors.transparent,
    };

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: sunkenDecoration(
          context,
          borderRadius: AppRadius.medium,
          outline: borderColor,
        ),
        alignment: Alignment.center,
        child: filled
            ? Text(
                code[index],
                style: context.texts.titleLarge?.copyWith(fontFeatures: const [
                  FontFeature.tabularFigures(),
                ]),
              )
            : isCurrent
                ? Container(
                    width: AppStroke.thick,
                    height: AppSpacing.s6,
                    color: context.colors.primary,
                  )
                : null,
      ),
    );
  }
}
