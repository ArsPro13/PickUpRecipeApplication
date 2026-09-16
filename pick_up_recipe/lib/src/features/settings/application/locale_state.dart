// Язык приложения, выбранный человеком.
//
// ПОЧЕМУ ЭТО ВООБЩЕ НУЖНО. До этого язык брался только из системного:
// `localeResolutionCallback` искал среди .arb тот, что совпадает с языком
// телефона, и на всё остальное отвечал английским. Это верно по умолчанию и
// неверно как единственный вариант — человек, у которого телефон на одном
// языке, а кофе он читает на другом, поменять ничего не мог.
//
// Хранится на телефоне, а не на сервере, в отличие от кофемолки: язык — это
// свойство того, как человек СМОТРИТ на приложение здесь и сейчас, а не его
// имущество. На планшете с итальянской системой и на телефоне с русской
// разумны разные ответы, и синхронизировать их между устройствами было бы
// не услугой, а навязчивостью.

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ключ в настройках телефона.
const String localePrefsKey = 'app_locale';

/// Языки, между которыми можно выбирать.
///
/// Список руками, а не из `AppLocalizations.supportedLocales`: туда генератор
/// складывает всё, что нашёл по именам файлов, и недописанный .arb попал бы в
/// выбор раньше, чем в нём появился хоть один перевод.
///
/// Подписи — на самих этих языках и в словарь не идут. Список языков читает
/// тот, кто нынешнего языка может не понимать: «итальянский» по-русски не
/// поможет человеку, который ищет Italiano.
const List<({Locale locale, String label})> appLocales = [
  (locale: Locale('ru'), label: 'Русский'),
  (locale: Locale('en'), label: 'English'),
  (locale: Locale('it'), label: 'Italiano'),
];

/// Выбранный язык. null — «как в системе», и это умолчание.
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _restore();
  }

  void _restore() {
    final saved =
        EncryptedSharedPreferences.getInstance().getString(localePrefsKey);
    if (saved == null || saved.isEmpty) return;

    // Сверяем с известными: в настройках может лежать код языка, перевод
    // для которого потом убрали, и тогда приложение молча осталось бы на
    // запасном английском, не умея объяснить почему.
    for (final entry in appLocales) {
      if (entry.locale.languageCode == saved) {
        state = entry.locale;
        return;
      }
    }
  }

  /// Ставит язык; null возвращает «как в системе».
  Future<void> choose(Locale? locale) async {
    state = locale;

    final prefs = EncryptedSharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(localePrefsKey);
      return;
    }
    await prefs.setString(localePrefsKey, locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (ref) => LocaleNotifier(),
);
