import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:pick_up_recipe/main.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/info_inserting_date_widget.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/info_inserting_line_widget.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/info_inserting_number_widget.dart';
import 'package:pick_up_recipe/src/features/packs/application/state/active_packs_state.dart';

class InsertingPackInfoWidget extends ConsumerStatefulWidget {
  const InsertingPackInfoWidget({super.key});

  @override
  _InsertingPackInfoWidgetState createState() =>
      _InsertingPackInfoWidgetState();
}

const specialtyCoffeeDescriptors = ['aaa', 'bbb', 'aabbb', 'acccc'];

class _InsertingPackInfoWidgetState
    extends ConsumerState<InsertingPackInfoWidget> {
  final List<TextEditingController> _descriptorControllers = [];
  final TextEditingController _countryInputController = TextEditingController();
  final TextEditingController _dateInputController = TextEditingController();
  final TextEditingController _nameInputController = TextEditingController();
  final TextEditingController _scaScoreController = TextEditingController();
  final TextEditingController _varietyController = TextEditingController();
  final TextEditingController _processingMethodInputController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _descriptorControllers.add(TextEditingController());
  }

  void initFields() {
    final formState = ref.watch(formNotifierProvider);

    _nameInputController.text = formState.name ?? '';
    _countryInputController.text = formState.country ?? '';
    _dateInputController.text = formState.roastDate ?? '';
    _scaScoreController.text = formState.scaScore ?? '';
    _varietyController.text = formState.variety ?? '';
    _processingMethodInputController.text = formState.processingMethod ?? '';

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
  }

  @override
  void dispose() {
    for (var controller in _descriptorControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && _descriptorControllers.last.text == text) {
      setState(() {
        _descriptorControllers.add(TextEditingController());
      });
    }
  }

  void _onSubmitTap() async {
    // final formState = ref.watch(formNotifierProvider);
    final formNotifier = ref.read(formNotifierProvider.notifier);

    if (_formKey.currentState!.validate()) {
      List<String> descriptors = _descriptorControllers
          .map((c) => c.text)
          .where((text) => text.isNotEmpty)
          .toList();

      try {
        formNotifier.submitForm(
          name: _nameInputController.text,
          country: _countryInputController.text,
          scaScore: int.tryParse(_scaScoreController.text) ?? 0,
          variety: _varietyController.text,
          processingMethod: _processingMethodInputController.text,
          roastDate: _dateInputController.text,
          descriptors: descriptors,
          image: ref
              .read(formNotifierProvider)
              .image,
        );
        await ref.read(activePacksNotifierProvider.notifier).fetchPacks();
      } catch (e) {
        logger.e('Error submitting form', error: e);
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    Future(() {
      initFields();
    });
    final isLoading = ref.watch(formNotifierProvider).isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InputWidget(
            title: 'Name',
            child: TextInputWithHints(
              hintsArray: specialtyCoffeeDescriptors,
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
              hintsArray: specialtyCoffeeDescriptors,
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
                        hintsArray: specialtyCoffeeDescriptors,
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
              hintsArray: specialtyCoffeeDescriptors,
              labelText: 'Variety',
              controller: _varietyController,
              onChanged: _onTextChanged,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          _InputWidget(
            title: 'Processing method',
            child: TextInputWithHints(
              hintsArray: specialtyCoffeeDescriptors,
              labelText: 'Processing method',
              controller: _processingMethodInputController,
              onChanged: _onTextChanged,
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
              onPressed: _onSubmitTap,
              child: isLoading
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
  const _InputWidget({super.key, required this.title, required this.child});

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
