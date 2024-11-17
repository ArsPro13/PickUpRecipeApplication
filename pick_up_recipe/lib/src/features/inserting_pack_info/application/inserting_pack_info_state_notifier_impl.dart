
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:pick_up_recipe/main.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state_notifier.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/data/DAO/pack_info_dao.dart';

class PackInfoFormStateNotifierImpl extends StateNotifier<PackInfoFormState>
    implements PackInfoFormStateNotifier {
  PackInfoFormStateNotifierImpl() : super(PackInfoFormState());

  @override
  Future<void> updateForm({
    required String? name,
    required String? country,
    required String? scaScore,
    required String? variety,
    required String? processingMethod,
    required String? roastDate,
    required List<String>? descriptors,
    required String? image,
  }) async {
    state = state.copyWith(
      isLoading: false,
      errorMessage: null,
      name: name,
      country: country,
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
    required String name,
    required String country,
    required int scaScore,
    required String variety,
    required String processingMethod,
    required String roastDate,
    required List<String> descriptors,
    required String? image,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      GetIt getIt = GetIt.instance;

      final dao = getIt.get<PackInfoDAO>();

      final answer = await dao.sendPack(
        country,
        roastDate,
        descriptors,
        image ?? '',
        name,
        [processingMethod],
        scaScore,
        variety,
      );
      logger.i(answer);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
}
