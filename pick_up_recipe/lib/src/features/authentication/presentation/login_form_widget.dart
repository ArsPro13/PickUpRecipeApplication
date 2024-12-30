import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/authentication/provider/authentification_provider_impl.dart';

class LoginFormWidget extends ConsumerStatefulWidget {
  const LoginFormWidget({super.key});

  @override
  ConsumerState<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends ConsumerState<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _error = '';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _onSubmitTap() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
        });

        await ref.read(authenticationProvider.notifier).login(
              _emailController.text,
              _passwordController.text,
            );

        if (mounted) {
          context.router.replace(const MainRoute());
        }
        _error = '';
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Align(
          alignment: Alignment.topLeft,
          child: Text(
            'Sign in to account',
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
                    return 'Enter existing email';
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
                    return 'Password must contain minimum 6 symbols';
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
                        Theme.of(context).colorScheme.primary),
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
                          'Sign in',
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
