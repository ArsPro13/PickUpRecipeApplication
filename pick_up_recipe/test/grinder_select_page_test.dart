// Экран кофемолки: перевод и выбор одним касанием.
//
// На записи владельца (кадры 260s–270s) нижняя панель уже английская —
// «Packs / Recipes / Scan / Profile», — а над ней стоит «Кофемолка», «Найти
// кофемолку», «Ручные» и «Сохранить». Экран из перевода выпал целиком.
//
// Проверяется не список ключей, а результат: на собранном экране при
// английской локали кириллицы не остаётся ни в одной строке, которую рисует
// сам экран. Имена кофемолок при этом обязаны уцелеть — они приходят из
// справочника, и в них кириллица законна: «Eureka Mignon  жернова 50mm
// Filtro Pro» ищется по имени строгим равенством, и перевод разорвал бы связь
// с grinder_translator.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/src/features/grinders/application/grinder_state.dart';
import 'package:pick_up_recipe/src/features/grinders/data_sources/remote/grinder_service.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/models/grinder_model.dart';
import 'package:auto_route/auto_route.dart';
import 'package:pick_up_recipe/src/pages/grinder_select_page.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';

/// Кусок настоящего справочника: имена взяты из миграции слово в слово.
const List<Grinder> catalog = [
  Grinder(id: 0, name: 'Base Grinder'),
  Grinder(id: 11, name: 'Comandante C40', kind: GrinderKind.manual),
  Grinder(
      id: 17,
      name: 'Eureka Mignon  жернова 50mm Filtro Pro',
      kind: GrinderKind.electric),
  Grinder(id: 40, name: 'Timemore Chestnut C2', kind: GrinderKind.manual),
];

/// Справочник отвечает, набор пользователя пуст: так экран и открывают
/// в первый раз.
///
/// Сохранение запоминается: что именно экран отдал наружу — единственная
/// проверяемая правда о выборе. Считать кружки на экране значило бы
/// проверять оформление вместо поведения.
class CatalogService implements GrinderService {
  List<Grinder>? savedGrinders;
  int? savedPrimaryId;

  @override
  Future<List<Grinder>> getAllGrinders() async => catalog;

  @override
  Future<List<UserGrinder>> getUserGrinders() async => const [];

  @override
  Future<List<UserGrinder>> setUserGrinders(
    List<Grinder> grinders, {
    int? primaryGrinderId,
  }) async {
    savedGrinders = grinders;
    savedPrimaryId = primaryGrinderId;
    return [
      for (final grinder in grinders)
        UserGrinder(
            grinder: grinder, isPrimary: grinder.id == primaryGrinderId),
    ];
  }
}

/// Справочник и УЖЕ выбранная кофемолка: так экран открывают во второй раз.
class ChosenService extends CatalogService {
  ChosenService(this.chosen);

  final Grinder chosen;

  @override
  Future<List<UserGrinder>> getUserGrinders() async =>
      [UserGrinder(grinder: chosen, isPrimary: true)];
}

/// Роутер-заглушка: экран после сохранения уходит назад, и без роутера
/// этот уход падает. Тот же приём, что в recipes_page_test — поднимать ради
/// одного `maybePop` настоящий AppRouter значило бы тянуть в тест половину
/// приложения вместе с навигацией всех экранов.
class _StubRouter extends RootStackRouter {
  int popped = 0;

  @override
  List<AutoRoute> get routes => const [];

  @override
  Future<bool> maybePop<T extends Object?>([T? result]) async {
    popped++;
    return true;
  }
}

final RegExp cyrillic = RegExp('[а-яёА-ЯЁ]');

/// Имена справочника: их кириллица — данные, а не недоперевод.
final Set<String> catalogNames = catalog.map((grinder) => grinder.name).toSet();

