// Помол делениями вашей кофемолки, а не словом (пункт 8).
//
// В рецепте крупность записана двумя способами: словесной ступенью
// (`grind_descriptor`, семь штук от «очень тонкого» до «очень крупного») и
// делением конкретной кофемолки (`grind_step` + `grinder_id`). У справочного
// рецепта деления нет вовсе — grinder_id там 0, техническая заглушка, —
// поэтому на экране оставалось одно слово. Владельцу нужно число ЕГО
// кофемолки.
//
// Перевод идёт в два шага, ровно как обещает миграция справочника крупности:
// дескриптор → микроны → ближайшее деление шкалы. Микроны знает справочник
// grind_descriptors, шкалу — grinder_translator; она приезжает вместе с
// кофемолками пользователя в профиле.
//
// Пересчёт лежит здесь, а не в экранах: его показывают четыре экрана, и
// расходиться им нельзя. Из Flutter файлу нужен один словарь — подписи вокруг
// числа («примерно», «делений …», «щ.») это текст интерфейса, и в коде им не
// место. Ни имя кофемолки, ни слово справочника крупности, ни подпись деления
// через словарь не проходят: это данные сервера.

import 'package:flutter/widgets.dart' show Locale;

import '../../../../l10n/app_localizations.dart';
import '../../recipes/domain/models/grind_descriptor_model.dart';
import 'models/grinder_model.dart';

/// Словарь на языке шаблона.
///
/// Стоит, пока экран не передал свой: помол показывают четыре экрана из разных
/// веток, и перевести их одной правкой этого файла нельзя. Русского текста в
/// коде при этом не остаётся — строка всё равно приходит из `app_ru.arb`.
final AppLocalizations _templateTexts = lookupAppLocalizations(const Locale('ru'));

/// Помол так, как его показывают человеку.
class GrindReading {
  const GrindReading({
    required this.value,
    this.grinderName,
    this.word = '',
    this.isApproximate = false,
    this.isDivision = false,
    this.needsGrinder = false,
    this.texts,
  });

  /// Что стоит на месте помола: «14», «2 круг + 3», «Средне-тонкий», «26 щ.».
  final String value;

  /// Чья это шкала. Пусто — значение не привязано к кофемолке.
  final String? grinderName;

  /// Крупность словом из справочника. Нужна подписи, когда на виду число.
  final String word;

  /// Значение получено пересчётом, а не записано в рецепте. Такое помечают
  /// словом «примерно»: считать его точным нельзя, шкалы кофемолок сходятся
  /// только по средней крупности.
  final bool isApproximate;

  /// Это деление кофемолки, а не слово справочника.
  final bool isDivision;

  /// Кофемолки нет, и потому показано слово. Не «нечего показать», а
  /// «покажем больше, если выберете» — приглашение, а не ошибка.
  final bool needsGrinder;

  /// Словарь, которым подписано число. Пусто — язык шаблона.
  final AppLocalizations? texts;

  AppLocalizations get _words => texts ?? _templateTexts;

  bool get isEmpty => value.isEmpty;

  /// Готовая строка на месте помола.
  String get label => isApproximate ? _words.grinderApproximately(value) : value;

  /// Короткая подпись — для плиток показателей, где места на одно слово.
  String? get caption {
    if (isDivision && grinderName != null) return grinderName;
    if (needsGrinder) return _words.grinderPickPrompt;
    return null;
  }

  /// Подпись строкой — для экрана заваривания, где места больше.
  String? get hint {
    if (isDivision && grinderName != null) {
      return [
        _words.grinderScaleOf(grinderName!),
        if (word.isNotEmpty) word,
      ].join(' · ');
    }
    if (needsGrinder) return _words.grinderPickPromptHint;
    return null;
  }
}

