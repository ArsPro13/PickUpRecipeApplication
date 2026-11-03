import 'method_names.dart';

/// Метод заваривания из справочника.
class BrewMethod {
  const BrewMethod({
    required this.id,
    required this.slug,
    required this.name,
    required this.iconKey,
    this.nameEn = '',
    this.nameIt = '',
    this.groupId,
    this.allowedStepTypes = const [],
    this.waterMeaning = 'poured',
    this.sortOrder = 0,
  });

  final int id;
  final String slug;

  /// Русское название: «Кемекс (Chemex)», «Френч-пресс». На других языках —
  /// [nameFor].
  final String name;

  /// Английское и итальянское названия; пустые — у сервера старше 03.11.2026.
  final String nameEn;
  final String nameIt;

  /// Название на языке экрана.
  String nameFor(String language) =>
      localizedMethodName(language, name: name, en: nameEn, it: nameIt);

  /// Ключ иконки на клиенте, не путь к файлу.
  final String iconKey;

  final int? groupId;

  /// Какие типы шагов разрешены этому методу. Лист выбора показывает только их.
  final List<String> allowedStepTypes;

  /// Что означает вес воды: 'poured' — налитая, 'in_cup' — вес в чашке.
  /// У эспрессо это выход напитка, и подписывать поле так же, как у V60,
  /// значит соврать.
  final String waterMeaning;

  final int sortOrder;

  factory BrewMethod.fromJson(Map<String, dynamic> json) {
    return BrewMethod(
      id: (json['id'] as num).toInt(),
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      nameIt: json['name_it'] as String? ?? '',
      iconKey: json['icon_key'] as String? ?? '',
      groupId: (json['group_id'] as num?)?.toInt(),
      allowedStepTypes:
          (json['allowed_step_types'] as List<dynamic>? ?? const [])
              .cast<String>(),
      waterMeaning: json['water_meaning'] as String? ?? 'poured',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Группа методов: пуровер, иммерсия, давление, холодный.
class BrewMethodGroup {
  const BrewMethodGroup({
    required this.id,
    required this.slug,
    required this.name,
    required this.iconKey,
    this.nameEn = '',
    this.nameIt = '',
    this.sortOrder = 0,
  });

  final int id;
  final String slug;
  final String name;
  final String nameEn;
  final String nameIt;
  final String iconKey;
  final int sortOrder;

  /// Название группы на языке экрана: «Пуровер» / «Pour-over».
  String nameFor(String language) =>
      localizedMethodName(language, name: name, en: nameEn, it: nameIt);

  factory BrewMethodGroup.fromJson(Map<String, dynamic> json) {
    return BrewMethodGroup(
      id: (json['id'] as num).toInt(),
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      nameIt: json['name_it'] as String? ?? '',
      iconKey: json['icon_key'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
