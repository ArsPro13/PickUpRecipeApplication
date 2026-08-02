// Экран 01 «Сканировать» — вкладка, а не камера.
//
// Вкладка ведёт сюда, а не сразу в видоискатель (ответ на вопрос 32): путей
// здесь три — камера, ручной ввод кода и «кода нет вовсе», — и камера,
// открытая на весь экран, прячет два из них.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../routing/app_router.dart';
import '../features/codes/domain/pack_code.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final TextEditingController _code = TextEditingController();

  /// Ошибка разбора кода. Показывается до похода на сервер: контрольный
  /// символ ловит опечатку локально, и незачем гонять запрос ради этого.
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final entered = _code.text;
    final normalized = PackCode.normalize(entered);

    setState(() => _error = PackCode.validationError(normalized));
    if (_error != null) return;

    context.router.push(CoffeeRoute(code: normalized));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сканировать')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          AppCard(
            onTap: () => context.router.push(const RecognitionCameraRoute()),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s6,
            ),
            child: Column(
              children: [
                AppIcon(
                  AppIcons.uiScan,
                  size: AppSizes.icon48,
                  color: context.colors.primary,
                ),
                const SizedBox(height: AppSpacing.s3),
                Text('Навести камеру на QR', style: context.texts.titleMedium),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  'Код на упаковке ведёт прямо на рецепт обжарщика',
                  style: context.texts.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SectionTitle('Или введите код с упаковки'),
          TextField(
            controller: _code,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            inputFormatters: [
              // Код печатается с дефисами, вводится как угодно: приводим к
              // печатному виду на лету, чтобы человек видел то же, что на пачке.
              TextInputFormatter.withFunction((oldValue, newValue) {
                final formatted = PackCode.format(PackCode.normalize(newValue.text));
                return TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }),
            ],
            decoration: InputDecoration(
              hintText: 'ABCD-2345-68',
              errorText: _error,
              prefixIcon: Padding(
                padding: const EdgeInsets.all(AppSpacing.s3),
                child: AppIcon(
                  AppIcons.uiPack,
                  size: AppSizes.icon20,
                  color: context.colors.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          AppButton(label: 'Найти кофе', onPressed: _submit),
          const SectionTitle('Кода на упаковке нет'),
          AppButton(
            label: 'Добавить пачку по фото',
            icon: AppIcons.uiCamera,
            kind: AppButtonKind.secondary,
            onPressed: () => context.router.push(const RecognitionCameraRoute()),
          ),
        ],
      ),
    );
  }
}
