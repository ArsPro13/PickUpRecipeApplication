import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state_notifier.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state_notifier_impl.dart';

class PackInfoFormState {
  final bool isLoading;
  final String? errorMessage;

  final String? name;
  final String? country;
  final String? scaScore;
  final String? variety;
  final String? processingMethod;
  final String? roastDate;
  final List<String>? descriptors;
  final String? image;

  PackInfoFormState({
    this.isLoading = false,
    this.errorMessage,
    this.name,
    this.country,
    this.descriptors,
    this.processingMethod,
    this.roastDate,
    this.scaScore,
    this.variety,
    this.image,
  });

  PackInfoFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? name,
    String? country,
    String? scaScore,
    String? variety,
    String? processingMethod,
    String? roastDate,
    List<String>? descriptors,
    String? image,
  }) {
    return PackInfoFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
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
