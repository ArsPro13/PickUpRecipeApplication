// Экран выбора кофемолки.
//
// Список сгруппирован по виду — ручные и электрические (ответ E7): в
// справочнике полсотни записей, и без группировки найти свою на глаз тяжело.
//
// Кофемолка выбирается ОДНА и одним касанием. До этого экран собирал набор
// галочками, а из набора отдельной кнопкой «сделать основной» назначалась
// главная: два действия ради одного решения, причём про второе легко было
// забыть — и тогда щелчки в рецептах считались по чужой шкале.
//
// Приложению нужна ровно одна: её имя стоит кнопкой в шапке главного экрана,
// её делениями подписан помол в каждом рецепте. Набор из нескольких нигде
// не использовался — только как место, откуда берут основную.
//
// Поиск нестрогий (пункт 16). Точное вхождение подстроки отвечало «такой
// кофемолки нет» на «commondante», «команданте» и на имя с двойным пробелом,
// набранное с одним, — и выхода из пустого экрана не было. Разбор запроса
// живёт в domain/grinder_search.dart, здесь остаётся только показ.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/network_status.dart';
import '../../l10n/app_localizations.dart';
import '../features/grinders/application/grinder_state.dart';
import '../features/grinders/domain/grinder_search.dart';
import '../features/grinders/domain/models/grinder_model.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class GrinderSelectPage extends ConsumerStatefulWidget {
  const GrinderSelectPage({super.key});

  @override
  ConsumerState<GrinderSelectPage> createState() => _GrinderSelectPageState();
}

class _GrinderSelectPageState extends ConsumerState<GrinderSelectPage> {
  final TextEditingController _search = TextEditingController();

  /// Запрос, по которому построен список. Отстаёт от поля на [_pause]:
  /// перебирать полсотни имён на каждое нажатие незачем, а список,
  /// прыгающий под пальцем, читать невозможно.
  String _query = '';
  Timer? _debounce;

  static const Duration _pause = AppDuration.base;

