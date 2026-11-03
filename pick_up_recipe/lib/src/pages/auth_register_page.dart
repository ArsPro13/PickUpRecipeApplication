// Экран регистрации.
//
// Два отличия от макета, и оба — по ответам владельца:
//
//   • правило пароля одно, а не два. На макете стояло второе — «есть цифра
//     или знак», — но это было предположение: authsvc.ValidatePassword
//     проверяет только длину (ответ на вопрос 8). Требовать в форме то, чего
//     сервер не требует, значит отказывать в пароле, который он бы принял;
//
//   • добавлено согласие на обработку данных (ответ на вопрос 11). С
//     1 сентября 2025 года оно оформляется отдельно от прочих документов
//     (152-ФЗ, ст. 9), поэтому отметок две: «принимаю соглашение» и «даю
//     согласие». Политика — строкой под ними, без флажка: её не принимают,
//     а читают.

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

  bool _terms = false;
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

  bool get _lengthMet =>
      _password.text.runes.length >= AuthRules.minPasswordLength;

  Future<void> _submit() async {
    final texts = AppLocalizations.of(context);

    setState(() {
      _emailError = AuthRules.emailProblem(_email.text)?.text(texts);
      _passwordError = AuthRules.passwordProblem(_password.text)?.text(texts);
      _repeatError =
          AuthRules.repeatProblem(_password.text, _repeat.text)?.text(texts);
      _formError = _terms && _consent ? null : texts.registerConsentRequired;
    });
    if (_emailError != null ||
        _passwordError != null ||
        _repeatError != null ||
        !_terms ||
        !_consent) {
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
        await context.router
            .replace(AuthVerifyRoute(email: _email.text.trim()));
      }
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        // Занятая почта — про поле почты, всё остальное — про форму целиком.
        if (failure.statusCode == 409) {
          _emailError = failure.text(texts);
        } else {
          _formError = failure.text(texts);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _formError = AuthFailure.offline.text(texts));
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
                valid: _emailError == null &&
                    AuthRules.emailProblem(_email.text) == null,
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
                valid:
                    _repeat.text.isNotEmpty && _repeat.text == _password.text,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _submit(),
                onChanged: (_) => setState(() => _repeatError = null),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        _ConsentRow(
          value: _terms,
          prefix: texts.registerTermsPrefix,
          link: texts.registerTermsLink,
          document: LegalKind.userAgreement,
          onChanged: (value) => setState(() {
            _terms = value;
            _formError = null;
          }),
        ),
        const SizedBox(height: AppSpacing.s3),
        _ConsentRow(
          value: _consent,
          prefix: texts.registerDataPrefix,
          link: texts.registerDataLink,
          document: LegalKind.consent,
          onChanged: (value) => setState(() {
            _consent = value;
            _formError = null;
          }),
        ),
        const SizedBox(height: AppSpacing.s3),
        const _PolicyNote(),
        if (_formError != null) ...[
          const SizedBox(height: AppSpacing.s3),
          Text(
            _formError!,
            style:
                context.texts.bodySmall?.copyWith(color: context.colors.error),
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

/// Одна отметка: флажок, текст и ссылка на документ.
///
/// Ссылка открывает документ листом снизу — он приезжает с сервера
/// (`/legal/*`) и там же меняется, без пересборки приложения. Сам текст
/// перед ссылкой переключает флажок.
///
/// Соглашение, а не оферта: оферты нет и не будет, пока в сервисе нет
/// платежей, а ссылка на несуществующий документ хуже её отсутствия.
class _ConsentRow extends StatefulWidget {
  const _ConsentRow({
    required this.value,
    required this.prefix,
    required this.link,
    required this.document,
    required this.onChanged,
  });

  final bool value;
  final String prefix;
  final String link;
  final LegalKind document;
  final ValueChanged<bool> onChanged;

  @override
  State<_ConsentRow> createState() => _ConsentRowState();
}

class _ConsentRowState extends State<_ConsentRow> {
  // Распознаватели нажатий живут столько же, сколько виджет, и требуют
  // явного освобождения: без dispose каждая перерисовка формы оставляла бы
  // после себя ещё один. Замыкания читают widget в момент нажатия, поэтому
  // и после перерисовки флажок переключается от актуального значения.
  late final TapGestureRecognizer _toggleTap;
  late final TapGestureRecognizer _documentTap;

  @override
  void initState() {
    super.initState();
    _toggleTap = TapGestureRecognizer()
      ..onTap = () => widget.onChanged(!widget.value);
    _documentTap = TapGestureRecognizer()
      ..onTap = () => showLegalSheet(context, widget.document);
  }

  @override
  void dispose() {
    _toggleTap.dispose();
    _documentTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                TextSpan(text: widget.prefix, recognizer: _toggleTap),
                TextSpan(
                  text: widget.link,
                  style: TextStyle(
                    color: context.colors.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: _documentTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Строка под отметками: где прочитать, как обращаются с данными.
///
/// Без флажка: политику не принимают — это рассказ оператора о том, что он
/// делает с данными. Прочитать её до регистрации человек должен иметь
/// возможность, и ссылка здесь ровно для этого.
class _PolicyNote extends StatefulWidget {
  const _PolicyNote();

  @override
  State<_PolicyNote> createState() => _PolicyNoteState();
}

class _PolicyNoteState extends State<_PolicyNote> {
  late final TapGestureRecognizer _policyTap;

  @override
  void initState() {
    super.initState();
    _policyTap = TapGestureRecognizer()
      ..onTap = () => showLegalSheet(context, LegalKind.privacy);
  }

  @override
  void dispose() {
    _policyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return Padding(
      // Под текстом отметок, а не под флажками: так строка читается как
      // пояснение к ним, а не как третья отметка без флажка.
      padding: const EdgeInsets.only(left: AppSizes.icon24 + AppSpacing.s3),
      child: Text.rich(
        TextSpan(
          // Тем же цветом, что текст отметок: пояснение не должно звучать
          // громче того, к чему оно поясняет.
          style: context.texts.bodySmall,
          children: [
            TextSpan(text: texts.registerPolicyNote),
            TextSpan(
              text: texts.registerPolicyLink,
              style: TextStyle(
                color: context.colors.primary,
                decoration: TextDecoration.underline,
              ),
              recognizer: _policyTap,
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
