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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../features/authentication/domain/auth_rules.dart';
import '../features/authentication/provider/authentication_state_notifier.dart';
import '../features/legal/data_sources/remote/legal_service.dart';
import '../features/legal/domain/legal_document.dart';
import '../general_widgets/legal_sheet.dart';
import '../general_widgets/app_field.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import 'auth_rule_texts.dart';
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

  /// Редакция документов, с которой человек соглашается прямо сейчас.
  ///
  /// Берётся с сервера, а не зашивается в приложение: документы меняются без
  /// пересборки, и версия, вшитая в сборку полугодовой давности, доказывала
  /// бы согласие не с тем текстом, который человек видел на экране.
  String _consentVersion = '';

  @override
  void initState() {
    super.initState();
    _loadConsentVersion();
  }

  Future<void> _loadConsentVersion() async {
    try {
      final version = await const LegalService().currentConsentVersion();
      if (!mounted) return;
      setState(() => _consentVersion = version);
    } catch (_) {
      // Молча: сообщение об этом человек увидит при попытке отправить форму,
      // а не в момент открытия экрана. Ругаться на связь до того, как он
      // что-то сделал, — значит ругаться в пустоту.
      if (!mounted) return;
      setState(() => _consentVersion = '');
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  bool get _lengthMet => _password.text.runes.length >= AuthRules.minPasswordLength;

  Future<void> _submit() async {
    final texts = AppLocalizations.of(context);

    setState(() {
      _emailError = AuthRules.emailProblem(_email.text)?.text(texts);
      _passwordError = AuthRules.passwordProblem(_password.text)?.text(texts);
      _repeatError = AuthRules.repeatProblem(_password.text, _repeat.text)?.text(texts);
      _formError = _consent ? null : texts.registerConsentRequired;
    });
    if (_emailError != null || _passwordError != null || _repeatError != null || !_consent) {
      return;
    }

    // Без версии согласия сервер откажет (422), и лучше сказать об этом
    // здесь, чем отправить запрос наугад и показать «ошибка сервера».
    if (_consentVersion.isEmpty) {
      await _loadConsentVersion();
      if (!mounted) return;
      if (_consentVersion.isEmpty) {
        setState(() => _formError = texts.registerTermsUnavailable);
        return;
      }
    }

    setState(() => _busy = true);

    try {
      await ref
          .read(authenticationStateNotifierProvider.notifier)
          .register(_email.text.trim(), _password.text, _consentVersion);
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
    final texts = AppLocalizations.of(context);

    return AppScreen(
      showNav: false,
      title: texts.authCreateAccount,
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
                valid: _emailError == null && AuthRules.emailProblem(_email.text) == null,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) => setState(() => _emailError = null),
              ),
              const SizedBox(height: AppSpacing.s4),
              AppField(
                label: texts.fieldPassword,
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
                text: texts.registerPasswordRule(AuthRules.minPasswordLength),
                met: _lengthMet,
              ),
              const SizedBox(height: AppSpacing.s4),
              AppField(
                label: texts.registerRepeat,
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
            title: texts.registerNextMail,
            subtitle: texts.registerNextMailNote,
            iconColor: context.colors.secondary,
          ),
        ),
      ],
      bottom: [
        AppButton(
          label: texts.authCreateAccount,
          loading: _busy,
          onPressed: _busy ? null : _submit,
        ),
        SwapLine(
          question: texts.registerHaveAccount,
          action: texts.authSignIn,
          onTap: () => context.router.replace(AuthLoginRoute()),
        ),
      ],
    );
  }
}

/// Согласие на обработку данных: флажок и две ссылки (ответ на вопрос 11).
///
/// Ссылки открывают документы листом снизу — они приезжают с сервера
/// (`/legal/*`) и там же меняются, без пересборки приложения.
///
/// Вторая ссылка ведёт на пользовательское соглашение, а не на оферту:
/// оферты нет и не будет, пока в сервисе нет платежей, а ссылка на
/// несуществующий документ хуже её отсутствия.
class _ConsentRow extends StatefulWidget {
  const _ConsentRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<_ConsentRow> createState() => _ConsentRowState();
}

class _ConsentRowState extends State<_ConsentRow> {
  // Распознаватели нажатий живут столько же, сколько виджет, и требуют
  // явного освобождения: без dispose каждая перерисовка формы оставляла бы
  // после себя ещё один.
  late final TapGestureRecognizer _privacyTap;
  late final TapGestureRecognizer _agreementTap;

  @override
  void initState() {
    super.initState();
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => showLegalSheet(context, LegalKind.privacy);
    _agreementTap = TapGestureRecognizer()
      ..onTap = () => showLegalSheet(context, LegalKind.userAgreement);
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    _agreementTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppSizes.icon24,
          height: AppSizes.icon24,
          child: Checkbox(
            value: widget.value,
            onChanged: (checked) => widget.onChanged(checked ?? false),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: context.texts.bodySmall,
              children: [
                // Сам текст переключает флажок, ссылки — открывают документ.
                TextSpan(
                  text: texts.consentPrefix,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => widget.onChanged(!widget.value),
                ),
                TextSpan(
                  text: texts.consentPrivacy,
                  style: TextStyle(
                    color: context.colors.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: _privacyTap,
                ),
                TextSpan(
                  text: texts.consentAnd,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => widget.onChanged(!widget.value),
                ),
                TextSpan(
                  text: texts.consentAgreement,
                  style: TextStyle(
                    color: context.colors.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: _agreementTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
