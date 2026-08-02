// Кофемолка пользователя.
//
// От неё зависят щелчки в каждом рецепте: рецепт хранит крупность помола,
// а показать её человеку можно только в делениях его собственной кофемолки.
// Поэтому кофемолка стоит кнопкой в шапке главного экрана, а не в глубине
// профиля.

/// Вид кофемолки. Совпадает с колонкой kind справочника grinders.
enum GrinderKind {
  manual('manual', 'Ручные'),
  electric('electric', 'Электрические'),
  unknown('', 'Прочие');

  const GrinderKind(this.wireName, this.title);

  final String wireName;

  /// Заголовок группы в списке выбора.
  final String title;

  static GrinderKind fromWire(String? value) {
    if (value == null || value.isEmpty) return GrinderKind.unknown;
    for (final kind in GrinderKind.values) {
      if (kind.wireName == value) return kind;
    }
    return GrinderKind.unknown;
  }
}

class Grinder {
  const Grinder({
    required this.id,
    required this.name,
    this.kind = GrinderKind.unknown,
  });

  final int id;
  final String name;
  final GrinderKind kind;

  factory Grinder.fromJson(Map<String, dynamic> json) {
    return Grinder(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      kind: GrinderKind.fromWire(json['kind'] as String?),
    );
  }

  @override
  bool operator ==(Object other) => other is Grinder && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Grinder($id, $name)';
}

/// Кофемолка пользователя вместе с признаком основной.
///
/// Основная нужна для пересчёта: в рецепте показывается одно число, и выбирать
/// его из нескольких кофемолок приложение не может — только человек.
class UserGrinder {
  const UserGrinder({required this.grinder, this.isPrimary = false});

  final Grinder grinder;
  final bool isPrimary;

  factory UserGrinder.fromJson(Map<String, dynamic> json) {
    return UserGrinder(
      grinder: Grinder.fromJson(json),
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}
