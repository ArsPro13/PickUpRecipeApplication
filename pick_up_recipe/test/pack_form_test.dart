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
//
// Три теста внизу — про перевод. Форма целиком выпала из словаря, и на
// английском телефоне владелец видел английскую шапку приложения и русскую
// форму под ней. Последний из трёх сторожит разбор даты: подпись поля и пример
// в нём переводятся, а формат дд.ММ.гггг — нет, потому что ровно его читают
// parsePackDate и pack_request_model, и другой порядок частей молча подменил
// бы дату обжарки сегодняшней.
//
// Дату обжарки и оценку SCA больше не печатают — их крутят барабаном. Группа
// «барабаны формы» проверяет, что выбранное на барабане доезжает до сервера.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/inserting_pack_info_widget.dart';
import 'package:pick_up_recipe/src/general_widgets/app_wheel.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';

/// Клиент, который не ходит в сеть и запоминает, что у него просили отправить.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(onAuthError: _nothing);

  static Future<void> _nothing() async {}

  /// Что правда ушло на сервер — по порядку.
  final List<(String, Map<String, dynamic>)> posts = [];

  /// Чем сервер отвечает на отправку пачки. Не 200 — форма показывает плашку
  /// «Пачка не отправилась».
  int postStatus = 200;

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
    if (postStatus != 200) return http.Response('', postStatus);

    return http.Response(jsonEncode(_pack), 200);
  }
}

/// Приложение вокруг формы. Язык задаётся прямо, а не берётся у машины,
/// на которой запустили тест: половина проверок здесь — про то, каким языком
/// форма разговаривает.
Widget _app(Widget form, Locale locale) {
  return ProviderScope(
    child: MaterialApp(
      theme: lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: form)),
    ),
  );
}

/// Всё, что экран нарисовал словами: подписи, пояснения, подсказки внутри
/// пустых полей и подсказка у корзины. Значения из справочника сюда не
/// попадают — их в тесте нет вовсе, сервер отдаёт пустые списки.
Iterable<String> _drawnText(WidgetTester tester) sync* {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final data = text.data;
    if (data != null) yield data;
  }
  for (final tooltip in tester.widgetList<Tooltip>(find.byType(Tooltip))) {
    final message = tooltip.message;
    if (message != null) yield message;
  }
}

/// Ни одной русской буквы в том, что нарисовал экран.
void _expectNoCyrillic(WidgetTester tester) {
  final cyrillic = RegExp('[а-яёА-ЯЁ]');

  for (final line in _drawnText(tester)) {
    expect(
      cyrillic.hasMatch(line),
      isFalse,
      reason: 'на английском экране осталось «$line»',
    );
  }
}

