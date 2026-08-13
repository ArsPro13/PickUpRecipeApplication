// Справочник крупности помола: семь ступеней от очень тонкого до очень крупного.
//
// В рецепте лежит slug — `medium_fine`, — а человеку нужно слово. Держать эти
// семь слов копией в клиенте нельзя: справочник засеян миграцией, и второй
// список с теми же данными станет источником расхождений в первый же день,
// когда кто-нибудь поправит один из них.

/// Ступень крупности помола.
class GrindDescriptor {
  const GrindDescriptor({
    required this.slug,
    required this.name,
    required this.microns,
    this.sortOrder = 0,
  });

  /// Совпадает с `grind.descriptor` формата рецепта: именно эта строка лежит
  /// в самом рецепте.
  final String slug;

  final String name;

  /// Микроны ступени. Нужны пересчёту помола между кофемолками.
  final int microns;

  final int sortOrder;

  factory GrindDescriptor.fromJson(Map<String, dynamic> json) {
    return GrindDescriptor(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      microns: (json['microns'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Перевод slug в слово.
///
/// Незнакомый slug возвращается как есть: показать `medium_fine` некрасиво,
/// но это хотя бы правда — а пустая строка на месте помола читается как
/// «помол неизвестен», и это ложь.
String grindDescriptorName(List<GrindDescriptor> reference, String slug) {
  final value = slug.trim();
  if (value.isEmpty) return '';

  for (final descriptor in reference) {
    if (descriptor.slug == value) return descriptor.name;
  }
  return value;
}