/// Всё, что экран показал словами: подписи, заголовки, кнопки и подсказка
/// поля поиска. Подсвеченное имя собирается из кусков `Text.rich`, поэтому
/// берётся не только `data`.
List<String> screenTexts(WidgetTester tester) {
  final found = <String>[];

  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final value = text.data ?? text.textSpan?.toPlainText();
    if (value != null && value.trim().isNotEmpty) found.add(value);
  }

  for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
    final hint = field.decoration?.hintText;
    if (hint != null) found.add(hint);
  }

  for (final button in tester.widgetList<IconButton>(find.byType(IconButton))) {
    final tooltip = button.tooltip;
    if (tooltip != null) found.add(tooltip);
  }

  return found;
}

/// Строки, за которые отвечает экран: всё, кроме имён из справочника.
List<String> ownTexts(WidgetTester tester) {
  return screenTexts(tester)
      .where((text) => !catalogNames.contains(text))
      .toList();
}

typedef Pumped = ({CatalogService service, _StubRouter router});

Future<Pumped> pumpGrinders(WidgetTester tester, String language,
    {CatalogService? withService}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final service = withService ?? CatalogService();
  final router = _StubRouter();

  await tester.pumpWidget(ProviderScope(
    overrides: [grinderServiceProvider.overrideWithValue(service)],
    child: MaterialApp(
      theme: lightTheme,
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StackRouterScope(
        controller: router,
        stateHash: 0,
        child: const GrinderSelectPage(),
      ),
    ),
  ));

  await tester.pumpAndSettle();

  return (service: service, router: router);
}

