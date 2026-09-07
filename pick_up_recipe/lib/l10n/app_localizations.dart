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

  /// Кнопка на экране, который не открылся: повторить тот же запрос. Одна на все такие экраны — просьба одна и та же.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// Заголовок экрана выбора метода под конкретное зерно.
  ///
  /// In ru, this message translates to:
  /// **'Чем заварить'**
  String get methodsTitle;

  /// Выбор метода: справочник не пришёл с сервера, показывать нечего.
  ///
  /// In ru, this message translates to:
  /// **'Справочник методов не открылся'**
  String get methodsFailed;

  /// Заголовок экрана конфликта жалоб: цифры сейчас не ответ, ответ — про технику.
  ///
  /// In ru, this message translates to:
  /// **'Что проверить'**
  String get conflictTitle;

  /// Конфликт жалоб: главный выход — перезаварить, следя за техникой.
  ///
  /// In ru, this message translates to:
  /// **'Заварить так же ещё раз'**
  String get conflictBrewAgain;

  /// Конфликт жалоб: второй выход — всё-таки подвинуть цифры.
  ///
  /// In ru, this message translates to:
  /// **'Всё равно открыть конструктор'**
  String get conflictOpenBuilder;

  /// Число с граммами. Число уже посчитано и записано на месте вызова — здесь только единица и её место в строке.
  ///
  /// In ru, this message translates to:
  /// **'{value} г'**
  String unitGrams(String value);

  /// Число с миллилитрами. Как и граммы: число приходит готовым, строка ставит единицу.
  ///
  /// In ru, this message translates to:
  /// **'{value} мл'**
  String unitMillilitres(String value);

  /// Кнопка правки рецепта. Одна на все экраны, где рецепт можно подвинуть.
  ///
  /// In ru, this message translates to:
  /// **'Править'**
  String get edit;

  /// Заголовок экрана со списком рецептов. Отдельно от подписи вкладки: там ярлык, здесь название экрана.
  ///
  /// In ru, this message translates to:
  /// **'Рецепты'**
  String get recipesTitle;

  /// Выбор рецепта: список не пришёл с сервера.
  ///
  /// In ru, this message translates to:
  /// **'Рецепты не открылись'**
  String get chooseFailed;

  /// Выбор рецепта: базового рецепта у метода в базе не оказалось.
  ///
  /// In ru, this message translates to:
  /// **'У этого метода нет справочного рецепта'**
  String get chooseNoBase;

  /// Выбор рецепта: базовый рецепт запрашивали, но запрос не прошёл.
  ///
  /// In ru, this message translates to:
  /// **'Рецепт не открылся: {error}'**
  String chooseBaseFailed(String error);

  /// Выбор рецепта: заголовок первого раздела.
  ///
  /// In ru, this message translates to:
  /// **'От обжарщика'**
  String get chooseRoaster;

  /// Выбор рецепта: пояснение к разделу обжарщика.
  ///
  /// In ru, this message translates to:
  /// **'под это зерно'**
  String get chooseRoasterNote;

  /// Выбор рецепта: заголовок второго раздела.
  ///
  /// In ru, this message translates to:
  /// **'Базовый'**
  String get chooseBase;

  /// Выбор рецепта: пояснение к базовому разделу.
  ///
  /// In ru, this message translates to:
  /// **'из справочника'**
  String get chooseBaseNote;

  /// Выбор рецепта: строка, ведущая на заваривание по справочному рецепту.
  ///
  /// In ru, this message translates to:
  /// **'Рецепт метода'**
  String get chooseMethodRecipe;

  /// Выбор рецепта: чем справочный рецепт хуже рецепта обжарщика.
  ///
  /// In ru, this message translates to:
  /// **'зерно не учитывает'**
  String get chooseMethodRecipeNote;

  /// Выбор рецепта: заголовок третьего раздела.
  ///
  /// In ru, this message translates to:
  /// **'Ваши рецепты'**
  String get chooseMine;

  /// Выбор рецепта: пояснение к разделу своих рецептов.
  ///
  /// In ru, this message translates to:
  /// **'прошлые версии'**
  String get chooseMineNote;

  /// Выбор рецепта: кнопка заваривания с длительностью рецепта в виде м:сс.
  ///
  /// In ru, this message translates to:
  /// **'Заварить · {time}'**
  String chooseBrewWithTime(String time);

  /// Подпись «что выбираем» — в шапке листа выбора типа и в карточке шага конструктора.
  ///
  /// In ru, this message translates to:
  /// **'Тип шага'**
  String get stepTypeLabel;

  /// Лист выбора типа: справочник типов шагов не пришёл с сервера.
  ///
  /// In ru, this message translates to:
  /// **'Справочник не пришёл'**
  String get stepTypesFailed;

  /// Лист выбора типа: чем плохо отсутствие справочника.
  ///
  /// In ru, this message translates to:
  /// **'Без него неизвестно, какие шаги умеет этот прибор.'**
  String get stepTypesFailedNote;

  /// Лист выбора типа: сколько типов показано из всех, что есть в справочнике. Склонение «1 тип / 2 типа / 5 типов» считает ICU, а не рука: таблица форм у каждого языка своя.
  ///
  /// In ru, this message translates to:
  /// **'{shown, plural, one{{shown} тип} few{{shown} типа} many{{shown} типов} other{{shown} типов}} из {total}'**
  String stepTypesCount(int shown, int total);

  /// То же, но у прибора есть свои заготовки. Оба числа склоняет ICU: рука считала «21 ваших» и «2 типов».
  ///
  /// In ru, this message translates to:
  /// **'{shown, plural, one{{shown} тип} few{{shown} типа} many{{shown} типов} other{{shown} типов}} из {total} и {own, plural, one{{own} ваша заготовка} few{{own} ваших} many{{own} ваших} other{{own} ваших}}'**
  String stepTypesCountWithOwn(int shown, int total, int own);

  /// Лист выбора типа: заголовок группы своих заготовок, когда их ещё нет.
  ///
  /// In ru, this message translates to:
  /// **'Ваши типы'**
  String get stepTypesOwnGroup;

  /// Лист выбора типа: тот же заголовок, когда заготовки есть. Хвост объясняет, почему на другом приборе их не будет.
  ///
  /// In ru, this message translates to:
  /// **'Ваши типы · только для этого прибора'**
  String get stepTypesOwnGroupOnly;

  /// Лист выбора типа: подзаголовок у группы, чьи типы ставят строку состояния в шапку заваривания — иначе непонятно, чем «открыть клапан» отличается от ремарки.
  ///
  /// In ru, this message translates to:
  /// **'{name} · меняет состояние прибора'**
  String stepTypesStateful(String name);

  /// Лист выбора типа: клетка, открывающая форму своего шага. Не тип, а выход за справочник.
  ///
  /// In ru, this message translates to:
  /// **'новый'**
  String get stepTypeNew;

  /// Заголовок экрана профиля. Отдельно от подписи вкладки: там ярлык, здесь название экрана.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileTitle;

  /// Профиль: заголовок раздела со счётом накопленного.
  ///
  /// In ru, this message translates to:
  /// **'Что накопилось'**
  String get profileStatsTitle;

  /// Профиль: списки ещё не приехали и сохранённого тоже нет — первый запуск.
  ///
  /// In ru, this message translates to:
  /// **'Считаем ваши пачки и рецепты…'**
  String get profileCounting;

  /// Профиль: считать нечего — ни пачек, ни рецептов.
  ///
  /// In ru, this message translates to:
  /// **'Пока считать нечего. Отсканируйте пачку и заварите по рецепту — здесь появятся ваши цифры.'**
  String get profileNothingYet;

  /// Профиль: подпись под числом рецептов. Число стоит отдельной строкой крупным, здесь только слово в нужной форме — считает ICU, а не рука.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{рецепт} few{рецепта} many{рецептов} other{рецептов}}'**
  String profileRecipes(int count);

  /// Профиль: подпись под числом версий.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{версия} few{версии} many{версий} other{версий}}'**
  String profileVersions(int count);

  /// Профиль: подпись под числом пачек.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{пачка} few{пачки} many{пачек} other{пачек}}'**
  String profilePacks(int count);

  /// Профиль: подпись под числом стран на полке.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{страна} few{страны} many{стран} other{стран}}'**
  String profileCountries(int count);

  /// Профиль: подпись под числом сортов на полке.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{сорт} few{сорта} many{сортов} other{сортов}}'**
  String profileVarieties(int count);

  /// Профиль: строка про прибор, которым рецептов сделано больше всего.
  ///
  /// In ru, this message translates to:
  /// **'Чаще всего'**
  String get profileFavourite;

  /// Профиль: значение строки про любимый прибор — название и счёт рецептов под ним.
  ///
  /// In ru, this message translates to:
  /// **'{name} · {count, plural, one{{count} рецепт} few{{count} рецепта} many{{count} рецептов} other{{count} рецептов}}'**
  String profileFavouriteValue(String name, int count);

  /// Профиль: строка с датой самого раннего рецепта.
  ///
  /// In ru, this message translates to:
  /// **'Первый рецепт'**
  String get profileFirstRecipe;

  /// Профиль: заголовок раздела с кофемолками.
  ///
  /// In ru, this message translates to:
  /// **'Мои кофемолки'**
  String get profileGrindersTitle;

  /// Профиль: кофемолок не выбрано ни одной, и чем это плохо.
  ///
  /// In ru, this message translates to:
  /// **'Кофемолка не выбрана. Без неё рецепт показывает крупность словами, а не щелчками вашей кофемолки.'**
  String get profileNoGrinder;

  /// Профиль: метка у той кофемолки, в щелчках которой пересчитываются рецепты.
  ///
  /// In ru, this message translates to:
  /// **'основная'**
  String get profileGrinderPrimary;

  /// Профиль: кнопка под списком, когда кофемолок нет.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать кофемолку'**
  String get profileChooseGrinder;

  /// Профиль: та же кнопка, когда кофемолки уже выбраны.
  ///
  /// In ru, this message translates to:
  /// **'Изменить набор'**
  String get profileChangeGrinders;

  /// Профиль: заголовок раздела с выходом из аккаунта.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get profileAccountTitle;

  /// Профиль: выход из аккаунта. Одна строка на строку списка и на кнопку в вопросе перед выходом.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get profileLogout;

  /// Профиль: заголовок вопроса перед выходом, когда в очереди отправки что-то есть.
  ///
  /// In ru, this message translates to:
  /// **'Выйти, не отправив?'**
  String get profileLogoutTitle;

  /// Профиль: что человек потеряет, если выйдет с непустой очередью. Склонение считает ICU: рука знала два варианта и на двух делах говорила «2 дел ждут».
  ///
  /// In ru, this message translates to:
  /// **'Связи не было, и {count, plural, one{{count} дело ждёт} few{{count} дела ждут} many{{count} дел ждут} other{{count} дел ждут}} отправки — оценки и правки рецептов. Выход сотрёт их вместе с аккаунтом.'**
  String profileLogoutPending(int count);

  /// Профиль: отказ от выхода в вопросе перед выходом.
  ///
  /// In ru, this message translates to:
  /// **'Остаться'**
  String get profileStay;

  /// Крестик в поле ввода. Читается голосовым помощником и всплывающей подсказкой.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get clear;

  /// Заголовок экрана-вкладки, с которого начинается добавление пачки.
  ///
  /// In ru, this message translates to:
  /// **'Код с пачки'**
  String get scanTitle;

  /// Код с пачки: подпись кадра-подсказки для голосового помощника. Живой камеры в кадре нет, он открывает сканер по нажатию.
  ///
  /// In ru, this message translates to:
  /// **'Открыть камеру'**
  String get scanOpenCamera;

  /// Код с пачки: подпись в углу кадра-подсказки.
  ///
  /// In ru, this message translates to:
  /// **'нажмите, чтобы навести'**
  String get scanTapToAim;

  /// Код с пачки: где искать код на упаковке.
  ///
  /// In ru, this message translates to:
  /// **'Код мелкий — ищите его в углу пачки'**
  String get scanCodeIsSmall;

  /// Код с пачки: заголовок половины экрана с ручным вводом. Не запасной выход, а равноправный путь.
  ///
  /// In ru, this message translates to:
  /// **'Ввести код руками'**
  String get scanManualTitle;

  /// Код с пачки: кнопка под введённым кодом.
  ///
  /// In ru, this message translates to:
  /// **'Открыть рецепт'**
  String get scanOpenRecipe;

  /// Код с пачки: третий путь — распознать пачку по фотографии. Сейчас он самый частый, поэтому это кнопка, а не ссылка.
  ///
  /// In ru, this message translates to:
  /// **'На пачке нет кода'**
  String get scanNoCode;

  /// Кнопка сохранения, пока запрос в пути.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняем…'**
  String get saving;

  /// Заголовок экрана, где заводят свой тип шага.
  ///
  /// In ru, this message translates to:
  /// **'Свой тип шага'**
  String get customStepTitle;

  /// Свой тип шага: к какому прибору он привязан. Название метода приходит с сервера и не переводится.
  ///
  /// In ru, this message translates to:
  /// **'останется у вас для метода {method}'**
  String customStepForMethod(String method);

  /// Свой тип шага: подпись пустая, сохранять нечего.
  ///
  /// In ru, this message translates to:
  /// **'Без названия шаг не встанет в список'**
  String get customStepNoLabel;

  /// Свой тип шага: подпись поля названия.
  ///
  /// In ru, this message translates to:
  /// **'Название · как оно встанет в список'**
  String get customStepLabelField;

  /// Свой тип шага: пример названия в пустом поле.
  ///
  /// In ru, this message translates to:
  /// **'Продуть поршнем'**
  String get customStepLabelHint;

  /// Свой тип шага: подпись набора значков. Чужой файл не перекрасится под тему и не отмасштабируется в строке списка.
  ///
  /// In ru, this message translates to:
  /// **'Значок · из набора, свои картинки нельзя'**
  String get customStepIcon;

  /// Подпись выбора «таймер / кнопка / признак».
  ///
  /// In ru, this message translates to:
  /// **'Чем шаг заканчивается'**
  String get stepEndsWith;

  /// Свой тип шага: чем заменить название прибора в пояснении, когда его не передали.
  ///
  /// In ru, this message translates to:
  /// **'этому прибору'**
  String get customStepThisDevice;

  /// Свой тип шага: что человек получит и чего не получит. {device} — название метода или «этому прибору».
  ///
  /// In ru, this message translates to:
  /// **'Шаг привязан к {device}: в рецептах на других приборах он не появится. Воду такой шаг не считает — для воды есть «пролив».'**
  String customStepNote(String device);

  /// Свой тип шага: кнопка сохранения.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить тип'**
  String get customStepSave;

  /// Крестик, убирающий плашку с экрана. Читается голосовым помощником и всплывающей подсказкой.
  ///
  /// In ru, this message translates to:
  /// **'Убрать'**
  String get remove;

  /// Заголовок первой вкладки: полка пачек, с которой начинается приложение.
  ///
  /// In ru, this message translates to:
  /// **'Мои пачки'**
  String get packsTitle;

  /// Мои пачки: полка пуста.
  ///
  /// In ru, this message translates to:
  /// **'Пачек пока нет'**
  String get packsEmpty;

  /// Мои пачки: что сделать, чтобы полка перестала быть пустой.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте код с упаковки — рецепт обжарщика подтянется сам'**
  String get packsEmptyNote;

  /// Мои пачки: кнопка с пустой полки, уводящая на вкладку сканирования.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать код'**
  String get packsScanCode;

  /// Мои пачки: кнопка в конце списка.
  ///
  /// In ru, this message translates to:
  /// **'Добавить пачку'**
  String get packsAdd;

  /// Мои пачки: подпись кнопки кофемолки в шапке для голосового помощника.
  ///
  /// In ru, this message translates to:
  /// **'Сменить кофемолку'**
  String get packsChangeGrinder;

  /// Мои пачки: метка на карточке пачки, которая кончилась.
  ///
  /// In ru, this message translates to:
  /// **'допита'**
  String get packsFinished;

  /// Степень обжарки словом на месте фотографии пачки. Слово рядом с цветом: цвет сам по себе пришлось бы расшифровывать.
  ///
  /// In ru, this message translates to:
  /// **'светлая'**
  String get roastLight;

  /// Степень обжарки словом на месте фотографии пачки.
  ///
  /// In ru, this message translates to:
  /// **'средняя'**
  String get roastMedium;

  /// Степень обжарки словом на месте фотографии пачки.
  ///
  /// In ru, this message translates to:
  /// **'тёмная'**
  String get roastDark;

  /// Плашка на вкладке «Пачки»: у человека осталась недооценённая чашка.
  ///
  /// In ru, this message translates to:
  /// **'Оценка не дописана'**
  String get ratingDraftTitle;

  /// Плашка недописанной оценки: сказать про чашку человек ещё ничего не успел.
  ///
  /// In ru, this message translates to:
  /// **'продолжить с того же места'**
  String get ratingDraftContinue;

  /// Плашка недописанной оценки: что человек успел сказать. {summary} складывает домен и по-английски пока не говорит — отдельная задача.
  ///
  /// In ru, this message translates to:
  /// **'{summary} — продолжить'**
  String ratingDraftContinueWith(String summary);

  /// Вкладка «Рецепты»: список не пришёл с сервера. Отдельно от пустого списка: бодрый текст на месте сбоя врал бы.
  ///
  /// In ru, this message translates to:
  /// **'Рецепты не загрузились'**
  String get recipesFailed;

  /// Вкладка «Рецепты»: история пуста.
  ///
  /// In ru, this message translates to:
  /// **'Ещё ни одного заваривания'**
  String get recipesEmpty;

  /// Вкладка «Рецепты»: чем наполнить пустую историю.
  ///
  /// In ru, this message translates to:
  /// **'Заварите кофе по рецепту — он появится здесь вместе с оценкой'**
  String get recipesEmptyNote;

  /// Вкладка «Рецепты»: кнопка с пустого экрана на первую вкладку.
  ///
  /// In ru, this message translates to:
  /// **'К пачкам'**
  String get recipesToPacks;

  /// Вкладка «Рецепты»: сколько версий в стопке. Склонение считает ICU: рука знала русскую таблицу и говорила «2 версий».
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} версия} few{{count} версии} many{{count} версий} other{{count} версий}}'**
  String recipesVersionsCount(int count);

  /// Вкладка «Рецепты»: подпись верхней карточки стопки.
  ///
  /// In ru, this message translates to:
  /// **'сейчас'**
  String get recipesNow;

  /// То же, когда в системе выключены анимации: про жест рассказывала сама карточка, отходя вбок, и без движения о нём надо сказать словами.
  ///
  /// In ru, this message translates to:
  /// **'сейчас · листается вбок'**
  String get recipesNowSwipe;

  /// Вкладка «Рецепты»: какую по счёту версию стопки листает человек.
  ///
  /// In ru, this message translates to:
  /// **'версия {number} из {count}'**
  String recipesVersionOf(int number, int count);

  /// Вкладка «Рецепты»: версия ещё не уехала на сервер.
  ///
  /// In ru, this message translates to:
  /// **'не сохранён'**
  String get recipesDraft;

  /// Вкладка «Рецепты»: верхняя версия стопки — та, по которой человек заваривает сейчас.
  ///
  /// In ru, this message translates to:
  /// **'так завариваю'**
  String get recipesCurrent;

  /// Вкладка «Рецепты»: версия из глубины стопки.
  ///
  /// In ru, this message translates to:
  /// **'прошлая версия'**
  String get recipesPastVersion;

  /// Вкладка «Рецепты»: кружок на карточке версии, пускающий таймер сразу. Подпись для голосового помощника.
  ///
  /// In ru, this message translates to:
  /// **'Заварить снова'**
  String get recipesBrewAgain;
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
