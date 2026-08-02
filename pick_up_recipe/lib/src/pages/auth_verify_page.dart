// Подтверждение почты кодом из письма.
//
// Три вещи, без которых экран был тупиком:
//
//   • повторная отправка — ручка на бэкенде была, клиент её не звал, и
//     человек без письма не мог ничего;
//   • отсчёт до повторной отправки: на всех почтовых ручках стоит ограничение
//     в минуту, и кнопка, которая молча отвечает «слишком часто», хуже
//     кнопки, которая честно показывает, сколько ждать;
//   • правка адреса прямо отсюда — опечатка в почте самая частая причина,
//     по которой код не приходит, и возвращать за ней в регистрацию жестоко.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/app_router.dart';
import '../features/authentication/domain/auth_rules.dart';
import '../features/authentication/provider/authentication_state_notifier.dart';
import '../general_widgets/app_field.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class AuthVerifyPage extends ConsumerStatefulWidget {
  const AuthVerifyPage({super.key, @QueryParam('email') this.email});

  final String? email;

  @override
  ConsumerState<AuthVerifyPage> createState() => _AuthVerifyPageState();
}

class _AuthVerifyPageState extends ConsumerState<AuthVerifyPage> {
  /// Пауза между отправками писем. Совпадает с мидлваром OncePerMinute
  /// на почтовых ручках: обещать раньше — значит обещать отказ.
  static const Duration _resendCooldown = Duration(seconds: 60);

  final TextEditingController _code = TextEditingController();

  Timer? _ticker;
  Duration _left = _resendCooldown;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
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

  Future<void> _resend() async {
    final email = widget.email;
    if (email == null || email.isEmpty) return;

    setState(() => _error = null);

    try {
      await ref.read(authenticationStateNotifierProvider.notifier).resendVerificationCode(email);
      if (mounted) _startCooldown();
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) setState(() => _error = AuthFailure.offline.message);
    }
  }

  Future<void> _submit() async {
    setState(() => _error = AuthRules.codeError(_code.text));
    if (_error != null) return;

    setState(() => _busy = true);

    try {
      await ref
          .read(authenticationStateNotifierProvider.notifier)
          .verifyMail(widget.email ?? '', _code.text.trim());
      if (mounted) await context.router.replace(AuthLoginRoute(email: widget.email));
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) setState(() => _error = AuthFailure.offline.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _left <= Duration.zero;
    final ready = _code.text.length == 6;

    return AppScreen(
      title: 'Подтвердите почту',
      body: [
        Column(
          children: [
            AppIcon(
              AppIcons.uiMail,
              size: AppSizes.icon56,
              color: context.colors.primary,
            ),
            const SizedBox(height: AppSpacing.s3),
            Text('Отправили код из шести знаков', style: context.texts.bodyMedium),
            const SizedBox(height: AppSpacing.s1),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    widget.email ?? '',
                    style: context.texts.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Semantics(
                  button: true,
                  label: 'Изменить адрес',
                  child: InkResponse(
                    onTap: () => context.router.replace(const AuthRegisterRoute()),
                    radius: AppSizes.icon24,
                    child: AppIcon(
                      AppIcons.uiEdit,
                      size: AppSizes.icon16,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s5),
        HeroSurface(
          child: Column(
            children: [
              CodeInput(
                controller: _code,
                hasError: _error != null,
                onCompleted: (_) => setState(() {}),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s3),
                Text(
                  _error!,
                  style: context.texts.labelSmall?.copyWith(color: context.colors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.s4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Не пришёл?', style: context.texts.bodySmall),
                  TextButton(
                    onPressed: canResend ? _resend : null,
                    child: Text(
                      canResend
                          ? 'Отправить заново'
                          : 'Отправить заново через ${_formatLeft(_left)}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s5),
        IconRow(
          icon: AppIcons.uiInfo,
          title: 'Письмо может лежать в «Спаме»',
          subtitle: 'отправитель новый, почта его ещё не знает',
          iconColor: context.colors.secondary,
        ),
      ],
      bottom: [
        AppButton(
          label: 'Подтвердить',
          loading: _busy,
          onPressed: ready && !_busy ? _submit : null,
        ),
      ],
    );
  }
}

/// м:сс — как на таймере заваривания, чтобы формат времени был один на всё.
String _formatLeft(Duration left) {
  final seconds = left.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${left.inMinutes}:$seconds';
}
