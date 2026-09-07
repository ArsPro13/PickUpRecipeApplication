// Свой тип шага: заготовка, которая останется у вас для этого прибора.
//
// По макету S07. Три поля и ни одним больше: подпись, значок из набора и
// способ завершения. Значок выбирается из фиксированного набора — свои
// картинки нельзя (ответ C12 про валидацию icon): чужой файл не перекрасится
// под тему и не отмасштабируется в строке списка.
//
// Шаг привязан к методу: в рецептах на других приборах он не появится.
// Воду такой шаг не считает — для воды есть «пролив».

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../features/recipes/application/step_types_state.dart';
import '../features/recipes/domain/models/user_step_type_model.dart';
import '../general_widgets/app_field.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../general_widgets/step_ending_choice.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

/// Значки, из которых можно выбрать. Набор шагов, без приборных: значок
/// должен читаться в строке списка при 20 px.
const _iconChoices = [
  'press', 'swirl', 'stir', 'pour', 'grind', 'serve', 'note', 'custom',
];

@RoutePage()
class CustomStepPage extends ConsumerStatefulWidget {
  const CustomStepPage({
    super.key,
    required this.brewMethodId,
    this.methodName,
  });

  final int brewMethodId;
  final String? methodName;

  @override
  ConsumerState<CustomStepPage> createState() => _CustomStepPageState();
}

class _CustomStepPageState extends ConsumerState<CustomStepPage> {
  final TextEditingController _label = TextEditingController();

  String _icon = 'custom';
  StepEndsWith _endsWith = StepEndsWith.timer;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _label.text.trim();
    if (label.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).customStepNoLabel);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final created = await ref.read(stepTypeServiceProvider).createUserStepType(
            brewMethodId: widget.brewMethodId,
            label: label,
            icon: _icon,
            endsWith: _endsWith,
          );
      // Лист выбора читает заготовки из провайдера — без инвалидации новая
      // появится там только после перезапуска.
      ref.invalidate(userStepTypesProvider(widget.brewMethodId));
      if (!mounted) return;
      context.router.maybePop(created);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final method = widget.methodName;
    final texts = AppLocalizations.of(context);

    return AppScreen(
      title: texts.customStepTitle,
      body: [
        if (method != null)
          Text(texts.customStepForMethod(method), style: context.texts.bodySmall),
        const SizedBox(height: AppSpacing.s4),
        AppField(
          controller: _label,
          label: texts.customStepLabelField,
          hint: texts.customStepLabelHint,
          error: _error,
        ),
        const SizedBox(height: AppSpacing.s5),
        Text(texts.customStepIcon, style: context.texts.labelSmall),
        const SizedBox(height: AppSpacing.s2),
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: [
            for (final icon in _iconChoices)
              _IconChoice(
                icon: icon,
                selected: icon == _icon,
                onTap: () => setState(() => _icon = icon),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s5),
        Text(texts.stepEndsWith, style: context.texts.labelSmall),
        const SizedBox(height: AppSpacing.s2),
        StepEndingChoice(
          value: _endsWith,
          onChanged: (option) => setState(() => _endsWith = option),
        ),
        const SizedBox(height: AppSpacing.s5),
        QuietSurface(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(AppIcons.uiInfo, size: AppSizes.icon20, color: context.colors.secondary),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  texts.customStepNote(method ?? texts.customStepThisDevice),
                  style: context.texts.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: [
        AppButton(
          label: _saving ? texts.saving : texts.customStepSave,
          icon: AppIcons.uiCheck,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({required this.icon, required this.selected, required this.onTap});

  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s3),
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: selected ? context.colors.primary : context.palette.border,
              width: selected ? AppStroke.thick : AppStroke.thin,
            ),
          ),
          child: AppIcon(
            AppIcons.step(icon),
            size: AppSizes.icon24,
            color: selected ? context.colors.primary : context.colors.onSurface,
          ),
        ),
      ),
    );
  }
}
