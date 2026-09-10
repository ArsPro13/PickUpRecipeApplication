// Порядок полки: последняя заведённая пачка — первая.
//
// На видео владелец заводит «бразилия · серрадо» и находит её под пачкой,
// лежащей там с прошлой недели: «кофе, добавленный последним, должен быть
// самым ранним». Порядок приезжает с сервера в порядке появления, и без
// этой сортировки новое всегда оказывается внизу.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_model.dart';
import 'package:pick_up_recipe/src/features/packs/domain/pack_order.dart';

PackData pack(int id, {String name = 'пачка', String date = '01.09.2026'}) {
  return PackData(
    packId: id,
    userId: '1',
    packDate: date,
    packName: name,
    packDescriptors: const [],
    packCountry: 'бразилия',
    packProcessingMethod: const [],
    packImage: '',
    packVariety: 'бурбон',
    packScaScore: 86,
    isActive: true,
  );
}

void main() {
  group('порядок полки', () {
    test('последняя заведённая идёт первой', () {
      final shelf = newestFirst([pack(1), pack(2), pack(3)]);

      expect(shelf.map((p) => p.packId), [3, 2, 1]);
    });

    test('дата обжарки на порядок не влияет', () {
      // Дату печатает человек, и у половины пачек её нет вовсе. Заведённая
      // позже пачка старой обжарки всё равно сверху.
      final shelf = newestFirst([
        pack(1, name: 'свежая обжарка', date: '09.09.2026'),
        pack(2, name: 'старая обжарка', date: '01.01.2026'),
      ]);

      expect(shelf.first.packName, 'старая обжарка');
    });

    test('исходный список не трогается', () {
      // Список приезжает из состояния, и переставлять его на месте значило бы
      // менять то, на что уже смотрят другие экраны.
      final source = [pack(1), pack(2)];
      newestFirst(source);

      expect(source.map((p) => p.packId), [1, 2]);
    });

    test('пустая полка не роняет разбор', () {
      expect(newestFirst(const []), isEmpty);
    });
  });
}