/// Ввод в поле поиска вместе с паузой, которую экран держит намеренно:
/// список ждёт, пока человек допечатает.
Future<void> search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(AppDuration.base);
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations ru;
  late AppLocalizations en;

  setUpAll(() async {
    ru = await AppLocalizations.delegate.load(const Locale('ru'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('счётчик моделей справочника', () {
    // Число берётся из справочника, а не пишется словом: в базе полсотни
    // записей сегодня и другое число завтра. Формы слова собирает ICU —
    // у русского их три, у английского две, и рукой это не пишется.
    test('по-русски склоняется по числу', () {
      expect(ru.grinderCatalogSize(1), contains('1 модель'));
      expect(ru.grinderCatalogSize(2), contains('2 модели'));
      expect(ru.grinderCatalogSize(5), contains('5 моделей'));
      expect(ru.grinderCatalogSize(11), contains('11 моделей'));
      expect(ru.grinderCatalogSize(51), contains('51 модель'));
    });

    test('по-английски множественное только у одного', () {
      expect(en.grinderCatalogSize(1), contains('1 model'));
      expect(en.grinderCatalogSize(2), contains('2 models'));
      expect(en.grinderCatalogSize(5), contains('5 models'));
    });

    test('в английской строке кириллицы нет', () {
      for (final count in [0, 1, 2, 5, 11, 51]) {
        expect(
          cyrillic.hasMatch(en.grinderCatalogSize(count)),
          isFalse,
          reason:
              'счётчик на $count остался русским: ${en.grinderCatalogSize(count)}',
        );
      }
    });
  });

  group('английская локаль', () {
    testWidgets('в списке справочника кириллицы нет ни в одной подписи экрана',
        (tester) async {
      await pumpGrinders(tester, 'en');

      expect(find.text(en.grinderTitle), findsOneWidget);
      expect(find.text(en.grinderKindManual), findsOneWidget);
      expect(find.text(en.grinderKindElectric), findsOneWidget);
      // Кофемолки нет ни одной — сверху приглашение выбрать, а не «выбрана».
      expect(find.text(en.grinderPick), findsOneWidget);

      for (final text in ownTexts(tester)) {
        expect(cyrillic.hasMatch(text), isFalse,
            reason: 'русская строка на экране: $text');
      }
    });

    testWidgets('имя кофемолки из справочника остаётся как записано',
        (tester) async {
      await pumpGrinders(tester, 'en');

      // Двойной пробел внутри имени — тоже данные: по имени сходится
      // grinder_translator, и любая нормализация рвёт связь.
      expect(
          find.text('Eureka Mignon  жернова 50mm Filtro Pro'), findsOneWidget);
    });

    testWidgets('касание строки применяется сразу и закрывает экран',
        (tester) async {
      final pumped = await pumpGrinders(tester, 'en');

      // Ни кнопки «Сохранить» внизу, ни «сделать основной» рядом со строкой:
      // выбор, назначение основной и сохранение — одно действие, а не три.
      expect(find.byType(TextButton), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Save'), findsNothing);

      await tester.tap(find.text('Timemore Chestnut C2'));
      await tester.pumpAndSettle();

      expect(pumped.service.savedGrinders, isNotNull,
          reason: 'касание не дошло до службы: нужен ещё один щелчок?');
      expect(pumped.service.savedGrinders!.map((g) => g.id), [40]);
      expect(pumped.service.savedPrimaryId, 40);
      expect(pumped.router.popped, 1, reason: 'экран не закрылся после выбора');

      for (final text in ownTexts(tester)) {
        expect(cyrillic.hasMatch(text), isFalse,
            reason: 'русская строка на экране: $text');
      }
    });

    testWidgets('выбранную видно сверху, и повторное касание ничего не пишет',
        (tester) async {
      final chosen = catalog.firstWhere((g) => g.id == 11);
      final pumped = await pumpGrinders(tester, 'en',
          withService: ChosenService(chosen));

      // Верхний блок отвечает на вопрос «а какая сейчас» до всякого поиска.
      expect(find.text(en.grinderCurrent), findsOneWidget);
      expect(find.text(en.grinderChangeTo), findsOneWidget);
      expect(find.text('Comandante C40'), findsWidgets);

      await tester.tap(find.text('Comandante C40').last);
      await tester.pumpAndSettle();

      expect(pumped.service.savedGrinders, isNull,
          reason: 'ту же самую записали заново');
      expect(pumped.router.popped, 1, reason: 'экран не закрылся');
    });

    testWidgets('пустой ответ поиска объясняется по-английски', (tester) async {
      await pumpGrinders(tester, 'en');
      await search(tester, 'zzzzzz');

      expect(find.text(en.grinderNotFound), findsOneWidget);
      expect(find.text(en.grinderShowAll), findsOneWidget);
      // Из трёх записей справочника видна одна: техническая «Base Grinder»
      // в выбор не идёт.
      expect(find.text(en.grinderCatalogSize(3)), findsOneWidget);

      for (final text in ownTexts(tester)) {
        expect(cyrillic.hasMatch(text), isFalse,
            reason: 'русская строка на экране: $text');
      }
    });

    testWidgets('подсказка «вы имели в виду» тоже переведена', (tester) async {
      await pumpGrinders(tester, 'en');
      // Три ошибки: поиск не нашёл ничего, но человек явно метил в Comandante.
      await search(tester, 'kommondonte');

      expect(find.text(en.grinderDidYouMean), findsOneWidget);
      expect(find.text('Comandante C40'), findsOneWidget);

      for (final text in ownTexts(tester)) {
        expect(cyrillic.hasMatch(text), isFalse,
            reason: 'русская строка на экране: $text');
      }
    });
  });

  group('русская локаль', () {
    testWidgets('экран остаётся прежним', (tester) async {
      await pumpGrinders(tester, 'ru');

      expect(find.text('Кофемолка'), findsOneWidget);
      expect(find.text('Ручные'), findsOneWidget);
      expect(find.text('Электрические'), findsOneWidget);
      expect(find.text(ru.grinderPick), findsOneWidget);
    });

    testWidgets('поиск набором латиницей находит кириллическое имя',
        (tester) async {
      await pumpGrinders(tester, 'ru');
      await search(tester, 'zhernova');

      expect(find.text(ru.grinderNotFound), findsNothing);
      expect(
        find.textContaining('жернова', findRichText: true),
        findsWidgets,
        reason: 'таблица раскладки в поиске сломана',
      );
    });
  });
}
