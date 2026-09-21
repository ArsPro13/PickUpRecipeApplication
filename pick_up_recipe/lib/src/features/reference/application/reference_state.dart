// Палитра и подсказки на весь запуск приложения.
//
// Оба справочника читаются один раз: они не меняются между экранами, а нужны
// на каждом, где есть тег или поле ввода. Ошибка загрузки не ломает ни одного
// экрана — палитра падает на встроенную, подсказки просто не предлагаются.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data_sources/remote/reference_service.dart';
import '../domain/flavor_descriptor_entry.dart';
import '../domain/flavor_palette.dart';
import '../domain/reference_term.dart';

final referenceServiceProvider =
    Provider<ReferenceService>((ref) => ReferenceService());

/// Словарь дескрипторов: слова, категории, ступени.
///
/// Пустой список — законный ответ: без сети тег красится встроенной палитрой
/// по слагу, а поле ввода работает как обычное поле.
final flavorDescriptorsProvider =
    FutureProvider<List<FlavorDescriptorEntry>>((ref) async {
  final service = ref.watch(referenceServiceProvider);
  try {
    return await service.getDescriptors();
  } catch (_) {
    return const [];
  }
});

/// Палитра дескрипторов: серверная поверх встроенной.
///
/// Провайдер отдаёт готовую палитру, а не «палитру или null»: у каждого
/// вызывающего иначе появился бы свой запасной цвет, и теги в разных местах
/// разошлись бы. Встроенная палитра — часть ответа, а не аварийный случай.
final flavorPaletteProvider = FutureProvider<FlavorPalette>((ref) async {
  final service = ref.watch(referenceServiceProvider);
  final builtIn = FlavorPalette.builtIn();

  // Цвета необязательны так же, как словарь: цвет без словаря красит по
  // слагам, словарь без цвета — встроенной палитрой.
  List<FlavorCategory> categories = const [];
  try {
    categories = await service.getFlavorCategories();
  } catch (_) {
    categories = const [];
  }

  final descriptors = await ref.watch(flavorDescriptorsProvider.future);

  // Ключом идёт и слаг, и имя: на пачке пишут «ягода», в рецепте может
  // стоять `berry`, и оба обязаны покраситься одинаково.
  final index = <String, DescriptorTone>{};
  for (final entry in descriptors) {
    final tone = DescriptorTone(entry.category, entry.intensity);
    if (entry.slug.isNotEmpty) index[entry.slug.toLowerCase()] = tone;
    if (entry.name.isNotEmpty) index[entry.name.toLowerCase()] = tone;
  }

  return builtIn.merge(categories, index);
});

/// Палитра прямо сейчас: пока грузится — встроенная.
///
/// Теги рисуются в списках и на карточках, и заставлять каждый из них
/// показывать крутилку ради цвета — хуже, чем показать встроенный цвет,
/// который в девяти случаях из десяти и есть правильный.
final paletteNowProvider = Provider<FlavorPalette>((ref) {
  return ref.watch(flavorPaletteProvider).valueOrNull ?? FlavorPalette.builtIn();
});

/// Подсказки для поля ввода. Вид — `country`, `region`, `processing`,
/// `variety`.
final referenceTermsProvider =
    FutureProvider.family<List<ReferenceTerm>, String>((ref, kind) async {
  final service = ref.watch(referenceServiceProvider);
  try {
    return await service.getTerms(kind);
  } catch (_) {
    // Подсказка — удобство, а не условие работы формы: без сети поле
    // остаётся обычным полем ввода.
    return const [];
  }
});

/// Подсказки дескрипторов на языке экрана — те же слова, которыми красятся
/// теги.
///
/// Язык параметром, а не из настройки: настройка бывает «как в системе», и
/// тогда сама она языка не знает. На английском телефоне подсказка «ягода»
/// бесполезна — человек набирает berry.
final descriptorHintsProvider =
    Provider.family<List<String>, bool>((ref, english) {
  final descriptors = ref.watch(flavorDescriptorsProvider).valueOrNull;
  final names = [
    for (final entry in descriptors ?? const <FlavorDescriptorEntry>[])
      if (entry.label(english).isNotEmpty) entry.label(english),
  ];
  names.sort();
  return names;
});
