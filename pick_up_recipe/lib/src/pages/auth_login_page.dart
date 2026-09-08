// Экран входа.
//
// Ошибка разбирается по коду ответа и живёт у того поля, в котором произошла.
// Раньше сюда падал e.toString() одной строкой над формой — человек видел
// «Exception: Failed to login user» и не понимал, что именно перенабирать.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../features/authentication/domain/auth_rules.dart';
import '../features/authentication/provider/authentication_state_notifier.dart';
import '../general_widgets/app_field.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import 'auth_rule_texts.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class AuthLoginPage extends ConsumerStatefulWidget {
  const AuthLoginPage({super.key, @QueryParam('email') this.email});

  final String? email;

  @override
  ConsumerState<AuthLoginPage> createState() => _AuthLoginPageState();
}

class _AuthLoginPageState extends ConsumerState<AuthLoginPage> {
  // В отладочной сборке поля приходят заполненными демо-аккаунтом: иначе
  // каждый запуск начинается с набора почты и пароля руками. Почта из
  // маршрута важнее — на вход приводит «забыли пароль» с конкретным адресом.
  late final TextEditingController _email =
      TextEditingController(text: widget.email ?? Config.devLoginEmail);
  late final TextEditingController _password =
      TextEditingController(text: Config.devLoginPassword);

  String? _emailError;
  String? _passwordError;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final texts = AppLocalizations.of(context);

    setState(() {
      _emailError = AuthRules.emailProblem(_email.text)?.text(texts);
      _passwordError = AuthRules.passwordProblem(_password.text)?.text(texts);
    });
    if (_emailError != null || _passwordError != null) return;

    setState(() => _busy = true);

    try {
      await ref
          .read(authenticationStateNotifierProvider.notifier)
          .login(_email.text.trim(), _password.text);
      if (mounted) await context.router.replaceAll([const RootRoute()]);
    } on AuthFailure catch (failure) {
      if (!mounted) return;

      // Почта не подтверждена — это не ошибка формы, а недоделанный шаг:
      // уводим на ввод кода, а не оставляем перебирать пароль.
      if (failure.emailNotVerified) {
        await context.router.push(AuthVerifyRoute(email: _email.text.trim()));
        return;
      }

      setState(() {
        // 401 — это про пару целиком, и подписывать ею одну только почту
        // значило бы указать не туда.
        _passwordError = failure.text(texts);
      });
    } catch (_) {
      if (mounted) setState(() => _passwordError = AuthFailure.offline.text(texts));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return AppScreen(
      showNav: false,
      title: texts.loginTitle,
      body: [
        HeroSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppField(
                label: texts.fieldEmail,
                controller: _email,
                icon: AppIcons.uiMail,
                hint: 'you@example.com',
                error: _emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
              ),
              const SizedBox(height: AppSpacing.s4),
              AppField(
                label: texts.fieldPassword,
                controller: _password,
                icon: AppIcons.uiLock,
                obscure: true,
                error: _passwordError,
                textInputAction: TextInputAction.go,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_passwordError != null) setState(() => _passwordError = null);
                },
              ),
              const SizedBox(height: AppSpacing.s2),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.router.push(
                    PasswordResetRoute(email: _email.text.trim()),
                  ),
                  child: Text(
                    texts.loginForgot,
                    style: context.texts.bodySmall?.copyWith(color: context.colors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: [
        AppButton(label: texts.authSignIn, loading: _busy, onPressed: _busy ? null : _submit),
        SwapLine(
          question: texts.loginNoAccount,
          action: texts.loginCreate,
          onTap: () => context.router.replace(const AuthRegisterRoute()),
        ),
      ],
    );
  }
}
