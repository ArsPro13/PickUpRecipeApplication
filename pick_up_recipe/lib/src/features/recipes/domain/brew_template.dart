// Шесть шаблонов экрана заваривания (design/night4/brew.html).
//
// Двадцать методов не требуют двадцати экранов — но и одним не покрываются.
// Граница между шаблонами проходит не по группе прибора, а по тому, чем
// определяется конец шага: секундомером, признаком, усилием руки или часами
// на стене.

import 'models/recipe_data_model.dart';

enum BrewTemplate {
  /// Пролив по таймеру: шаги короткие, вода делится порциями. Опорный случай.
  pour,

  /// То же плюс состояние прибора, которое обязано быть видно всегда:
  /// шаг «закрыть клапан» длится пять секунд, а состояние живёт минуту.
  valve,

  /// Усилие руками: отжим, переворот. Конец шага определяет рука, таймер
  /// вторичен.
  press,

  /// Готовность определяет признак, а не секундомер: пена поднялась,
  /// забулькало. Время — ориентир.
  cue,

  /// Часы вместо минут: экран не держат в руках, важно «готово в 08:40».
  long,

  /// Один короткий пролив, цель — вес в чашке, а не налитая вода.
  /// Секундомер считает вверх: следят за первой каплей и выходом.
  shot,
}

/// Порог «часов»: час. Настаивание длиннее часа не смотрят на экране —
/// к нему возвращаются.
const _longThreshold = Duration(hours: 1);

/// Выбирает шаблон по рецепту и методу.
///
/// [waterMeaning] и [methodGroup] — из справочника brew_methods; пустые
/// строки допустимы: рецепт без метода получает опорный шаблон по шагам.
BrewTemplate resolveBrewTemplate(
  RecipeData recipe, {
  String waterMeaning = 'poured',
  String methodGroup = '',
}) {
  if (recipe.time > _longThreshold.inSeconds) return BrewTemplate.long;
  if (waterMeaning == 'in_cup') return BrewTemplate.shot;

  final types = {for (final step in recipe.steps) step.stepType};

  if (types.contains('open_valve') || types.contains('close_valve')) {
    return BrewTemplate.valve;
  }
  if (types.contains('press') || types.contains('invert') || types.contains('flip')) {
    return BrewTemplate.press;
  }

  // Огонь и пар: мока, перколятор, сифон — конец шага слышно и видно,
  // а не отсчитывается. Турка и брю-пайп греются без давления, но признак
  // у них тот же — пена, — и по группе их не поймать.
  if (methodGroup == 'pressure') return BrewTemplate.cue;
  if (recipe.device == 'cezve' || recipe.device == 'bripe' || recipe.device == 'siphon') {
    return BrewTemplate.cue;
  }

  return BrewTemplate.pour;
}
