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

  /// Вкладка «Рецепты»: кружок на карточке версии, открывающий конструктор. Подпись для голосового помощника.
  ///
  /// In ru, this message translates to:
  /// **'Править рецепт'**
  String get recipesEditRecipe;

  /// Заголовок экрана кофе, когда название пачки ещё не приехало.
  ///
  /// In ru, this message translates to:
  /// **'Кофе'**
  String get coffeeTitle;

  /// Экран кофе: код набран верно, но такой пачки в системе нет.
  ///
  /// In ru, this message translates to:
  /// **'Такого кода нет'**
  String get coffeeNotFound;

  /// Экран кофе: сюда пришли не по коду, и проверять нечего.
  ///
  /// In ru, this message translates to:
  /// **'Такого кофе нет в системе.'**
  String get coffeeNotFoundNoCode;

  /// Экран кофе: почему верный код всё-таки не нашёлся.
  ///
  /// In ru, this message translates to:
  /// **'Код набран без опечаток — контрольный символ сходится, — но в системе его нет. Возможно, обжарщик ещё не выложил эту партию.'**
  String get coffeeNotFoundNote;

  /// Экран кофе: вернуться к вводу кода.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать ещё раз'**
  String get coffeeScanAgain;

  /// Экран кофе: уйти на полку пачек.
  ///
  /// In ru, this message translates to:
  /// **'К моим пачкам'**
  String get coffeeToPacks;

  /// Экран кофе: заголовок над дескрипторами вкуса. Обещает именно обжарщик, а не мы: у пачки, заведённой руками, дескрипторы вписал сам человек.
  ///
  /// In ru, this message translates to:
  /// **'Обжарщик обещает'**
  String get coffeeRoasterPromises;

  /// Экран кофе: начало жёлтой плашки, выделенное жирным. Пробел на конце обязателен — дальше без разрыва идёт остальной текст.
  ///
  /// In ru, this message translates to:
  /// **'Этой партии больше нет в продаже. '**
  String get coffeeWithdrawnTitle;

  /// Экран кофе: продолжение плашки. {what} — название и обжарщик в скобках или пусто, если их не передали.
  ///
  /// In ru, this message translates to:
  /// **'Обжарщик снял её{what} — обычно это значит, что зерно кончилось. Рецепты остаются: заварить пачку, которая уже стоит у вас на полке, ничто не мешает.'**
  String coffeeWithdrawnNote(String what);

  /// Экран кофе: сеть не ответила и запасного рецепта нет.
  ///
  /// In ru, this message translates to:
  /// **'Сети нет, и сохранённого рецепта в памяти тоже: заваривать пока не из чего.'**
  String get coffeeOfflineNoCache;

  /// Экран кофе: сети нет, но в памяти лежит рецепт. {when} — день сохранения; формат даты пока считается отдельно и по-русски.
  ///
  /// In ru, this message translates to:
  /// **'Сети нет. В памяти лежит рецепт, сохранённый {when}, — заваривать по нему можно. Обновится сам, когда появится связь.'**
  String coffeeOfflineCached(String when);

  /// Экран кофе: заголовок списка того, чего без сети не сделать.
  ///
  /// In ru, this message translates to:
  /// **'Что сейчас нельзя'**
  String get coffeeOfflineCantTitle;

  /// Экран кофе: первое, чего без сети нельзя.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать новую пачку'**
  String get coffeeOfflineScan;

  /// Экран кофе: почему без сети нельзя сканировать.
  ///
  /// In ru, this message translates to:
  /// **'код проверяется на сервере'**
  String get coffeeOfflineScanNote;

  /// Экран кофе: второе, чего без сети нельзя.
  ///
  /// In ru, this message translates to:
  /// **'Отправить оценку'**
  String get coffeeOfflineRating;

  /// Экран кофе: оценка не пропадёт, она уедет из очереди.
  ///
  /// In ru, this message translates to:
  /// **'поставить можно, отправится позже'**
  String get coffeeOfflineRatingNote;

  /// Экран кофе: третье, чего без сети нельзя.
  ///
  /// In ru, this message translates to:
  /// **'Получить поправку'**
  String get coffeeOfflineCorrection;

  /// Экран кофе: почему без сети нет поправки.
  ///
  /// In ru, this message translates to:
  /// **'считает сервер, не телефон'**
  String get coffeeOfflineCorrectionNote;

  /// Экран кофе: заварить по рецепту из памяти, пока сети нет.
  ///
  /// In ru, this message translates to:
  /// **'Заварить по сохранённому'**
  String get coffeeBrewCached;

  /// Экран кофе: подпись быстрого повтора. {date} пока складывается отдельно и по-русски — формат дат правится своей задачей.
  ///
  /// In ru, this message translates to:
  /// **'так вы заваривали {date}'**
  String coffeeLastBrewed(String date);

  /// Экран кофе: подпись кружка быстрого повтора для голосового помощника. Название метода приходит с сервера.
  ///
  /// In ru, this message translates to:
  /// **'Заварить на {method}'**
  String coffeeBrewOn(String method);

  /// Экран кофе: справочник методов не пришёл, выбирать не из чего.
  ///
  /// In ru, this message translates to:
  /// **'Способы заваривания не загрузились'**
  String get coffeeMethodsFailed;

  /// Название месяца в дате рецепта или пачки. По-русски родительный падеж («9 сентября»), по-английски именительный («September 9»).
  ///
  /// In ru, this message translates to:
  /// **'января'**
  String get dateMonth1;

  /// Название месяца в дате рецепта или пачки. По-русски родительный падеж («9 сентября»), по-английски именительный («September 9»).
  ///
  /// In ru, this message translates to:
  /// **'февраля'**
  String get dateMonth2;

  /// Название месяца в дате рецепта или пачки. По-русски родительный падеж («9 сентября»), по-английски именительный («September 9»).
  ///
  /// In ru, this message translates to:
  /// **'марта'**
  String get dateMonth3;

  /// Название месяца в дате рецепта или пачки. По-русски родительный падеж («9 сентября»), по-английски именительный («September 9»).
  ///
  /// In ru, this message translates to:
  /// **'апреля'**
  String get dateMonth4;

  /// Название месяца в дате рецепта или пачки. По-русски родительный падеж («9 сентября»), по-английски именительный («September 9»).
  ///
  /// In ru, this message translates to:
  /// **'мая'**
  String get dateMonth5;

  /// Название месяца в дате рецепта или пачки. По-русски родительный падеж («9 сентября»), по-английски именительный («September 9»).
  ///
  /// In ru, this message translates to:
  /// **'июня'**
  String get dateMonth6;

  /// Название месяца в дате рецепта или пачки. По-русски родительный падеж («9 сентября»), по-английски именительный («September 9»).
  ///
  /// In ru, this message translates to:
  /// **'июля'**
  String get dateMonth7;

  /// Название месяца в дате рецепта или пачки. По-русски родительный падеж («9 сентября»), по-английски именительный («September 9»).
  ///
  /// In ru, this message translates to:
  /// **'августа'**
  String get dateMonth8;

  /// Название месяца в дате рецепта или пачки. По-русски родительный падеж («9 сентября»), по-английски именительный («September 9»).
  ///
  /// In ru, this message translates to:
  /// **'сентября'**
  String get dateMonth9;

  /// Название месяца в дате рецепта или пачки. По-русски родительный падеж («9 сентября»), по-английски именительный («September 9»).
  ///
  /// In ru, this message translates to:
  /// **'октября'**
  String get dateMonth10;

  /// Название месяца в дате рецепта или пачки. По-русски родительный падеж («9 сентября»), по-английски именительный («September 9»).
  ///
  /// In ru, this message translates to:
  /// **'ноября'**
  String get dateMonth11;

  /// Название месяца в дате рецепта или пачки. По-русски родительный падеж («9 сентября»), по-английски именительный («September 9»).
  ///
  /// In ru, this message translates to:
  /// **'декабря'**
  String get dateMonth12;

  /// День и месяц без года. Порядок слов у языков разный, поэтому он живёт в переводе, а не в коде.
  ///
  /// In ru, this message translates to:
  /// **'{day} {month}'**
  String dateDayMonth(String day, String month);

  /// То же с годом: год добавляется, только когда он не нынешний.
  ///
  /// In ru, this message translates to:
  /// **'{day} {month} {year}'**
  String dateDayMonthYear(String day, String month, String year);

  /// Шапка экрана оценки чашки: спрашивает, что получилось в чашке.
  ///
  /// In ru, this message translates to:
  /// **'Как получилось'**
  String get rateTitle;

  /// Плашка под картой вкуса, когда точка стоит в центре: жалоб нет.
  ///
  /// In ru, this message translates to:
  /// **'Получилось как задумано'**
  String get rateOnTarget;

  /// Одна половина жалобы на карте вкуса: сила отклонения и его сторона — «чуть кисло». Порядок слов живёт в переводе, а не в коде: у языков он разный.
  ///
  /// In ru, this message translates to:
  /// **'{strength} {taste}'**
  String rateSaid(String strength, String taste);

  /// Первое кольцо карты вкуса: насколько сильно отклонение. Встаёт перед стороной отклонения — «чуть кисло».
  ///
  /// In ru, this message translates to:
  /// **'чуть'**
  String get rateDegreeSlight;

  /// Второе кольцо карты вкуса — «заметно горько».
  ///
  /// In ru, this message translates to:
  /// **'заметно'**
  String get rateDegreeNoticeable;

  /// Край карты вкуса — «сильно слабо».
  ///
  /// In ru, this message translates to:
  /// **'сильно'**
  String get rateDegreeStrong;

  /// Левый конец горизонтальной оси карты вкуса. Наречие, как и три соседних конца: круг задаёт один вопрос, и части речи на нём не смешиваются.
  ///
  /// In ru, this message translates to:
  /// **'кисло'**
  String get rateTasteSour;

  /// Правый конец горизонтальной оси карты вкуса — противоположность «кисло».
  ///
  /// In ru, this message translates to:
  /// **'горько'**
  String get rateTasteBitter;

  /// Верхний конец вертикальной оси карты вкуса: концентрация.
  ///
  /// In ru, this message translates to:
  /// **'крепко'**
  String get rateTasteStrong;

  /// Нижний конец вертикальной оси карты вкуса — противоположность «крепко».
  ///
  /// In ru, this message translates to:
  /// **'слабо'**
  String get rateTasteWeak;

  /// Подпись карты вкуса для голосового помощника: точку пальцем он не покажет, поэтому читает её словами.
  ///
  /// In ru, this message translates to:
  /// **'Карта вкуса. {summary}'**
  String rateMapSemantics(String summary);

  /// Подпись строки со звёздами: общее впечатление от чашки.
  ///
  /// In ru, this message translates to:
  /// **'Общее'**
  String get rateOverall;

  /// Сколько звёзд поставлено из пяти. Стоит подсказкой на звезде и в подписи недописанного черновика.
  ///
  /// In ru, this message translates to:
  /// **'{stars} из 5'**
  String rateStarsOf(int stars);

  /// Разделитель на экране оценки: всё, что нужно правилам поправки, осталось выше.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно'**
  String get rateOptional;

  /// Заголовок необязательной части экрана оценки: шесть ползунков по признакам.
  ///
  /// In ru, this message translates to:
  /// **'Разобрать по осям'**
  String get rateAxesTitle;

  /// Пояснение под заголовком «Разобрать по осям»: нетронутый ползунок не уезжает вовсе.
  ///
  /// In ru, this message translates to:
  /// **'Можно не трогать — уедет только то, что подвинете'**
  String get rateAxesHint;

  /// Ползунок развёрнутой оценки: аромат.
  ///
  /// In ru, this message translates to:
  /// **'Аромат'**
  String get rateAxisAroma;

  /// Ползунок развёрнутой оценки: вкус.
  ///
  /// In ru, this message translates to:
  /// **'Вкус'**
  String get rateAxisFlavor;

  /// Ползунок развёрнутой оценки: послевкусие.
  ///
  /// In ru, this message translates to:
  /// **'Послевкусие'**
  String get rateAxisAftertaste;

  /// Ползунок развёрнутой оценки: кислотность.
  ///
  /// In ru, this message translates to:
  /// **'Кислотность'**
  String get rateAxisAcidity;

  /// Ползунок развёрнутой оценки: горечь.
  ///
  /// In ru, this message translates to:
  /// **'Горечь'**
  String get rateAxisBitterness;

  /// Ползунок развёрнутой оценки: сладость.
  ///
  /// In ru, this message translates to:
  /// **'Сладость'**
  String get rateAxisSweetness;

  /// Сколько ползунков тронуто — в подписи недописанного черновика. Склонение делает ICU, а не рука: правило «1 ось / 2 оси / 5 осей» у каждого языка своё.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} ось} few{{count} оси} many{{count} осей} other{{count} оси}}'**
  String rateAxesCount(int count);

  /// Кнопка экрана оценки, когда жалоб нет: отправить оценку и уйти.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get rateSave;

  /// Главная кнопка экрана оценки, когда жалоба есть: отправить оценку и открыть рецепт с поправкой.
  ///
  /// In ru, this message translates to:
  /// **'Поправить рецепт'**
  String get rateFixRecipe;

  /// Вторая кнопка экрана оценки: оценку отправить, а рецепт не трогать.
  ///
  /// In ru, this message translates to:
  /// **'Просто сохранить отзыв'**
  String get rateJustSave;

  /// Сообщение после отправки оценки без сети: она встала в очередь.
  ///
  /// In ru, this message translates to:
  /// **'Оценка сохранена и уедет, когда появится связь'**
  String get rateSavedOffline;

  /// Сообщение, когда без сети попросили поправку: оценка в очереди, а поправку считает сервер, и повторять его правила на телефоне нечем.
  ///
  /// In ru, this message translates to:
  /// **'Оценка сохранена. Поправку посчитает сервер — она будет, когда появится связь'**
  String get rateSavedCorrectionLater;

  /// Сообщение, когда правила не нашли, что подвинуть: параметры рецепта упёрлись в свои пределы.
  ///
  /// In ru, this message translates to:
  /// **'Менять нечего: рецепт уже на границе своих значений'**
  String get rateNothingToChange;

  /// Название параметра в поправке рецепта: крупность помола.
  ///
  /// In ru, this message translates to:
  /// **'Помол'**
  String get rateParamGrind;

  /// Название параметра в поправке рецепта: температура воды.
  ///
  /// In ru, this message translates to:
  /// **'Температура'**
  String get rateParamTemperature;

  /// Название параметра в поправке рецепта: соотношение кофе и воды.
  ///
  /// In ru, this message translates to:
  /// **'Соотношение'**
  String get rateParamRatio;

  /// Название параметра в поправке рецепта: насколько сильно размешивают.
  ///
  /// In ru, this message translates to:
  /// **'Размешивание'**
  String get rateParamAgitation;

  /// Название параметра в поправке рецепта: сколько вода стоит на кофе.
  ///
  /// In ru, this message translates to:
  /// **'Время контакта'**
  String get rateParamContactTime;

  /// Название параметра в поправке рецепта: сколько кофе засыпают.
  ///
  /// In ru, this message translates to:
  /// **'Доза'**
  String get rateParamDose;

  /// Шапка экрана ручного добавления пачки — того, куда ведёт кнопка «На пачке нет кода».
  ///
  /// In ru, this message translates to:
  /// **'Пачка без кода'**
  String get packFormTitle;

  /// Пояснение первой строкой формы пачки: что заполнять и почему обязательна одна страна.
  ///
  /// In ru, this message translates to:
  /// **'Впишите, что написано на пачке. Обязательна только страна — из неё и региона соберётся название.'**
  String get packFormIntro;

  /// Подпись в пунктирной рамке над формой пачки: приглашение снять упаковку.
  ///
  /// In ru, this message translates to:
  /// **'Сфотографируйте пачку'**
  String get packFormPhotoTitle;

  /// Пояснение под приглашением снять пачку: зачем нужен кадр.
  ///
  /// In ru, this message translates to:
  /// **'Снимок сохранится вместе с пачкой — по нему вы узнаете её в списке'**
  String get packFormPhotoNote;

  /// Кнопка под рамкой снимка в форме пачки: открыть камеру, когда кадра ещё нет.
  ///
  /// In ru, this message translates to:
  /// **'Сфотографировать'**
  String get packFormPhotoTake;

  /// Та же кнопка камеры в форме пачки, когда снимок уже сделан.
  ///
  /// In ru, this message translates to:
  /// **'Переснять'**
  String get packFormPhotoRetake;

  /// Кнопка рядом с камерой в форме пачки: взять готовый снимок из галереи телефона.
  ///
  /// In ru, this message translates to:
  /// **'Из галереи'**
  String get packFormPhotoFromGallery;

  /// Ошибка под кнопками камеры в форме пачки: кадр не удалось получить.
  ///
  /// In ru, this message translates to:
  /// **'Снимок не получился — попробуйте ещё раз'**
  String get packFormPhotoFailed;

  /// Подпись поля страны в форме пачки. Единственное обязательное поле.
  ///
  /// In ru, this message translates to:
  /// **'Страна'**
  String get packFormCountry;

  /// Пример внутри пустого поля страны в форме пачки. Пример наш, а не значение из справочника.
  ///
  /// In ru, this message translates to:
  /// **'Бразилия'**
  String get packFormCountryHint;

  /// Ошибка под полем страны в форме пачки: имя пачки собирается из страны, и без неё его нет.
  ///
  /// In ru, this message translates to:
  /// **'Без страны пачку нечем назвать'**
  String get packFormCountryRequired;

  /// Подпись необязательного поля региона в форме пачки.
  ///
  /// In ru, this message translates to:
  /// **'Регион — если знаете'**
  String get packFormRegion;

  /// Пример внутри пустого поля региона в форме пачки.
  ///
  /// In ru, this message translates to:
  /// **'Серрадо'**
  String get packFormRegionHint;

  /// Подпись поля сорта зерна в форме пачки.
  ///
  /// In ru, this message translates to:
  /// **'Сорт'**
  String get packFormVariety;

  /// Пример внутри пустого поля сорта в форме пачки.
  ///
  /// In ru, this message translates to:
  /// **'бурбон'**
  String get packFormVarietyHint;

  /// Подпись поля оценки SCA в форме пачки. SCA — имя ассоциации, оно не переводится.
  ///
  /// In ru, this message translates to:
  /// **'Оценка SCA'**
  String get packFormScaScore;

  /// Подпись поля даты обжарки в форме пачки.
  ///
  /// In ru, this message translates to:
  /// **'Дата обжарки'**
  String get packFormRoastDate;

  /// Пример внутри пустого поля даты обжарки. Порядок частей и точки повторяют маску ввода дд.ММ.гггг: разбор даты завязан на неё, и другой порядок молча испортил бы дату.
  ///
  /// In ru, this message translates to:
  /// **'дд.мм.гггг'**
  String get packFormDateHint;

  /// Ошибка под полем даты обжарки: набранное не разбирается в дату или лежит в будущем.
  ///
  /// In ru, this message translates to:
  /// **'Такой даты не бывает'**
  String get packFormDateInvalid;

  /// Пояснение под полем даты обжарки: пустое поле не ошибка, сервер поставит сегодняшнее число.
  ///
  /// In ru, this message translates to:
  /// **'Не знаете — оставьте пустым, поставим сегодняшнюю'**
  String get packFormDateEmptyNote;

  /// Метка рядом с полем даты обжарки: поставить в поле сегодняшнее число одним касанием.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get packFormToday;

  /// Заголовок раздела формы пачки со списком вкусовых слов с упаковки.
  ///
  /// In ru, this message translates to:
  /// **'Дескрипторы'**
  String get packFormDescriptors;

  /// Пояснение под заголовком раздела дескрипторов в форме пачки.
  ///
  /// In ru, this message translates to:
  /// **'Чем пахнет и какой на вкус — по слову в строке'**
  String get packFormDescriptorsNote;

  /// Подпись строки списка дескрипторов в форме пачки: строки нумеруются с единицы.
  ///
  /// In ru, this message translates to:
  /// **'Дескриптор {number}'**
  String packFormDescriptorNumbered(int number);

  /// Пример внутри пустого поля дескриптора. Пример наш; сами дескрипторы человек списывает с пачки и мы их не переводим.
  ///
  /// In ru, this message translates to:
  /// **'малина'**
  String get packFormDescriptorHint;

  /// Кнопка под списком дескрипторов в форме пачки: ещё одна строка.
  ///
  /// In ru, this message translates to:
  /// **'Добавить дескриптор'**
  String get packFormAddDescriptor;

  /// Заголовок раздела формы пачки со списком способов обработки зерна.
  ///
  /// In ru, this message translates to:
  /// **'Способ обработки'**
  String get packFormProcessing;

  /// Пояснение под заголовком раздела обработки в форме пачки: где искать это слово.
  ///
  /// In ru, this message translates to:
  /// **'Обычно написан на пачке рядом с сортом'**
  String get packFormProcessingNote;

  /// Подпись строки списка способов обработки в форме пачки: строки нумеруются с единицы.
  ///
  /// In ru, this message translates to:
  /// **'Обработка {number}'**
  String packFormProcessingNumbered(int number);

  /// Пример внутри пустого поля способа обработки в форме пачки.
  ///
  /// In ru, this message translates to:
  /// **'мытая'**
  String get packFormProcessingHint;

  /// Кнопка под списком способов обработки в форме пачки: ещё одна строка.
  ///
  /// In ru, this message translates to:
  /// **'Добавить обработку'**
  String get packFormAddProcessing;

  /// Подсказка у корзины рядом с лишней строкой списка в форме пачки. Читается голосовым помощником и всплывающей подсказкой.
  ///
  /// In ru, this message translates to:
  /// **'Убрать строку'**
  String get packFormRemoveLine;

  /// Главная кнопка внизу формы пачки: завести пачку на сервере.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get packFormSubmit;

  /// Заголовок плашки внизу формы пачки: сервер или сеть не приняли пачку.
  ///
  /// In ru, this message translates to:
  /// **'Пачка не отправилась'**
  String get packFormSubmitFailed;

  /// Строка под заголовком той же плашки: причина от сервера и напоминание, что поля не очистились.
  ///
  /// In ru, this message translates to:
  /// **'{reason}. Набранное осталось — попробуйте ещё раз.'**
  String packFormSubmitFailedNote(String reason);

  /// Глаз справа в поле пароля, когда пароль спрятан. Читается голосовым помощником; поле общее для входа, регистрации и смены пароля.
  ///
  /// In ru, this message translates to:
  /// **'Показать пароль'**
  String get packFormShowPassword;

  /// Тот же глаз, когда пароль показан.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть пароль'**
  String get packFormHidePassword;

  /// Заваривание: вопрос при уходе с идущего заваривания — кнопкой телефона или стрелкой в шапке.
  ///
  /// In ru, this message translates to:
  /// **'Прервать заваривание?'**
  String get brewAbortTitle;

  /// Заваривание: чем кончится уход — пояснение под вопросом «Прервать заваривание?».
  ///
  /// In ru, this message translates to:
  /// **'Отсчёт остановится, и вернуться к нему на этой же секунде не выйдет.'**
  String get brewAbortNote;

  /// Заваривание: согласие уйти в вопросе перед уходом. Останавливает отсчёт.
  ///
  /// In ru, this message translates to:
  /// **'Прервать'**
  String get brewAbort;

  /// Заваривание: отказ уходить в вопросе перед уходом. Отсчёт остаётся идти.
  ///
  /// In ru, this message translates to:
  /// **'Остаться'**
  String get brewStay;

  /// Заваривание: подсказка карандаша в шапке. Отдельного экрана рецепта нет, правка живёт здесь.
  ///
  /// In ru, this message translates to:
  /// **'Править рецепт'**
  String get brewEditRecipe;

  /// Заваривание: какой шаг идёт сейчас, в строке параметров под шапкой.
  ///
  /// In ru, this message translates to:
  /// **'шаг {number} из {count}'**
  String brewStepOf(int number, int count);

  /// Заваривание: главная кнопка до старта, когда рамка над ней просит смолоть кофе.
  ///
  /// In ru, this message translates to:
  /// **'Смолол, начинаем'**
  String get brewGrindAndStart;

  /// Заваривание: главная кнопка до старта, когда молоть уже нечего — доза и помол неизвестны.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get brewStart;

  /// Заваривание: главная кнопка у идущего отсчёта.
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get brewPause;

  /// Заваривание: главная кнопка на паузе, она же возврат к брошенному завариванию.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get brewResume;

  /// Заваривание: главная кнопка на шаге, который ждёт человека, и вторая кнопка на шаге усилия руки.
  ///
  /// In ru, this message translates to:
  /// **'Сделал'**
  String get brewDidIt;

  /// Заваривание: главная кнопка после финала — уводит на оценку.
  ///
  /// In ru, this message translates to:
  /// **'Оценить'**
  String get brewRate;

  /// Заваривание: вторая кнопка на обычном шаге. Шаг не сделан, а выброшен.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get brewSkip;

  /// Заваривание: вторая кнопка на шаге с признаком окончания — признак видно и слышно.
  ///
  /// In ru, this message translates to:
  /// **'Случилось'**
  String get brewHappened;

  /// Заваривание: шапка экрана у рецепта без шагов, где название показывать не из чего.
  ///
  /// In ru, this message translates to:
  /// **'Заваривание'**
  String get brewTitle;

  /// Заваривание: рецепт без шагов — проигрывать нечего.
  ///
  /// In ru, this message translates to:
  /// **'В рецепте нет шагов'**
  String get brewNoSteps;

  /// Заваривание: что делать с рецептом без шагов.
  ///
  /// In ru, this message translates to:
  /// **'Проигрывать нечего. Соберите рецепт заново или выберите другой.'**
  String get brewNoStepsNote;

  /// Заваривание: вернулись к колд брю, который успел настояться без нас.
  ///
  /// In ru, this message translates to:
  /// **'Настаивание закончилось, пока приложение было закрыто. Доделайте оставшиеся шаги — дальше кофе только горчит.'**
  String get brewSteepingOver;

  /// Заваривание: вернулись к колд брю, который ещё настаивается.
  ///
  /// In ru, this message translates to:
  /// **'Настаивание идёт: прошло {away}. Экран можно закрывать — время считается по часам, а не по таймеру на экране.'**
  String brewSteepingGoes(String away);

  /// Заваривание: у настоявшегося колд брю остались шаги после настаивания.
  ///
  /// In ru, this message translates to:
  /// **'К оставшимся шагам'**
  String get brewToRemainingSteps;

  /// Заваривание: третий исход у брошенного заваривания — заварилось, просто до оценки руки не дошли.
  ///
  /// In ru, this message translates to:
  /// **'Считать законченным'**
  String get brewCallItFinished;

  /// Заваривание: сколько нас не было, заголовок экрана возврата к брошенному завариванию.
  ///
  /// In ru, this message translates to:
  /// **'Прошло {away}'**
  String brewAwayTitle(String away);

  /// Заваривание: на чём остановились и почему возвращаться поздно. Название шага приходит с сервера.
  ///
  /// In ru, this message translates to:
  /// **'Вы остановились на шаге «{step}». Столько кофе уже не стоит на месте: вода остыла, воронка проливается.'**
  String brewStoppedAtStep(String step);

  /// Заваривание: первый исход у брошенного заваривания.
  ///
  /// In ru, this message translates to:
  /// **'Начать заново'**
  String get brewStartOver;

  /// Заваривание: почему начать заново обычно правильно.
  ///
  /// In ru, this message translates to:
  /// **'Обычно правильный выбор: 15 г кофе дешевле испорченной чашки'**
  String get brewStartOverNote;

  /// Заваривание: второй исход у брошенного заваривания.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить с этого места'**
  String get brewContinueFromHere;

  /// Заваривание: когда продолжить с этого места всё-таки имеет смысл.
  ///
  /// In ru, this message translates to:
  /// **'Если вы всё это время лили и просто выключили экран'**
  String get brewContinueFromHereNote;

  /// Заваривание: когда брошенное заваривание считать законченным.
  ///
  /// In ru, this message translates to:
  /// **'Заварилось, но до оценки руки не дошли — оценим сейчас'**
  String get brewCallItFinishedNote;

  /// Заваривание: длительность в целых часах — сколько нас не было или сколько осталось.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч'**
  String brewAwayHours(int hours);

  /// Заваривание: длительность в часах с минутами.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч {minutes} мин'**
  String brewAwayHoursMinutes(int hours, int minutes);

  /// Заваривание: длительность в минутах.
  ///
  /// In ru, this message translates to:
  /// **'{minutes, plural, one{{minutes} минута} few{{minutes} минуты} many{{minutes} минут} other{{minutes} минут}}'**
  String brewAwayMinutes(int minutes);

  /// Заваривание: длительность меньше минуты.
  ///
  /// In ru, this message translates to:
  /// **'{seconds} с'**
  String brewAwaySeconds(int seconds);

  /// Заваривание: рамка до старта занята подготовкой, и это её заголовок.
  ///
  /// In ru, this message translates to:
  /// **'Смелите кофе'**
  String get brewGrindCoffee;

  /// Заваривание: центр рамки на шаге, который ждёт человека, а признака окончания у шага нет.
  ///
  /// In ru, this message translates to:
  /// **'ждём вас'**
  String get brewWaitingForYou;

  /// Заваривание: у шага длиннее получаса в центре рамки не отсчёт, а время готовности — его сверяют с будильником.
  ///
  /// In ru, this message translates to:
  /// **'в {time}'**
  String brewReadyAt(String time);

  /// Заваривание: сколько воды должно быть налито к этой секунде.
  ///
  /// In ru, this message translates to:
  /// **'налито {poured} из {total} г'**
  String brewPouredOf(String poured, String total);

  /// Заваривание: у эспрессо цель — вес напитка в чашке, а не налитая вода.
  ///
  /// In ru, this message translates to:
  /// **'цель — {grams} г в чашке'**
  String brewTargetInCup(String grams);

  /// Заваривание: та же цель эспрессо после финала.
  ///
  /// In ru, this message translates to:
  /// **'готово · {grams} г в чашке'**
  String brewTargetInCupDone(String grams);

  /// Заваривание: та же цель эспрессо во время пролива, с ориентиром по первым каплям.
  ///
  /// In ru, this message translates to:
  /// **'цель — {grams} г в чашке · первые капли на 5–7 с'**
  String brewTargetInCupFirstDrops(String grams);

  /// Заваривание: у шага с признаком окончания секундомер ничего не решает.
  ///
  /// In ru, this message translates to:
  /// **'время — ориентир, смотрите на признак'**
  String get brewTimeIsAGuide;

  /// Заваривание: то же, когда под таймером есть ещё и вода.
  ///
  /// In ru, this message translates to:
  /// **'время — ориентир · {water}'**
  String brewTimeIsAGuideWithWater(String water);

  /// Заваривание: под временем готовности длинного шага — через сколько это будет.
  ///
  /// In ru, this message translates to:
  /// **'готово через {time}'**
  String brewReadyIn(String time);

  /// Заваривание: подпись под таймером до старта.
  ///
  /// In ru, this message translates to:
  /// **'шаг ещё не начат'**
  String get brewStepNotStarted;

  /// Заваривание: подпись под таймером идущего шага.
  ///
  /// In ru, this message translates to:
  /// **'осталось'**
  String get brewLeft;

  /// Заваривание: подпись под таймером на паузе.
  ///
  /// In ru, this message translates to:
  /// **'на паузе'**
  String get brewOnPause;

  /// Заваривание: подпись под таймером шага, который ждёт человека. Слово в кавычках — надпись главной кнопки.
  ///
  /// In ru, this message translates to:
  /// **'нажмите «Сделал», когда закончите'**
  String get brewTapDidIt;

  /// Заваривание: подпись под таймером после финала.
  ///
  /// In ru, this message translates to:
  /// **'готово'**
  String get brewFinished;

  /// Заваривание: метка необязательного шага в списке шагов.
  ///
  /// In ru, this message translates to:
  /// **'не обязательно'**
  String get brewOptional;

  /// Заваривание: подсказка шага не влезла в строку — шеврон раскрывает её.
  ///
  /// In ru, this message translates to:
  /// **'Показать подсказку целиком'**
  String get brewTipExpand;

  /// Заваривание: тот же шеврон у раскрытой подсказки шага.
  ///
  /// In ru, this message translates to:
  /// **'Свернуть подсказку'**
  String get brewTipCollapse;

  /// Заваривание: заголовок первой фазы в списке шагов — смолоть, налить лёд.
  ///
  /// In ru, this message translates to:
  /// **'подготовка'**
  String get brewPhasePrep;

  /// Заваривание: заголовок средней фазы в списке шагов — проливы, помешивания, ожидание.
  ///
  /// In ru, this message translates to:
  /// **'заваривание'**
  String get brewPhaseBrewing;

  /// Заваривание: заголовок последней фазы в списке шагов — снять фильтр, разбавить, подать.
  ///
  /// In ru, this message translates to:
  /// **'финал'**
  String get brewPhaseFinish;

  /// Заваривание: на месте времени у шага, который кончается признаком, а не секундомером.
  ///
  /// In ru, this message translates to:
  /// **'по признаку'**
  String get brewEndsBySign;

  /// Заваривание: на месте времени у шага, который ждёт слова «сделал».
  ///
  /// In ru, this message translates to:
  /// **'по кнопке'**
  String get brewEndsByTap;

  /// Заваривание: метка на карточке шага, который ждёт человека. Слово в кавычках — надпись главной кнопки.
  ///
  /// In ru, this message translates to:
  /// **'пока не скажете «сделал»'**
  String get brewUntilYouSayDidIt;

  /// Заголовок экрана выбора кофемолки в шапке.
  ///
  /// In ru, this message translates to:
  /// **'Кофемолка'**
  String get grinderTitle;

  /// Подсказка в поле поиска по справочнику кофемолок.
  ///
  /// In ru, this message translates to:
  /// **'Найти кофемолку'**
  String get grinderSearchHint;

  /// Заголовок группы списка: кофемолки с ручкой. Вид приходит с сервера кодом manual, а слово для человека стоит здесь.
  ///
  /// In ru, this message translates to:
  /// **'Ручные'**
  String get grinderKindManual;

  /// Заголовок группы списка: кофемолки с мотором. Вид приходит с сервера кодом electric.
  ///
  /// In ru, this message translates to:
  /// **'Электрические'**
  String get grinderKindElectric;

  /// Заголовок группы списка для записей справочника без вида.
  ///
  /// In ru, this message translates to:
  /// **'Прочие'**
  String get grinderKindOther;

  /// Кнопка в строке выбранной кофемолки: отметить её основной. По основной пересчитывается помол в рецептах.
  ///
  /// In ru, this message translates to:
  /// **'сделать основной'**
  String get grinderMakePrimary;

  /// Кнопка внизу экрана кофемолки: применить набор и отметку основной.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get grinderSave;

  /// Заголовок пустого состояния поиска: по запросу не нашлось ничего.
  ///
  /// In ru, this message translates to:
  /// **'Такой кофемолки нет'**
  String get grinderNotFound;

  /// Пустое состояние, когда справочник кофемолок не приехал с сервера вовсе.
  ///
  /// In ru, this message translates to:
  /// **'Справочник пуст — проверьте связь'**
  String get grinderCatalogEmpty;

  /// Пустое состояние поиска: сколько всего моделей в справочнике. Число берётся из справочника, поэтому форма слова считается ICU, а не рукой.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте написание — в справочнике {count, plural, one{{count} модель} few{{count} модели} many{{count} моделей} other{{count} модели}}'**
  String grinderCatalogSize(int count);

  /// Кнопка пустого состояния: очистить запрос и показать справочник целиком.
  ///
  /// In ru, this message translates to:
  /// **'Показать все'**
  String get grinderShowAll;

  /// Подпись над подсказками с близкими по написанию именами в пустом состоянии поиска.
  ///
  /// In ru, this message translates to:
  /// **'Вы имели в виду'**
  String get grinderDidYouMean;

  /// Всплывающее сообщение: сеть есть, но сервер набор кофемолок не принял.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить кофемолки'**
  String get grinderSaveFailed;

  /// Всплывающее сообщение: сети нет, а набор кофемолок живёт на сервере и в очередь отправки не встаёт.
  ///
  /// In ru, this message translates to:
  /// **'Без сети кофемолку не сохранить — она хранится в аккаунте'**
  String get grinderSaveOffline;

  /// Помол, полученный пересчётом из крупности рецепта: шкалы кофемолок сходятся только по средней крупности, и число нельзя выдавать за точное.
  ///
  /// In ru, this message translates to:
  /// **'примерно {value}'**
  String grinderApproximately(String value);

  /// Короткая подпись под помолом в плитке показателей: кофемолка не выбрана, и помол показан словом.
  ///
  /// In ru, this message translates to:
  /// **'выберите кофемолку'**
  String get grinderPickPrompt;

  /// То же приглашение строкой на экране заваривания, где места больше.
  ///
  /// In ru, this message translates to:
  /// **'выберите кофемолку — покажем деление'**
  String get grinderPickPromptHint;

  /// Подпись под помолом: чьей кофемолки это деления. Имя кофемолки приходит из справочника и не переводится.
  ///
  /// In ru, this message translates to:
  /// **'делений {name}'**
  String grinderScaleOf(String name);

  /// Помол числом у старого рецепта, где шкала неизвестна: щелчки без имени кофемолки.
  ///
  /// In ru, this message translates to:
  /// **'{value} щ.'**
  String grinderClicks(String value);

  /// Конструктор рецепта: заголовок экрана.
  ///
  /// In ru, this message translates to:
  /// **'Ваш рецепт'**
  String get builderTitle;

  /// Конструктор: заголовок карточки с дозой, водой, температурой и помолом.
  ///
  /// In ru, this message translates to:
  /// **'Параметры'**
  String get builderParams;

  /// Конструктор: название параметра «доза кофе» и заголовок его окна правки.
  ///
  /// In ru, this message translates to:
  /// **'Доза'**
  String get builderDose;

  /// Конструктор: название параметра «вода» — и общей, и той, что льёт шаг.
  ///
  /// In ru, this message translates to:
  /// **'Вода'**
  String get builderWater;

  /// Конструктор: название параметра «температура воды» и заголовок его окна правки.
  ///
  /// In ru, this message translates to:
  /// **'Температура'**
  String get builderTemperature;

  /// Конструктор: название параметра «помол» и заголовок его окна правки.
  ///
  /// In ru, this message translates to:
  /// **'Помол'**
  String get builderGrind;

  /// Конструктор: название производного параметра «кофе к воде». Не правится.
  ///
  /// In ru, this message translates to:
  /// **'Соотношение'**
  String get builderRatio;

  /// Единица массы рядом с полем ввода и в счётчике воды. Только буква, без числа.
  ///
  /// In ru, this message translates to:
  /// **'г'**
  String get builderGram;

  /// Единица объёма рядом с полем ввода общей воды. Только буква, без числа.
  ///
  /// In ru, this message translates to:
  /// **'мл'**
  String get builderMillilitre;

  /// Конструктор: заголовок списка шагов.
  ///
  /// In ru, this message translates to:
  /// **'Шаги'**
  String get builderSteps;

  /// Конструктор: подсказка справа от заголовка «Шаги» — как переставить шаг.
  ///
  /// In ru, this message translates to:
  /// **'потяните за ручку'**
  String get builderDragHint;

  /// Конструктор: пунктирная кнопка под списком шагов.
  ///
  /// In ru, this message translates to:
  /// **'Добавить шаг'**
  String get builderAddStep;

  /// Конструктор: заголовок окна правки названия и подсказки, и подпись шага, у которого названия нет.
  ///
  /// In ru, this message translates to:
  /// **'Шаг'**
  String get builderStep;

  /// Конструктор: поле названия шага в окне правки.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get builderStepName;

  /// Конструктор: поле подсказки шага в окне правки.
  ///
  /// In ru, this message translates to:
  /// **'Подсказка'**
  String get builderStepTip;

  /// Конструктор: кнопка справа от «Тип шага» у шага, тип которого справочнику неизвестен.
  ///
  /// In ru, this message translates to:
  /// **'выбрать'**
  String get builderChoose;

  /// Конструктор: название строки у шага, который ждёт человека, — вместо длительности.
  ///
  /// In ru, this message translates to:
  /// **'Заканчивается'**
  String get builderEndsLabel;

  /// Длительность шага: название строки в конструкторе и заголовок шторки с барабаном.
  ///
  /// In ru, this message translates to:
  /// **'Длительность'**
  String get builderDuration;

  /// Конструктор: у шага не заполнена подсказка.
  ///
  /// In ru, this message translates to:
  /// **'Подсказки нет'**
  String get builderNoTip;

  /// Конструктор: подсказка шага под его величинами.
  ///
  /// In ru, this message translates to:
  /// **'Подсказка · {tip}'**
  String builderTipValue(String tip);

  /// Конструктор: всплывающая подсказка у корзины в раскрытом шаге. Читается и голосовым помощником.
  ///
  /// In ru, this message translates to:
  /// **'Убрать шаг'**
  String get builderRemoveStep;

  /// Конструктор: итог — сколько воды разлито по шагам.
  ///
  /// In ru, this message translates to:
  /// **'Вода по шагам'**
  String get builderStepWater;

  /// Конструктор: значение итога по воде — сумма по шагам против общей воды рецепта.
  ///
  /// In ru, this message translates to:
  /// **'{done} из {total} г'**
  String builderStepWaterValue(int done, int total);

  /// Конструктор: итог — сумма длительностей шагов.
  ///
  /// In ru, this message translates to:
  /// **'Общее время'**
  String get builderTotalTime;

  /// Конструктор: кнопка сохранения рецепта новой версией.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get builderSave;

  /// Конструктор: кнопка, которая уводит заваривать собранный рецепт.
  ///
  /// In ru, this message translates to:
  /// **'Заварить'**
  String get builderBrew;

  /// Конструктор: кнопка выхода к пачкам, появляется после сохранения.
  ///
  /// In ru, this message translates to:
  /// **'На главную'**
  String get builderToHome;

  /// Конструктор: отказ в окне правки значения. Ничего не меняет.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get builderCancel;

  /// Готово: подтверждение в окне правки значения и в шторке с барабаном длительности.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get builderDone;

  /// Шторка длительности: подпись справа от заголовка — что означают два барабана.
  ///
  /// In ru, this message translates to:
  /// **'минуты и секунды'**
  String get builderMinutesSeconds;

  /// Счётчик величины: кнопка «минус». Видит только голосовой помощник.
  ///
  /// In ru, this message translates to:
  /// **'убавить'**
  String get builderDecrease;

  /// Счётчик величины: кнопка «плюс». Видит только голосовой помощник.
  ///
  /// In ru, this message translates to:
  /// **'прибавить'**
  String get builderIncrease;

  /// Конструктор: строка сверху — под какую жалобу система поправила рецепт.
  ///
  /// In ru, this message translates to:
  /// **'Поправлено под «{label}»'**
  String builderCorrectedFor(String label);

  /// Конструктор: как найти поправленное — под строкой «Поправлено под …».
  ///
  /// In ru, this message translates to:
  /// **'изменения помечены точкой'**
  String get builderCorrectedNote;

  /// Конструктор: кнопка, возвращающая рецепт к тому, каким он был до поправки.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get builderUndo;

  /// Конструктор: заголовок вопроса при выходе с несохранёнными правками.
  ///
  /// In ru, this message translates to:
  /// **'Уйти без сохранения?'**
  String get builderLeaveTitle;

  /// Конструктор: что человек потеряет, если уйдёт сейчас.
  ///
  /// In ru, this message translates to:
  /// **'Правки не сохранены — новая версия не появится.'**
  String get builderLeaveNote;

  /// Конструктор: согласие уйти с экрана и потерять правки.
  ///
  /// In ru, this message translates to:
  /// **'Уйти'**
  String get builderLeave;

  /// Конструктор: рецепт сохранён без сети и ждёт отправки.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено на телефоне — уедет, когда появится связь'**
  String get builderSavedOffline;

  /// Конструктор: рецепт уехал на сервер и стал новой версией.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено новой версией'**
  String get builderSavedVersion;

  /// Конструктор: сохранить не удалось; {error} — ответ сервера как есть.
  ///
  /// In ru, this message translates to:
  /// **'Не сохранилось: {error}'**
  String builderSaveFailed(String error);

  /// Чем заканчивается шаг: сам, по таймеру. Подпись варианта в форме своего типа и в строке шага.
  ///
  /// In ru, this message translates to:
  /// **'по времени'**
  String get builderEndsTimer;

  /// Чем заканчивается шаг: нажатием человека. Подпись варианта в форме своего типа и в строке шага.
  ///
  /// In ru, this message translates to:
  /// **'по кнопке'**
  String get builderEndsUser;

  /// Чем заканчивается шаг: человек ждёт увиденного. Подпись варианта в форме своего типа и в строке шага.
  ///
  /// In ru, this message translates to:
  /// **'по признаку'**
  String get builderEndsSign;

  /// Пояснение к варианту «по времени»: кто кого ждёт.
  ///
  /// In ru, this message translates to:
  /// **'идёт по таймеру и кончается сам'**
  String get builderEndsTimerHint;

  /// Пояснение к варианту «по кнопке»: кто кого ждёт.
  ///
  /// In ru, this message translates to:
  /// **'заваривание ждёт, пока вы нажмёте «дальше»'**
  String get builderEndsUserHint;

  /// Пояснение к варианту «по признаку»: кнопка та же, что и в «по кнопке», но момент задаёт увиденное.
  ///
  /// In ru, this message translates to:
  /// **'та же кнопка, но жмёте её по признаку: пена осела, вода стекла'**
  String get builderEndsSignHint;

  /// Сервер ответил 400 и ничего не объяснил: подпись под формой входа, регистрации и смены пароля.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте почту и пароль'**
  String get svcAuthBadFields;

  /// Сервер ответил 401. Подпись под полем пароля на входе: ошибка про пару целиком, а не про одну почту.
  ///
  /// In ru, this message translates to:
  /// **'Неверная почта или пароль'**
  String get svcAuthWrongCredentials;

  /// Сервер ответил 403. Показывается там, где экран не увёл на ввод кода сам.
  ///
  /// In ru, this message translates to:
  /// **'Почта не подтверждена'**
  String get svcAuthEmailNotVerified;

  /// Сервер ответил 404: адрес не зарегистрирован. Подпись под полем почты.
  ///
  /// In ru, this message translates to:
  /// **'Такой почты у нас нет'**
  String get svcAuthUnknownEmail;

  /// Сервер ответил 409 на регистрацию: адрес уже занят. Подпись под полем почты.
  ///
  /// In ru, this message translates to:
  /// **'Эта почта уже занята'**
  String get svcAuthEmailTaken;

  /// Сервер ответил 429: ограничение частоты на почтовых ручках. Подпись под формой.
  ///
  /// In ru, this message translates to:
  /// **'Слишком часто. Подождите минуту'**
  String get svcAuthTooOften;

  /// Сервер ответил 5xx и ничего не объяснил. Подпись под формой входа и регистрации.
  ///
  /// In ru, this message translates to:
  /// **'Сервер не отвечает. Попробуйте ещё раз'**
  String get svcAuthServerDown;

  /// Код подтверждения из письма не принят. Подпись под полем кода на экране подтверждения почты.
  ///
  /// In ru, this message translates to:
  /// **'Код не подошёл. Проверьте письмо ещё раз'**
  String get svcAuthWrongCode;

  /// Вход прошёл, но токенов в ответе нет — сессии не будет. Подпись под формой входа.
  ///
  /// In ru, this message translates to:
  /// **'Сервер ответил без токенов'**
  String get svcAuthNoTokens;

  /// До сервера не дошли. Подпись под формой входа, регистрации, подтверждения почты и смены пароля.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи. Проверьте интернет'**
  String get svcAuthOffline;

  /// Сервер отказал так, что разобрать нечего, а человек входил. Фраза собрана целиком: склейка «Не удалось» с глаголом по-английски не работает.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти'**
  String get svcAuthFailedLogin;

  /// То же, когда человек просил письмо для сброса пароля.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить письмо'**
  String get svcAuthFailedSendLetter;

  /// То же, когда человек менял пароль по коду из письма.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сменить пароль'**
  String get svcAuthFailedChangePassword;

  /// То же, когда человек заводил аккаунт.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось зарегистрироваться'**
  String get svcAuthFailedRegister;

  /// То же, когда человек подтверждал почту кодом из письма.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подтвердить почту'**
  String get svcAuthFailedVerifyEmail;

  /// Всплывающая подсказка после досыла очереди: всё уехало. Одно дело называть числом незачем, поэтому у единицы своя ветка.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, =1{Отправлено то, что ждало связи} other{Отправлено, что ждало связи: {count}}}'**
  String svcSyncSent(int count);

  /// Всплывающая подсказка после досыла: не уехало ничего, сервер отверг всё насовсем.
  ///
  /// In ru, this message translates to:
  /// **'Сервер не принял отложенное ({count}) — оно устарело'**
  String svcSyncDropped(int count);

  /// Всплывающая подсказка после досыла: часть уехала, часть сервер отверг.
  ///
  /// In ru, this message translates to:
  /// **'Отправлено: {sent}. Не принято сервером: {dropped}'**
  String svcSyncMixed(int sent, int dropped);

  /// Всплывающая подсказка крестика в шапке листа с правовым документом.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get svcLegalClose;

  /// Лист правового документа: сервер документ не отдал. Прямо говорим об этом, потому что пустой лист читается как «согласия не требуется».
  ///
  /// In ru, this message translates to:
  /// **'Документ сейчас недоступен. Он опубликован на сайте — откройте его там: {link}'**
  String svcLegalUnavailable(String link);

  /// Подпись над текстом правового документа: дата редакции, с которой человек соглашается.
  ///
  /// In ru, this message translates to:
  /// **'Редакция от {version}'**
  String svcLegalVersion(String version);

  /// Заголовок листа с пользовательским соглашением.
  ///
  /// In ru, this message translates to:
  /// **'Пользовательское соглашение'**
  String get svcLegalUserAgreement;

  /// Заголовок листа с политикой обработки данных.
  ///
  /// In ru, this message translates to:
  /// **'Политика обработки данных'**
  String get svcLegalPrivacy;

  /// Заголовок листа с согласием на обработку данных.
  ///
  /// In ru, this message translates to:
  /// **'Согласие на обработку данных'**
  String get svcLegalConsent;

  /// Ошибка под полем ручного ввода кода: поле пустое.
  ///
  /// In ru, this message translates to:
  /// **'Введите код с упаковки'**
  String get svcCodeEmpty;

  /// Ошибка под полем ручного ввода кода: набрано не столько символов, сколько нужно. Склонение делает ICU, а не рука.
  ///
  /// In ru, this message translates to:
  /// **'{expected, plural, one{В коде {expected} символ, а введено {actual}} few{В коде {expected} символа, а введено {actual}} many{В коде {expected} символов, а введено {actual}} other{В коде {expected} символов, а введено {actual}}}'**
  String svcCodeLength(int expected, int actual);

  /// Ошибка под полем ручного ввода кода: символа нет в алфавите кодов. Ноль и буква O из алфавита исключены как раз потому, что путаются.
  ///
  /// In ru, this message translates to:
  /// **'Символа «{symbol}» в кодах не бывает — проверьте, не 0 ли это вместо O'**
  String svcCodeUnknownSymbol(String symbol);

  /// Ошибка под полем ручного ввода кода: контрольный символ не сошёлся, значит где-то опечатка.
  ///
  /// In ru, this message translates to:
  /// **'Код набран с ошибкой — проверьте символы'**
  String get svcCodeChecksum;

  /// Заголовок последней группы в справочниках приборов и типов шагов: сюда попадает всё, что справочник не отнёс ни к одной группе. Имени с сервера у неё нет — она собирается на телефоне.
  ///
  /// In ru, this message translates to:
  /// **'Прочие'**
  String get svcGroupOther;

  /// Пояснение под заголовком отказа на экранах, куда не доехал список с сервера: справочник приборов и вкладка рецептов. Раньше на этом месте стоял текст исключения — он всегда по-русски и человеку ничего не говорит.
  ///
  /// In ru, this message translates to:
  /// **'Обычно это связь. Проверьте интернет и попробуйте ещё раз.'**
  String get svcLoadFailedNote;
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
