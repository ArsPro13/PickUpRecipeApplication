import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/config.dart';

import '../../domain/legal_document.dart';

/// Правовые документы с сервера.
///
/// Мимо ApiClient намеренно: тот на 401 зовёт обновление токенов, а эти ручки
/// открыты без авторизации и нужны как раз тогда, когда токена ещё нет, —
/// на экране регистрации.
class LegalService {
  const LegalService();

  static const Duration _timeout = Duration(seconds: 10);

  /// Версия действующей редакции согласия.
  ///
  /// Сервер отдаёт её заголовком `X-Legal-Version`, а не только в теле:
  /// так версию можно узнать, не разбирая весь документ. Пустая строка —
  /// «сервер не сказал»; регистрироваться с ней нельзя, и вызывающий обязан
  /// показать это человеку, а не отправлять запрос наугад.
  Future<String> currentConsentVersion() async {
    final response = await http
        .get(Uri.parse('${Config.baseUrl}${LegalKind.consent.path}'))
        .timeout(_timeout);

    if (response.statusCode != 200) {
      return '';
    }

    return response.headers['x-legal-version']?.trim() ?? '';
  }

  /// Текст документа целиком.
  Future<LegalDocument> fetch(LegalKind kind) async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}${kind.path}'),
      headers: const {'Accept': 'application/json'},
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw LegalUnavailable(kind);
    }

    // Ручка отдаёт markdown, а по Accept: application/json — объект с
    // заголовком, версией и телом. Второе удобнее: версия приезжает разобранной.
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) {
      return LegalDocument(
        title: decoded['title'] as String? ?? '',
        version: decoded['version'] as String? ?? '',
        body: decoded['body'] as String? ?? '',
      );
    }

    return LegalDocument(
      title: '',
      version: response.headers['x-legal-version'] ?? '',
      body: utf8.decode(response.bodyBytes),
    );
  }
}

/// Документа нет на сервере.
///
/// Текста для человека здесь нет и быть не может: слой данных языка экрана не
/// знает. Что показать вместо документа, решает лист — legal_sheet.dart.
class LegalUnavailable implements Exception {
  const LegalUnavailable(this.kind);

  final LegalKind kind;

  /// Только для журнала.
  @override
  String toString() => 'LegalUnavailable(${kind.name})';
}
