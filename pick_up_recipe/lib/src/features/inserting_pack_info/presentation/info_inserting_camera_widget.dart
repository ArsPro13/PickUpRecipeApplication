import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pick_up_recipe/core/converters.dart';

import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';
import 'package:pick_up_recipe/src/features/packs/data_sources/remote/pack_service.dart';

import 'package:pick_up_recipe/core/logger.dart';
import 'package:pick_up_recipe/src/general_widgets/buttons/app_button.dart';

class InsertingPackInfoCameraWidget extends ConsumerStatefulWidget {
  const InsertingPackInfoCameraWidget({super.key});

  @override
  ConsumerState<InsertingPackInfoCameraWidget> createState() =>
      _InsertingPackInfoCameraWidgetState();
}

class _InsertingPackInfoCameraWidgetState
    extends ConsumerState<InsertingPackInfoCameraWidget> {
  final ImagePicker _picker = ImagePicker();
  GetIt getIt = GetIt.instance;

  @override
  void initState() {
    super.initState();
  }

  Future getImage(bool fromCamera) async {
    final formNotifier = ref.read(formNotifierProvider.notifier);

    try {
      formNotifier.startScanning();

      XFile? image = await _picker.pickImage(
        source: (fromCamera ? ImageSource.camera : ImageSource.gallery),
        maxHeight: 1440,
        maxWidth: 720,
        imageQuality: 60,
      );

      final base64Image =
          image != null ? await convertXFileToBase64(image) : null;

      final packService = PackService();
      final recognisedPack = await packService.getPackByImage(base64Image);

      if (recognisedPack == null) {
        throw Exception(
          'Failed to fetch pack information: recognised pack information is null',
        );
      }

      await formNotifier.updateForm(
        name: recognisedPack.packName ?? '',
        country: recognisedPack.packCountry ?? '',
        scaScore: '',
        processingMethod: recognisedPack.packProcessingMethod ?? [],
        roastDate: '',
        descriptors: recognisedPack.packDescriptors ?? [],
        image: base64Image,
        variety: recognisedPack.packVariety ?? '',
      );

      setState(() {});

      logger.i('Successfully inserted image');

      formNotifier.finishScanning();
    } catch (e) {
      formNotifier.finishScanning(error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Add a new pack',
          style: TextStyle(fontSize: 30),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 10,
        ),
        const Text(
          'You can make a photo of your pack to recognise it',
          style: TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: AppButton(
                  onTap: () {
                    getImage(true);
                  },
                  centerWidget: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Camera'),
                      SizedBox(
                        width: 5,
                      ),
                      Icon(Icons.camera_alt),
                    ],
                  ),
                  buttonStyle: AppButtonStyle.secondary,
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: SizedBox(
                height: 50,
                child: AppButton(
                  onTap: () {
                    getImage(false);
                  },
                  centerWidget: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Gallery'),
                      SizedBox(
                        width: 5,
                      ),
                      Icon(Icons.pageview),
                    ],
                  ),
                  buttonStyle: AppButtonStyle.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 30,
        ),
      ],
    );
  }
}
