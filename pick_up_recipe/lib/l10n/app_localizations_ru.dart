// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get back => 'Назад';

  @override
  String get noNetwork => 'Нет сети';

  @override
  String get offlineCached => 'Нет сети. Показываем сохранённое';

  @override
  String get offlineSyncing => 'Связь есть — отправляем сохранённое';

  @override
  String offlinePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дела уедут',
      many: '$count дел уедут',
      few: '$count дела уедут',
      one: '$count дело уедет',
    );
    return 'Нет сети. $_temp0, когда появится связь';
  }
}
