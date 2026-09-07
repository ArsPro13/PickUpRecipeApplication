import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state_notifier.dart';

class PackInfoFormStateMockedNotifierImpl
    extends StateNotifier<PackInfoFormState>
    implements PackInfoFormStateNotifier {
  PackInfoFormStateMockedNotifierImpl() : super(PackInfoFormState());

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
      await Future.delayed(const Duration(milliseconds: 3000));
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
