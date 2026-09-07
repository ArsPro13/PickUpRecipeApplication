// Экран выбора кофемолки запускает две загрузки разом: справочник и набор
// пользователя. Пока результат клали прямо в аргумент copyWith, ответ второй
// затирал результат первой — Dart вычисляет получатель раньше аргумента, то
// есть копия снималась со старого состояния.
//
// Наружу это выглядело так: на экране кофемолки пусто, «Справочник пуст —
// проверьте связь», при живом сервере, который отдал все пятьдесят одну
// запись. Поиск при этом чинить было бессмысленно: искать не в чем.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/grinders/application/grinder_state.dart';
import 'package:pick_up_recipe/src/features/grinders/data_sources/remote/grinder_service.dart';
import 'package:pick_up_recipe/src/features/grinders/domain/models/grinder_model.dart';

/// Справочник отвечает быстро, набор пользователя — медленно.
///
/// Порядок именно такой, потому что так и было на живом стенде: профиль
/// приходил последним и затирал каталог.
class _SlowProfileService implements GrinderService {
  @override
  Future<List<Grinder>> getAllGrinders() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return const [
      Grinder(id: 1, name: 'Comandante C40', kind: GrinderKind.manual),
      Grinder(id: 2, name: 'Baratza Encore', kind: GrinderKind.electric),
    ];
  }

  @override
  Future<List<UserGrinder>> getUserGrinders() async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    return const [
      UserGrinder(
        grinder: Grinder(id: 1, name: 'Comandante C40', kind: GrinderKind.manual),
        isPrimary: true,
      ),
    ];
  }

  @override
  Future<List<UserGrinder>> setUserGrinders(
    List<Grinder> grinders, {
    int? primaryGrinderId,
  }) async =>
      const [];
}

void main() {
  test('две загрузки разом не затирают друг друга', () async {
    final notifier = GrinderStateNotifier(_SlowProfileService());

    // Ровно как на экране: обе загрузки стартуют в одном кадре и никто никого
    // не ждёт.
    await Future.wait([
      notifier.loadCatalog(),
      notifier.loadUserGrinders(),
    ]);

    expect(
      notifier.state.catalog.length,
      2,
      reason: 'справочник затёрт ответом, который пришёл позже',
    );
    expect(
      notifier.state.userGrinders.length,
      1,
      reason: 'набор пользователя затёрт ответом справочника',
    );
    expect(notifier.state.primary?.name, 'Comandante C40');
  });

  test('повторная загрузка справочника не ходит на сервер второй раз', () async {
    final notifier = GrinderStateNotifier(_SlowProfileService());

    await notifier.loadCatalog();
    final first = notifier.state.catalog;
    await notifier.loadCatalog();

    expect(identical(notifier.state.catalog, first), isTrue);
  });
}
