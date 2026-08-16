// Экран, который не гаснет во время заваривания.
//
// Пауза в рецепте бывает пятьдесят секунд, экран за это время тухнет, и его
// будят мокрым пальцем — с чайником в другой руке. Плагин ради одного флага
// окна не подключаем: стенд работает без сети, а канал до MainActivity стоит
// двадцати строк (см. android/.../MainActivity.kt).
//
// На вебе и iOS канала нет — вызов молча ничего не делает, и это правильное
// поведение: заваривание важнее, чем экран, который мог бы не гаснуть.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenWake {
  const ScreenWake._();

  static const MethodChannel _channel = MethodChannel('pickuprecipe/screen');

  /// Держать экран включённым (или отпустить его).
  static Future<void> keepAwake(bool on) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('keepAwake', {'on': on});
    } on MissingPluginException {
      // Платформа без обработчика — не повод падать посреди заваривания.
    } on PlatformException {
      // Тоже не повод: экран погаснет, рецепт доиграется.
    }
  }
}
