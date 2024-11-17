import 'package:auto_route/annotations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/src/features/authentication/presentation/mail_confirmation_form_widget.dart';
import 'package:pick_up_recipe/src/features/authentication/provider/authentication_state_notifier.dart';
import '../features/authentication/presentation/login_form_widget.dart';
import '../features/authentication/presentation/registration_form_widget.dart';

@RoutePage()
class AuthenticationPage extends ConsumerStatefulWidget {
  const AuthenticationPage({super.key});

  @override
  ConsumerState<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends ConsumerState<AuthenticationPage> {
  void toggleMode(AuthPageMode oldMode, WidgetRef ref) {
    switch (oldMode) {
      case AuthPageMode.registration:
        ref
            .read(authenticationStateNotifierProvider.notifier)
            .switchMode(AuthPageMode.login);
      case AuthPageMode.login:
        ref
            .read(authenticationStateNotifierProvider.notifier)
            .switchMode(AuthPageMode.registration);
      case AuthPageMode.verifyMail:
        ref
            .read(authenticationStateNotifierProvider.notifier)
            .switchMode(AuthPageMode.login);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(authenticationStateNotifierProvider).mode;
    final mail = ref.read(authenticationStateNotifierProvider).email ?? '';

    final body = switch (mode) {
      AuthPageMode.registration => const RegistrationFormWidget(),
      AuthPageMode.login => const LoginFormWidget(),
      AuthPageMode.verifyMail => MailConfirmationFormWidget(mail: mail),
    };

    final buttonTitle = switch (mode) {
      AuthPageMode.registration => "Have an account? Sign in",
      AuthPageMode.verifyMail => "Have an account? Sign in",
      AuthPageMode.login => "Not registered? Sign up",
    };

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.only(top: 50, left: 60, right: 60),
        child: ListView(
          children: [
            const Align(
                alignment: Alignment.center,
                child: Text(
                  'PickUpRecipe',
                  style: TextStyle(fontSize: 30),
                )),
            const SizedBox(
              height: 50,
            ),
            body,
            const SizedBox(height: 60),
            SizedBox(
              height: 60,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(
                      Theme.of(context).colorScheme.secondaryContainer),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                onPressed: () => toggleMode(mode, ref),
                child: Text(
                  buttonTitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AuthPageMode {
  registration,
  login,
  verifyMail,
}
