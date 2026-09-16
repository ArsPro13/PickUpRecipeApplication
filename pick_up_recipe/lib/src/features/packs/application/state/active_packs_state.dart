import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/core/library_revision.dart';
import 'package:pick_up_recipe/src/features/packs/application/state/active_packs_state_notifier.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';

class ActivePacksState {
  final List<PackData> activePacks;
  final bool isLoading;

  /// Догружается следующая страница.
  ///
  /// Отдельно от [isLoading] намеренно: первая загрузка имеет право занять
  /// экран крутилкой, а догрузка — нет. Одним признаком полка на каждой
  /// прокрутке подменялась бы пустым экраном, и человек терял бы место,
  /// на котором смотрел.
  final bool isLoadingMore;

  /// Возможно, есть ещё страница.
  ///
  /// Признак выводится из размера ответа: пришла полная страница — значит
  /// может быть и следующая, пришла неполная — значит полка кончилась.
  /// Общего числа пачек сервер не отдаёт, и заводить ради него отдельный
  /// запрос незачем: число это нигде не показывается.
  final bool hasMore;

  /// Все пачки, которые приложение вообще видело, по идентификатору.
  ///
  /// ЗАЧЕМ ОТДЕЛЬНО ОТ [activePacks]. Полка читается страницами, то есть
  /// список на экране — это первые сколько-то пачек, а не все. Но пачки
  /// нужны не только полке: экран «Рецепты» берёт отсюда имя обжарщика и
  /// фото для карточки заваривания, а заваривание могло быть по пачке,
  /// которая лежит на третьей странице и ещё не читалась.
  ///
  /// Без этой памяти постраничная полка молча сломала бы соседний экран:
  /// у половины карточек истории пропали бы и фото, и название кофе.
  final Map<int, PackData> known;

  const ActivePacksState({
    this.activePacks = const [],
    this.known = const {},
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  ActivePacksState copyWith({
    List<PackData>? activePacks,
    Map<int, PackData>? known,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return ActivePacksState(
      activePacks: activePacks ?? this.activePacks,
      known: known ?? this.known,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  List<Object?> get props => [activePacks];
}

final activePacksNotifierProvider =
    StateNotifierProvider<ActivePacksStateNotifier, ActivePacksState>(
  (ref) {
    final notifier = ActivePacksStateNotifier();

    // Тот же способ, что у списка рецептов: новая пачка или новое заваривание
    // поднимают `LibraryRevision`, и полка перечитывает себя сама.
    ref.listen<int>(libraryRevisionProvider, (_, __) => notifier.fetchPacks());

    return notifier;
  },
);
