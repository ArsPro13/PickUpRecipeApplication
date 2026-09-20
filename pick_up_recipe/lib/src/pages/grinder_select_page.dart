// Экран выбора кофемолки.
//
// Список сгруппирован по виду — ручные и электрические (ответ E7): в
// справочнике полсотни записей, и без группировки найти свою на глаз тяжело.
//
// КОФЕМОЛКА ВЫБИРАЕТСЯ ОДНА И ОДНИМ КАСАНИЕМ — так, как нарисовано в макете
// design/mockups/selected/grinder-select.html: сверху та, что выбрана сейчас,
// ниже «сменить на другую», и всё.
//
// Путь сюда был длинный. Сперва экран собирал НАБОР галочками, а из набора
// отдельной кнопкой «сделать основной» назначалась главная: два действия ради
// одного решения, причём про второе легко было забыть — и тогда щелчки в
// рецептах считались по чужой шкале. Набор убрали, но осталась кнопка
// «Сохранить» внизу: касание строки ничего не меняло, пока не нажмёшь ещё
// раз. Тот же лишний щелчок, только переименованный.
//
// Теперь строка применяется сразу и экран закрывается. Случайное касание
// лечится не подтверждением, а отменой: внизу появляется «Отменить», и
// прежняя кофемолка возвращается одним нажатием. Подтверждение стоит на пути
// у всех ради ошибки одного; отмена — только у того, кто ошибся.
//
// Приложению нужна ровно одна: её имя стоит кнопкой в шапке главного экрана,
// экрана заваривания и конструктора, её делениями подписан помол в рецепте.
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
import '../general_widgets/app_layout.dart';
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

  /// Кофемолка, которую сейчас записывают. Пока запись идёт, второе касание
  /// не проходит: два запроса подряд разойдутся в порядке ответов, и
  /// основной окажется та, что ответила второй, а не та, что нажали второй.
  int? _saving;

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
    final current = state.primary;

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
              AppSpacing.s2,
            ),
            child: _Current(grinder: current),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s3,
              AppSpacing.s4,
              AppSpacing.s2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    current == null ? texts.grinderPick : texts.grinderChangeTo,
                    style: context.texts.labelSmall,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              0,
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
                : _results(catalog, hits, current),
          ),
        ],
      ),
    );
  }

  Widget _results(List<Grinder> catalog, List<GrinderHit> hits, Grinder? now) {
    if (hits.isEmpty) return _nothingFound(catalog);

    // С запросом список идёт одной лентой по убыванию совпадения: заголовки
    // групп перемешали бы порядок, а в поиске важно, что первым стоит самое
    // похожее. Без запроса возвращается прежний вид, сгруппированный по виду.
    if (_query.trim().isEmpty) return _byKind(catalog, now);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      children: [
        for (final hit in hits) _tile(hit.grinder, hit, now),
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

  Widget _byKind(List<Grinder> catalog, Grinder? now) {
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
            for (final grinder in byKind[kind]!) _tile(grinder, null, now),
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

  Widget _tile(Grinder grinder, GrinderHit? hit, Grinder? now) {
    final chosen = now?.id == grinder.id;

    return AppRow(
      label: grinder.name,
      labelSpan: hit == null ? null : _highlight(grinder.name, hit),
      icon: AppIcons.metricGrind,
      onTap: _saving == null ? () => _apply(grinder, now) : null,
      trailing: _saving == grinder.id
          ? const SizedBox(
              height: AppSizes.icon20,
              width: AppSizes.icon20,
              child: CircularProgressIndicator(strokeWidth: AppStroke.thick),
            )
          : _ChoiceMark(chosen: chosen),
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

  /// Применяет выбор сразу и уходит обратно.
  Future<void> _apply(Grinder grinder, Grinder? previous) async {
    if (_saving != null) return;

    // Ту же самую нажали — значит, пришли посмотреть, а не менять.
    if (previous?.id == grinder.id) {
      await context.router.maybePop();
      return;
    }

    setState(() => _saving = grinder.id);
    final ok = await _write(grinder);
    if (!mounted) return;
    setState(() => _saving = null);
    if (!ok) return;

    final texts = AppLocalizations.of(context);
    // Сообщение берётся ДО ухода: messenger живёт над навигатором, и плашка
    // переживает закрытие экрана — её увидят уже на том, откуда пришли.
    final messenger = ScaffoldMessenger.of(context);
    await context.router.maybePop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(texts.grinderApplied(grinder.name)),
        action: previous == null
            ? null
            : SnackBarAction(
                label: texts.undo,
                onPressed: () => _write(previous),
              ),
      ),
    );
  }

  /// Запись набора на сервер. true — получилось.
  Future<bool> _write(Grinder grinder) async {
    final notifier = ref.read(grinderStateProvider.notifier);
    await notifier.save([grinder], primaryGrinderId: grinder.id);

    final error = ref.read(grinderStateProvider).error;
    if (error == null) return true;
    if (!mounted) return false;

    // Набор кофемолок живёт на сервере (ответ на вопрос 19), и в очередь
    // он не встаёт: выбор делают дома, а не у чайника, и «сохраню потом»
    // здесь означало бы, что человек ушёл, считая дело сделанным.
    final texts = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          NetworkStatus.online.value
              ? texts.grinderSaveFailed
              : texts.grinderSaveOffline,
        ),
      ),
    );
    return false;
  }
}

/// Та кофемолка, что выбрана сейчас, — отдельным блоком над списком.
///
/// Это ответ на вопрос, с которым сюда приходят чаще всего: «а какая у меня
/// стоит?» Искать её в списке из полусотни строк по одной залитой точке —
/// работа, которой можно не делать.
class _Current extends StatelessWidget {
  const _Current({required this.grinder});

  final Grinder? grinder;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    if (grinder == null) {
      return QuietSurface(
        child: Row(
          children: [
            AppIcon(
              AppIcons.metricGrind,
              size: AppSizes.icon24,
              color: context.colors.secondary,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(texts.profileNoGrinder,
                  style: context.texts.bodySmall),
            ),
          ],
        ),
      );
    }

    final scale = grinder!.modes.length;

    return HeroSurface(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        children: [
          AppIcon(
            AppIcons.metricGrind,
            size: AppSizes.icon32,
            color: context.metrics.grind,
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(texts.grinderCurrent, style: context.texts.labelSmall),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  grinder!.name,
                  style: context.texts.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (scale > 0) ...[
                  const SizedBox(height: AppSpacing.s1),
                  Text(texts.grinderScale(scale),
                      style: context.texts.labelSmall),
                ],
              ],
            ),
          ),
          AppIcon(
            AppIcons.uiCheck,
            size: AppSizes.icon20,
            color: context.colors.primary,
          ),
        ],
      ),
    );
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
