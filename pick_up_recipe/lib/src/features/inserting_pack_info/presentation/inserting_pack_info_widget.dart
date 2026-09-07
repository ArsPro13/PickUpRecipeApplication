// Форма пачки без кода: всё, что человек видит на чужой упаковке.
//
// Экран собран из набора: подписи над полями, метки-подсказки, поднятая
// поверхность под главным блоком — как на остальных экранах. Раньше форма
// жила по своим правилам: половина подписей по-английски, свои скругления,
// свой выпадающий список и старая кнопка из другого набора.
//
// Поля «Название» здесь нет: владелец назвал его непонятным. Имя пачки
// собирается из страны и региона — см. domain/pack_title.dart.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/data_sources/remote/possible_values_service.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/info_inserting_camera_widget.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/info_inserting_date_widget.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/info_inserting_line_widget.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/info_inserting_number_widget.dart';
import 'package:pick_up_recipe/src/general_widgets/app_icon.dart';
import 'package:pick_up_recipe/src/general_widgets/app_kit.dart';
import 'package:pick_up_recipe/src/general_widgets/app_layout.dart';
import 'package:pick_up_recipe/src/themes/app_icons.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';

class InsertingPackInfoWidget extends ConsumerStatefulWidget {
  const InsertingPackInfoWidget({super.key});

  @override
  ConsumerState<InsertingPackInfoWidget> createState() =>
      _InsertingPackInfoWidgetState();
}

