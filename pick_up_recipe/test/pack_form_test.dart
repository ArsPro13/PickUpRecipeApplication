// Форма ручного добавления пачки.
//
// Здесь проверяется то, на что жаловался владелец: набор — это процесс, а не
// поток значений; на экране не должно быть английского; поля «Название» нет,
// а «Регион» есть; дата доезжает до сервера; следующее поле появляется по
// кнопке, а не само.
//
// Про «м» на карточке пачки: форма клала в состояние текст поля на каждое
// нажатие клавиши, а следующая перерисовка возвращала огрызок обратно в поле.
// Человек печатал слово, в поле оставалась первая буква, и она же уезжала
// на сервер.

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
    // Не pumpAndSettle: рамка-подсказка над фотографией дышит без остановки.
    await tester.pump();

    return ProviderScope.containerOf(
      tester.element(find.byType(InsertingPackInfoWidget)),
    );
  }

  Finder fieldByKey(String key) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(TextFormField),
      );

  /// Что стоит в поле прямо сейчас. Через контроллер, а не через find.text:
  /// бледная подсказка внутри поля остаётся в дереве и находится тоже.
  String textOf(WidgetTester tester, String key) => tester
      .widget<EditableText>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;

  Future<void> fill(WidgetTester tester, String key, String text) async {
    await tester.enterText(fieldByKey(key), text);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
  }

  Future<Map<String, dynamic>> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Отправить'));
    await tester.tap(find.text('Отправить'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    return api.posts.firstWhere((call) => call.$1 == '/packs').$2;
  }

  group('форма пачки без кода', () {
    testWidgets('посимвольный набор не кладёт в дескрипторы огрызки слова',
        (tester) async {
      final container = await pumpForm(tester);

      for (final typed in ['м', 'ма', 'мал', 'мали', 'малин', 'малина']) {
        await tester.enterText(fieldByKey('descriptor-0'), typed);
        await tester.pump();

        expect(
          container.read(formNotifierProvider).descriptors ?? const <String>[],
          isEmpty,
          reason: 'начало слова «$typed» уехало в форму, не дождавшись конца ввода',
        );
      }

      // И поле не переписано огрызком: человек видит то, что набрал.
      expect(textOf(tester, 'descriptor-0'), 'малина');
    });

    testWidgets('законченный ввод кладёт в форму слово целиком', (tester) async {
      final container = await pumpForm(tester);

      await fill(tester, 'descriptor-0', 'малина');

      expect(container.read(formNotifierProvider).descriptors, ['малина']);
    });

    testWidgets('однобуквенный дескриптор не уезжает на сервер', (tester) async {
      await pumpForm(tester);

      await fill(tester, 'country', 'Бразилия');
      await fill(tester, 'descriptor-0', 'м');

      expect((await submit(tester))['pack_descriptors'], isEmpty);
    });

    testWidgets('английского на экране не осталось', (tester) async {
      await pumpForm(tester);

      const english = [
        'Add a new pack',
        'Camera',
        'Gallery',
        'Name',
        'Country',
        'Variety',
        'Descriptors',
        'Processing methods',
        'Roast date',
      ];
      for (final word in english) {
        expect(find.text(word), findsNothing, reason: word);
      }
    });

    testWidgets('поля «Название» нет, «Регион» есть и необязателен', (tester) async {
      await pumpForm(tester);

      expect(find.byKey(const ValueKey('region')), findsOneWidget);

      // Одной страны достаточно, чтобы пачка уехала: регион не обязателен.
      await fill(tester, 'country', 'Бразилия');
      expect((await submit(tester))['pack_name'], 'Бразилия');
    });

    testWidgets('имя пачки собирается из страны и региона', (tester) async {
      await pumpForm(tester);

      await fill(tester, 'country', 'Бразилия');
      await fill(tester, 'region', 'Серрадо');

      expect((await submit(tester))['pack_name'], 'Бразилия · Серрадо');
    });

    testWidgets('без страны пачка не уезжает: имя было бы пустым', (tester) async {
      await pumpForm(tester);

      await fill(tester, 'descriptor-0', 'малина');
      await tester.ensureVisible(find.text('Отправить'));
      await tester.tap(find.text('Отправить'));
      await tester.pump();

      expect(api.posts, isEmpty);
      expect(find.text('Без страны пачку нечем назвать'), findsOneWidget);
    });

    testWidgets('дата обжарки доезжает до сервера', (tester) async {
      await pumpForm(tester);

      await fill(tester, 'country', 'Бразилия');
      // Точки расставляются сами: человек набирает восемь цифр подряд.
      await fill(tester, 'roast-date', '01092026');
      expect(textOf(tester, 'roast-date'), '01.09.2026');

      expect((await submit(tester))['pack_date'], '2026-09-01T00:00:00Z');
    });

    testWidgets('снимок пачки уезжает вместе с ней', (tester) async {
      // Прозрачный пиксель в base64 — ровно то, что кладёт в форму камера.
      const photo = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4'
          '2mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

      final container = await pumpForm(tester);
      await container.read(formNotifierProvider.notifier).updateImage(image: photo);
      await tester.pump();

      await fill(tester, 'country', 'Бразилия');

      expect((await submit(tester))['pack_image'], photo);
    });

    testWidgets('на узком экране ничего не вылезает за край', (tester) async {
      // 360 точек по ширине — самый тесный телефон, ради которого экран и
      // проверяется. Шрифт в тестах шире настоящего, так что запас есть.
      tester.view.physicalSize = const Size(360, 3000);
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

      // Переполнение Flex приезжает исключением из разметки: молча оно только
      // рисует жёлтую полоску в углу, которую в тесте никто не увидит.
      expect(tester.takeException(), isNull);
    });

    testWidgets('следующее поле появляется по кнопке, а не само', (tester) async {
      await pumpForm(tester);

      await tester.enterText(fieldByKey('descriptor-0'), 'малина');
      await tester.pump();
      expect(
        find.byKey(const ValueKey('descriptor-1')),
        findsNothing,
        reason: 'поле выскочило само, пока человек печатал',
      );

      await tester.ensureVisible(find.text('Добавить дескриптор'));
      await tester.tap(find.text('Добавить дескриптор'));
      await tester.pump();

      expect(find.byKey(const ValueKey('descriptor-1')), findsOneWidget);
    });
  });
}
