// Обратная связь: письмо владельцу сервиса из профиля.
//
// Одно поле текста — без темы и категорий: «что не так» человек пишет
// своими словами, а не выбирает из списка. Версия сборки, платформа и язык
// уходят вместе с письмом сами, чтобы не спрашивать их потом в переписке.
// Читает письма владелец в кабинете, отвечает на почту аккаунта.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../../core/api_client.dart';
import '../../../core/app_version.dart';

/// Предел длины письма — тот же, что на сервере.
const int feedbackMaxLength = 2000;

/// Сервер письмо не принял. Офлайн сюда не попадает — он летит
/// [OfflineException] из ApiClient, и экран говорит про сеть отдельно.
class FeedbackFailure implements Exception {
  const FeedbackFailure(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'FeedbackFailure($statusCode)';
}

class FeedbackService {
  ApiClient get _apiClient => GetIt.instance<ApiClient>();

  Future<void> send({required String message, required String locale}) async {
    final response = await _apiClient.post('/feedback', {
      'message': message.trim(),
      'app_version': appVersion,
      'platform': feedbackPlatform(),
      'locale': locale,
    });

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw FeedbackFailure(response.statusCode);
    }
  }
}

/// Платформа строкой для письма: android, ios, web.
///
/// Через foundation, а не dart:io: веб-сборка dart:io не знает.
String feedbackPlatform() {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    TargetPlatform.fuchsia => 'fuchsia',
  };
}

final feedbackServiceProvider =
    Provider<FeedbackService>((ref) => FeedbackService());