class _InsertingPackInfoWidgetState
    extends ConsumerState<InsertingPackInfoWidget> {
  final List<TextEditingController> _descriptorControllers = [];
  final List<TextEditingController> _processingMethodControllers = [];
  final TextEditingController _countryInputController = TextEditingController();
  final TextEditingController _regionInputController = TextEditingController();
  final TextEditingController _dateInputController = TextEditingController();
  final TextEditingController _scaScoreController = TextEditingController();
  final TextEditingController _varietyController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PossibleValuesService _possibleValuesService = PossibleValuesService();

  List<String> possibleCountries = [];
  List<String> possibleRegions = [];
  List<String> possibleDescriptors = [];
  List<String> possibleVariety = [];
  List<String> possibleProcessingMethods = [];

  /// Снимок значений, которыми поля уже заполнены. Пока он не изменился,
  /// поля трогать нельзя: в них печатает человек.
  String? _seededFrom;

  @override
  void initState() {
    super.initState();
    _descriptorControllers.add(TextEditingController());
    _processingMethodControllers.add(TextEditingController());
    _seedFields(ref.read(formNotifierProvider));
    getPossibleValues();
  }

  void getPossibleValues() async {
    try {
      possibleCountries =
          await _possibleValuesService.getByEndpoint('pack_country') ?? [];
      // Справочник регионов на сервере есть — три сотни значений, — но по
      // имени pack_region он пока не отдаётся: в text_interpreter нет такой
      // пары имён. Запрос стоит здесь заранее: подсказки включатся сами,
      // как только пару добавят, а до тех пор поле работает как обычное.
      possibleRegions =
          await _possibleValuesService.getByEndpoint('pack_region') ?? [];
      possibleDescriptors =
          await _possibleValuesService.getByEndpoint('pack_descriptors') ?? [];
      possibleVariety =
          await _possibleValuesService.getByEndpoint('pack_variety') ?? [];
      possibleProcessingMethods =
          await _possibleValuesService.getByEndpoint('pack_processing_method') ??
              [];
    } catch (e) {
      // Справочник подсказок — удобство, а не условие работы формы: без сети
      // подсказок не будет, а заполнить поля руками по-прежнему можно.
      logger.e('Подсказки не загрузились', error: e);
    }
    if (!mounted) return;
    setState(() {});
  }

  /// Заполнить поля тем, что пришло в состояние извне, — например, разобранным
  /// с фотографии пачки, когда распознавание вернут.
  ///
  /// Раньше это делалось на каждой перерисовке, и отсюда бралась «м» на
  /// карточке пачки: форма клала в состояние текст поля на каждое нажатие
  /// клавиши, а следующая перерисовка возвращала огрызок обратно в поле.
  void _seedFields(PackInfoFormState formState) {
    final snapshot = [
      formState.country,
      formState.region,
      formState.roastDate,
      formState.scaScore,
      formState.variety,
      formState.descriptors?.join(','),
      formState.processingMethod?.join(','),
    ].join('|');

    if (snapshot == _seededFrom) return;
    _seededFrom = snapshot;

    _seedField(_countryInputController, formState.country);
    _seedField(_regionInputController, formState.region);
    _seedField(_dateInputController, formState.roastDate);
    _seedField(_scaScoreController, formState.scaScore);
    _seedField(_varietyController, formState.variety);

    _seedList(_descriptorControllers, formState.descriptors);
    _seedList(_processingMethodControllers, formState.processingMethod);
  }

  static void _seedField(TextEditingController controller, String? value) {
    final text = value ?? '';
    if (controller.text == text) return;
    controller.text = text;
  }

  /// Заполнить список полей. Если в полях уже стоит ровно то же самое — это
  /// вернулась наша собственная запись, и трогать их незачем.
  void _seedList(
    List<TextEditingController> controllers,
    List<String>? values,
  ) {
    final incoming = values ?? const <String>[];
    if (listEquals(_valuesOf(controllers), incoming)) return;

    while (controllers.length <= incoming.length) {
      controllers.add(TextEditingController());
    }
    for (var i = 0; i < controllers.length; ++i) {
      controllers[i].text = i < incoming.length ? incoming[i] : '';
    }
  }

  /// Что набрано в списке полей: без пустых и без крайних пробелов.
  static List<String> _valuesOf(List<TextEditingController> controllers) => [
        for (final controller in controllers)
          if (controller.text.trim().isNotEmpty) controller.text.trim(),
      ];

  /// Что из списка не стыдно отправить на сервер.
  ///
  /// Одиночная буква — не дескриптор, а огрызок недопечатанного слова: такие
  /// «м» и висели на карточке пачки в разделе «Обжарщик обещает».
  /// Однобуквенных дескрипторов у кофе не бывает, и проще не пускать их вовсе.
  static List<String> _valuesToSend(List<TextEditingController> controllers) =>
      _valuesOf(controllers).where((value) => value.length > 1).toList();

  @override
  void dispose() {
    for (final controller in _descriptorControllers) {
      controller.dispose();
    }
    for (final controller in _processingMethodControllers) {
      controller.dispose();
    }
    _countryInputController.dispose();
    _regionInputController.dispose();
    _dateInputController.dispose();
    _scaScoreController.dispose();
    _varietyController.dispose();
    super.dispose();
  }

  /// Набранное уезжает в состояние формы, когда ввод в поле закончен: по
  /// «далее», по уходу в соседнее поле или по выбору подсказки. Посимвольно
  /// этого делать нельзя — слово ещё не набрано.
  void _commitFields() {
    ref.read(formNotifierProvider.notifier).updateForm(
          country: _countryInputController.text,
          region: _regionInputController.text,
          scaScore: _scaScoreController.text,
          variety: _varietyController.text,
          processingMethod: _valuesOf(_processingMethodControllers),
          roastDate: _dateInputController.text,
          descriptors: _valuesOf(_descriptorControllers),
          image: ref.read(formNotifierProvider).image,
        );
  }

  /// Ещё одно поле в списке — по кнопке.
  ///
  /// Раньше следующее поле выскакивало само на первой набранной букве, и
  /// форма росла быстрее, чем человек печатал: два дескриптора превращались
  /// в шесть пустых строк.
  void _addField(List<TextEditingController> controllers) {
    setState(() => controllers.add(TextEditingController()));
  }

  void _removeField(List<TextEditingController> controllers, int index) {
    final removed = controllers[index];
    setState(() => controllers.removeAt(index));
    _commitFields();

    // Освобождаем после перерисовки: пока кадр не собран заново, поле с этим
    // контроллером ещё висит в дереве.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _onSubmitTap() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Сначала собираем набранное: последнее поле человек мог не закрыть —
    // с открытой клавиатурой ввод в нём формально не закончен.
    _commitFields();

    await ref.read(formNotifierProvider.notifier).submitForm(
          country: _countryInputController.text.trim(),
          region: _regionInputController.text.trim(),
          scaScore: int.tryParse(_scaScoreController.text.trim()) ?? 0,
          variety: _varietyController.text.trim(),
          processingMethod: _valuesToSend(_processingMethodControllers),
          roastDate: _dateInputController.text.trim(),
          descriptors: _valuesToSend(_descriptorControllers),
          image: ref.read(formNotifierProvider).image,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(formNotifierProvider);

    // Поля заполняются, только когда значения пришли извне. Прежний код звал
    // это из каждой перерисовки и затирал то, что человек набирает.
    ref.listen<PackInfoFormState>(
      formNotifierProvider,
      (_, next) => _seedFields(next),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Впишите, что написано на пачке. Обязательна только страна — '
            'из неё и региона соберётся название.',
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: AppSpacing.s4),
          const InsertingPackInfoCameraWidget(),
          const SizedBox(height: AppSpacing.s5),
          HeroSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextInputWithHints(
                  key: const ValueKey('country'),
                  hintsArray: possibleCountries,
                  labelText: 'Страна',
                  hintText: 'Бразилия',
                  controller: _countryInputController,
                  onEditingFinished: _commitFields,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Без страны пачку нечем назвать'
                      : null,
                ),
                const SizedBox(height: AppSpacing.s4),
                TextInputWithHints(
                  key: const ValueKey('region'),
                  hintsArray: possibleRegions,
                  labelText: 'Регион — если знаете',
                  hintText: 'Серрадо',
                  controller: _regionInputController,
                  onEditingFinished: _commitFields,
                ),
                const SizedBox(height: AppSpacing.s4),
                TextInputWithHints(
                  key: const ValueKey('variety'),
                  hintsArray: possibleVariety,
                  labelText: 'Сорт',
                  hintText: 'бурбон',
                  controller: _varietyController,
                  onEditingFinished: _commitFields,
                ),
                const SizedBox(height: AppSpacing.s4),
                NumberInput(
                  key: const ValueKey('sca'),
                  controller: _scaScoreController,
                  labelText: 'Оценка SCA',
                  hintText: '86',
                  minimalPercentageNumber: 70,
                  onEditingFinished: _commitFields,
                ),
                const SizedBox(height: AppSpacing.s4),
                DateInputField(
                  key: const ValueKey('roast-date'),
                  labelText: 'Дата обжарки',
                  controller: _dateInputController,
                  onEditingFinished: _commitFields,
                ),
              ],
            ),
          ),
          _listSection(
            title: 'Дескрипторы',
            note: 'Чем пахнет и какой на вкус — по слову в строке',
            keyPrefix: 'descriptor',
            controllers: _descriptorControllers,
            hints: possibleDescriptors,
            fieldLabel: 'Дескриптор',
            hintText: 'малина',
            addLabel: 'Добавить дескриптор',
          ),
          _listSection(
            title: 'Способ обработки',
            note: 'Обычно написан на пачке рядом с сортом',
            keyPrefix: 'processing',
            controllers: _processingMethodControllers,
            hints: possibleProcessingMethods,
            fieldLabel: 'Обработка',
            hintText: 'мытая',
            addLabel: 'Добавить обработку',
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.s4),
            _FailurePlate(reason: state.errorMessage!),
          ],
          const SizedBox(height: AppSpacing.s6),
          AppButton(
            label: 'Отправить',
            icon: AppIcons.uiCheck,
            loading: state.isSubmitting,
            onPressed: _onSubmitTap,
          ),
        ],
      ),
    );
  }

  /// Раздел со списком значений: поля, кнопка «добавить ещё» и корзина у
  /// лишней строки.
  Widget _listSection({
    required String title,
    required String note,
    required String keyPrefix,
    required List<TextEditingController> controllers,
    required List<String> hints,
    required String fieldLabel,
    required String hintText,
    required String addLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title),
        Text(note, style: context.texts.labelSmall),
        const SizedBox(height: AppSpacing.s3),
        for (var index = 0; index < controllers.length; ++index) ...[
          if (index > 0) const SizedBox(height: AppSpacing.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextInputWithHints(
                  key: ValueKey('$keyPrefix-$index'),
                  hintsArray: hints,
                  labelText: '$fieldLabel ${index + 1}',
                  hintText: hintText,
                  controller: controllers[index],
                  onEditingFinished: _commitFields,
                ),
              ),
              if (controllers.length > 1)
                Padding(
                  // Ровняем корзину по самому полю, а не по подписи над ним.
                  padding: const EdgeInsets.only(top: AppSpacing.s4),
                  child: IconButton(
                    onPressed: () => _removeField(controllers, index),
                    tooltip: 'Убрать строку',
                    icon: AppIcon(
                      AppIcons.uiTrash,
                      size: AppSizes.icon20,
                      color: context.colors.secondary,
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.s3),
        AppButton(
          label: addLabel,
          icon: AppIcons.uiPlus,
          kind: AppButtonKind.secondary,
          onPressed: () => _addField(controllers),
        ),
      ],
    );
  }
}

/// Пачка не уехала: сеть или сервер. Не тупик — набранное осталось в полях.
class _FailurePlate extends StatelessWidget {
  const _FailurePlate({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return QuietSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            AppIcons.uiWarning,
            size: AppSizes.icon20,
            color: context.colors.error,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Пачка не отправилась',
                  style: context.texts.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                // Набранное никуда не делось: повторить можно той же кнопкой.
                Text(
                  '$reason. Набранное осталось — попробуйте ещё раз.',
                  style: context.texts.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
