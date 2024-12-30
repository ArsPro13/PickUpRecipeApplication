import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/core/styles.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/data_sources/remote/possible_values_service.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/info_inserting_date_widget.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/info_inserting_line_widget.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/info_inserting_number_widget.dart';
import 'package:pick_up_recipe/src/features/packs/application/state/active_packs_state.dart';

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

  @override
  void initState() {
    super.initState();
    _descriptorControllers.add(TextEditingController());
    _processingMethodControllers.add(TextEditingController());
    getPossibleValues();
  }

  void getPossibleValues() async {
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
    setState(() {});
  }

  void initFields() {
    final formState = ref.watch(formNotifierProvider);

    _nameInputController.text = formState.name ?? '';
    _countryInputController.text = formState.country ?? '';
    _dateInputController.text = formState.roastDate ?? '';
    _scaScoreController.text = formState.scaScore ?? '';
    _varietyController.text = formState.variety ?? '';

    if (_descriptorControllers.length <
        (formState.descriptors?.length ?? 0) + 1) {
      while (_descriptorControllers.length <=
          (formState.descriptors?.length ?? 0)) {
        _descriptorControllers.add(TextEditingController());
      }
      setState(() {});
    }
    for (var i = 0; i < (formState.descriptors?.length ?? 0); ++i) {
      _descriptorControllers[i].text = formState.descriptors![i];
    }

    if (_processingMethodControllers.length <
        (formState.processingMethod?.length ?? 0) + 1) {
      while (_processingMethodControllers.length <=
          (formState.processingMethod?.length ?? 0)) {
        _processingMethodControllers.add(TextEditingController());
      }
      setState(() {});
    }
    for (var i = 0; i < (formState.processingMethod?.length ?? 0); ++i) {
      _processingMethodControllers[i].text = formState.processingMethod![i];
    }
  }

  @override
  void dispose() {
    for (var controller in _descriptorControllers) {
      controller.dispose();
    }
    for (var controller in _processingMethodControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void updateState() {
    final name = _nameInputController.text;
    final country = _countryInputController.text;
    final scaScore = int.tryParse(_scaScoreController.text);
    final variety = _varietyController.text;
    final roastDate = _dateInputController.text;
    final processingMethods = ref.read(formNotifierProvider).processingMethod;
    final descriptors = ref.read(formNotifierProvider).descriptors;

    ref.read(formNotifierProvider.notifier).updateForm(
          name: name,
          country: country,
          scaScore: scaScore.toString(),
          variety: variety,
          processingMethod: processingMethods ?? [],
          roastDate: roastDate,
          descriptors: descriptors ?? [],
          image: ref.read(formNotifierProvider).image,
        );
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && _descriptorControllers.last.text == text) {
      final descriptors =
          _descriptorControllers.map((controller) => controller.text).toList();
      ref
          .read(formNotifierProvider.notifier)
          .updateDescriptors(descriptors: descriptors);
      updateState();
      setState(() {
        _descriptorControllers.add(TextEditingController());
      });
    }
    if (text.isNotEmpty && _processingMethodControllers.last.text == text) {
      final descriptors = _processingMethodControllers
          .map((controller) => controller.text)
          .toList();
      ref
          .read(formNotifierProvider.notifier)
          .updateDescriptors(descriptors: descriptors);
      updateState();
      setState(() {
        _processingMethodControllers.add(TextEditingController());
      });
    }
  }

  void _cleanListControllers() {
    _descriptorControllers.map((controller) => controller.dispose());
    _processingMethodControllers.map((controller) => controller.dispose());

    _descriptorControllers.clear();
    _descriptorControllers.add(TextEditingController());

    _processingMethodControllers.clear();
    _processingMethodControllers.add(TextEditingController());
  }

  void _onSubmitTap() async {
    final formNotifier = ref.read(formNotifierProvider.notifier);

    if (_formKey.currentState!.validate()) {
      List<String> descriptors = _descriptorControllers
          .map((c) => c.text)
          .where((text) => text.isNotEmpty)
          .toList();

      List<String> processingMethods = _processingMethodControllers
          .map((c) => c.text)
          .where((text) => text.isNotEmpty)
          .toList();

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

        logger.e('roast date: $roastDate');

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

    Future(() {
      initFields();
    });

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
                    onChanged: _onTextChanged,
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
                    onChanged: _onTextChanged,
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
                    minimalPercentageNumber: 80,
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
                              hintsArray: possibleDescriptors,
                              labelText: 'Descriptor ${index + 1}',
                              controller: _descriptorControllers[index],
                              onChanged: _onTextChanged,
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
                    onChanged: _onTextChanged,
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
                              hintsArray: possibleProcessingMethods,
                              labelText: 'Method ${index + 1}',
                              controller: _processingMethodControllers[index],
                              onChanged: _onTextChanged,
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
                  height: 50,
                  child: ElevatedButton(
                    style: secondaryButtonStyle(context),
                    onPressed: _onSubmitTap,
                    child: isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('Отправить'),
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
