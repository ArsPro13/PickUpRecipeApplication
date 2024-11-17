import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

Future<String> convertXFileToBase64(XFile file) async {
  try {
    final bytes = await File(file.path).readAsBytes();

    return base64Encode(bytes);
  } catch (e) {
    throw Exception('Error converting file to Base64: $e');
  }
}

String convertDateToString(DateTime date) {
  DateFormat dateFormat = DateFormat("yyyy-MM-ddTHH:mm:ss");
  return '${dateFormat.format(date)}Z';
}