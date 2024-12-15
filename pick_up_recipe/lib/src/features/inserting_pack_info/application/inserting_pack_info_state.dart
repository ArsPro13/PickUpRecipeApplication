import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state_notifier.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state_notifier_impl.dart';

class PackInfoFormState {
  final bool isSubmitting;
  final bool isLoading;
  final String? errorMessage;
  final String? imageErrorMessage;
  final String? name;
  final String? country;
  final String? scaScore;
  final String? variety;
  final List<String>? processingMethod;
  final String? roastDate;
  final List<String>? descriptors;
  final String? image;
  final String? date;

  PackInfoFormState({
    this.isSubmitting = false,
    this.isLoading = false,
    this.errorMessage,
    this.imageErrorMessage,
    this.name,
    this.country,
    this.descriptors,
    this.processingMethod,
    this.roastDate,
    this.scaScore,
    this.variety,
    this.image,
    this.date,
  });

  PackInfoFormState copyWith({
    bool? isSubmitting,
    bool? isLoading,
    String? errorMessage,
    String? imageErrorMessage,
    String? name,
    String? country,
    String? scaScore,
    String? variety,
    List<String>? processingMethod,
    String? roastDate,
    List<String>? descriptors,
    String? image,
    String? date,
  }) {
    return PackInfoFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      imageErrorMessage: imageErrorMessage,
      name: name,
      country: country,
      descriptors: descriptors,
      processingMethod: processingMethod,
      roastDate: roastDate,
      scaScore: scaScore,
      variety: variety,
      image: image,
    );
  }
}

final formNotifierProvider =
    StateNotifierProvider<PackInfoFormStateNotifier, PackInfoFormState>(
  (ref) => PackInfoFormStateNotifierImpl(),
);
