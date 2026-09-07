// Подтверждение почты кодом из письма.
//
// Экран, на котором чаще всего заканчивается регистрация, — и заканчивается
// молча: письмо не пришло, а перед человеком пустые шесть ячеек и никакого
// объяснения. Поэтому здесь не только поле кода:
//
//   • повторная отправка с отсчётом — на почтовых ручках стоит ограничение в
//     минуту, и кнопка, которая молча получает «слишком часто», хуже кнопки,
//     которая честно показывает, сколько ждать;
//   • список «если письмо не пришло»: спам, минута ожидания, опечатка в
//     адресе, повторная отправка — других причин у не пришедшего письма нет;
//   • отдельное объяснение, когда почта не работает на нашей стороне: человек
//     обязан узнать, что дело не в нём, иначе он будет искать ошибку у себя;
//   • правка адреса прямо отсюда — опечатка в почте самая частая причина,
//     по которой код не приходит, и возвращать за ней в регистрацию жестоко.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/app_router.dart';
import '../features/authentication/domain/auth_rules.dart';
import '../features/authentication/domain/code_resend.dart';
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
  final TextEditingController _code = TextEditingController();

  Timer? _ticker;

  /// Когда можно просить следующее письмо.
  ///
  /// Экран открывается сразу после регистрации, а её письмо уже ушло, —
  /// значит минута идёт с открытия экрана, а не с первого нажатия.
  ResendCooldown _cooldown = const ResendCooldown.idle();

  bool _busy = false;
  bool _resending = false;

  /// Почта на сервере не работает. Держится до удачной отправки: пока она не
  /// прошла, объяснение остаётся правдой, и убирать его с экрана не за что.
  bool _mailDown = false;

  /// Ошибка набранного кода.
  String? _error;

  /// Что случилось с письмом. Живёт отдельно от [_error]: одно про то, что
  /// набрал человек, другое — про то, что сделал сервер.
  _Notice? _notice;

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

  void _startCooldown([Duration pause = ResendCooldown.serverPause]) {
    _ticker?.cancel();
    setState(() => _cooldown = ResendCooldown.sentAt(DateTime.now(), pause: pause));

    // Секунда здесь — шаг перерисовки, а не сам отсчёт: остаток считается от
    // момента готовности, и приложение, свёрнутое на полминуты, возвращается
    // с правильным числом, а не с тем, на котором его прервали.
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {});
      if (_cooldown.ready(DateTime.now())) timer.cancel();
    });
  }

  Future<void> _resend() async {
    final email = widget.email;
    if (email == null || email.isEmpty) return;

    // В серверное ограничение вслепую не бьёмся: отказ ничего не даёт, а
    // отсчёт после него пошёл бы заново — и ждать пришлось бы дольше.
    if (_resending || !_cooldown.ready(DateTime.now())) return;

    setState(() {
      _resending = true;
      _notice = null;
    });

    final outcome =
        await ref.read(authenticationStateNotifierProvider.notifier).resendVerificationCode(email);
    if (!mounted) return;

    final wait = outcome.retryAfter ?? ResendCooldown.serverPause;

    setState(() {
      _resending = false;

      switch (outcome.status) {
        case ResendStatus.sent:
          _mailDown = false;
          _notice = const _Notice('Отправили ещё одно письмо', good: true);
        case ResendStatus.tooOften:
          // Не «слишком часто», а срок: со сроком понятно, что делать.
          _notice = _Notice(
            'Письмо уже уходило. Следующее — через ${ResendCooldown.format(wait)}',
          );
        case ResendStatus.mailDown:
          _mailDown = true;
          _notice = null;
        case ResendStatus.rejected:
          _notice = const _Notice('Сервер не принял этот адрес. Проверьте, тот ли он');
        case ResendStatus.offline:
          _notice = _Notice(AuthFailure.offline.message);
      }
    });

    // Отсчёт начинается после любого ответа, а не только после удачного:
    // ограничение стоит мидлваром ПЕРЕД обработчиком, и неудачная попытка
    // тратит минуту так же, как удачная. Исключение одно — запрос, который
    // до сервера не дошёл: там тратить было нечего.
    if (outcome.status != ResendStatus.offline) _startCooldown(wait);
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
    final left = _cooldown.left(DateTime.now());
    final canResend = left == Duration.zero && !_resending;
    final ready = _code.text.length == 6;

    return AppScreen(
      showNav: false,
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
              // Wrap, а не Row: на узком экране подпись кнопки с отсчётом в
              // строку с вопросом не помещается и ломает разметку.
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Не пришёл?', style: context.texts.bodySmall),
                  TextButton(
                    onPressed: canResend ? _resend : null,
                    child: Text(
                      switch ((_resending, canResend)) {
                        (true, _) => 'Отправляем…',
                        (false, true) => 'Отправить код ещё раз',
                        (false, false) => 'Ещё раз через ${ResendCooldown.format(left)}',
                      },
                    ),
                  ),
                ],
              ),
              if (_notice != null) ...[
                const SizedBox(height: AppSpacing.s2),
                Text(
                  _notice!.text,
                  style: context.texts.labelSmall?.copyWith(
                    color: _notice!.good ? context.palette.success : context.colors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        if (_mailDown) ...[
          const SizedBox(height: AppSpacing.s5),
          const _MailDownCard(),
        ] else ...[
          const SectionTitle('Если письмо не пришло'),
          const _WhatToDoCard(),
        ],
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

/// Сообщение о письме: удачная отправка или причина, по которой её не было.
class _Notice {
  const _Notice(this.text, {this.good = false});

  final String text;
  final bool good;
}

/// Что делать, если письма нет.
///
/// Четыре строки — четыре причины, других у не пришедшего письма не бывает:
/// оно в спаме, оно ещё в пути, адрес набран с опечаткой, письма не было.
class _WhatToDoCard extends StatelessWidget {
  const _WhatToDoCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      flat: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconRow(
            icon: AppIcons.uiInfo,
            title: 'Загляните в «Спам»',
            subtitle: 'отправитель новый, и почта его ещё не знает',
            iconColor: context.colors.secondary,
          ),
          const SizedBox(height: AppSpacing.s3),
          IconRow(
            icon: AppIcons.uiHistory,
            title: 'Подождите минуту',
            subtitle: 'письмо идёт не мгновенно, обычно меньше минуты',
            iconColor: context.colors.secondary,
          ),
          const SizedBox(height: AppSpacing.s3),
          IconRow(
            icon: AppIcons.uiMail,
            title: 'Проверьте адрес',
            subtitle: 'опечатка в почте — самая частая причина; исправить адрес '
                'можно карандашом наверху',
            iconColor: context.colors.secondary,
          ),
          const SizedBox(height: AppSpacing.s3),
          IconRow(
            icon: AppIcons.uiRefresh,
            title: 'Отправьте код ещё раз',
            subtitle: 'кнопка над этим списком; чаще раза в минуту письма не уходят',
            iconColor: context.colors.secondary,
          ),
        ],
      ),
    );
  }
}

/// Почта не работает у нас.
///
/// Отдельная карточка вместо строки ошибки: человеку нужно не сообщение об
/// отказе, а три вещи — что дело не в нём, что аккаунт уже создан и что
/// делать дальше. Строкой этого не сказать.
class _MailDownCard extends StatelessWidget {
  const _MailDownCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: context.colors.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconRow(
            icon: AppIcons.uiWarning,
            title: 'Письма сейчас не уходят',
            subtitle: 'дело не в вашем адресе: сервер не смог отправить письмо',
            iconColor: context.colors.error,
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'Аккаунт уже создан — проходить регистрацию заново не нужно. '
            'Подождите несколько минут и отправьте код ещё раз: как только '
            'почта заработает, письмо придёт на тот же адрес.',
            style: context.texts.bodySmall,
          ),
        ],
      ),
    );
  }
}
