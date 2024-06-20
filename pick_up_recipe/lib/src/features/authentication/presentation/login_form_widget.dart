import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/routing/app_router.dart';

import '../../themes/app_theme.dart';
import '../provider/mocked_authentication_provider.dart';

class LoginFormWidget extends ConsumerStatefulWidget {
  const LoginFormWidget({super.key});

  @override
  ConsumerState<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends ConsumerState<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppTheme>() ?? AppTheme.defaultThemeData;

    return Column(
      children: [
        const Align(
          alignment: Alignment.topLeft,
          child: Text(
            'Войти в свой аккаунт',
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
                    borderSide: BorderSide(color: theme.secondaryColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty || !value.contains('@')) {
                    return 'Пожалуйста, введите действительный email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.secondaryColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty || value.length < 6) {
                    return 'Пароль должен содержать минимум 6 символов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        theme.primaryColor),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await ref.watch(authenticationProvider.notifier).login(_emailController.text, _passwordController.text);
                      if (mounted) {
                        if (context.router.canPop()) {
                          context.router.maybePop();
                        } else {
                          context.router.replace(const MainRoute());
                        }
                      }
                    }
                  },
                  child: Text(
                    'Войти',
                    style: TextStyle(
                        fontSize: 20,
                        color: theme.backgroundColor),
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
