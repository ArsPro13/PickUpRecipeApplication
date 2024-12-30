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
