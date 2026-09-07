import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// Стрелка возврата в шапке экрана. Читается только голосовым помощником и всплывающей подсказкой.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get back;

  /// Запрос не дошёл до сервера. Коротко: строка встаёт в чужое сообщение об ошибке.
  ///
  /// In ru, this message translates to:
  /// **'Нет сети'**
  String get noNetwork;

  /// Полоска связи наверху: сети нет, а отправлять нечего.
  ///
  /// In ru, this message translates to:
  /// **'Нет сети. Показываем сохранённое'**
  String get offlineCached;

  /// Полоска связи наверху: сеть вернулась, очередь разбирается.
  ///
  /// In ru, this message translates to:
  /// **'Связь есть — отправляем сохранённое'**
  String get offlineSyncing;

  /// Полоска связи наверху: сети нет и в очереди что-то ждёт отправки. Склонение делает ICU, а не рука: правило «1 дело / 2 дела / 5 дел» у каждого языка своё, и в коде ему не место.
  ///
  /// In ru, this message translates to:
  /// **'Нет сети. {count, plural, one{{count} дело уедет} few{{count} дела уедут} many{{count} дел уедут} other{{count} дела уедут}}, когда появится связь'**
  String offlinePending(int count);

  /// Кнопка и заголовок: завести новый аккаунт. Одна строка на приветствие и регистрацию.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get authCreateAccount;

  /// Кнопка входа. Стоит на приветствии, на входе и под формой регистрации.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get authSignIn;

  /// Подпись поля адреса — на входе, регистрации и восстановлении пароля.
  ///
  /// In ru, this message translates to:
  /// **'Почта'**
  String get fieldEmail;

  /// Подпись поля пароля на входе и регистрации.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get fieldPassword;

  /// Приветствие: строка под названием приложения.
  ///
  /// In ru, this message translates to:
  /// **'Рецепт от того, кто жарил это зерно'**
  String get welcomeTagline;

  /// Приветствие: заголовок списка того, что даёт аккаунт.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт хранит'**
  String get welcomeKeepsTitle;

  /// Приветствие: первое, что хранит аккаунт.
  ///
  /// In ru, this message translates to:
  /// **'Ваши рецепты'**
  String get welcomeKeepsRecipes;

  /// Приветствие: пояснение к рецептам.
  ///
  /// In ru, this message translates to:
  /// **'версии переживают смену телефона'**
  String get welcomeKeepsRecipesNote;

  /// Приветствие: второе, что хранит аккаунт.
  ///
  /// In ru, this message translates to:
  /// **'Кофемолку'**
  String get welcomeKeepsGrinder;

  /// Приветствие: пояснение к кофемолке.
  ///
  /// In ru, this message translates to:
  /// **'помол пересчитывается в ваши щелчки'**
  String get welcomeKeepsGrinderNote;

  /// Приветствие: третье, что хранит аккаунт.
  ///
  /// In ru, this message translates to:
  /// **'Историю пачек'**
  String get welcomeKeepsPacks;

  /// Приветствие: пояснение к истории пачек.
  ///
  /// In ru, this message translates to:
  /// **'что и как заваривали полгода назад'**
  String get welcomeKeepsPacksNote;

  /// Заголовок экрана входа. Отдельно от кнопки: заголовок называет экран, кнопка — действие.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get loginTitle;

  /// Вход: ссылка на восстановление пароля.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get loginForgot;

  /// Вход: вопрос в строке перехода на регистрацию.
  ///
  /// In ru, this message translates to:
  /// **'Нет аккаунта?'**
  String get loginNoAccount;

  /// Вход: действие в строке перехода на регистрацию.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get loginCreate;

  /// Регистрация: подпись поля повтора пароля.
  ///
  /// In ru, this message translates to:
  /// **'Ещё раз'**
  String get registerRepeat;

  /// Регистрация: правило пароля под полем. Длину задаёт сервер, поэтому она подставляется, а не вписана в строку.
  ///
  /// In ru, this message translates to:
  /// **'не короче {length} знаков'**
  String registerPasswordRule(int length);

  /// Регистрация: что произойдёт после нажатия кнопки.
  ///
  /// In ru, this message translates to:
  /// **'Дальше — письмо с кодом'**
  String get registerNextMail;

  /// Регистрация: пояснение к письму с кодом.
  ///
  /// In ru, this message translates to:
  /// **'шесть знаков, чтобы подтвердить адрес'**
  String get registerNextMailNote;

  /// Регистрация: вопрос в строке перехода на вход.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть аккаунт?'**
  String get registerHaveAccount;

  /// Регистрация: отметки согласия нет, а без неё регистрация невозможна.
  ///
  /// In ru, this message translates to:
  /// **'Без согласия зарегистрировать аккаунт нельзя'**
  String get registerConsentRequired;

  /// Регистрация: редакцию документов не удалось получить с сервера, а без неё согласие ничего не доказывает.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить условия. Проверьте связь и попробуйте ещё раз.'**
  String get registerTermsUnavailable;

  /// Регистрация: начало строки согласия. Дальше идут две ссылки, поэтому строка обрывается пробелом.
  ///
  /// In ru, this message translates to:
  /// **'Соглашаюсь с '**
  String get consentPrefix;

  /// Регистрация: ссылка на политику обработки данных внутри строки согласия.
  ///
  /// In ru, this message translates to:
  /// **'политикой обработки данных'**
  String get consentPrivacy;

  /// Регистрация: союз между двумя ссылками в строке согласия. Пробелы по краям обязательны.
  ///
  /// In ru, this message translates to:
  /// **' и '**
  String get consentAnd;

  /// Регистрация: ссылка на пользовательское соглашение внутри строки согласия.
  ///
  /// In ru, this message translates to:
  /// **'пользовательским соглашением'**
  String get consentAgreement;

  /// Заголовок экрана подтверждения почты.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите почту'**
  String get verifyTitle;

  /// Подтверждение почты: что человек должен искать в письме.
  ///
  /// In ru, this message translates to:
  /// **'Отправили код из шести знаков'**
  String get verifySubtitle;

  /// Подтверждение почты: подпись карандаша рядом с адресом. Читается голосовым помощником.
  ///
  /// In ru, this message translates to:
  /// **'Изменить адрес'**
  String get verifyChangeEmail;

  /// Подтверждение почты: главная кнопка.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get verifyConfirm;

  /// Подтверждение почты: вопрос перед кнопкой повторной отправки. Речь о коде.
  ///
  /// In ru, this message translates to:
  /// **'Не пришёл?'**
  String get verifyNotArrived;

  /// Подтверждение почты: письмо в пути, кнопка занята.
  ///
  /// In ru, this message translates to:
  /// **'Отправляем…'**
  String get verifySending;

  /// Подтверждение почты: кнопка повторной отправки, когда её уже можно нажать.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код ещё раз'**
  String get verifyResend;

  /// Подтверждение почты: та же кнопка, пока идёт отсчёт. {time} — остаток в виде м:сс.
  ///
  /// In ru, this message translates to:
  /// **'Ещё раз через {time}'**
  String verifyResendIn(String time);

  /// Подтверждение почты: повторная отправка удалась.
  ///
  /// In ru, this message translates to:
  /// **'Отправили ещё одно письмо'**
  String get verifySentAgain;

  /// Подтверждение почты: сервер отказал по частоте. Человеку нужен срок, а не слово «часто».
  ///
  /// In ru, this message translates to:
  /// **'Письмо уже уходило. Следующее — через {time}'**
  String verifyTooOften(String time);

  /// Подтверждение почты: сервер отверг сам запрос, а не почту.
  ///
  /// In ru, this message translates to:
  /// **'Сервер не принял этот адрес. Проверьте, тот ли он'**
  String get verifyAddressRejected;

  /// Подтверждение почты: заголовок списка того, что делать без письма.
  ///
  /// In ru, this message translates to:
  /// **'Если письмо не пришло'**
  String get verifyHelpTitle;

  /// Подтверждение почты: первая причина, по которой письма не видно.
  ///
  /// In ru, this message translates to:
  /// **'Загляните в «Спам»'**
  String get verifyHelpSpam;

  /// Подтверждение почты: пояснение про папку со спамом.
  ///
  /// In ru, this message translates to:
  /// **'отправитель новый, и почта его ещё не знает'**
  String get verifyHelpSpamNote;

  /// Подтверждение почты: вторая причина — письмо ещё в пути.
  ///
  /// In ru, this message translates to:
  /// **'Подождите минуту'**
  String get verifyHelpWait;

  /// Подтверждение почты: пояснение про время доставки.
  ///
  /// In ru, this message translates to:
  /// **'письмо идёт не мгновенно, обычно меньше минуты'**
  String get verifyHelpWaitNote;

  /// Подтверждение почты: третья причина — опечатка в адресе.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте адрес'**
  String get verifyHelpAddress;

  /// Подтверждение почты: пояснение про опечатку в адресе.
  ///
  /// In ru, this message translates to:
  /// **'опечатка в почте — самая частая причина; исправить адрес можно карандашом наверху'**
  String get verifyHelpAddressNote;

  /// Подтверждение почты: четвёртое, что можно сделать. Отличается от подписи кнопки: здесь это совет, там действие.
  ///
  /// In ru, this message translates to:
  /// **'Отправьте код ещё раз'**
  String get verifyHelpResend;

  /// Подтверждение почты: пояснение к повторной отправке.
  ///
  /// In ru, this message translates to:
  /// **'кнопка над этим списком; чаще раза в минуту письма не уходят'**
  String get verifyHelpResendNote;

  /// Подтверждение почты: почта не работает на сервере.
  ///
  /// In ru, this message translates to:
  /// **'Письма сейчас не уходят'**
  String get verifyMailDownTitle;

  /// Подтверждение почты: главное про поломку почты — человек не виноват.
  ///
  /// In ru, this message translates to:
  /// **'дело не в вашем адресе: сервер не смог отправить письмо'**
  String get verifyMailDownNote;

  /// Подтверждение почты: что делать, пока почта не работает.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт уже создан — проходить регистрацию заново не нужно. Подождите несколько минут и отправьте код ещё раз: как только почта заработает, письмо придёт на тот же адрес.'**
  String get verifyMailDownWhatToDo;

  /// Заголовок экрана восстановления пароля, пока он не пройден.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get resetTitle;

  /// Заголовок экрана восстановления пароля на последнем шаге.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get resetDoneTitle;

  /// Восстановление пароля: кнопка первого шага.
  ///
  /// In ru, this message translates to:
  /// **'Прислать код'**
  String get resetSendCode;

  /// Восстановление пароля: кнопка второго шага.
  ///
  /// In ru, this message translates to:
  /// **'Сменить пароль'**
  String get resetChangePassword;

  /// Восстановление пароля: кнопка после смены пароля.
  ///
  /// In ru, this message translates to:
  /// **'К входу'**
  String get resetToLogin;

  /// Восстановление пароля: подпись первого шага.
  ///
  /// In ru, this message translates to:
  /// **'Куда прислать код'**
  String get resetStepWhere;

  /// Восстановление пароля: предупреждение о том, что форма не выдаёт чужие адреса.
  ///
  /// In ru, this message translates to:
  /// **'Ответ будет одинаковым'**
  String get resetSameAnswer;

  /// Восстановление пароля: пояснение к одинаковому ответу.
  ///
  /// In ru, this message translates to:
  /// **'и если адрес у нас есть, и если нет — так форма не выдаёт, кто у нас зарегистрирован'**
  String get resetSameAnswerNote;

  /// Восстановление пароля: свёрнутый первый шаг.
  ///
  /// In ru, this message translates to:
  /// **'Письмо отправлено'**
  String get resetStepSent;

  /// Восстановление пароля: подпись второго шага.
  ///
  /// In ru, this message translates to:
  /// **'Придумайте новый пароль'**
  String get resetStepNewPassword;

  /// Восстановление пароля: подпись поля кода.
  ///
  /// In ru, this message translates to:
  /// **'Код из письма'**
  String get resetFieldCode;

  /// Восстановление пароля: вопрос перед повторной отправкой. Речь о письме.
  ///
  /// In ru, this message translates to:
  /// **'Не пришло?'**
  String get resetNotArrived;

  /// Восстановление пароля: повторная отправка письма.
  ///
  /// In ru, this message translates to:
  /// **'Отправить заново'**
  String get resetResend;

  /// Восстановление пароля: повторная отправка, пока идёт отсчёт. {time} — остаток в виде м:сс.
  ///
  /// In ru, this message translates to:
  /// **'Отправить заново через {time}'**
  String resetResendIn(String time);

  /// Восстановление пароля: подпись поля нового пароля. Совпадает с заголовком экрана по-русски, но это разные строки.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get resetFieldNewPassword;

  /// Восстановление пароля: подсказка под полем нового пароля.
  ///
  /// In ru, this message translates to:
  /// **'Не короче {length} знаков'**
  String resetPasswordHelper(int length);

  /// Восстановление пароля: итог на последнем шаге.
  ///
  /// In ru, this message translates to:
  /// **'Пароль сменён'**
  String get resetDoneHeading;

  /// Восстановление пароля: что делать после смены пароля.
  ///
  /// In ru, this message translates to:
  /// **'Войдите с новым паролем'**
  String get resetDoneNote;

  /// Правило формы: адрес не введён.
  ///
  /// In ru, this message translates to:
  /// **'Введите почту'**
  String get ruleEmailEmpty;

  /// Правило формы: собаки нет или их больше одной.
  ///
  /// In ru, this message translates to:
  /// **'В адресе должна быть одна собака'**
  String get ruleEmailAtSign;

  /// Правило формы: домена после собаки нет. Пример подставлен местный — .ru по-русски, .com по-английски.
  ///
  /// In ru, this message translates to:
  /// **'После собаки должен быть домен: example.ru'**
  String get ruleEmailDomain;

  /// Правило формы: в адресе пробел.
  ///
  /// In ru, this message translates to:
  /// **'В адресе не бывает пробелов'**
  String get ruleEmailSpaces;

  /// Правило формы: пароль не введён.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль'**
  String get rulePasswordEmpty;

  /// Правило формы: пароль короче серверного порога.
  ///
  /// In ru, this message translates to:
  /// **'Не короче {length} символов'**
  String rulePasswordTooShort(int length);

  /// Правило формы: повтор пароля не введён.
  ///
  /// In ru, this message translates to:
  /// **'Повторите пароль'**
  String get ruleRepeatEmpty;

  /// Правило формы: пароль и его повтор разные.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get ruleRepeatMismatch;

  /// Правило формы: код не введён.
  ///
  /// In ru, this message translates to:
  /// **'Введите код из письма'**
  String get ruleCodeEmpty;

  /// Правило формы: в коде не шесть знаков.
  ///
  /// In ru, this message translates to:
  /// **'В коде шесть цифр'**
  String get ruleCodeLength;

  /// Правило формы: в коде есть не цифры.
  ///
  /// In ru, this message translates to:
  /// **'Код состоит только из цифр'**
  String get ruleCodeDigits;

  /// Первая вкладка внизу: полка своих пачек.
  ///
  /// In ru, this message translates to:
  /// **'Пачки'**
  String get tabPacks;

  /// Вторая вкладка внизу: история своих рецептов.
  ///
  /// In ru, this message translates to:
  /// **'Рецепты'**
  String get tabRecipes;

  /// Третья вкладка внизу: как добавить пачку — код, камера или без кода.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать'**
  String get tabScan;

  /// Четвёртая вкладка внизу: счёт накопленного, кофемолки, выход.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get tabProfile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
