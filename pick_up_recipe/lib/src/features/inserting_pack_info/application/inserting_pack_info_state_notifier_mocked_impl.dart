import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state_notifier.dart';

class PackInfoFormStateMockedNotifierImpl
    extends StateNotifier<PackInfoFormState>
    implements PackInfoFormStateNotifier {
  PackInfoFormStateMockedNotifierImpl() : super(PackInfoFormState());

  @override
  Future<void> updateForm({
    required String? name,
    required String? country,
    required String? scaScore,
    required String? variety,
    required List<String>? processingMethod,
    required String? roastDate,
    required List<String>? descriptors,
    required String? image,
  }) async {
    state = state.copyWith(
      isSubmitting: false,
      errorMessage: null,
      name: name,
      country: country,
      scaScore: scaScore,
      variety: variety,
      processingMethod: processingMethod,
      roastDate: roastDate,
      descriptors: descriptors,
    );
  }

  @override
  Future<void> submitForm({
    required String name,
    required String country,
    required int scaScore,
    required String variety,
    required List<String>? processingMethod,
    required String roastDate,
    required List<String> descriptors,
    required String? image,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      await Future.delayed(const Duration(milliseconds: 3000));
      state = state.copyWith(isSubmitting: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  @override
  Future<void> cleanForm() async {
    await updateForm(
      name: null,
      country: null,
      scaScore: null,
      variety: null,
      processingMethod: null,
      roastDate: null,
      descriptors: null,
      image: null,
    );
  }

  @override
  Future<void> updateImage({
    required String image,
  }) async {
    state = state.copyWith(
      image: image,
    );
  }

  @override
  Future<void> startScanning() async {
    state = state.copyWith(
      isLoading: true,
    );
  }

  @override
  Future<void> finishScanning({String? error}) async {
    state = state.copyWith(
      isLoading: false,
      imageErrorMessage: error,
    );
  }

  @override
  Future<void> updateDescriptors({
    required List<String> descriptors,
  }) async {
    state = state.copyWith(
      name: state.name,
      country: state.country,
      descriptors: descriptors,
      processingMethod: state.processingMethod,
      roastDate: state.roastDate,
      scaScore: state.scaScore,
      variety: state.variety,
      image: state.image,
    );
  }

  @override
  Future<void> updateProcessingMethods({
    required List<String> processingMethods,
  }) async {
    state = state.copyWith(
      name: state.name,
      country: state.country,
      descriptors: state.descriptors,
      processingMethod: processingMethods,
      roastDate: state.roastDate,
      scaScore: state.scaScore,
      variety: state.variety,
      image: state.image,
    );
  }
}
