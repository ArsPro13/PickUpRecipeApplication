// Что сканер делает с прочитанным: уходит к кофе или остаётся на камере.
//
// Камера в тесте не нужна: за кадр она отдаёт список прочитанных строк, и
// весь вопрос в том, какую из них сканер примет за код с пачки.

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_up_recipe/src/pages/code_scanner_page.dart';

void main() {
  const demo = 'ABCD234568';

  group('прочитанное за кадр', () {
    test('из двух QR в кадре берётся наш, а не код обжарщика рядом', () {
      expect(
        packCodeFromScan([
          'https://roaster.example/coffee/ethiopia',
          null,
          'https://recipetocup.ru/r/$demo',
        ]),
        demo,
      );
    });

    test('чужие QR — не повод уходить с камеры', () {
      expect(
        packCodeFromScan([
          'https://example.com/menu',
          'WIFI:S:Кофейня;T:WPA;P:12345678;;',
          null,
        ]),
        isNull,
      );
      expect(packCodeFromScan(const []), isNull);
    });
  });
}
