class Config {
  // Адрес бэкенда переопределяется при запуске, умолчание — прод:
  //   flutter run --dart-define=BASE_URL=http://10.0.2.2:1324
  //
  // 10.0.2.2 — это хост-машина с точки зрения андроид-эмулятора.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://84.201.180.72:1323',
  );

  static const String packImageBaseUrl = String.fromEnvironment(
    'PACK_IMAGE_BASE_URL',
    defaultValue: 'http://84.201.180.72:5003',
  );
}
