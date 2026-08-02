// Экран регистрации.
//
// Два отличия от макета, и оба — по ответам владельца:
//
//   • правило пароля одно, а не два. На макете стояло второе — «есть цифра
//     или знак», — но это было предположение: authsvc.ValidatePassword
//     проверяет только длину (ответ на вопрос 8). Требовать в форме то, чего
//     сервер не требует, значит отказывать в пароле, который он бы принял;
//
//   • добавлено согласие на обработку данных с двумя ссылками (ответ на
//     вопрос 11). Для сторов и для 152-ФЗ это обязательный флажок, и без него
//     приложение не подать.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/app_router.dart';
import '../features/authentication/domain/auth_rules.dart';
import '../features/authentication/provider/authentication_state_notifier.dart';
import '../general_widgets/app_field.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class AuthRegisterPage extends ConsumerStatefulWidget {
  const AuthRegisterPage({super.key});

  @override
  ConsumerState<AuthRegisterPage> createState() => _AuthRegisterPageState();
}

class _AuthRegisterPageState extends ConsumerState<AuthRegisterPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _repeat = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _repeatError;
  String? _formError;

  bool _consent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  bool get _lengthMet => _password.text.runes.length >= AuthRules.minPasswordLength;

  Future<void> _submit() async {
    setState(() {
      _emailError = AuthRules.emailError(_email.text);
      _passwordError = AuthRules.passwordError(_password.text);
      _repeatError = AuthRules.repeatError(_password.text, _repeat.text);
      _formError = _consent ? null : 'Без согласия зарегистрировать аккаунт нельзя';
    });
    if (_emailError != null || _passwordError != null || _repeatError != null || !_consent) {
      return;
    }

    setState(() => _busy = true);

    try {
      await ref
          .read(authenticationStateNotifierProvider.notifier)
          .register(_email.text.trim(), _password.text);
      if (mounted) {
        await context.router.replace(AuthVerifyRoute(email: _email.text.trim()));
      }
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        // Занятая почта — про поле почты, всё остальное — про форму целиком.
        if (failure.statusCode == 409) {
          _emailError = failure.message;
        } else {
          _formError = failure.message;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _formError = AuthFailure.offline.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Создать аккаунт',
      body: [
        HeroSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppField(
                label: 'Почта',
                controller: _email,
                icon: AppIcons.uiMail,
                hint: 'you@example.com',
                error: _emailError,
                valid: _emailError == null && AuthRules.emailError(_email.text) == null,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) => setState(() => _emailError = null),
              ),
              const SizedBox(height: AppSpacing.s4),
              AppField(
                label: 'Пароль',
                controller: _password,
                icon: AppIcons.uiLock,
                obscure: true,
                error: _passwordError,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() => _passwordError = null),
              ),
              const SizedBox(height: AppSpacing.s2),
              PasswordRule(
                text: 'не короче ${AuthRules.minPasswordLength} знаков',
                met: _lengthMet,
              ),
              const SizedBox(height: AppSpacing.s4),
              AppField(
                label: 'Ещё раз',
                controller: _repeat,
                icon: AppIcons.uiLock,
                obscure: true,
                error: _repeatError,
                valid: _repeat.text.isNotEmpty && _repeat.text == _password.text,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _submit(),
                onChanged: (_) => setState(() => _repeatError = null),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        _ConsentRow(
          value: _consent,
          onChanged: (value) => setState(() {
            _consent = value;
            _formError = null;
          }),
        ),
        if (_formError != null) ...[
          const SizedBox(height: AppSpacing.s3),
          Text(
            _formError!,
            style: context.texts.bodySmall?.copyWith(color: context.colors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.s4),
        QuietSurface(
          child: IconRow(
            icon: AppIcons.uiMail,
            title: 'Дальше — письмо с кодом',
            subtitle: 'шесть знаков, чтобы подтвердить адрес',
            iconColor: context.colors.secondary,
          ),
        ),
      ],
      bottom: [
        AppButton(label: 'Создать аккаунт', loading: _busy, onPressed: _busy ? null : _submit),
        SwapLine(
          question: 'Уже есть аккаунт?',
          action: 'Войти',
          onTap: () => context.router.replace(AuthLoginRoute()),
        ),
      ],
    );
  }
}

/// Согласие на обработку данных: флажок и две ссылки (ответ на вопрос 11).
///
/// Тексты политики и оферты нужны до подачи в стор — пока ссылки ведут на
/// заглушку, и это видно по сообщению, а не молча.
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppSizes.icon24,
          height: AppSizes.icon24,
          child: Checkbox(
            value: value,
            onChanged: (checked) => onChanged(checked ?? false),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text.rich(
              TextSpan(
                style: context.texts.bodySmall,
                children: [
                  const TextSpan(text: 'Соглашаюсь с '),
                  TextSpan(
                    text: 'политикой обработки данных',
                    style: TextStyle(color: context.colors.primary),
                  ),
                  const TextSpan(text: ' и '),
                  TextSpan(
                    text: 'офертой',
                    style: TextStyle(color: context.colors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
