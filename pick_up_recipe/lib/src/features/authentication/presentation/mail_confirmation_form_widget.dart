import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pick_up_recipe/src/features/authentication/provider/authentication_page_state_notifier.dart';
import 'package:pick_up_recipe/src/features/authentication/provider/authentication_state_notifier.dart';
import 'package:pick_up_recipe/src/general_widgets/buttons/app_button.dart';
import 'package:pick_up_recipe/src/pages/authentication_page.dart';

class MailConfirmationFormWidget extends ConsumerStatefulWidget {
  const MailConfirmationFormWidget({
    super.key,
    required this.mail,
  });

  final String mail;

  @override
  ConsumerState<MailConfirmationFormWidget> createState() =>
      _MailConfirmationFormWidgetState();
}

class _MailConfirmationFormWidgetState
    extends ConsumerState<MailConfirmationFormWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _error = '';

  final TextEditingController _codeController = TextEditingController();

  void _onSubmitTap() async {
    try {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
        });
        await ref.read(authenticationStateNotifierProvider.notifier).verifyMail(
              widget.mail,
              _codeController.text,
            );
        _error = '';
        ref
            .read(authenticationPageStateNotifierProvider.notifier)
            .switchMode(AuthPageMode.login);
      }
    } catch (e) {
      _error = e.toString();
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Align(
          alignment: Alignment.topLeft,
          child: Text(
            'Confirm your e-mail address',
            style: TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Confirmation code',
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.secondary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty || value.length != 6) {
                    return 'Code must contain 6 symbols';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                _error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: AppButton(
                  onTap: _onSubmitTap,
                  centerWidget: _isLoading
                      ? SpinKitWaveSpinner(
                          color: Theme.of(context).colorScheme.surface,
                        )
                      : Text(
                          'Confirm email',
                          style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                  buttonStyle: AppButtonStyle.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
