// Один сигнал «списки устарели» на всё приложение.
//
// Списки рецептов и пачек грузились ровно один раз — в `initState` своей
// вкладки. Вкладки живут в `AutoTabsScaffold` и не пересоздаются при
// переключении, поэтому сохранённый рецепт или оценка появлялись в списке
// только после «потянуть вниз» или перезапуска: человек сохранял версию,
// переходил на «Рецепты» и не находил её там.
//
// Способ обновления намеренно один и общий на оба списка. Два разных (скажем,
// «Рецепты» слушают провайдер, а «Пачки» перечитываются по возврату на экран)
// разошлись бы при первой же новой причине обновиться — а причин будет больше:
// черновик заваривания, новая пачка, досыл очереди.
//
// Носитель — `ValueNotifier`, а не провайдер: сигнал подают и оттуда, где
// riverpod недоступен, — из `RecipeService`, из очереди отправки. Тот же приём,
// что у `NetworkStatus.online` и `Outbox.pending`.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class LibraryRevision {
  /// Сколько раз данные менялись. Значение само по себе не значит ничего —
  /// важно, что оно изменилось.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Данные изменились: списки перечитают себя сами.
  ///
  /// Зовётся из того места, где изменение произошло, а не из экрана: рецепт
  /// сохраняют из конструктора, оценку — с экрана оценки, версию из очереди
  /// досылает фон, и требовать от каждого помнить про два списка значит
  /// однажды забыть.
  static void bump() => revision.value++;
}

/// Тот же счётчик в терминах riverpod: на него подписываются списки.
class LibraryRevisionNotifier extends StateNotifier<int> {
  LibraryRevisionNotifier() : super(LibraryRevision.revision.value) {
    LibraryRevision.revision.addListener(_pull);
  }

  void _pull() => state = LibraryRevision.revision.value;

  @override
  void dispose() {
    LibraryRevision.revision.removeListener(_pull);
    super.dispose();
  }
}

final libraryRevisionProvider =
    StateNotifierProvider<LibraryRevisionNotifier, int>((ref) => LibraryRevisionNotifier());
