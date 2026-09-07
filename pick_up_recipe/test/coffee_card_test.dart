// Карточка кофе: «Обжарщик обещает» — обещание обжарщика, а не наше.
//
// У пачки, заведённой руками, обжарщика нет: дескрипторы в неё вписал сам
// человек. Раньше блок показывался всегда, и на такой пачке в нём висел
// одинокий чип с обрывком слова — с этого владелец и начал разговор.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/src/pages/coffee_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';

/// Клиент, который отдаёт одну пачку и молчит обо всём остальном.
///
/// Справочник методов и рецепты страница переживает без сети сама: без них
/// она показывает зерно и строку «способы не загрузились».
class _OnePackApiClient extends ApiClient {
  _OnePackApiClient({required this.roasterName}) : super(onAuthError: _nothing);

  static Future<void> _nothing() async {}

  final String roasterName;

  @override
  Future<http.Response> getCached(
    String endpoint,
    Map<String, String> queryParams, {
    required String cacheKey,
  }) async {
    if (endpoint != '/packs') return http.Response('[]', 200);

    return http.Response(
      jsonEncode({
        'id': 1,
        'pack_country': 'Бразилия',
        'pack_date': '2026-09-01',
        'pack_descriptors': ['малиновый', 'карамель'],
        'pack_image': '',
        'pack_name': 'бразилия',
        'pack_processing_method': <String>[],
        'pack_sca_score': 84,
        'pack_variety': 'арабика',
        'user_id': 1,
        'roaster_name': roasterName,
      }),
      200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

void main() {
  Future<void> pumpCard(WidgetTester tester, {required String roasterName}) async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<ApiClient>(
      _OnePackApiClient(roasterName: roasterName),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: lightTheme, home: const CoffeePage(packId: 1)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('карточка кофе', () {
    testWidgets('у пачки, заведённой руками, обещаний обжарщика нет', (tester) async {
      await pumpCard(tester, roasterName: '');

      expect(find.text('бразилия'), findsWidgets);
      expect(find.text('Обжарщик обещает'), findsNothing);
      expect(find.text('малиновый'), findsNothing);
    });

    testWidgets('у пачки по коду обжарщика блок остаётся', (tester) async {
      await pumpCard(tester, roasterName: 'Tasty Coffee');

      expect(find.text('Обжарщик обещает'), findsOneWidget);
      expect(find.text('малиновый'), findsOneWidget);
    });
  });
}
