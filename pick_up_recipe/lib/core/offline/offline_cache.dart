// Ответы сервера, сохранённые на телефоне.
//
// Кладётся не разобранная модель, а тело ответа как оно пришло. Разбирают его
// потом те же строки кода, что и живой ответ, — значит, офлайн не может
// разойтись с онлайном в мелочах вроде необязательного поля или порядка
// элементов. Цена — лишний jsonDecode при чтении; она того стоит.
//
// Срока годности у кэша нет. Рецепт, сохранённый месяц назад, — единственное,
// что можно показать человеку у чайника без сети, и стирать его по таймеру
// значит ровно в этот момент оставить экран пустым.

import 'package:encrypt_shared_preferences/provider.dart';

abstract final class OfflineCache {
  static const String prefix = 'offline_cache_v1:';
  static const String _atSuffix = '@at';

  static EncryptedSharedPreferences get _prefs =>
      EncryptedSharedPreferences.getInstance();

  /// Сохраняет тело ответа под ключом запроса.
  static Future<void> put(String key, String body) async {
    await _prefs.setString('$prefix$key', body);
    await _prefs.setString(
      '$prefix$key$_atSuffix',
      DateTime.now().toIso8601String(),
    );
  }

  /// Сохранённое тело или null, если такого запроса ещё не было.
  static String? body(String key) => _prefs.getString('$prefix$key');

  /// Когда это сохранили. Показывается человеку: «данные от 14 августа».
  static DateTime? savedAt(String key) {
    final raw = _prefs.getString('$prefix$key$_atSuffix');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// Стирает всё сохранённое — на выходе из аккаунта.
  ///
  /// Именно всё: на одном телефоне заваривают вдвоём, и чужой список пачек
  /// после смены аккаунта — хуже пустого экрана.
  static Future<void> clearAll() async {
    for (final key in _prefs.getKeys().where((k) => k.startsWith(prefix))) {
      await _prefs.remove(key);
    }
  }
}
