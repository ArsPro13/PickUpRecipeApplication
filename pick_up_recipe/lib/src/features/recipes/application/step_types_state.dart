import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data_sources/remote/grind_descriptor_service.dart';
import '../data_sources/remote/step_type_service.dart';
import '../domain/models/grind_descriptor_model.dart';
import '../domain/models/step_type_model.dart';

final stepTypeServiceProvider = Provider<StepTypeService>((ref) => StepTypeService());

/// Справочник типов шагов, загруженный один раз на весь запуск.
///
/// Семнадцать записей, которые не меняются между экранами: перезапрашивать их
/// на каждое открытие листа выбора значило бы платить сетью за константу.
/// `FutureProvider` кэширует результат и сам умеет показывать ошибку.
final stepTypesProvider = FutureProvider<StepTypeReference>((ref) {
  return ref.watch(stepTypeServiceProvider).getReference();
});

final grindDescriptorServiceProvider =
    Provider<GrindDescriptorService>((ref) => GrindDescriptorService());

/// Семь ступеней крупности помола, загруженные один раз на весь запуск.
///
/// Тот же расчёт, что у типов шагов: справочник не меняется между экранами,
/// и платить сетью за константу незачем. Ошибка загрузки не мешает экрану —
/// на месте слова остаётся slug из рецепта.
final grindDescriptorsProvider = FutureProvider<List<GrindDescriptor>>((ref) {
  return ref.watch(grindDescriptorServiceProvider).getDescriptors();
});
