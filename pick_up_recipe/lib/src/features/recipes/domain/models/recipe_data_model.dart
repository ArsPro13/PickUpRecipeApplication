import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_response_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';

part 'recipe_data_model.g.dart';

@JsonSerializable()
class RecipeData {
  /// Идентификатор рецепта. Без него нельзя ни сохранить оценку, ни попросить
  /// поправку: обе ручки работают по recipe_id.
  late int id;

  late String device;

  late String date;

  @JsonKey(name: "pack")
  late int packId;

  @JsonKey(name: "grinder_id")
  late int grinderId;

  @JsonKey(name: "grind_step")
  late String grindStep;

  @JsonKey(name: "grind_sub_step")
  late String? grindSubStep;

  late int water;

  late int time;

  /// Температура воды. null — рецепт её не знает: так у исторических записей,
  /// и показывать вместо неё придуманное число нельзя.
  late double? temperature;

  late double load;

  /// Название рецепта. Пусто — экран показывает метод заваривания.
  late String title;

  late String notes;

  late String grindDescriptor;

  late int? agitationLevel;

  late List<RecipeStep> steps;

  /// У этой чашки уже есть оценка. Приезжает вместе со списком рецептов.
  ///
  /// Умолчание false, и параметр конструктора необязательный: рецепт, только
  /// что собранный конструктором или поправкой, оценки заведомо не имеет, и
  /// требовать её указания от каждого вызывающего было бы шумом.
  @JsonKey(name: "has_estimation", defaultValue: false)
  late bool hasEstimation;

  /// Когда по рецепту заваривали последний раз — ISO-строкой, как [date].
  ///
  /// [date] — когда версию сохранили, и это разные вещи: рецепт сохраняют
  /// один раз, а заваривают по нему каждое утро. Пока поля не было, повтор
  /// рецепта не менял на карточке ничего, а чтобы дата «сдвинулась»,
  /// приложение сохраняло ещё одну такую же версию.
  ///
  /// null — по рецепту не заваривали (или сервер старый и этого не считает).
  /// Что показывать на карточке, решает [RecipeUse.usedAt].
  @JsonKey(name: "last_brewed_at")
  late String? lastBrewedAt;

  RecipeData({
    required this.id,
    required this.device,
    required this.date,
    required this.packId,
    required this.grinderId,
    required this.grindStep,
    required this.grindSubStep,
    required this.water,
    required this.time,
    required this.temperature,
    required this.load,
    required this.title,
    required this.notes,
    required this.grindDescriptor,
    required this.agitationLevel,
    required this.steps,
    this.hasEstimation = false,
    this.lastBrewedAt,
  });

  factory RecipeData.fromJson(Map<String, dynamic> json) =>
      _$RecipeDataFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeDataToJson(this);

  factory RecipeData.fromResponse(RecipeResponseModel response) => RecipeData(
        id: response.id,
        device: response.device,
        date: response.date,
        packId: response.packId,
        grinderId: response.grinderId,
        grindStep: response.grindStep,
        grindSubStep: response.grindSubStep,
        water: response.water,
        time: response.time,
        temperature: response.temperature,
        load: response.load,
        title: response.title,
        notes: response.notes,
        grindDescriptor: response.grindDescriptor,
        agitationLevel: response.agitationLevel,
        steps: response.steps.map((e) => RecipeStep.fromResponse(e)).toList(),
        hasEstimation: response.hasEstimation,
        lastBrewedAt: response.lastBrewedAt,
      );
}

/// Когда рецептом пользовались.
///
/// Расширением, а не геттером класса: RecipeData собирает json_serializable,
/// и геттер, добавленный в сам класс, уехал бы в toJson — то есть в кэш, в
/// черновики и в запрос к серверу.
extension RecipeUse on RecipeData {
  /// Момент последнего заваривания, а если по рецепту не заваривали — момент,
  /// когда версию сохранили. По нему карточки стоят в списке и по нему же
  /// подписаны: «когда я последний раз так заваривал».
  String get usedAt {
    final brewed = lastBrewedAt;
    if (brewed == null || brewed.isEmpty) return date;
    return compareMoments(brewed, date) >= 0 ? brewed : date;
  }
}

/// Сравнивает два момента, записанных ISO-строками: раньше — меньше.
///
/// Через разбор, а не строками как есть. Сервер отдаёт время то с долями
/// секунды, то без, и «…:05Z» при сравнении букв оказывается позже, чем
/// «…:05.300Z», хотя на деле раньше: точка в таблице символов стоит до «Z».
/// Неразобранная строка сравнивается буквами — как раньше сравнивались все.
int compareMoments(String a, String b) {
  final left = DateTime.tryParse(a);
  final right = DateTime.tryParse(b);
  if (left == null || right == null) return a.compareTo(b);
  return left.compareTo(right);
}

/// Глубокая копия рецепта.
///
/// Через JSON, а не полем за полем: у рецепта есть список шагов, и копия,
/// сделанная присваиванием, делила бы его с оригиналом — правка одной версии
/// молча меняла бы другую.
///
/// Именно `jsonEncode(recipe)`, а не `recipe.toJson()`: генератор оставляет в
/// карте сами объекты шагов (`'steps': instance.steps`), и разбор такой карты
/// падает на приведении типа. jsonEncode проходит по шагам сам и превращает
/// их в карты — как это делает отправка на сервер.
RecipeData copyRecipe(RecipeData recipe) {
  return RecipeData.fromJson(
      jsonDecode(jsonEncode(recipe)) as Map<String, dynamic>);
}

/// Версии по порядку «чем заваривали последним» и без повторов.
///
/// Одинаковые версии — те же числа и те же шаги — это один рецепт, и
/// показывается он один раз. Прежние сборки плодили такие копии сами: каждое
/// заваривание по справочному рецепту сохраняло его заново, и стопка
/// показывала «5 версий» с одними и теми же числами. Новых копий больше не
/// заводится, а эти остались в базе; стирать их оттуда незачем (на них висят
/// оценки), но и показывать как разные рецепты нельзя.
///
/// Из одинаковых остаётся та, по которой заваривали последней: с неё и
/// заваривают снова. [fingerprint] — чем версии сравнивать; обычно это
/// `recipeFingerprint`, и он передаётся сюда, а не зовётся напрямую, чтобы
/// модель не тянула за собой слой хранения.
///
/// [onDuplicate] зовётся для каждой отброшенной версии — с ней и с той, что
/// осталась вместо неё: так список узнаёт, что оценка есть хотя бы у одной.
List<RecipeData> distinctVersions(
  Iterable<RecipeData> recipes, {
  required String Function(RecipeData) fingerprint,
  void Function(RecipeData kept, RecipeData duplicate)? onDuplicate,
}) {
  final sorted = [...recipes]
    ..sort((a, b) => compareMoments(b.usedAt, a.usedAt));

  final byKey = <String, RecipeData>{};
  final distinct = <RecipeData>[];
  for (final recipe in sorted) {
    final key = fingerprint(recipe);
    final kept = byKey[key];
    if (kept != null) {
      onDuplicate?.call(kept, recipe);
      continue;
    }
    byKey[key] = recipe;
    distinct.add(recipe);
  }
  return distinct;
}
