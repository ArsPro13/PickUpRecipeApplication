import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';

abstract interface class PackInfoFormStateNotifier
    implements StateNotifier<PackInfoFormState> {
  Future<void> submitForm({
    required String name,
    required String country,
    required int scaScore,
    required String variety,
    required List<String>? processingMethod,
    required String roastDate,
    required List<String> descriptors,
    required String? image,
  });

  Future<void> updateForm({
    required String name,
    required String country,
    required String scaScore,
    required String variety,
    required List<String> processingMethod,
    required String roastDate,
    required List<String> descriptors,
    required String? image,
  });

  Future<void> updateImage({
    required String image,
  });

  Future<void> cleanForm();

  Future<void> startScanning();

  Future<void> finishScanning({String? error});

  Future<void> updateDescriptors({
    required List<String> descriptors,
  });

  Future<void> updateProcessingMethods({
    required List<String> processingMethods,
  });
}
