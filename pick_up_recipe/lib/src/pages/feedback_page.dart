// Экран «Обратная связь» — из профиля, строкой «Написать нам».
//
// Одно поле и кнопка. Темы, категорий и оценок нет: человек, у которого
// что-то сломалось, не должен сперва решать, «ошибка» это или «пожелание».
// Версия сборки, платформа и язык уходят с письмом сами.
//
// Ответ сервера — на этом же экране: сообщений внизу в приложении нет
// (test/no_snackbars_test.dart). Отправилось — вместо формы «Спасибо»;
// не отправилось — строка под полем, а текст остаётся на месте: набранное
// письмо, пропавшее из-за сети, второй раз не пишут.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/offline_exception.dart';
import '../../l10n/app_localizations.dart';
import '../features/feedback/feedback_service.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key});

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  final TextEditingController _text = TextEditingController();

  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Кнопка оживает от первой буквы, а не после ухода с поля.
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSend => !_sending && _text.text.trim().isNotEmpty;

  Future<void> _send() async {
    final texts = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    FocusScope.of(context).unfocus();

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await ref
          .read(feedbackServiceProvider)
          .send(message: _text.text, locale: locale);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
    } on OfflineException {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = texts.noNetwork;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = texts.feedbackFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(texts.feedbackTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s4,
            AppSpacing.s5,
            AppSpacing.s8,
          ),
          children: _sent ? _thanks(texts) : _form(texts),
        ),
      ),
    );
  }

  List<Widget> _form(AppLocalizations texts) {
    return [
      Text(texts.feedbackIntro, style: context.texts.bodyMedium),
      const SizedBox(height: AppSpacing.s4),
      TextField(
        key: const ValueKey('feedback-text'),
        controller: _text,
        enabled: !_sending,
        minLines: 6,
        maxLines: 14,
        maxLength: feedbackMaxLength,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: texts.feedbackHint,
          hintMaxLines: 3,
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.s2),
        Text(
          _error!,
          style: context.texts.bodySmall?.copyWith(color: context.colors.error),
        ),
      ],
      const SizedBox(height: AppSpacing.s4),
      AppButton(
        label: texts.feedbackSend,
        icon: AppIcons.uiMail,
        loading: _sending,
        onPressed: _canSend ? _send : null,
      ),
    ];
  }

  List<Widget> _thanks(AppLocalizations texts) {
    return [
      const SizedBox(height: AppSpacing.s8),
      Center(
        child: AppIcon(
          AppIcons.uiCheck,
          size: AppSizes.icon48,
          color: context.colors.primary,
        ),
      ),
      const SizedBox(height: AppSpacing.s4),
      Text(
        texts.feedbackThanksTitle,
        style: context.texts.titleLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.s2),
      Text(
        texts.feedbackThanksText,
        style: context.texts.bodyMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.s6),
      AppButton(
        label: texts.builderDone,
        onPressed: () => context.router.maybePop(),
      ),
    ];
  }
}
