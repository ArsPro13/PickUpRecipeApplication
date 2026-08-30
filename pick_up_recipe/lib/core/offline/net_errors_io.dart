// Обрывы сети на телефоне.
//
// Отдельным файлом ради веба: dart:io там нет вовсе, и один только импорт
// ломает сборку. Условный экспорт в net_errors.dart подставляет нужный.

import 'dart:io';

bool isPlatformNetworkError(Object error) =>
    error is SocketException || error is HandshakeException || error is HttpException;
