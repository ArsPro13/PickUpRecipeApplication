import 'dart:convert';
import 'dart:typed_data';
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

/// Разбирает картинку пачки, присланную base64-строкой.
///
/// Фото хранится в БД текстовой колонкой, а не в файловом хранилище, поэтому
/// строка бывает пустой, обрезанной или с префиксом data:. Возвращает null
/// вместо исключения: карточка пачки должна нарисоваться и без фото.
Uint8List? decodePackImage(String? base64Image) {
  if (base64Image == null || base64Image.isEmpty) return null;

  final comma = base64Image.indexOf(',');
  final payload = base64Image.startsWith('data:') && comma != -1
      ? base64Image.substring(comma + 1)
      : base64Image;

  try {
    return base64Decode(payload);
  } on FormatException {
    return null;
  }
}
