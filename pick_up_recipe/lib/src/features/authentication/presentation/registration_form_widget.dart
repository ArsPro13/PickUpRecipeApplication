import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:pick_up_recipe/src/features/authentication/provider/authentication_page_state_notifier.dart';
import 'package:pick_up_recipe/src/features/authentication/provider/authentication_state_notifier.dart';
import 'package:pick_up_recipe/src/pages/authentication_page.dart';

class RegistrationFormWidget extends ConsumerStatefulWidget {
  const RegistrationFormWidget({super.key});

  @override
  ConsumerState<RegistrationFormWidget> createState() =>
      _RegistrationFormWidgetState();
}

class _RegistrationFormWidgetState
    extends ConsumerState<RegistrationFormWidget> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  String _error = '';

  void _onSubmitTap() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_formKey.currentState!.validate()) {
        final email = _emailController.text;
        await ref.watch(authenticationStateNotifierProvider.notifier).register(
              email,
              _passwordController.text,
            );
        ref
            .read(authenticationPageStateNotifierProvider.notifier)
            .switchMode(AuthPageMode.verifyMail);
        ref
            .read(authenticationPageStateNotifierProvider.notifier)
            .updateEmail(email);
      }
      _error = '';
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
            'Create new account',
            style: TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.secondary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty || !value.contains('@')) {
                    return 'Enter existing email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.secondary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty || value.length < 6) {
                    return 'Password must contain minimum of 6 symbols';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.secondary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
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
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    )),
                  ),
                  onPressed: _onSubmitTap,
                  child: _isLoading
                      ? SpinKitWaveSpinner(
                          color: Theme.of(context).colorScheme.surface,
                        )
                      : Text(
                          'Sign up',
                          style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
