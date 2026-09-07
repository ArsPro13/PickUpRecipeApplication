// Экран «Пачка без кода»: то, куда ведёт кнопка «На пачке нет кода».
//
// Файл называется recognition_camera_page по старой памяти — когда-то экран
// начинался с распознавания надписей. Дорогу к распознаванию с экрана убрали
// (сам разбор фотографии остался в сервисном слое и ждёт своего часа), и
// теперь это обычная форма: снимок пачки и то, что человек прочитал на ней сам.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pick_up_recipe/routing/app_router.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/application/inserting_pack_info_state.dart';
import 'package:pick_up_recipe/src/features/inserting_pack_info/presentation/inserting_pack_info_widget.dart';
import 'package:pick_up_recipe/src/general_widgets/app_layout.dart';

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
    // Пачка заведена — человек уходит на главный экран, к своей полке, а не
    // остаётся на форме, которую только что заполнил. Куда идти, решает экран,
    // а не форма: сама форма про навигацию ничего не знает.
    ref.listen<bool>(
      formNotifierProvider.select((state) => state.isSent),
      (_, isSent) {
        if (!isSent) return;
        // Следующим кадром: чистить состояние прямо в обработчике уведомления
        // значит менять провайдер, пока он рассылает изменение.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(formNotifierProvider.notifier).cleanForm();
          context.router.navigate(const PacksRoute());
        });
      },
    );

    return const AppScreen(
      title: 'Пачка без кода',
      body: [InsertingPackInfoWidget()],
    );
  }
}
