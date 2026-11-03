// Экран «Обратная связь».
//
// Проверяется то, ради чего он такой: пустое письмо не отправить, ответ
// сервера — на месте, без всплывающих сообщений, и набранный текст не
// пропадает, если письмо не ушло.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/core/offline/offline_exception.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/features/feedback/feedback_service.dart';
import 'package:pick_up_recipe/src/pages/feedback_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';

/// Служба, которая запоминает письмо и отвечает тем, что ей задали.
class _FakeFeedback extends FeedbackService {
  _FakeFeedback({this.error});

  final Object? error;
  final sent = <({String message, String locale})>[];

  @override
  Future<void> send({required String message, required String locale}) async {
    if (error != null) throw error!;
    sent.add((message: message, locale: locale));
  }
}

Future<void> pumpFeedback(WidgetTester tester, _FakeFeedback service,
    {Locale locale = const Locale('ru')}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [feedbackServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        theme: lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FeedbackPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder sendButton() => find.widgetWithText(ElevatedButton, 'Отправить');

void main() {
  testWidgets('пустое письмо не отправить', (tester) async {
    final service = _FakeFeedback();
    await pumpFeedback(tester, service);

    expect(find.text('Обратная связь'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(sendButton()).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('feedback-text')), '   ');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(sendButton()).onPressed, isNull,
        reason: 'одни пробелы — тоже пустое письмо');
  });

  testWidgets('письмо уходит с языком экрана, вместо формы — «Спасибо»',
      (tester) async {
    final service = _FakeFeedback();
    await pumpFeedback(tester, service);

    await tester.enterText(find.byKey(const ValueKey('feedback-text')),
        'После скана открылся не тот кофе');
    await tester.pump();
    await tester.tap(sendButton());
    await tester.pumpAndSettle();

    expect(service.sent, hasLength(1));
    expect(service.sent.single.message, 'После скана открылся не тот кофе');
    expect(service.sent.single.locale, 'ru');
    expect(find.text('Спасибо!'), findsOneWidget);
    expect(find.byKey(const ValueKey('feedback-text')), findsNothing);
  });

  testWidgets('сервер не принял — строка под полем, текст на месте',
      (tester) async {
    final service = _FakeFeedback(error: const FeedbackFailure(500));
    await pumpFeedback(tester, service);

    await tester.enterText(
        find.byKey(const ValueKey('feedback-text')), 'Хочу тёмную тему');
    await tester.pump();
    await tester.tap(sendButton());
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Не получилось отправить. Попробуйте ещё раз — текст на месте.'),
        findsOneWidget);
    expect(find.text('Хочу тёмную тему'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(sendButton()).onPressed, isNotNull,
        reason: 'можно повторить');
  });

  testWidgets('без сети — про сеть, а не «не получилось»', (tester) async {
    final service = _FakeFeedback(error: const OfflineException());
    await pumpFeedback(tester, service, locale: const Locale('en'));

    await tester.enterText(
        find.byKey(const ValueKey('feedback-text')), 'Dark theme please');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send'));
    await tester.pumpAndSettle();

    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('Dark theme please'), findsOneWidget);
  });
}
