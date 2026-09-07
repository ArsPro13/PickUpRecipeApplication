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

  @override
  String get authCreateAccount => 'Создать аккаунт';

  @override
  String get authSignIn => 'Войти';

  @override
  String get fieldEmail => 'Почта';

  @override
  String get fieldPassword => 'Пароль';

  @override
  String get welcomeTagline => 'Рецепт от того, кто жарил это зерно';

  @override
  String get welcomeKeepsTitle => 'Аккаунт хранит';

  @override
  String get welcomeKeepsRecipes => 'Ваши рецепты';

  @override
  String get welcomeKeepsRecipesNote => 'версии переживают смену телефона';

  @override
  String get welcomeKeepsGrinder => 'Кофемолку';

  @override
  String get welcomeKeepsGrinderNote => 'помол пересчитывается в ваши щелчки';

  @override
  String get welcomeKeepsPacks => 'Историю пачек';

  @override
  String get welcomeKeepsPacksNote => 'что и как заваривали полгода назад';

  @override
  String get loginTitle => 'Вход';

  @override
  String get loginForgot => 'Забыли пароль?';

  @override
  String get loginNoAccount => 'Нет аккаунта?';

  @override
  String get loginCreate => 'Создать';

  @override
  String get registerRepeat => 'Ещё раз';

  @override
  String registerPasswordRule(int length) {
    return 'не короче $length знаков';
  }

  @override
  String get registerNextMail => 'Дальше — письмо с кодом';

  @override
  String get registerNextMailNote => 'шесть знаков, чтобы подтвердить адрес';

  @override
  String get registerHaveAccount => 'Уже есть аккаунт?';

  @override
  String get registerConsentRequired =>
      'Без согласия зарегистрировать аккаунт нельзя';

  @override
  String get registerTermsUnavailable =>
      'Не удалось загрузить условия. Проверьте связь и попробуйте ещё раз.';

  @override
  String get consentPrefix => 'Соглашаюсь с ';

  @override
  String get consentPrivacy => 'политикой обработки данных';

  @override
  String get consentAnd => ' и ';

  @override
  String get consentAgreement => 'пользовательским соглашением';

  @override
  String get verifyTitle => 'Подтвердите почту';

  @override
  String get verifySubtitle => 'Отправили код из шести знаков';

  @override
  String get verifyChangeEmail => 'Изменить адрес';

  @override
  String get verifyConfirm => 'Подтвердить';

  @override
  String get verifyNotArrived => 'Не пришёл?';

  @override
  String get verifySending => 'Отправляем…';

  @override
  String get verifyResend => 'Отправить код ещё раз';

  @override
  String verifyResendIn(String time) {
    return 'Ещё раз через $time';
  }

  @override
  String get verifySentAgain => 'Отправили ещё одно письмо';

  @override
  String verifyTooOften(String time) {
    return 'Письмо уже уходило. Следующее — через $time';
  }

  @override
  String get verifyAddressRejected =>
      'Сервер не принял этот адрес. Проверьте, тот ли он';

  @override
  String get verifyHelpTitle => 'Если письмо не пришло';

  @override
  String get verifyHelpSpam => 'Загляните в «Спам»';

  @override
  String get verifyHelpSpamNote =>
      'отправитель новый, и почта его ещё не знает';

  @override
  String get verifyHelpWait => 'Подождите минуту';

  @override
  String get verifyHelpWaitNote =>
      'письмо идёт не мгновенно, обычно меньше минуты';

  @override
  String get verifyHelpAddress => 'Проверьте адрес';

  @override
  String get verifyHelpAddressNote =>
      'опечатка в почте — самая частая причина; исправить адрес можно карандашом наверху';

  @override
  String get verifyHelpResend => 'Отправьте код ещё раз';

  @override
  String get verifyHelpResendNote =>
      'кнопка над этим списком; чаще раза в минуту письма не уходят';

  @override
  String get verifyMailDownTitle => 'Письма сейчас не уходят';

  @override
  String get verifyMailDownNote =>
      'дело не в вашем адресе: сервер не смог отправить письмо';

  @override
  String get verifyMailDownWhatToDo =>
      'Аккаунт уже создан — проходить регистрацию заново не нужно. Подождите несколько минут и отправьте код ещё раз: как только почта заработает, письмо придёт на тот же адрес.';

  @override
  String get resetTitle => 'Новый пароль';

  @override
  String get resetDoneTitle => 'Готово';

  @override
  String get resetSendCode => 'Прислать код';

  @override
  String get resetChangePassword => 'Сменить пароль';

  @override
  String get resetToLogin => 'К входу';

  @override
  String get resetStepWhere => 'Куда прислать код';

  @override
  String get resetSameAnswer => 'Ответ будет одинаковым';

  @override
  String get resetSameAnswerNote =>
      'и если адрес у нас есть, и если нет — так форма не выдаёт, кто у нас зарегистрирован';

  @override
  String get resetStepSent => 'Письмо отправлено';

  @override
  String get resetStepNewPassword => 'Придумайте новый пароль';

  @override
  String get resetFieldCode => 'Код из письма';

  @override
  String get resetNotArrived => 'Не пришло?';

  @override
  String get resetResend => 'Отправить заново';

  @override
  String resetResendIn(String time) {
    return 'Отправить заново через $time';
  }

  @override
  String get resetFieldNewPassword => 'Новый пароль';

  @override
  String resetPasswordHelper(int length) {
    return 'Не короче $length знаков';
  }

  @override
  String get resetDoneHeading => 'Пароль сменён';

  @override
  String get resetDoneNote => 'Войдите с новым паролем';

  @override
  String get ruleEmailEmpty => 'Введите почту';

  @override
  String get ruleEmailAtSign => 'В адресе должна быть одна собака';

  @override
  String get ruleEmailDomain => 'После собаки должен быть домен: example.ru';

  @override
  String get ruleEmailSpaces => 'В адресе не бывает пробелов';

  @override
  String get rulePasswordEmpty => 'Введите пароль';

  @override
  String rulePasswordTooShort(int length) {
    return 'Не короче $length символов';
  }

  @override
  String get ruleRepeatEmpty => 'Повторите пароль';

  @override
  String get ruleRepeatMismatch => 'Пароли не совпадают';

  @override
  String get ruleCodeEmpty => 'Введите код из письма';

  @override
  String get ruleCodeLength => 'В коде шесть цифр';

  @override
  String get ruleCodeDigits => 'Код состоит только из цифр';

  @override
  String get tabPacks => 'Пачки';

  @override
  String get tabRecipes => 'Рецепты';

  @override
  String get tabScan => 'Сканировать';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get retry => 'Повторить';

  @override
  String get methodsTitle => 'Чем заварить';

  @override
  String get methodsFailed => 'Справочник методов не открылся';

  @override
  String get conflictTitle => 'Что проверить';

  @override
  String get conflictBrewAgain => 'Заварить так же ещё раз';

  @override
  String get conflictOpenBuilder => 'Всё равно открыть конструктор';

  @override
  String unitGrams(String value) {
    return '$value г';
  }

  @override
  String unitMillilitres(String value) {
    return '$value мл';
  }

  @override
  String get edit => 'Править';

  @override
  String get recipesTitle => 'Рецепты';

  @override
  String get chooseFailed => 'Рецепты не открылись';

  @override
  String get chooseNoBase => 'У этого метода нет справочного рецепта';

  @override
  String chooseBaseFailed(String error) {
    return 'Рецепт не открылся: $error';
  }

  @override
  String get chooseRoaster => 'От обжарщика';

  @override
  String get chooseRoasterNote => 'под это зерно';

  @override
  String get chooseBase => 'Базовый';

  @override
  String get chooseBaseNote => 'из справочника';

  @override
  String get chooseMethodRecipe => 'Рецепт метода';

  @override
  String get chooseMethodRecipeNote => 'зерно не учитывает';

  @override
  String get chooseMine => 'Ваши рецепты';

  @override
  String get chooseMineNote => 'прошлые версии';

  @override
  String chooseBrewWithTime(String time) {
    return 'Заварить · $time';
  }

  @override
  String get stepTypeLabel => 'Тип шага';

  @override
  String get stepTypesFailed => 'Справочник не пришёл';

  @override
  String get stepTypesFailedNote =>
      'Без него неизвестно, какие шаги умеет этот прибор.';

  @override
  String stepTypesCount(int shown, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      shown,
      locale: localeName,
      other: '$shown типов',
      many: '$shown типов',
      few: '$shown типа',
      one: '$shown тип',
    );
    return '$_temp0 из $total';
  }

  @override
  String stepTypesCountWithOwn(int shown, int total, int own) {
    String _temp0 = intl.Intl.pluralLogic(
      shown,
      locale: localeName,
      other: '$shown типов',
      many: '$shown типов',
      few: '$shown типа',
      one: '$shown тип',
    );
    String _temp1 = intl.Intl.pluralLogic(
      own,
      locale: localeName,
      other: '$own ваших',
      many: '$own ваших',
      few: '$own ваших',
      one: '$own ваша заготовка',
    );
    return '$_temp0 из $total и $_temp1';
  }

  @override
  String get stepTypesOwnGroup => 'Ваши типы';

  @override
  String get stepTypesOwnGroupOnly => 'Ваши типы · только для этого прибора';

  @override
  String stepTypesStateful(String name) {
    return '$name · меняет состояние прибора';
  }

  @override
  String get stepTypeNew => 'новый';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileStatsTitle => 'Что накопилось';

  @override
  String get profileCounting => 'Считаем ваши пачки и рецепты…';

  @override
  String get profileNothingYet =>
      'Пока считать нечего. Отсканируйте пачку и заварите по рецепту — здесь появятся ваши цифры.';

  @override
  String profileRecipes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'рецептов',
      many: 'рецептов',
      few: 'рецепта',
      one: 'рецепт',
    );
    return '$_temp0';
  }

  @override
  String profileVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'версий',
      many: 'версий',
      few: 'версии',
      one: 'версия',
    );
    return '$_temp0';
  }

  @override
  String profilePacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'пачек',
      many: 'пачек',
      few: 'пачки',
      one: 'пачка',
    );
    return '$_temp0';
  }

  @override
  String profileCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'стран',
      many: 'стран',
      few: 'страны',
      one: 'страна',
    );
    return '$_temp0';
  }

  @override
  String profileVarieties(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'сортов',
      many: 'сортов',
      few: 'сорта',
      one: 'сорт',
    );
    return '$_temp0';
  }

  @override
  String get profileFavourite => 'Чаще всего';

  @override
  String profileFavouriteValue(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count рецептов',
      many: '$count рецептов',
      few: '$count рецепта',
      one: '$count рецепт',
    );
    return '$name · $_temp0';
  }

  @override
  String get profileFirstRecipe => 'Первый рецепт';

  @override
  String get profileGrindersTitle => 'Мои кофемолки';

  @override
  String get profileNoGrinder =>
      'Кофемолка не выбрана. Без неё рецепт показывает крупность словами, а не щелчками вашей кофемолки.';

  @override
  String get profileGrinderPrimary => 'основная';

  @override
  String get profileChooseGrinder => 'Выбрать кофемолку';

  @override
  String get profileChangeGrinders => 'Изменить набор';

  @override
  String get profileAccountTitle => 'Аккаунт';

  @override
  String get profileLogout => 'Выйти';

  @override
  String get profileLogoutTitle => 'Выйти, не отправив?';

  @override
  String profileLogoutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дел ждут',
      many: '$count дел ждут',
      few: '$count дела ждут',
      one: '$count дело ждёт',
    );
    return 'Связи не было, и $_temp0 отправки — оценки и правки рецептов. Выход сотрёт их вместе с аккаунтом.';
  }

  @override
  String get profileStay => 'Остаться';

  @override
  String get clear => 'Очистить';

  @override
  String get scanTitle => 'Код с пачки';

  @override
  String get scanOpenCamera => 'Открыть камеру';

  @override
  String get scanTapToAim => 'нажмите, чтобы навести';

  @override
  String get scanCodeIsSmall => 'Код мелкий — ищите его в углу пачки';

  @override
  String get scanManualTitle => 'Ввести код руками';

  @override
  String get scanOpenRecipe => 'Открыть рецепт';

  @override
  String get scanNoCode => 'На пачке нет кода';

  @override
  String get saving => 'Сохраняем…';

  @override
  String get customStepTitle => 'Свой тип шага';

  @override
  String customStepForMethod(String method) {
    return 'останется у вас для метода $method';
  }

  @override
  String get customStepNoLabel => 'Без названия шаг не встанет в список';

  @override
  String get customStepLabelField => 'Название · как оно встанет в список';

  @override
  String get customStepLabelHint => 'Продуть поршнем';

  @override
  String get customStepIcon => 'Значок · из набора, свои картинки нельзя';

  @override
  String get stepEndsWith => 'Чем шаг заканчивается';

  @override
  String get customStepThisDevice => 'этому прибору';

  @override
  String customStepNote(String device) {
    return 'Шаг привязан к $device: в рецептах на других приборах он не появится. Воду такой шаг не считает — для воды есть «пролив».';
  }

  @override
  String get customStepSave => 'Сохранить тип';
}
