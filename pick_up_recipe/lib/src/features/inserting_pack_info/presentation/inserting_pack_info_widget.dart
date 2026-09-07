import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/data_sources/remote/possible_values_service.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/info_inserting_date_widget.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/info_inserting_line_widget.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/info_inserting_number_widget.dart';
import 'package:pick_up_recipe/src/features/packs/application/state/active_packs_state.dart';
import 'package:pick_up_recipe/src/general_widgets/buttons/app_button.dart';

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
  final TextEditingController _dateInputController = TextEditingController();
  final TextEditingController _nameInputController = TextEditingController();
  final TextEditingController _scaScoreController = TextEditingController();
  final TextEditingController _varietyController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PossibleValuesService _possibleValuesService = PossibleValuesService();

  List<String> possibleCountries = [];
  List<String> possibleDescriptors = [];
  List<String> possibleName = [];
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
      possibleDescriptors =
          await _possibleValuesService.getByEndpoint('pack_descriptors') ?? [];
      possibleName =
          await _possibleValuesService.getByEndpoint('pack_name') ?? [];
      possibleVariety =
          await _possibleValuesService.getByEndpoint('pack_variety') ?? [];
      possibleProcessingMethods =
          await _possibleValuesService.getByEndpoint('pack_processing_method') ??
              [];
    } catch (e) {
      // Справочник подсказок — удобство, а не условие работы формы: без сети
      // поля остаются пустыми, но заполнить их руками по-прежнему можно.
      logger.e('Подсказки не загрузились', error: e);
    }
    if (!mounted) return;
    setState(() {});
  }

  /// Заполнить поля тем, что пришло в состояние извне — например, разобранным
  /// с фотографии пачки.
  ///
  /// Раньше это делалось на каждой перерисовке, и отсюда бралась «м» на
  /// карточке пачки: форма клала в состояние текст поля на каждое нажатие
  /// клавиши, а следующая перерисовка возвращала огрызок обратно в поле.
  /// Человек печатал «малиновый», в поле оставалась одна буква, и она же
  /// уезжала на сервер.
  void _seedFields(PackInfoFormState formState) {
    final snapshot = [
      formState.name,
      formState.country,
      formState.roastDate,
      formState.scaScore,
      formState.variety,
      formState.descriptors?.join(','),
      formState.processingMethod?.join(','),
    ].join('\u0000');

    if (snapshot == _seededFrom) return;
    _seededFrom = snapshot;

    _seedField(_nameInputController, formState.name);
    _seedField(_countryInputController, formState.country);
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
    for (var controller in _descriptorControllers) {
      controller.dispose();
    }
    for (var controller in _processingMethodControllers) {
      controller.dispose();
    }
    _countryInputController.dispose();
    _dateInputController.dispose();
    _nameInputController.dispose();
    _scaScoreController.dispose();
    _varietyController.dispose();
    super.dispose();
  }

  /// Набранное уезжает в состояние формы, когда ввод в поле закончен: по
  /// Enter, по уходу в соседнее поле или по выбору подсказки. Посимвольно
  /// этого делать нельзя — слово ещё не набрано.
  void _commitFields() {
    ref.read(formNotifierProvider.notifier).updateForm(
          name: _nameInputController.text,
          country: _countryInputController.text,
          scaScore: _scaScoreController.text,
          variety: _varietyController.text,
          processingMethod: _valuesOf(_processingMethodControllers),
          roastDate: _dateInputController.text,
          descriptors: _valuesOf(_descriptorControllers),
          image: ref.read(formNotifierProvider).image,
        );
  }

  /// Ввод в поле списка закончен: если это было последнее поле и в нём
  /// что-то есть, под ним появляется пустое — для следующего значения.
  void _commitListField(List<TextEditingController> controllers) {
    if (controllers.last.text.trim().isNotEmpty) {
      setState(() => controllers.add(TextEditingController()));
    }
    _commitFields();
  }

  void _cleanListControllers() {
    for (final controller in _descriptorControllers) {
      controller.dispose();
    }
    for (final controller in _processingMethodControllers) {
      controller.dispose();
    }

    _descriptorControllers.clear();
    _descriptorControllers.add(TextEditingController());

    _processingMethodControllers.clear();
    _processingMethodControllers.add(TextEditingController());
  }

  void _onSubmitTap() async {
    final formNotifier = ref.read(formNotifierProvider.notifier);

    if (_formKey.currentState!.validate()) {
      final descriptors = _valuesToSend(_descriptorControllers);
      final processingMethods = _valuesToSend(_processingMethodControllers);

      try {
        final name = _nameInputController.text;
        final country = _countryInputController.text;
        final scaScore = int.tryParse(_scaScoreController.text);
        final variety = _varietyController.text;
        final roastDate = _dateInputController.text;

        await formNotifier.submitForm(
          name: name,
          country: country,
          scaScore: scaScore ?? 0,
          variety: variety,
          processingMethod: processingMethods,
          roastDate: roastDate,
          descriptors: descriptors,
          image: ref.read(formNotifierProvider).image,
        );

        // todo remove await
        await ref.read(activePacksNotifierProvider.notifier).fetchPacks();
        _cleanListControllers();
        await formNotifier.cleanForm();
      } catch (e) {
        logger.e('Error submitting form', error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(formNotifierProvider).isSubmitting;
    final isLoading = ref.watch(formNotifierProvider).isLoading;
    final imageError = ref.watch(formNotifierProvider).imageErrorMessage;

    // Поля заполняются, только когда значения пришли извне. Прежний код звал
    // это из каждой перерисовки и затирал то, что человек набирает.
    ref.listen<PackInfoFormState>(
      formNotifierProvider,
      (_, next) => _seedFields(next),
    );

    return isLoading
        ? Center(
            child: SpinKitWaveSpinner(
              color: Theme.of(context).colorScheme.surface,
            ),
          )
        : Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageError != null)
                  Text(
                    'Error fetching information from pack image',
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.error),
                  ),
                _InputWidget(
                  title: 'Name',
                  child: TextInputWithHints(
                    hintsArray: possibleName,
                    labelText: 'Name',
                    controller: _nameInputController,
                    onEditingFinished: _commitFields,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                _InputWidget(
                  title: 'Country',
                  child: TextInputWithHints(
                    hintsArray: possibleCountries,
                    labelText: 'Country',
                    controller: _countryInputController,
                    onEditingFinished: _commitFields,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                _InputWidget(
                  title: 'SCA score',
                  child: NumberInput(
                    controller: _scaScoreController,
                    hintText: "SCA score",
                    minimalPercentageNumber: 70,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                AnimatedContainer(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(15),
                    ),
                  ),
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 12, top: 10),
                          child: Text(
                            'Descriptors',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _descriptorControllers.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: TextInputWithHints(
                              key: ValueKey('descriptor-$index'),
                              hintsArray: possibleDescriptors,
                              labelText: 'Descriptor ${index + 1}',
                              controller: _descriptorControllers[index],
                              onEditingFinished: () =>
                                  _commitListField(_descriptorControllers),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                _InputWidget(
                  title: 'Variety',
                  child: TextInputWithHints(
                    hintsArray: possibleVariety,
                    labelText: 'Variety',
                    controller: _varietyController,
                    onEditingFinished: _commitFields,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                AnimatedContainer(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(15),
                    ),
                  ),
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 12, top: 10),
                          child: Text(
                            'Processing methods',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _processingMethodControllers.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: TextInputWithHints(
                              key: ValueKey('processing-$index'),
                              hintsArray: possibleProcessingMethods,
                              labelText: 'Method ${index + 1}',
                              controller: _processingMethodControllers[index],
                              onEditingFinished: () => _commitListField(
                                _processingMethodControllers,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                DateInputField(
                  hintText: 'Roast date',
                  controller: _dateInputController,
                ),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: AppButton(
                    onTap: _onSubmitTap,
                    centerWidget: isSubmitting
                        ? const CircularProgressIndicator()
                        : Text(
                            'Отправить',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                    buttonStyle: AppButtonStyle.secondary,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                if (ref.watch(formNotifierProvider).errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      ref.watch(formNotifierProvider).errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          );
  }
}

class _InputWidget extends StatelessWidget {
  const _InputWidget({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.all(
          Radius.circular(15),
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 7),
              child: Text(
                title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
