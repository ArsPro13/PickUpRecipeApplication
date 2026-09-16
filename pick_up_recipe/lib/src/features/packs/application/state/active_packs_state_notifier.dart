import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/src/features/packs/data_sources/remote/pack_service.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'active_packs_state.dart';

class ActivePacksStateNotifier extends StateNotifier<ActivePacksState> {
  ActivePacksStateNotifier() : super(const ActivePacksState());

  GetIt getIt = GetIt.instance;

  /// Сколько пачек в одной странице.
  ///
  /// ПОЧЕМУ ВООБЩЕ СТРАНИЦАМИ. Фото пачки приезжает base64-строкой прямо в
  /// списке — не ссылкой, а телом, — и полка на полсотни пачек весила
  /// десятки мегабайт в одном ответе. Человек ждал их целиком, чтобы увидеть
  /// три верхние карточки.
  ///
  /// Дюжина — это примерно два экрана прокрутки: полка появляется сразу, а
  /// следующая страница успевает доехать, пока смотрят первую.
  static const int pageSize = 12;

  final PackService _packService = PackService();

  void clearPacks() {
    state = const ActivePacksState(isLoading: false);
  }

  /// Читает полку заново, с первой страницы.
  Future<void> fetchPacks() => _load(fromStart: true);

  /// Дочитывает следующую страницу.
  ///
  /// Молча выходит, если читать нечего или чтение уже идёт: экран зовёт этот
  /// метод из построения списка, то есть по многу раз за прокрутку, и защита
  /// от повторного входа обязана жить здесь, а не у каждого вызывающего.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    await _load(fromStart: false);
  }

  /// Дочитывает пачки, которых нет в справочнике.
  ///
  /// Нужна экранам, которые показывают пачку по идентификатору из рецепта:
  /// история завариваний уходит глубже, чем прочитанные страницы полки.
  /// Запрос на пачку кэшируется (`pack:<id>`), поэтому повторное открытие
  /// экрана в сеть уже не ходит.
  Future<void> ensurePacks(Iterable<int> ids) async {
    final missing = ids.toSet()
      ..removeAll(state.known.keys)
      ..remove(0); // 0 — справочный рецепт метода, пачки у него нет.

    if (missing.isEmpty) return;

    final found = <int, PackData>{};
    for (final id in missing) {
      try {
        final pack = await _packService.getPackById(id);
        if (pack != null) found[id] = pack;
      } catch (error) {
        // Одна не открывшаяся пачка не должна уносить с собой остальные:
        // карточка без фото читается, отсутствующий экран — нет.
        logger.e('Пачка $id не загрузилась', error: error);
      }
    }

    if (found.isEmpty || !mounted) return;
    state = state.copyWith(known: {...state.known, ...found});
  }

  Future<void> _load({required bool fromStart}) async {
    final List<PackData> loaded =
        fromStart ? const <PackData>[] : state.activePacks;

    state = fromStart
        ? state.copyWith(isLoading: true, isLoadingMore: false)
        : state.copyWith(isLoadingMore: true);

    try {
      final page = await _packService.getPacks(
            offset: loaded.length,
            limit: pageSize,
          ) ??
          const <PackData>[];

      state = state.copyWith(
        activePacks: [...loaded, ...page],
        known: {
          ...state.known,
          for (final pack in page) pack.packId: pack,
        },
        isLoading: false,
        isLoadingMore: false,
        // Неполная страница — конец полки. Полная не обещает следующую, но
        // разрешает за ней сходить: пустой ответ на следующем шаге закроет
        // вопрос, и это дешевле, чем отдельный запрос за счётчиком.
        hasMore: page.length >= pageSize,
      );
    } catch (error) {
      // Полка молчит только в одном случае — сети нет и в памяти пусто
      // (первый запуск без связи). Крутилка в этом случае крутилась бы
      // вечно: исключение уходило из postFrameCallback в никуда, и
      // isLoading оставался поднятым навсегда.
      //
      // hasMore гасим: иначе экран, не сумевший дочитать страницу, просил
      // бы её снова на каждой прокрутке — то есть долбил бы мёртвую сеть.
      logger.e('Полка не загрузилась', error: error);
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasMore: false,
      );
    }
  }
}
