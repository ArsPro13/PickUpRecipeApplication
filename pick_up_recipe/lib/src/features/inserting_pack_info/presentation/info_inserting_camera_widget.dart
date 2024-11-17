
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pick_up_recipe/core/converters.dart';
import 'package:pick_up_recipe/main.dart';

import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/data/DAO/pack_info_from_camera_dao.dart';

class InsertingPackInfoCameraWidget extends ConsumerStatefulWidget {
  const InsertingPackInfoCameraWidget({super.key});

  @override
  ConsumerState<InsertingPackInfoCameraWidget> createState() =>
      _InsertingPackInfoCameraWidgetState();
}

class _InsertingPackInfoCameraWidgetState
    extends ConsumerState<InsertingPackInfoCameraWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _hasImage = false;
  XFile? _image;
  GetIt getIt = GetIt.instance;
  late final PackInfoFromCameraDAO dao;

  @override
  void initState() {
    super.initState();
    dao = getIt.get<PackInfoFromCameraDAO>();
  }

  final ButtonStyle buttonStyle = ButtonStyle(
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: Color.fromRGBO(0, 0, 0, 0.2), width: 0.2),
      ),
    ),
  );

  Future getImage(bool fromCamera) async {
    XFile? image = await _picker.pickImage(
        source: (fromCamera ? ImageSource.camera : ImageSource.gallery));

    final formNotifier = ref.read(formNotifierProvider.notifier);

    final base64Image = image != null ? await convertXFileToBase64(image) : null;

    final recognisedPack = await dao.getInfoByImg('insert base64 img');

    String processingMethod = '';
    for (final method in recognisedPack.packProcessingMethod ?? []) {
      processingMethod += '$method ';
    }

    await formNotifier.updateForm(name: recognisedPack.packName, country: recognisedPack.packCountry, scaScore: recognisedPack.packScaScore.toString(), variety: recognisedPack.packVariety, processingMethod: processingMethod, roastDate: recognisedPack.packDate, descriptors: recognisedPack.packDescriptors ?? [], image: base64Image);

    setState(() {
      _hasImage = image != null;
      _image = image;
    });

    logger.i('Successfully inserted image: $base64Image');
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
            SizedBox(
              width: 180,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  getImage(true);
                },
                style: buttonStyle,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Camera'),
                    SizedBox(
                      width: 5,
                    ),
                    Icon(Icons.camera_alt),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 180,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  getImage(false);
                },
                style: buttonStyle,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Gallery'),
                    SizedBox(
                      width: 5,
                    ),
                    Icon(Icons.pageview),
                  ],
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
