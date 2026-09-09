// Восстановление пароля — экран входа, которого не было вовсе, при том что
// forgot_password и reset_password на бэкенде есть с самого начала.
//
// Два шага на одном экране, а не два экрана: между ними человек уходит в
// почту и возвращается, и терять при этом введённый адрес незачем. Пройденный
// шаг сворачивается в строку — видно, где ты и сколько осталось.
//
// Ответ на письмо одинаковый и для известного адреса, и для неизвестного
// (ответ 39): иначе форма превращается в проверялку, зарегистрирован ли
// человек, и это утечка.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../features/authentication/domain/auth_rules.dart';
import '../features/authentication/provider/authentication_state_notifier.dart';
import '../general_widgets/app_field.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';
import 'auth_rule_texts.dart';

/// Шаг восстановления.
enum ResetStep { requestCode, enterNewPassword, done }

@RoutePage()
class PasswordResetPage extends ConsumerStatefulWidget {
  const PasswordResetPage({super.key, @QueryParam('email') this.email});

  /// Почта, введённая на экране входа. Перенабирать её незачем.
  final String? email;

  @override
  ConsumerState<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends ConsumerState<PasswordResetPage> {
  /// Пауза между письмами. Совпадает с мидлваром OncePerMinute на ручке.
  static const Duration _resendCooldown = Duration(seconds: 60);

  late final TextEditingController _email = TextEditingController(text: widget.email ?? '');
  final TextEditingController _code = TextEditingController();
  final TextEditingController _password = TextEditingController();

  ResetStep _step = ResetStep.requestCode;
  Timer? _ticker;
  Duration _left = Duration.zero;

  bool _busy = false;
  String? _error;
  String? _emailError;
  String? _codeError;
  String? _passwordError;

  @override
  void dispose() {
    _ticker?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _ticker?.cancel();
    setState(() => _left = _resendCooldown);

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _left -= const Duration(seconds: 1));
      if (_left <= Duration.zero) timer.cancel();
    });
  }

  Future<void> _requestCode() async {
    final texts = AppLocalizations.of(context);

    setState(() => _emailError = AuthRules.emailProblem(_email.text)?.text(texts));
    if (_emailError != null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref
          .read(authenticationStateNotifierProvider.notifier)
          .requestPasswordReset(_email.text.trim());
      if (!mounted) return;
      setState(() => _step = ResetStep.enterNewPassword);
      _startCooldown();
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.text(texts));
    } catch (_) {
      if (mounted) setState(() => _error = AuthFailure.offline.text(texts));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyNewPassword() async {
    final texts = AppLocalizations.of(context);

    setState(() {
      _codeError = AuthRules.codeProblem(_code.text)?.text(texts);
      _passwordError = AuthRules.passwordProblem(_password.text)?.text(texts);
    });
    if (_codeError != null || _passwordError != null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(authenticationStateNotifierProvider.notifier).resetPassword(
            _email.text.trim(),
            _code.text.trim(),
            _password.text,
          );
      if (mounted) setState(() => _step = ResetStep.done);
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.text(texts));
    } catch (_) {
      if (mounted) setState(() => _error = AuthFailure.offline.text(texts));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return AppScreen(
      showNav: false,
      title: _step == ResetStep.done ? texts.resetDoneTitle : texts.resetTitle,
      body: switch (_step) {
        ResetStep.requestCode => _requestCodeStep(texts),
        ResetStep.enterNewPassword => _newPasswordStep(texts),
        ResetStep.done => _doneStep(texts),
      },
      bottom: switch (_step) {
        ResetStep.requestCode => [
            AppButton(
              label: texts.resetSendCode,
              loading: _busy,
              onPressed: _busy ? null : _requestCode,
            ),
          ],
        ResetStep.enterNewPassword => [
            AppButton(
              label: texts.resetChangePassword,
              loading: _busy,
              onPressed: _busy ? null : _applyNewPassword,
            ),
          ],
        ResetStep.done => [
            AppButton(label: texts.resetToLogin, onPressed: () => context.router.maybePop()),
          ],
      },
    );
  }

  List<Widget> _requestCodeStep(AppLocalizations texts) {
    return [
      _Step(number: 1, title: texts.resetStepWhere, current: true),
      const SizedBox(height: AppSpacing.s3),
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
              textInputAction: TextInputAction.go,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _requestCode(),
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
          ],
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.s3),
        _ErrorLine(text: _error!),
      ],
      const SizedBox(height: AppSpacing.s4),
      IconRow(
        icon: AppIcons.uiInfo,
        title: texts.resetSameAnswer,
        subtitle: texts.resetSameAnswerNote,
        iconColor: context.colors.secondary,
      ),
    ];
  }

  List<Widget> _newPasswordStep(AppLocalizations texts) {
    final canResend = _left <= Duration.zero;

    return [
      // Пройденный шаг сворачивается в строку: видно, что письмо ушло и куда.
      _Step(number: 1, title: texts.resetStepSent, subtitle: _email.text.trim(), done: true),
      const SizedBox(height: AppSpacing.s3),
      _Step(number: 2, title: texts.resetStepNewPassword, current: true),
      const SizedBox(height: AppSpacing.s3),
      HeroSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppField(
              label: texts.resetFieldCode,
              controller: _code,
              icon: AppIcons.uiMail,
              hint: '000000',
              error: _codeError,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (_) {
                if (_codeError != null) setState(() => _codeError = null);
              },
            ),
            Row(
              children: [
                Text(texts.resetNotArrived, style: context.texts.bodySmall),
                TextButton(
                  onPressed: canResend && !_busy ? _requestCode : null,
                  child: Text(
                    canResend ? texts.resetResend : texts.resetResendIn(_formatLeft(_left)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            AppField(
              label: texts.resetFieldNewPassword,
              controller: _password,
              icon: AppIcons.uiLock,
              obscure: true,
              error: _passwordError,
              helper: texts.resetPasswordHelper(AuthRules.minPasswordLength),
              textInputAction: TextInputAction.go,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _applyNewPassword(),
              onChanged: (_) {
                if (_passwordError != null) setState(() => _passwordError = null);
              },
            ),
          ],
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.s3),
        _ErrorLine(text: _error!),
      ],
    ];
  }

  List<Widget> _doneStep(AppLocalizations texts) {
    return [
      const SizedBox(height: AppSpacing.s12),
      AppState(
        icon: AppIcons.uiCheck,
        title: texts.resetDoneHeading,
        description: texts.resetDoneNote,
      ),
    ];
  }
}

/// Шаг мастера: номер в кружке, подпись, состояние.
class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    this.subtitle,
    this.done = false,
    this.current = false,
  });

  final int number;
  final String title;
  final String? subtitle;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final active = done || current;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSizes.icon24,
          height: AppSizes.icon24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? context.palette.success
                : current
                    ? context.colors.primary
                    : Colors.transparent,
            border: active ? null : Border.all(color: context.palette.border),
          ),
          alignment: Alignment.center,
          child: done
              ? AppIcon(
                  AppIcons.uiCheck,
                  size: AppSizes.icon16,
                  color: context.colors.secondaryContainer,
                )
              : Text(
                  '$number',
                  style: context.texts.labelSmall?.copyWith(
                    color: current ? context.colors.secondaryContainer : context.colors.secondary,
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.texts.bodySmall),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s1),
                Text(subtitle!, style: context.texts.labelSmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Строка ошибки под формой.
class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(AppIcons.uiWarning, size: AppSizes.icon20, color: context.colors.error),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: Text(
            text,
            style: context.texts.bodySmall?.copyWith(color: context.colors.error),
          ),
        ),
      ],
    );
  }
}

String _formatLeft(Duration left) {
  final seconds = left.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${left.inMinutes}:$seconds';
}