/// Помол рецепта в делениях кофемолки человека.
///
/// [grinder] — основная кофемолка пользователя. `null` означает «не выбрана»,
/// и это нормальное состояние: помол тогда остаётся словом, а рядом встаёт
/// приглашение выбрать кофемолку. Прятать помол в этом случае нельзя — до
/// пункта 8 он именно так и показывался, и это единственное, что у человека
/// было.
///
/// [recipeGrinderId] и [recipeGrindStep] — помол, записанный в самом рецепте.
/// Если он записан в делениях той же кофемолки, пересчитывать нечего: своё
/// число точнее любого перевода.
///
/// [texts] — словарь экрана: им подписывают число слова «примерно», «делений»
/// и «щ.». Без него подписи встают на языке шаблона.
GrindReading grindReading({
  required String descriptorSlug,
  List<GrindDescriptor> reference = const [],
  int? recipeMicrons,
  int recipeGrinderId = 0,
  String recipeGrindStep = '',
  Grinder? grinder,
  AppLocalizations? texts,
}) {
  final step = recipeGrindStep.trim();
  final word = grindDescriptorName(reference, descriptorSlug).trim();

  // Рецепт уже записан в делениях этой кофемолки — считать нечего и незачем.
  if (grinder != null && grinder.id == recipeGrinderId && step.isNotEmpty) {
    return GrindReading(
      value: grinderDivisionLabel(step),
      grinderName: grinder.name,
      word: word,
      isDivision: true,
      texts: texts,
    );
  }

  final microns = recipeMicrons ?? grindDescriptorMicrons(reference, descriptorSlug);

  if (grinder != null && microns != null && microns > 0) {
    final mode = nearestGrinderMode(grinder.modes, microns);
    if (mode != null) {
      return GrindReading(
        value: grinderDivisionLabel(mode.mode),
        grinderName: grinder.name,
        word: word,
        isApproximate: true,
        isDivision: true,
        texts: texts,
      );
    }
  }

  // Деление взять неоткуда: кофемолки нет, её шкалы нет или крупность рецепта
  // неизвестна. Остаётся слово — пустое место на месте помола читалось бы как
  // «помол неизвестен», а это неправда.
  if (word.isNotEmpty) {
    return GrindReading(value: word, needsGrinder: grinder == null, texts: texts);
  }

  // Слова нет — у исторических рецептов его и не было. Тогда показывается
  // число самого рецепта, и «щ.» объясняет его само: чья это шкала, здесь
  // сказать нечего.
  if (step.isNotEmpty) {
    return GrindReading(
      value: (texts ?? _templateTexts).grinderClicks(grinderDivisionLabel(step)),
      needsGrinder: grinder == null,
      texts: texts,
    );
  }

  return const GrindReading(value: '');
}

/// Ближайшее деление шкалы к заданной крупности.
///
/// Ближайшее по средней крупности — так же, как это делает сам сервис
/// пересчёта: точного соответствия между шкалами разных кофемолок не бывает.
GrinderMode? nearestGrinderMode(List<GrinderMode> modes, int microns) {
  GrinderMode? best;
  var distance = double.infinity;

  for (final mode in modes) {
    if (mode.mode.isEmpty || mode.microns <= 0) continue;
    final gap = (mode.microns - microns).abs();
    if (gap < distance) {
      distance = gap;
      best = mode;
    }
  }

  return best;
}

/// Микроны ступени крупности. `null` — ступени нет в справочнике.
int? grindDescriptorMicrons(List<GrindDescriptor> reference, String slug) {
  final value = slug.trim();
  if (value.isEmpty) return null;

  for (final descriptor in reference) {
    if (descriptor.slug == value) {
      return descriptor.microns > 0 ? descriptor.microns : null;
    }
  }
  return null;
}

/// Деление без лишнего хвоста: «14.0» → «14», «7.5» → «7,5».
///
/// Текстовые деления возвращаются как есть: «2 круг + 3» и «2A» — тоже
/// законные подписи шкалы, и разбирать их числом нельзя.
String grinderDivisionLabel(String mode) {
  final value = mode.trim();
  final number = double.tryParse(value.replaceAll(',', '.'));
  if (number == null) return value;

  final rounded = (number * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return rounded.round().toString();
  return rounded.toStringAsFixed(1).replaceAll('.', ',');
}