void main() {
  late _FakeApiClient api;

  setUp(() async {
    api = _FakeApiClient();
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<ApiClient>(api);
  });

  Future<ProviderContainer> pumpForm(
    WidgetTester tester, {
    Locale locale = const Locale('ru'),
  }) async {
    // Окно выше обычного: форма длинная, а кнопка «Отправить» нужна нажимаемой.
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const InsertingPackInfoWidget(), locale));
    // Не pumpAndSettle: рамка-подсказка над фотографией дышит без остановки.
    await tester.pump();

    return ProviderScope.containerOf(
      tester.element(find.byType(InsertingPackInfoWidget)),
    );
  }

  /// Словарь того языка, на котором сейчас нарисована форма.
  AppLocalizations textsOf(WidgetTester tester) => AppLocalizations.of(
        tester.element(find.byType(InsertingPackInfoWidget)),
      );

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

  /// Дата, пришедшая в форму снаружи — так её кладёт разбор снимка пачки.
  Future<void> seedDate(
      ProviderContainer container, WidgetTester tester, String date) async {
    final form = container.read(formNotifierProvider);
    await container.read(formNotifierProvider.notifier).updateForm(
          country: form.country,
          region: form.region,
          scaScore: form.scaScore,
          variety: form.variety,
          processingMethod: form.processingMethod,
          roastDate: date,
          descriptors: form.descriptors,
          image: form.image,
        );
    await tester.pump();
  }

  /// Шторка доехала, барабан встал. Не pumpAndSettle: рамка над фото дышит
  /// без остановки и не успокоится никогда.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Крутит колонку барабана на [items] строк вперёд — с порогом пальца,
  /// как в тестах самого барабана.
  Future<void> spin(WidgetTester tester, Finder wheel, int items) async {
    final distance = kWheelItemExtent * items;
    await tester.drag(
        wheel, Offset(0, -(distance + distance.sign * kDragSlopDefault)));
    await settle(tester);
  }

  Future<Map<String, dynamic>> submit(WidgetTester tester) async {
    final label = textsOf(tester).packFormSubmit;
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
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
          reason:
              'начало слова «$typed» уехало в форму, не дождавшись конца ввода',
        );
      }

      // И поле не переписано огрызком: человек видит то, что набрал.
      expect(textOf(tester, 'descriptor-0'), 'малина');
    });

    testWidgets('законченный ввод кладёт в форму слово целиком',
        (tester) async {
      final container = await pumpForm(tester);

      await fill(tester, 'descriptor-0', 'малина');

      expect(container.read(formNotifierProvider).descriptors, ['малина']);
    });

    testWidgets('однобуквенный дескриптор не уезжает на сервер',
        (tester) async {
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

    testWidgets('поля «Название» нет, «Регион» есть и необязателен',
        (tester) async {
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

    testWidgets('без страны пачка не уезжает: имя было бы пустым',
        (tester) async {
      await pumpForm(tester);

      await fill(tester, 'descriptor-0', 'малина');
      await tester.ensureVisible(find.text('Отправить'));
      await tester.tap(find.text('Отправить'));
      await tester.pump();

      expect(api.posts, isEmpty);
      expect(find.text('Без страны пачку нечем назвать'), findsOneWidget);
    });

    testWidgets('дата обжарки доезжает до сервера', (tester) async {
      final container = await pumpForm(tester);

      await fill(tester, 'country', 'Бразилия');
      // Дата приходит в поле и снаружи — разбором снимка пачки, — и тогда
      // стоит в том же формате, в каком её читает запрос.
      await seedDate(container, tester, '01.09.2026');
      expect(textOf(tester, 'roast-date'), '01.09.2026');

      expect((await submit(tester))['pack_date'], '2026-09-01T00:00:00Z');
    });

    testWidgets('снимок пачки уезжает вместе с ней', (tester) async {
      // Прозрачный пиксель в base64 — ровно то, что кладёт в форму камера.
      const photo = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4'
          '2mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

      final container = await pumpForm(tester);
      await container
          .read(formNotifierProvider.notifier)
          .updateImage(image: photo);
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
        _app(const InsertingPackInfoWidget(), const Locale('ru')),
      );
      await tester.pump();

      // Переполнение Flex приезжает исключением из разметки: молча оно только
      // рисует жёлтую полоску в углу, которую в тесте никто не увидит.
      expect(tester.takeException(), isNull);
    });

    testWidgets('следующее поле появляется по кнопке, а не само',
        (tester) async {
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

    testWidgets('на английской локали форма не рисует кириллицу',
        (tester) async {
      await pumpForm(tester, locale: const Locale('en'));
      final texts = textsOf(tester);

      _expectNoCyrillic(tester);

      // Вторая строка в списке — ради корзины: у неё своя подсказка, и
      // на одной строке корзины нет вовсе.
      await tester.ensureVisible(find.text(texts.packFormAddDescriptor));
      await tester.tap(find.text(texts.packFormAddDescriptor));
      await tester.pump();

      // Отправка без страны — ради ошибки под полем: она тоже подпись экрана.
      await tester.ensureVisible(find.text(texts.packFormSubmit));
      await tester.tap(find.text(texts.packFormSubmit));
      await tester.pump();
      expect(api.posts, isEmpty, reason: 'форма уехала без обязательного поля');

      _expectNoCyrillic(tester);
    });

    testWidgets('плашка «пачка не отправилась» тоже на языке экрана',
        (tester) async {
      // Причина от сервера остаётся технической строкой — переводится рамка
      // вокруг неё, а не текст исключения.
      api.postStatus = 500;
      await pumpForm(tester, locale: const Locale('en'));

      await fill(tester, 'country', 'Brazil');
      await submit(tester);
      await tester.pump();

      expect(find.text(textsOf(tester).packFormSubmitFailed), findsOneWidget);

      _expectNoCyrillic(tester);
    });

    testWidgets('перевод не задел разбор даты: 09.09.2026 доезжает как раньше',
        (tester) async {
      // Подпись поля и пояснение под ним переведены, а маска — нет: точки и
      // порядок частей читает pack_request_model, и от них зависит, доедет ли
      // набранная дата или сервер молча поставит сегодняшнюю.
      //
      // Дат две. 09.09.2026 — та, что владелец набирал на видео: в ней день и
      // месяц совпали, и она отвечает только на вопрос «принимается ли».
      // 31.12.2025 отвечает на второй: день от месяца отличим, и переставленные
      // местами части не пройдут ни маску, ни разбор.
      const cases = [
        ('09.09.2026', '2026-09-09T00:00:00Z'),
        ('31.12.2025', '2025-12-31T00:00:00Z'),
      ];

      for (final locale in [const Locale('ru'), const Locale('en')]) {
        for (final (shown, sent) in cases) {
          api.posts.clear();
          await pumpForm(tester, locale: locale);

          final container = ProviderScope.containerOf(
              tester.element(find.byType(InsertingPackInfoWidget)));
          await fill(tester, 'country', 'Бразилия');
          await seedDate(container, tester, shown);
          expect(
            textOf(tester, 'roast-date'),
            shown,
            reason: 'формат даты разъехался на локали ${locale.languageCode}',
          );

          expect(
            (await submit(tester))['pack_date'],
            sent,
            reason:
                'дата обжарки уехала не той на локали ${locale.languageCode}',
          );
        }
      }
    });
  });

  group('барабаны формы', () {
    testWidgets('дата обжарки выбирается барабаном и доезжает до сервера',
        (tester) async {
      await pumpForm(tester);
      await fill(tester, 'country', 'Бразилия');

      await tester.ensureVisible(fieldByKey('roast-date'));
      await tester.tap(fieldByKey('roast-date'));
      await settle(tester);

      // Пустое поле открывает барабан на сегодняшнем дне. Год назад — один
      // поворот колонки лет: по-русски она третья — число, месяц, год.
      expect(find.byType(ListWheelScrollView), findsNWidgets(3));
      await spin(tester, find.byType(ListWheelScrollView).at(2), -1);
      await tester.tap(find.text('Готово'));
      await settle(tester);

      final now = DateTime.now();
      final day =
          math.min(now.day, DateUtils.getDaysInMonth(now.year - 1, now.month));
      String two(int value) => value.toString().padLeft(2, '0');

      expect(textOf(tester, 'roast-date'),
          '${two(day)}.${two(now.month)}.${now.year - 1}');
      expect((await submit(tester))['pack_date'],
          '${now.year - 1}-${two(now.month)}-${two(day)}T00:00:00Z');
    });

    testWidgets('у даты есть «Сегодня» и крестик, возвращающий пустоту',
        (tester) async {
      await pumpForm(tester);
      final texts = textsOf(tester);

      await tester.ensureVisible(find.text(texts.packFormToday));
      await tester.tap(find.text(texts.packFormToday));
      await tester.pump();

      final now = DateTime.now();
      String two(int value) => value.toString().padLeft(2, '0');
      expect(textOf(tester, 'roast-date'),
          '${two(now.day)}.${two(now.month)}.${now.year}');

      // Пустое поле — тоже ответ: тогда дату поставит сервер.
      await tester.tap(find.descendant(
        of: find.byKey(const ValueKey('roast-date')),
        matching: find.byTooltip(texts.clear),
      ));
      await tester.pump();
      expect(textOf(tester, 'roast-date'), '');
    });

    testWidgets('клавиатура у даты и оценки не открывается', (tester) async {
      await pumpForm(tester);

      for (final key in ['roast-date', 'sca']) {
        final field = tester.widget<EditableText>(find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(EditableText),
        ));
        expect(field.readOnly, isTrue, reason: key);
      }
    });

    testWidgets('оценка SCA: «Готово» у пустого поля ставит показанное число',
        (tester) async {
      await pumpForm(tester);
      await fill(tester, 'country', 'Бразилия');

      await tester.ensureVisible(fieldByKey('sca'));
      await tester.tap(fieldByKey('sca'));
      await settle(tester);

      // Открылся на примере из пустого поля — 86 — и на одну строку выше
      // стал 87.
      await spin(tester, find.byType(ListWheelScrollView), 1);
      await tester.tap(find.text('Готово'));
      await settle(tester);

      expect(textOf(tester, 'sca'), '87');
      expect((await submit(tester))['pack_sca_score'], 87);
    });
  });
}
