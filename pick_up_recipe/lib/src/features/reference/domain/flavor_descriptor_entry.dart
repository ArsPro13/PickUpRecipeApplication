// Строка словаря дескрипторов: слово, его категория и ступень.
//
// Одна и та же строка работает в двух местах: красит тег (категория задаёт
// тон, ступень — цветность) и подсказывает в поле ввода. Разводить их в две
// сущности значит завести два списка слов, которые разойдутся.

class FlavorDescriptorEntry {
  const FlavorDescriptorEntry({
    required this.slug,
    required this.name,
    required this.category,
    required this.intensity,
    this.nameEn = '',
  });

  final String slug;
  final String name;

  /// Английское имя. Пустое — показывается русское: словарь правят руками,
  /// и перевода может не быть.
  final String nameEn;

  String label(bool english) => english && nameEn.isNotEmpty ? nameEn : name;

  /// Слаг категории флейвор-вила: `berry`, `citrus`, `mouthfeel`…
  final String category;

  /// Ступень внутри категории: 1 — семья, 2 — обычное слово, 3 — редкое.
  final int intensity;

  factory FlavorDescriptorEntry.fromJson(Map<String, dynamic> json) {
    return FlavorDescriptorEntry(
      slug: (json['slug'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      category: (json['flavor_category'] as String? ?? 'other').trim(),
      // Ступени может не быть: сервер старее приложения — обычное дело у
      // тех, кто не обновляется. Двойка — середина, а не «неизвестно».
      intensity: (json['intensity'] as num?)?.toInt() ?? 2,
      nameEn: (json['name_en'] as String? ?? '').trim(),
    );
  }
}
