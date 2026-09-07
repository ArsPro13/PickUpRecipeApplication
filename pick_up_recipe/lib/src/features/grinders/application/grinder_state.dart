import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data_sources/remote/grinder_service.dart';
import '../domain/models/grinder_model.dart';

/// Кофемолки пользователя и та из них, что основная.
///
/// Состояние поднято на уровень приложения, а не экрана: кофемолка стоит
/// кнопкой в шапке главного экрана и участвует в пересчёте помола в рецептах,
/// то есть её знают минимум два экрана из разных веток.
class GrinderState {
  const GrinderState({
    this.userGrinders = const [],
    this.catalog = const [],
    this.isLoading = false,
    this.error,
  });

  final List<UserGrinder> userGrinders;

  /// Справочник целиком. Пуст, пока не открывали экран выбора.
  final List<Grinder> catalog;

  final bool isLoading;
  final String? error;

  /// Основная кофемолка. null — не выбрана, и это нормальное состояние:
  /// у человека может не быть ни одной.
  Grinder? get primary {
    for (final grinder in userGrinders) {
      if (grinder.isPrimary) return grinder.grinder;
    }
    return userGrinders.isEmpty ? null : userGrinders.first.grinder;
  }

  bool get hasGrinder => userGrinders.isNotEmpty;

  GrinderState copyWith({
    List<UserGrinder>? userGrinders,
    List<Grinder>? catalog,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GrinderState(
      userGrinders: userGrinders ?? this.userGrinders,
      catalog: catalog ?? this.catalog,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GrinderStateNotifier extends StateNotifier<GrinderState> {
  GrinderStateNotifier(this._service) : super(const GrinderState());

  final GrinderService _service;

  // Ответ дожидается ДО присваивания — намеренно, и это не стилистика.
  //
  // В `state = state.copyWith(x: await …)` Dart вычисляет получатель раньше
  // аргумента: копия снимается со старого состояния, а кладётся уже поверх
  // нового. Экран выбора кофемолки запускает обе загрузки разом, и та, что
  // ответила второй, затирала результат первой: набор кофемолок приходил
  // позже справочника, и каталог на экране оказывался пустым — при живом
  // сервере, отдавшем все пятьдесят одну запись.

  Future<void> loadUserGrinders() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final loaded = await _service.getUserGrinders();
      state = state.copyWith(userGrinders: loaded, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> loadCatalog() async {
    if (state.catalog.isNotEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final loaded = await _service.getAllGrinders();
      state = state.copyWith(catalog: loaded, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  /// Сохраняет набор кофемолок и отмечает основную.
  Future<void> save(List<Grinder> grinders, {int? primaryGrinderId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final saved = await _service.setUserGrinders(grinders, primaryGrinderId: primaryGrinderId);
      state = state.copyWith(userGrinders: saved, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  /// Делает кофемолку основной, не меняя набор.
  Future<void> makePrimary(Grinder grinder) async {
    final grinders = state.userGrinders.map((item) => item.grinder).toList();
    if (!grinders.contains(grinder)) grinders.add(grinder);
    await save(grinders, primaryGrinderId: grinder.id);
  }
}

final grinderServiceProvider = Provider<GrinderService>((ref) => GrinderService());

final grinderStateProvider = StateNotifierProvider<GrinderStateNotifier, GrinderState>(
  (ref) => GrinderStateNotifier(ref.watch(grinderServiceProvider)),
);
