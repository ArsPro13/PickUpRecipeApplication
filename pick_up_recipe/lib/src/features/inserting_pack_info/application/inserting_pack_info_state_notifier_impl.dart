import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state_notifier.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/domain/pack_title.dart';
import 'package:pick_up_recipe/src/features/packs/data_sources/remote/pack_service.dart';
import 'package:pick_up_recipe/src/features/packs/domain/models/pack_request_model.dart';

class PackInfoFormStateNotifierImpl extends StateNotifier<PackInfoFormState>
    implements PackInfoFormStateNotifier {
  PackInfoFormStateNotifierImpl() : super(PackInfoFormState());

  @override
  Future<void> updateForm({
    required String? country,
    required String? region,
    required String? scaScore,
    required String? variety,
    required List<String>? processingMethod,
    required String? roastDate,
    required List<String>? descriptors,
    required String? image,
  }) async {
    state = state.copyWith(
      isSubmitting: false,
      country: country,
      region: region,
      scaScore: scaScore,
      variety: variety,
      processingMethod: processingMethod,
      roastDate: roastDate,
      descriptors: descriptors,
      image: image,
    );
  }

  @override
  Future<void> submitForm({
    required String country,
    required String region,
    required int scaScore,
    required String variety,
    required List<String>? processingMethod,
    required String roastDate,
    required List<String> descriptors,
    required String? image,
  }) async {
    state = state.copyWith(isSubmitting: true);

    try {
      final packService = PackService();

      final answer = await packService.addPack(
        PackRequestModel(
          packCountry: country,
          packDate: roastDate,
          packDescriptors: descriptors,
          // Фотография уезжает тем же base64, каким её отдал image_picker:
          // на сервере pack_image — обычный текстовый столбец.
          packImage: image ?? '',
          // Регион в запрос отдельным полем не уходит: такого столбца на
          // сервере нет. Он виден в имени пачки — и это всё, что мы сейчас
          // умеем про него сохранить.
          packName: packTitleFrom(
            country: country,
            region: region,
            variety: variety,
          ),
          packProcessingMethod: processingMethod ?? [],
          packScaScore: scaScore,
          packVariety: variety,
        ),
      );

      logger.i('Added pack information: $answer');

      state = state.copyWith(isSubmitting: false, isSent: true);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  @override
  Future<void> cleanForm() async {
    state = PackInfoFormState();
  }

  @override
  Future<void> updateImage({
    required String image,
  }) async {
    state = state.copyWith(image: image);
  }

  @override
  Future<void> startScanning() async {
    state = state.copyWith(isLoading: true);
  }

  @override
  Future<void> finishScanning({String? error}) async {
    state = state.copyWith(isLoading: false, imageErrorMessage: error);
  }

  @override
  Future<void> updateDescriptors({
    required List<String> descriptors,
  }) async {
    state = state.copyWith(descriptors: descriptors);
  }

  @override
  Future<void> updateProcessingMethods({
    required List<String> processingMethods,
  }) async {
    state = state.copyWith(processingMethod: processingMethods);
  }
}
