import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state_notifier.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state_notifier_impl.dart';

class PackInfoFormState {
  final bool isSubmitting;
  final bool isLoading;
  final String? errorMessage;
  final String? imageErrorMessage;
  final String? country;

  /// Регион внутри страны. Необязателен: на многих пачках его просто нет.
  final String? region;
  final String? scaScore;
  final String? variety;
  final List<String>? processingMethod;
  final String? roastDate;
  final List<String>? descriptors;

  /// Фотография пачки в base64 — ровно то, что уезжает в pack_image.
  final String? image;

  /// Отправка прошла: экран уходит на главный, и повторно этого делать не надо.
  final bool isSent;

  PackInfoFormState({
    this.isSubmitting = false,
    this.isLoading = false,
    this.errorMessage,
    this.imageErrorMessage,
    this.country,
    this.region,
    this.descriptors,
    this.processingMethod,
    this.roastDate,
    this.scaScore,
    this.variety,
    this.image,
    this.isSent = false,
  });

  /// Правка одного-двух полей, остальные остаются как были.
  ///
  /// Раньше copyWith подставлял переданное значение напрямую, и любой вызов
  /// с одним аргументом обнулял всю остальную форму: сохранить фотографию
  /// значило потерять страну и дату.
  PackInfoFormState copyWith({
    bool? isSubmitting,
    bool? isLoading,
    String? errorMessage,
    String? imageErrorMessage,
    String? country,
    String? region,
    String? scaScore,
    String? variety,
    List<String>? processingMethod,
    String? roastDate,
    List<String>? descriptors,
    String? image,
    bool? isSent,
  }) {
    return PackInfoFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoading: isLoading ?? this.isLoading,
      // Сообщения об ошибках не наследуются: они про последнее действие,
      // и молча дотащить вчерашнюю ошибку до следующего экрана — враньё.
      errorMessage: errorMessage,
      imageErrorMessage: imageErrorMessage,
      country: country ?? this.country,
      region: region ?? this.region,
      descriptors: descriptors ?? this.descriptors,
      processingMethod: processingMethod ?? this.processingMethod,
      roastDate: roastDate ?? this.roastDate,
      scaScore: scaScore ?? this.scaScore,
      variety: variety ?? this.variety,
      image: image ?? this.image,
      isSent: isSent ?? this.isSent,
    );
  }
}

final formNotifierProvider =
    StateNotifierProvider<PackInfoFormStateNotifier, PackInfoFormState>(
  (ref) => PackInfoFormStateNotifierImpl(),
);
