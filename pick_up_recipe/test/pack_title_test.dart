// Имя пачки, заведённой руками.
//
// Поля «Название» в форме нет — владелец назвал его непонятным. Серверу имя
// при этом обязательно, и собирается оно из того, что человек про пачку точно
// знает. Проверяется здесь, а не через форму: правило одно на всё приложение,
// и от вёрстки оно не зависит.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/domain/pack_title.dart';

void main() {
  group('имя пачки', () {
    test('страна и регион — то, что различает две бразильские пачки', () {
      expect(
        packTitleFrom(country: 'Бразилия', region: 'Серрадо', variety: 'бурбон'),
        'Бразилия · Серрадо',
      );
    });

    test('без региона в ход идёт сорт', () {
      expect(
        packTitleFrom(country: 'Бразилия', region: '', variety: 'бурбон'),
        'Бразилия · бурбон',
      );
    });

    test('нет ни региона, ни сорта — остаётся страна', () {
      expect(packTitleFrom(country: 'Бразилия', region: '', variety: ''), 'Бразилия');
    });

    test('пробелы по краям в имя не уезжают', () {
      expect(
        packTitleFrom(country: '  Бразилия ', region: ' ', variety: ' бурбон '),
        'Бразилия · бурбон',
      );
    });
  });
}
