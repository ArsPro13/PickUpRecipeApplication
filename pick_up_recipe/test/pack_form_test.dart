// Форма ручного добавления пачки: набор — это процесс, а не поток значений.
//
// Владелец увидел на карточке пачки «бразилия» единственный чип с буквой «м»
// в разделе «Обжарщик обещает». Буква приехала не с карточки: форма клала в
// состояние текст поля на каждое нажатие клавиши, а следующая перерисовка
// возвращала этот огрызок обратно в поле. Человек печатал слово, в поле
// оставалась первая буква, и она же уезжала на сервер.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/inserting_pack_info_widget.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';

/// Клиент, который не ходит в сеть и запоминает, что у него просили отправить.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(onAuthError: _nothing);

  static Future<void> _nothing() async {}

  /// Что правда ушло на сервер — по порядку.
  final List<(String, Map<String, dynamic>)> posts = [];

  static const Map<String, dynamic> _pack = {
    'id': 1,
    'pack_country': 'Brazil',
    'pack_date': '2026-09-01',
    'pack_descriptors': <String>[],
    'pack_image': '',
    'pack_name': 'Brazil',
    'pack_processing_method': <String>[],
    'pack_sca_score': 84,
    'pack_variety': 'arabica',
    'user_id': 1,
  };

  @override
  Future<http.Response> getPossibleValues(
    String endpoint,
    Map<String, String> queryParams,
  ) async {
    return http.Response('[]', 200);
  }

  @override
  Future<http.Response> getCached(
    String endpoint,
    Map<String, String> queryParams, {
    required String cacheKey,
  }) async {
    return http.Response('[]', 200);
  }

  @override
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    posts.add((endpoint, body));
    return http.Response(jsonEncode(_pack), 200);
  }
}

void main() {
  late _FakeApiClient api;

  setUp(() async {
    api = _FakeApiClient();
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<ApiClient>(api);
  });

  Future<ProviderContainer> pumpForm(WidgetTester tester) async {
    // Окно выше обычного: форма длинная, а кнопка «Отправить» нужна нажимаемой.
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(child: InsertingPackInfoWidget()),
          ),
        ),
      ),
    );
    await tester.pump();

    return ProviderScope.containerOf(
      tester.element(find.byType(InsertingPackInfoWidget)),
    );
  }

  /// Поле дескриптора ищется по подписи, а не по ключу: тот же поиск должен
  /// работать и на старом коде, иначе тест не докажет, что чинил настоящее.
  Finder descriptorField(int number) => find.ancestor(
        of: find.text('Descriptor $number'),
        matching: find.byType(TextField),
      );

  group('форма пачки без кода', () {
    testWidgets('посимвольный набор не кладёт в дескрипторы огрызки слова',
        (tester) async {
      final container = await pumpForm(tester);

      for (final typed in ['м', 'ма', 'мал', 'мали', 'малин', 'малина']) {
        await tester.enterText(descriptorField(1), typed);
        await tester.pump();

        expect(
          container.read(formNotifierProvider).descriptors ?? const <String>[],
          isEmpty,
          reason: 'начало слова «$typed» уехало в форму, не дождавшись конца ввода',
        );
      }

      // И поле не переписано огрызком: человек видит то, что набрал.
      expect(find.text('малина'), findsOneWidget);
    });

    testWidgets('законченный ввод кладёт в форму слово целиком', (tester) async {
      final container = await pumpForm(tester);

      await tester.enterText(descriptorField(1), 'малина');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(container.read(formNotifierProvider).descriptors, ['малина']);
    });

    testWidgets('однобуквенный дескриптор не уезжает на сервер', (tester) async {
      await pumpForm(tester);

      await tester.enterText(descriptorField(1), 'м');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      await tester.ensureVisible(find.text('Отправить'));
      await tester.tap(find.text('Отправить'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final sent = api.posts.firstWhere((call) => call.$1 == '/packs');
      expect(sent.$2['pack_descriptors'], isEmpty);
    });
  });
}
