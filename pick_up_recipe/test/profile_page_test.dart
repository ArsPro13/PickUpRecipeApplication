// Профиль: лист выбора языка и строка «Чаще всего».
//
// Оба случая пришли снимком с телефона владельца (6 ноября 2026). В листе
// «Язык» строки стояли вплотную к краям экрана: значки у левого, галочка у
// правого — боковых полей у строки нет, в карточках их даёт карточка, а лист
// не давал. Строкой выше «Чаще всего» стояло столбиком по букве: значение
// «Харио V60 (Hario V60) · 5 рецептов» забирало строку целиком.

import 'package:auto_route/auto_route.dart';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:pick_up_recipe/core/api_client.dart';
import 'package:pick_up_recipe/l10n/app_localizations.dart';
import 'package:pick_up_recipe/prefs_key.dart';
import 'package:pick_up_recipe/src/features/brew_methods/application/brew_methods_state.dart';
import 'package:pick_up_recipe/src/features/brew_methods/data_sources/remote/brew_method_service.dart';
import 'package:pick_up_recipe/src/features/brew_methods/domain/brew_method.dart';
import 'package:pick_up_recipe/src/features/grinders/application/grinder_state.dart';
import 'package:pick_up_recipe/src/features/grinders/data_sources/remote/grinder_service.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/models/grinder_model.dart';
import 'package:pick_up_recipe/src/features/recipes/application/state/recipes_list_state.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/general_widgets/app_icon.dart';
import 'package:pick_up_recipe/src/general_widgets/app_kit.dart';
import 'package:pick_up_recipe/src/pages/profile_page.dart';
import 'package:pick_up_recipe/src/themes/app_icons.dart';
import 'package:pick_up_recipe/src/themes/app_theme.dart';
import 'package:pick_up_recipe/src/themes/app_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Router extends RootStackRouter {
  @override
  List<AutoRoute> get routes => const [];
}

/// Пять рецептов под один прибор — будет чему стоять в «Чаще всего».
class _Recipes extends RecipeService {
  @override
  Future<List<RecipeData>?> getByParams({
    int? packId,
    int? grinderId,
    int? grindStep,
    int? grindSubStep,
    String? device,
    String? startDate,
    String? endDate,
    int? offset,
    int? limit,
    String? sortBy,
    bool allVersions = false,
  }) async {
    return [
      for (var pack = 1; pack <= 5; pack++)
        RecipeData(
          hasEstimation: true,
          id: pack,
          device: 'hario_v60',
          date: '2026-10-0${pack}T08:00:00Z',
          packId: pack,
          grinderId: 0,
          grindStep: '',
          grindSubStep: null,
          water: 250,
          time: 150,
          temperature: 93,
          load: 15,
          title: '',
          notes: '',
          grindDescriptor: '',
          agitationLevel: null,
          steps: const [],
        ),
    ];
  }
}

/// Название прибора — как на телефоне владельца: русское с английским в
/// скобках. Оно и делает значение строки длинным.
class _Methods extends BrewMethodService {
  @override
  Future<List<BrewMethod>> getMethods() async => const [
        BrewMethod(
            id: 1,
            slug: 'hario_v60',
            name: 'Харио V60 (Hario V60)',
            iconKey: 'v60',
            groupId: 1),
      ];

  @override
  Future<List<BrewMethodGroup>> getGroups() async => const [
        BrewMethodGroup(id: 1, slug: 'pourover', name: 'Пуровер', iconKey: ''),
      ];
}

class _NoGrinders implements GrinderService {
  @override
  Future<List<Grinder>> getAllGrinders() async => const [];

  @override
  Future<List<UserGrinder>> getUserGrinders() async => const [];

  @override
  Future<List<UserGrinder>> setUserGrinders(
    List<Grinder> grinders, {
    int? primaryGrinderId,
  }) async =>
      const [];
}

/// Полка пачек пуста: профилю хватает рецептов.
class _SilentApiClient extends ApiClient {
  _SilentApiClient() : super(onAuthError: _nothing);

  static Future<void> _nothing() async {}

  @override
  Future<http.Response> getCached(
    String endpoint,
    Map<String, String> queryParams, {
    required String cacheKey,
  }) async {
    return http.Response('[]', 200);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EncryptedSharedPreferences.initialize(prefsKey);
    await EncryptedSharedPreferences.getInstance().clear();

    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<ApiClient>(_SilentApiClient());
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    // Ширина телефона владельца в логических точках.
    tester.view.physicalSize = const Size(393, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipeServiceProvider.overrideWithValue(_Recipes()),
          brewMethodServiceProvider.overrideWithValue(_Methods()),
          grinderStateProvider
              .overrideWith((ref) => GrinderStateNotifier(_NoGrinders())),
        ],
        child: MaterialApp(
          theme: lightTheme,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StackRouterScope(
            controller: _Router(),
            stateHash: 0,
            child: const ProfilePage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('лист «Язык»', () {
    Future<void> openSheet(WidgetTester tester) async {
      await pumpProfile(tester);
      await tester.tap(find.widgetWithText(AppRow, 'Язык'));
      await tester.pumpAndSettle();
    }

    testWidgets('строки стоят с теми же полями, что и заголовок',
        (tester) async {
      await openSheet(tester);

      final list = find.byKey(const ValueKey('profile-language-list'));
      final title = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Язык'),
      );
      final rows = find.descendant(of: list, matching: find.byType(AppRow));

      expect(rows, findsNWidgets(4), reason: 'как в системе и три языка');
      for (var index = 0; index < 4; index++) {
        final row = tester.getRect(rows.at(index));
        expect(row.left, tester.getTopLeft(title).dx,
            reason: 'значок языка прилип к левому краю экрана');
        expect(row.right, 393 - AppSpacing.s5,
            reason: 'галочка прилипла к правому краю экрана');
      }
    });

    testWidgets('выбранный язык отмечен галочкой, и она не у края',
        (tester) async {
      await openSheet(tester);
      // Язык пока «как в системе» — выбираем русский и открываем лист снова.
      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppRow, 'Язык'));
      await tester.pumpAndSettle();

      final mark = find.descendant(
        of: find.widgetWithText(AppRow, 'Русский').last,
        matching: find.byWidgetPredicate(
          (widget) => widget is AppIcon && widget.asset == AppIcons.uiCheck,
        ),
      );
      expect(mark, findsOneWidget);
      expect(
          tester.getRect(mark).right, lessThanOrEqualTo(393 - AppSpacing.s5));
    });
  });

  group('строка «Чаще всего»', () {
    testWidgets('длинное значение не складывает подпись столбиком',
        (tester) async {
      await pumpProfile(tester);

      final label = find.text('Чаще всего');
      expect(label, findsOneWidget);
      expect(find.textContaining('Харио V60 (Hario V60)'), findsOneWidget);

      final paragraph = tester.renderObject<RenderParagraph>(label);
      final line = paragraph.getMaxIntrinsicHeight(double.infinity);
      // Подпись — в две строки по словам, не длиннее. Раньше ей оставалось
      // по букве на строку: десять строк на десять букв.
      expect(paragraph.size.height, lessThanOrEqualTo(line * 2 + 0.5));

      final value = tester.getSize(find.textContaining('Харио V60'));
      expect(value.width, lessThanOrEqualTo(393 / 2),
          reason: 'значению — не больше половины экрана, дальше перенос');
      expect(tester.takeException(), isNull);
    });
  });
}
