import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

// do not use
Future<String> compressBase64Img({
  required String base64Image,
  required int requiredQuality,
}) async {
  Uint8List imageBytes = base64Decode(base64Image);

  img.Image? image = img.decodeImage(imageBytes);
  if (image == null) {
    throw Exception("Failed to decode base64 image");
  }

  int quality = (requiredQuality / imageBytes.lengthInBytes).round();
  if (quality > 100) {
    quality = 100;
  }

  Uint8List? compressedBytes =
      Uint8List.fromList(img.encodeJpg(image, quality: quality));

  return base64Encode(compressedBytes);
}

/// Разобранные фото пачек: строка с провода → готовые байты.
///
/// ЗАЧЕМ КЭШ. `decodePackImage` звали прямо из `build`, а `build` у карточки
/// случается десятки раз в секунду: барабан версий на экране «Рецепты»
/// перестраивается на КАЖДОМ кадре перетаскивания. Каждый кадр заново
/// разбирал base64 на полтораста килобайт — отсюда и рывки, и мигание фото.
///
/// Мигание лечится не только скоростью. `Image.memory` заворачивает байты в
/// `MemoryImage`, а тот сравнивается по тождеству списка: новый `Uint8List` на
/// каждом кадре — это каждый раз ДРУГАЯ картинка, мимо кэша изображений
/// Flutter, с новой загрузкой и пустым кадром между ними. Кэш возвращает один
/// и тот же экземпляр, и сравнение наконец сходится.
///
/// Предел в записях, а не в байтах: фото пачки весит от силы четверть
/// мегабайта, полка на экране — десяток карточек, и сорок записей покрывают
/// её с запасом, не давая кэшу расти вместе с историей за год.
const int _packImageCacheLimit = 40;

final Map<String, Uint8List> _packImageCache = <String, Uint8List>{};

/// Разбирает картинку пачки, присланную base64-строкой.
///
/// Фото хранится в БД текстовой колонкой, а не в файловом хранилище, поэтому
/// строка бывает пустой, обрезанной или с префиксом data:. Возвращает null
/// вместо исключения: карточка пачки должна нарисоваться и без фото.
///
/// Один и тот же вход всегда отдаёт ОДИН И ТОТ ЖЕ список байтов — на этом
/// держится отсутствие мигания, см. пояснение у `_packImageCache`.
Uint8List? decodePackImage(String? base64Image) {
  if (base64Image == null || base64Image.isEmpty) return null;

  final cached = _packImageCache.remove(base64Image);
  if (cached != null) {
    // Вынули и положили обратно — запись уехала в конец очереди вытеснения.
    // Так из кэша первой уходит та пачка, на которую дольше всех не смотрели.
    _packImageCache[base64Image] = cached;
    return cached;
  }

  final comma = base64Image.indexOf(',');
  final payload = base64Image.startsWith('data:') && comma != -1
      ? base64Image.substring(comma + 1)
      : base64Image;

  final Uint8List bytes;
  try {
    bytes = base64Decode(payload);
  } on FormatException {
    // Битую строку не запоминаем: её разбор и так дешёвый — он падает сразу,
    // а держать в кэше мусор значит платить памятью за нулевую выгоду.
    return null;
  }

  if (_packImageCache.length >= _packImageCacheLimit) {
    _packImageCache.remove(_packImageCache.keys.first);
  }
  _packImageCache[base64Image] = bytes;

  return bytes;
}

/// Забывает разобранные фото. Нужна тестам и выходу из аккаунта: чужие пачки
/// не должны лежать в памяти после смены пользователя.
void clearPackImageCache() => _packImageCache.clear();

/// Замеренная яркость фото: по экземпляру байтов, а не по строке. Байты
/// `decodePackImage` отдаёт одним и тем же экземпляром, и замер, раз
/// сделанный, переживает перестройку карточки и уходит вместе с фото.
final Expando<double> _photoLuminance = Expando<double>();

/// Яркость, уже замеренная у этих байтов. null — ещё не мерили.
double? cachedPackPhotoLuminance(Uint8List bytes) => _photoLuminance[bytes];

/// Средняя яркость нижней полосы фото пачки — той, на которую на карточке
/// рецепта ложится подпись с датой. От 0 (чёрное) до 1 (белое), в тех же
/// единицах, что [ui.Color.computeLuminance]. null — фото не разобрать.
///
/// Фото уменьшается до горстки точек: средней яркости полосы этого хватает,
/// а разбор полного снимка на каждую карточку стоил бы памяти и времени.
Future<double?> measurePackPhotoLuminance(Uint8List bytes) async {
  final cached = _photoLuminance[bytes];
  if (cached != null) return cached;

  try {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 24);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    final height = image.height;
    image.dispose();
    codec.dispose();
    if (data == null || width == 0 || height == 0) return null;

    // Нижняя четверть кадра без самого края: снимок на карточке обрезан под
    // её пропорцию, и крайние строки туда почти никогда не попадают.
    final from = (height * 0.68).floor();
    final to = (height * 0.94).ceil().clamp(from + 1, height);
    var sum = 0.0;
    var count = 0;
    for (var y = from; y < to; y++) {
      for (var x = 0; x < width; x++) {
        final at = (y * width + x) * 4;
        sum += ui.Color.fromARGB(
          255,
          data.getUint8(at),
          data.getUint8(at + 1),
          data.getUint8(at + 2),
        ).computeLuminance();
        count++;
      }
    }
    if (count == 0) return null;

    final luminance = sum / count;
    _photoLuminance[bytes] = luminance;
    return luminance;
  } catch (_) {
    // Битое фото карточка и так покажет заливкой цвета обжарки.
    return null;
  }
}
