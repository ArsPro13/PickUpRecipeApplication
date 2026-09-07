import 'package:flutter/foundation.dart';

class Config {
  // Адрес бэкенда переопределяется при запуске, умолчание — прод:
  //   flutter run --dart-define=BASE_URL=http://10.0.2.2:1324
  //
  // 10.0.2.2 — это хост-машина с точки зрения андроид-эмулятора.
  //
  // Умолчание https, а не http: открытый трафик запрещён политикой сети
  // (android/app/src/main/res/xml/network_security_config.xml), и релизная
  // сборка с http-умолчанием просто не достучалась бы до сервера — молча,
  // с пустыми экранами вместо ошибки.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://recipetocup.ru',
  );

  // Распознавание пачки по фото в прод не выкатывается (BACKLOG, п. 5):
  // сервису нужно +2 ГБ памяти, а на машине их нет. Адрес указывает на
  // тот же домен, чтобы клиент получил внятную ошибку от прокси, а не
  // висел на несуществующем IP до тайм-аута.
  static const String packImageBaseUrl = String.fromEnvironment(
    'PACK_IMAGE_BASE_URL',
    defaultValue: 'https://recipetocup.ru',
  );

  // Демо-аккаунт, которым заполняется форма входа при отладке. Умолчание
  // совпадает с тем, что заводит `make seed` на бэкенде, поэтому обычно
  // переопределять ничего не нужно:
  //   flutter run --dart-define=DEV_EMAIL=... --dart-define=DEV_PASSWORD=...
  static const String _devEmail = String.fromEnvironment(
    'DEV_EMAIL',
    defaultValue: 'demo@pickuprecipe.local',
  );

  static const String _devPassword = String.fromEnvironment(
    'DEV_PASSWORD',
    defaultValue: 'demo12345',
  );

  /// Почта, которой заполняется форма входа. В релизе — пустая строка.
  ///
  /// Проверка на отладку живёт здесь, а не на экране: подставлять пароль в
  /// боевую сборку нельзя ни при каких значениях define, и полагаться на то,
  /// что каждый вызывающий про это помнит, — способ однажды забыть.
  static String get devLoginEmail => kDebugMode ? _devEmail : '';

  /// Пароль демо-аккаунта. В релизе — пустая строка.
  static String get devLoginPassword => kDebugMode ? _devPassword : '';
}
