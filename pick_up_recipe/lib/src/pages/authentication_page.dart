import 'package:auto_route/annotations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../features/authentication/presentation/login_form_widget.dart';
import '../features/authentication/presentation/registration_form_widget.dart';

@RoutePage()
class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() =>
      _AuthenticationPageState();
}

class _AuthenticationPageState
    extends State<AuthenticationPage> {
  bool isRegistration = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
            isRegistration ? const RegistrationFormWidget() : const LoginFormWidget(),
            const SizedBox(height: 60,),
            SizedBox(
              height: 60,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      Theme.of(context).colorScheme.onBackground),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
                      )),
                ),
                onPressed: () {
                  setState(() {
                    isRegistration = !isRegistration;
                  });
                },
                child: Text(
                  isRegistration ? 'Войти в аккаунт' : 'Зарегистрировать новый аккаунт',
                  style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.secondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