  /// Выбранная кофемолка. Правка применяется кнопкой, а не сразу: случайное
  /// касание не должно менять пересчёт помола во всех рецептах разом.
  int? _chosen;

  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(grinderStateProvider.notifier).loadCatalog();
      ref.read(grinderStateProvider.notifier).loadUserGrinders();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Переносит уже сохранённую кофемолку в локальный выбор ровно один раз.
  void _seedFrom(GrinderState state) {
    if (_initialised || state.userGrinders.isEmpty) return;
    _initialised = true;
    _chosen = state.primary?.id;
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_pause, () {
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  /// Ставит в поле готовый запрос: «Показать все» очищает, подсказка «Вы имели
  /// в виду» подставляет имя целиком. Ждать паузу тут нечего — нажали руками.
  void _setQuery(String value) {
    _debounce?.cancel();
    _search.text = value;
    _search.selection = TextSelection.collapsed(offset: value.length);
    setState(() => _query = value);
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final state = ref.watch(grinderStateProvider);
    _seedFrom(state);

    // Техническая запись справочника с нулевым идентификатором нужна базе, но
    // не человеку: «Base Grinder» стоял в списке наравне с настоящими.
    final catalog = selectableGrinders(state.catalog);
    final hits = searchGrinders(catalog, _query);

    return Scaffold(
      appBar: AppBar(title: Text(texts.grinderTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s2,
              AppSpacing.s4,
              AppSpacing.s3,
            ),
            child: TextField(
              controller: _search,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: texts.grinderSearchHint,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s3),
                  child: AppIcon(
                    AppIcons.uiSearch,
                    size: AppSizes.icon20,
                    color: context.colors.secondary,
                  ),
                ),
                // Крестик слушает поле напрямую, а не через _query: список
                // ждёт паузу, а кнопка очистки обязана появиться сразу.
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _search,
                  builder: (context, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: () => _setQuery(''),
                          tooltip: texts.clear,
                          icon: AppIcon(
                            AppIcons.uiClose,
                            size: AppSizes.icon20,
                            color: context.colors.secondary,
                          ),
                        ),
                ),
              ),
            ),
          ),
          Expanded(
            child: state.isLoading && state.catalog.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _results(catalog, hits),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: AppButton(
                label: texts.grinderSave,
                loading: state.isLoading && state.catalog.isNotEmpty,
                onPressed: _chosen == null ? null : () => _save(state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _results(List<Grinder> catalog, List<GrinderHit> hits) {
    if (hits.isEmpty) return _nothingFound(catalog);

    // С запросом список идёт одной лентой по убыванию совпадения: заголовки
    // групп перемешали бы порядок, а в поиске важно, что первым стоит самое
    // похожее. Без запроса возвращается прежний вид, сгруппированный по виду.
    if (_query.trim().isEmpty) return _byKind(catalog);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      children: [
        for (final hit in hits) _tile(hit.grinder, hit),
        const SizedBox(height: AppSpacing.s4),
      ],
    );
  }

  /// Заголовок группы списка.
  ///
  /// Вид кофемолки приходит с сервера кодом (`manual`, `electric`), а слово
  /// для человека стоит в словаре: перечислением его не записать, иначе на
  /// английском экране встанет русский заголовок.
  String _kindTitle(AppLocalizations texts, GrinderKind kind) {
    return switch (kind) {
      GrinderKind.manual => texts.grinderKindManual,
      GrinderKind.electric => texts.grinderKindElectric,
      GrinderKind.unknown => texts.grinderKindOther,
    };
  }

  Widget _byKind(List<Grinder> catalog) {
    final texts = AppLocalizations.of(context);
    final byKind = <GrinderKind, List<Grinder>>{};
    for (final grinder in catalog) {
      byKind.putIfAbsent(grinder.kind, () => []).add(grinder);
    }
    // По алфавиту внутри каждой группы. Порядок справочника — это порядок
    // строк в миграции: для того, кто ищет свою модель глазами, он случаен.
    for (final kind in byKind.keys) {
      byKind[kind] = grindersByName(byKind[kind]!);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      children: [
        for (final kind in GrinderKind.values)
          if (byKind[kind] != null) ...[
            SectionTitle(_kindTitle(texts, kind)),
            for (final grinder in byKind[kind]!) _tile(grinder, null),
          ],
        const SizedBox(height: AppSpacing.s4),
      ],
    );
  }

  /// Пустое состояние, из которого есть выход.
  ///
  /// Раньше здесь был тупик: ни «показать все», ни намёка на то, что человек
  /// ошибся в двух буквах. Число моделей берётся из справочника — написать
  /// «полсотни» значило бы соврать при первой же правке базы.
  Widget _nothingFound(List<Grinder> catalog) {
    final texts = AppLocalizations.of(context);
    final near = grinderDidYouMean(catalog, _query);

    return AppState(
      icon: AppIcons.stateEmpty,
      title: texts.grinderNotFound,
      description: catalog.isEmpty
          ? texts.grinderCatalogEmpty
          : texts.grinderCatalogSize(catalog.length),
      primaryAction: AppButton(
        label: texts.grinderShowAll,
        kind: AppButtonKind.secondary,
        onPressed: () => _setQuery(''),
      ),
      secondaryAction: near.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  texts.grinderDidYouMean,
                  style: context.texts.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s3),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.s2,
                  runSpacing: AppSpacing.s2,
                  children: [
                    for (final grinder in near)
                      AppChip(
                        label: grinder.name,
                        onTap: () => _setQuery(grinder.name),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _tile(Grinder grinder, GrinderHit? hit) {
    final chosen = _chosen == grinder.id;

    return AppRow(
      label: grinder.name,
      labelSpan: hit == null ? null : _highlight(grinder.name, hit),
      icon: AppIcons.metricGrind,
      // Повторное касание выбор не снимает. «Кофемолки нет» — не то
      // состояние, за которым сюда шли: уйти в него можно было бы случайно
      // и не заметить, а помол в рецептах перестал бы показываться числом.
      onTap: () => setState(() => _chosen = grinder.id),
      trailing: _ChoiceMark(chosen: chosen),
    );
  }

  /// Совпавший кусок имени фирменным цветом: так видно, почему строка вообще
  /// попала в список, — особенно когда её нашли с исправленной опечаткой.
  InlineSpan _highlight(String name, GrinderHit hit) {
    if (!hit.hasHighlight || hit.end > name.length) return TextSpan(text: name);

    return TextSpan(
      children: [
        TextSpan(text: name.substring(0, hit.start)),
        TextSpan(
          text: name.substring(hit.start, hit.end),
          style: TextStyle(
            color: context.colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(text: name.substring(hit.end)),
      ],
    );
  }

  Future<void> _save(GrinderState state) async {
    final texts = AppLocalizations.of(context);
    final chosen = state.catalog.where((g) => g.id == _chosen).toList();

    await ref
        .read(grinderStateProvider.notifier)
        .save(chosen, primaryGrinderId: _chosen);

    if (!mounted) return;

    final error = ref.read(grinderStateProvider).error;
    if (error != null) {
      // Набор кофемолок живёт на сервере (ответ на вопрос 19), и в очередь
      // он не встаёт: выбор делают дома, а не у чайника, и «сохраню потом»
      // здесь означало бы, что человек ушёл, считая дело сделанным.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            NetworkStatus.online.value
                ? texts.grinderSaveFailed
                : texts.grinderSaveOffline,
          ),
        ),
      );
      return;
    }

    await context.router.maybePop();
  }
}

/// Отметка одиночного выбора: кружок, залитый у выбранной строки.
///
/// Галочка тут не годится: она говорит «отмечено», то есть допускает, что
/// отмечено может быть и несколько. Кружок говорит «выбрано одно из» —
/// разницу видно, не читая подписей.
class _ChoiceMark extends StatelessWidget {
  const _ChoiceMark({required this.chosen});

  final bool chosen;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;

    return Container(
      height: AppSizes.icon20,
      width: AppSizes.icon20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: chosen ? accent : context.palette.border,
          width: chosen ? AppStroke.thick : AppStroke.thin,
        ),
      ),
      child: chosen
          ? Center(
              child: Container(
                height: AppSpacing.s2,
                width: AppSpacing.s2,
                decoration:
                    BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
            )
          : null,
    );
  }
}
