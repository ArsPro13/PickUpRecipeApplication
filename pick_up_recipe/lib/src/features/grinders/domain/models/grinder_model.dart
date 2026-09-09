// Кофемолка пользователя.
//
// От неё зависят щелчки в каждом рецепте: рецепт хранит крупность помола,
// а показать её человеку можно только в делениях его собственной кофемолки.
// Поэтому кофемолка стоит кнопкой в шапке главного экрана, а не в глубине
// профиля.

/// Вид кофемолки. Совпадает с колонкой kind справочника grinders.
///
/// В перечислении только код с провода: заголовок группы — слово для человека,
/// и лежит оно в словаре, а не здесь. Модель обязана оставаться на двух языках
/// одинаковой.
enum GrinderKind {
  manual('manual'),
  electric('electric'),
  unknown('');

  const GrinderKind(this.wireName);

  final String wireName;

  static GrinderKind fromWire(String? value) {
    if (value == null || value.isEmpty) return GrinderKind.unknown;
    for (final kind in GrinderKind.values) {
      if (kind.wireName == value) return kind;
    }
    return GrinderKind.unknown;
  }
}

/// Одно деление шкалы кофемолки.
///
/// Деление — строка, а не число: у части кофемолок шкала подписана словами
/// («2 круг + 3» у Feld47, «2A» у Baratza Forte), и загнать её в число значит
/// потерять пятую часть справочника.
class GrinderMode {
  const GrinderMode({required this.mode, required this.microns});

  /// Подпись деления: «14.0», «2 круг + 3», «2A».
  final String mode;

  /// Средняя крупность помола на этом делении. Через неё и идёт перевод:
  /// крупность рецепта → ближайшее деление шкалы.
  final double microns;

  factory GrinderMode.fromJson(Map<String, dynamic> json) {
    return GrinderMode(
      mode: json['mode'] as String? ?? '',
      microns: (json['avg'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Grinder {
  const Grinder({
    required this.id,
    required this.name,
    this.kind = GrinderKind.unknown,
    this.modes = const [],
  });

  final int id;
  final String name;
  final GrinderKind kind;

  /// Шкала кофемолки. Пусто — сервис пересчёта её не отдал, и помол
  /// показывается словом: выдуманное деление хуже честного слова.
  final List<GrinderMode> modes;

  factory Grinder.fromJson(Map<String, dynamic> json) {
    return Grinder(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      kind: GrinderKind.fromWire(json['kind'] as String?),
      modes: [
        for (final mode in json['modes'] as List<dynamic>? ?? const [])
          GrinderMode.fromJson(mode as Map<String, dynamic>),
      ],
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
