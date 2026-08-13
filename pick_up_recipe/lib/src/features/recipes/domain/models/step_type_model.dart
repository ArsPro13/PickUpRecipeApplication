// Справочник типов шагов: семнадцать типов и пять групп.
//
// Группы живут в базе, а не в клиенте (ответ C11): иначе четыре слова —
// вода, действие, обслуживание, текст — пришлось бы держать одинаковыми
// в трёх местах сразу, включая будущий кабинет обжарщика.
//
// Разрешённые методу типы перечислены не здесь, а у самого метода в
// `allowed_step_types`: справочник один на все двадцать методов, а живых
// клеток у медианного метода семь из семнадцати.

/// Группа типов шагов: вода, действие, обслуживание, пауза, текст.
class StepTypeGroup {
  const StepTypeGroup({
    required this.id,
    required this.slug,
    required this.name,
    this.sortOrder = 0,
  });

  final int id;
  final String slug;
  final String name;
  final int sortOrder;

  factory StepTypeGroup.fromJson(Map<String, dynamic> json) {
    return StepTypeGroup(
      id: (json['id'] as num).toInt(),
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Встроенный тип шага из справочника.
class StepType {
  const StepType({
    required this.id,
    required this.slug,
    required this.name,
    required this.shortName,
    required this.iconKey,
    required this.groupId,
    this.sortOrder = 0,
    this.deviceState = '',
    this.warning = '',
  });

  final int id;

  /// Совпадает с `type` в формате рецепта: pour, bloom, wait, stir.
  final String slug;

  final String name;

  /// Подпись в клетке листа выбора: их четыре в ряд, и полное название
  /// туда не помещается — «смачив.» вместо «предсмачивание».
  final String shortName;

  /// Ключ иконки, не путь к файлу: путь собирает [AppIcons.byKey].
  final String iconKey;

  final int groupId;
  final int sortOrder;

  /// Состояние прибора после этого шага: «Клапан закрыт», «Аэропресс
  /// перевёрнут». Пусто — шаг состояние не меняет.
  final String deviceState;

  /// Что показать до начала шага, с подтверждением. Не подсказка: `tip`
  /// читают во время шага, а это надо прочесть до.
  final String warning;

  factory StepType.fromJson(Map<String, dynamic> json) {
    return StepType(
      id: (json['id'] as num).toInt(),
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      shortName: json['short_name'] as String? ?? '',
      iconKey: json['icon_key'] as String? ?? '',
      groupId: (json['group_id'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      deviceState: json['device_state'] as String? ?? '',
      warning: json['warning'] as String? ?? '',
    );
  }

  /// Подпись для клетки: короткое имя, если оно есть, иначе полное.
  String get label => shortName.isEmpty ? name : shortName;
}

/// Группа вместе с попавшими в неё типами — то, что рисует лист выбора.
class GroupedStepTypes {
  const GroupedStepTypes({required this.slug, required this.name, required this.types});

  /// Slug группы из справочника: по нему лист узнаёт «Паузу и текст»,
  /// которую опускает под «Ваши типы».
  final String slug;

  final String name;
  final List<StepType> types;
}

/// Справочник целиком: группы и типы одной ручкой.
class StepTypeReference {
  const StepTypeReference({this.groups = const [], this.types = const []});

  /// Тип своего шага. Разрешён всем методам и потому ничего не сообщает
  /// о приборе — в сетке выбора ему не место.
  static const String customSlug = 'custom';

  final List<StepTypeGroup> groups;
  final List<StepType> types;

  factory StepTypeReference.fromJson(Map<String, dynamic> json) {
    final groups = (json['groups'] as List<dynamic>? ?? const [])
        .map((item) => StepTypeGroup.fromJson(item as Map<String, dynamic>))
        .toList();
    final types = (json['types'] as List<dynamic>? ?? const [])
        .map((item) => StepType.fromJson(item as Map<String, dynamic>))
        .toList();
    return StepTypeReference(groups: groups, types: types);
  }

  /// Тип по его ключу из рецепта. null — тип неизвестен справочнику:
  /// так бывает у своего шага, у него имя лежит в самом рецепте.
  StepType? bySlug(String slug) {
    for (final type in types) {
      if (type.slug == slug) return type;
    }
    return null;
  }

  /// Разрешённые методу типы, разложенные по группам в порядке справочника.
  ///
  /// Группа без единого разрешённого типа не возвращается вовсе: у V60 нечего
  /// обслуживать, и пустой заголовок «Обслуживание» там читался бы как
  /// «здесь что-то есть, но нам не показали».
  ///
  /// Пустой [allowed] означает «метод не сказал» — тогда показываем всё, а не
  /// ничего: лист без единой клетки хуже листа с лишними.
  ///
  /// `custom` из сетки исключён, хотя он разрешён всем двадцати методам: это
  /// не тип рядом с проливом, а выход за справочник, и в листе он стоит
  /// отдельной клеткой с пунктиром. Двумя клетками об одном лист бы врал.
  List<GroupedStepTypes> allowedFor(List<String> allowed) {
    final permitted = allowed.isEmpty ? null : allowed.toSet();

    final byGroup = <int, List<StepType>>{};
    for (final type in types) {
      if (type.slug == customSlug) continue;
      if (permitted != null && !permitted.contains(type.slug)) continue;
      byGroup.putIfAbsent(type.groupId, () => []).add(type);
    }
    for (final list in byGroup.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    final ordered = [...groups]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final result = <GroupedStepTypes>[];
    for (final group in ordered) {
      final inGroup = byGroup.remove(group.id);
      if (inGroup != null && inGroup.isNotEmpty) {
        result.add(GroupedStepTypes(slug: group.slug, name: group.name, types: inGroup));
      }
    }

    // Тип без группы не теряется: справочник может уехать вперёд клиента,
    // и молча спрятать новый тип — то же самое, что его не завести.
    final orphans = byGroup.values.expand((list) => list).toList();
    if (orphans.isNotEmpty) {
      orphans.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      result.add(GroupedStepTypes(slug: 'other', name: 'Прочие', types: orphans));
    }

    return result;
  }
}
