import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../packs/data_sources/remote/pack_service.dart';
import '../../packs/domain/models/pack_model.dart';
import '../domain/pack_code.dart';

enum CoffeeStatus { loading, ready, notFound, failed }

class CoffeeState {
  const CoffeeState({this.status = CoffeeStatus.loading, this.pack, this.error});

  final CoffeeStatus status;
  final PackData? pack;
  final String? error;
}

/// Открывает страницу кофе по коду с упаковки или по своей пачке.
///
/// Код проверяется локально до похода на сервер: контрольный символ ловит
/// опечатку ручного ввода, и незачем ради этого ждать ответа сети.
class CoffeeStateNotifier extends StateNotifier<CoffeeState> {
  CoffeeStateNotifier(this._packs) : super(const CoffeeState());

  final PackService _packs;

  Future<void> open({String? code, int? packId}) async {
    state = const CoffeeState();

    if (code != null && code.isNotEmpty) {
      // Ручка поиска кофе по коду появляется вместе с кабинетом обжарщика
      // (этап 7): пока код ведёт в то же «не найдено», что и чужая пачка,
      // но проверка контрольного символа уже работает и отличает опечатку
      // от честно ненайденного кода.
      state = const CoffeeState(status: CoffeeStatus.notFound);
      return;
    }

    if (packId == null) {
      state = const CoffeeState(status: CoffeeStatus.notFound);
      return;
    }

    try {
      final pack = await _packs.getPackById(packId);
      state = pack == null
          ? const CoffeeState(status: CoffeeStatus.notFound)
          : CoffeeState(status: CoffeeStatus.ready, pack: pack);
    } catch (error) {
      state = CoffeeState(status: CoffeeStatus.failed, error: error.toString());
    }
  }

  /// Разбирает код до похода на сервер.
  static bool isCodeUsable(String code) => PackCode.isValid(code);
}

final packServiceProvider = Provider<PackService>((ref) => PackService());

final coffeeStateProvider = StateNotifierProvider<CoffeeStateNotifier, CoffeeState>(
  (ref) => CoffeeStateNotifier(ref.watch(packServiceProvider)),
);
