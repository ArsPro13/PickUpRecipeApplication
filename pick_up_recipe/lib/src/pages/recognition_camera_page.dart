import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/info_inserting_camera_widget.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/inserting_pack_info_widget.dart';

@RoutePage()
class RecognitionCameraPage extends ConsumerStatefulWidget {
  const RecognitionCameraPage({super.key});

  @override
  ConsumerState<RecognitionCameraPage> createState() =>
      _RecognitionCameraPageState();
}

class _RecognitionCameraPageState extends ConsumerState<RecognitionCameraPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: ListView(
          children: const [
            InsertingPackInfoCameraWidget(),
            InsertingPackInfoWidget(),
          ],
        ),
      ),
    );
  }
}
