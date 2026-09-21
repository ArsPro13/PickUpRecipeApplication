// Поле формы с подсказками из справочника.
//
// Одно поле на все справочные значения: страна, регион, сорт, дескрипторы,
// обработка. Раньше подсказки были только у части полей и показывались
// собственным выпадающим списком с ручной анимацией — единственным таким
// элементом во всём приложении. Теперь совпадения показываются метками
// набора, теми же, какими на карточке пачки показаны дескрипторы: нажал —
// поле заполнилось, и это законченный ввод.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:pick_up_recipe/src/general_widgets/app_kit.dart';
import 'package:pick_up_recipe/src/general_widgets/descriptor_chip.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';

class TextInputWithHints extends StatefulWidget {
  const TextInputWithHints({
    super.key,
    required this.hintsArray,
    required this.labelText,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.onEditingFinished,
    this.validator,
    this.keyboardType,
    this.colored = false,
  });

  /// Справочник значений с сервера. Пустой — поле работает как обычное.
  final List<String> hintsArray;

  /// Подпись над полем.
  final String labelText;

  final TextEditingController controller;

  /// Бледная подсказка внутри пустого поля: пример значения.
  final String? hintText;

  final ValueChanged<String>? onChanged;

  /// Ввод в поле закончен: человек нажал «далее», ушёл в соседнее поле или
  /// выбрал подсказку. Значение уезжает в форму только здесь — пока идёт
  /// набор, слова ещё нет, есть только его начало.
  final VoidCallback? onEditingFinished;

  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;

  /// Красить подсказки по категории вкуса. Для дескрипторов — да: цвет метки
  /// в поле тот же, каким слово встанет на карточку, и это видно до нажатия.
  /// Для страны — нет: у страны нет категории вкуса, и серая метка честнее
  /// случайного цвета.
  final bool colored;

  @override
  State<TextInputWithHints> createState() => _TextInputWithHintsState();
}

class _TextInputWithHintsState extends State<TextInputWithHints> {
  /// Сколько совпадений показывать. Больше трёх меток отталкивают следующее
  /// поле вниз сильнее, чем помогают: справочник страны — одиннадцать строк,
  /// а дескрипторов — под сотню.
  static const int _maxHints = 3;

  late final FocusNode _focusNode;
  List<String> _matches = const [];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
    widget.controller.addListener(_refreshMatches);
  }

  @override
  void didUpdateWidget(TextInputWithHints oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_refreshMatches);
    widget.controller.addListener(_refreshMatches);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refreshMatches);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    if (_focusNode.hasFocus) {
      _refreshMatches();
      return;
    }
    setState(() => _matches = const []);
    widget.onEditingFinished?.call();
  }

  void _refreshMatches() {
    if (!mounted) return;

    final query = widget.controller.text.trim().toLowerCase();
    // Сначала те, что начинаются с набранного, потом те, где оно внутри.
    // На «ко» справочник страны отвечает «Колумбия» и «Коста-Рика», а не
    // «Никарагуа»: начало слова — то, что человек и набирал.
    final starts = <String>[];
    final inside = <String>[];
    if (query.isNotEmpty && _focusNode.hasFocus) {
      for (final hint in widget.hintsArray) {
        final lower = hint.toLowerCase();
        if (lower == query) continue;
        if (lower.startsWith(query)) {
          starts.add(hint);
        } else if (lower.contains(query)) {
          inside.add(hint);
        }
        if (starts.length >= _maxHints) break;
      }
    }
    final matches = [...starts, ...inside].take(_maxHints).toList();

    if (listEquals(matches, _matches)) return;
    setState(() => _matches = matches);
  }

  void _pick(String hint) {
    widget.controller.value = TextEditingValue(
      text: hint,
      selection: TextSelection.collapsed(offset: hint.length),
    );
    setState(() => _matches = const []);
    // Выбранная подсказка — законченный ввод: слово целиком, а не начало.
    widget.onEditingFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.labelText, style: context.texts.labelSmall),
        const SizedBox(height: AppSpacing.s1),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: TextInputAction.next,
          onChanged: widget.onChanged,
          onFieldSubmitted: (_) => widget.onEditingFinished?.call(),
          style: context.texts.bodyMedium,
          decoration: InputDecoration(hintText: widget.hintText),
        ),
        if (_matches.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s2),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              for (final hint in _matches)
                if (widget.colored)
                  DescriptorChip(word: hint, dense: true, onTap: () => _pick(hint))
                else
                  AppChip(label: hint, onTap: () => _pick(hint)),
            ],
          ),
        ],
      ],
    );
  }
}
