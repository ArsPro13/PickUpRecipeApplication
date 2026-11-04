// Шкалы кофемолок: откуда взять, когда сервер её не прислал.
//
// Владелец 04.11.2026: «я хочу, чтобы клики всё равно писались в числовых
// значениях, а не в словесных. Чтобы была конкретика». Слово вместо кликов
// вставало в трёх случаях, и все три — от того, что не было шкалы:
//
// - кофемолка не выбрана: чьи клики писать — неизвестно;
// - сервис шкал не ответил: профиль приехал с кофемолкой, но без делений;
// - рецепт записан делениями чужой кофемолки и без слова крупности: перевести
//   её «22» в свои клики было не через что, и на экране стояли её клики,
//   как будто ваши. Пересчёт объёма у воронки по той же причине не двигал
//   клики (вопрос владельца «почему не меняются клики»).
//
// Встроенная копия шкал (builtin_grinder_scales.dart, генерируется из базы
// сервиса шкал) закрывает все три. Без выбранной кофемолки клики пишутся
// эталонной — Comandante C40, как на сайте и в PDF, — с её именем рядом.
//
// Чистый Dart без Flutter: этим пользуется и пересчёт рецепта.

import 'builtin_grinder_scales.dart';
import 'models/grinder_model.dart';

/// id эталонной кофемолки в справочнике — Comandante C40. Ею помол пишут
/// сайт и PDF; ею же приложение пишет клики, пока человек не выбрал свою.
const int kReferenceGrinderId = 11;

/// Кофемолка справочника по id — с именем и встроенной шкалой.
///
/// null — такой кофемолки во встроенной таблице нет (её завели на сервере
/// позже): перевести её деления не во что.
Grinder? builtInGrinder(int id) {
  final name = builtInGrinderNames[id];
  if (name == null) return null;
  return Grinder(
    id: id,
    name: name,
    modes: builtInGrinderScales[name] ?? const [],
  );
}

/// Эталонная кофемолка: ею пишутся клики, пока своя не выбрана.
final Grinder referenceGrinder = builtInGrinder(kReferenceGrinderId)!;

extension GrinderKnownScale on Grinder {
  /// Шкала кофемолки: с сервера, а если не приехала — встроенная.
  ///
  /// Сервер прав, когда ответил: его база и есть источник. Встроенная —
  /// запасная, на случай, когда сервис шкал молчит или нет сети.
  List<GrinderMode> get knownModes {
    if (modes.isNotEmpty) return modes;
    return builtInGrinderScales[name] ??
        builtInGrinderScales[builtInGrinderNames[id]] ??
        const [];
  }
}

double? _number(String label) =>
    double.tryParse(label.trim().replaceAll(',', '.'));

/// Деление [label] на шкале [scale] — с его крупностью.
///
/// Сначала по подписи, потом по числу («14» и «14.0» — одно деление). Числа
/// между делениями шкалы («14,5» у рецепта на шкале из целых) получают
/// крупность по прямой между соседями: такой клик рецепт знает, и терять его
/// из-за того, что в базе сервиса нет половинок, нельзя. За краями шкалы и у
/// подписей словами вне шкалы — null: придумывать нечего.
GrinderMode? divisionOnScale(List<GrinderMode> scale, String label) {
  final wanted = label.trim();
  if (wanted.isEmpty) return null;
  for (final mode in scale) {
    if (mode.mode.trim() == wanted && mode.microns > 0) return mode;
  }

  final target = _number(wanted);
  if (target == null) return null;

  final numeric = <(double, GrinderMode)>[
    for (final mode in scale)
      if (mode.microns > 0)
        if (_number(mode.mode) case final value?) (value, mode),
  ]..sort((a, b) => a.$1.compareTo(b.$1));

  for (final (value, mode) in numeric) {
    if (value == target) return mode;
  }
  for (var i = 0; i + 1 < numeric.length; i++) {
    final (low, lowMode) = numeric[i];
    final (high, highMode) = numeric[i + 1];
    if (low < target && target < high) {
      final share = (target - low) / (high - low);
      return GrinderMode(
        mode: wanted,
        microns: lowMode.microns + (highMode.microns - lowMode.microns) * share,
      );
    }
  }
  return null;
}

/// Крупность деления [step] кофемолки [grinderId], мкм — по встроенной шкале.
///
/// Нужна рецепту, записанному делениями чужой кофемолки без слова крупности:
/// только через её микроны его «22» становятся кликами вашей. null — такой
/// кофемолки или такого деления не знаем.
int? stepMicrons(int grinderId, String step) {
  if (grinderId <= 0 || step.trim().isEmpty) return null;
  final grinder = builtInGrinder(grinderId);
  if (grinder == null) return null;
  return divisionOnScale(grinder.modes, step)?.microns.round();
}
