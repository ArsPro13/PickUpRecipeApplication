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

  @override
  String get remove => 'Убрать';

  @override
  String get packsTitle => 'Мои пачки';

  @override
  String get packsEmpty => 'Пачек пока нет';

  @override
  String get packsEmptyNote =>
      'Отсканируйте код с упаковки — рецепт обжарщика подтянется сам';

  @override
  String get packsScanCode => 'Сканировать код';

  @override
  String get packsAdd => 'Добавить пачку';

  @override
  String get packsChangeGrinder => 'Сменить кофемолку';

  @override
  String get packsFinished => 'допита';

  @override
  String get roastLight => 'светлая';

  @override
  String get roastMedium => 'средняя';

  @override
  String get roastDark => 'тёмная';

  @override
  String get ratingDraftTitle => 'Оценка не дописана';

  @override
  String get ratingDraftContinue => 'продолжить с того же места';

  @override
  String ratingDraftContinueWith(String summary) {
    return '$summary — продолжить';
  }

  @override
  String get recipesFailed => 'Рецепты не загрузились';

  @override
  String get recipesEmpty => 'Ещё ни одного заваривания';

  @override
  String get recipesEmptyNote =>
      'Заварите кофе по рецепту — он появится здесь вместе с оценкой';

  @override
  String get recipesToPacks => 'К пачкам';

  @override
  String recipesVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count версий',
      many: '$count версий',
      few: '$count версии',
      one: '$count версия',
    );
    return '$_temp0';
  }

  @override
  String get recipesNow => 'сейчас';

  @override
  String get recipesNowSwipe => 'сейчас · листается вбок';

  @override
  String recipesVersionOf(int number, int count) {
    return 'версия $number из $count';
  }

  @override
  String get recipesDraft => 'не сохранён';

  @override
  String get recipesCurrent => 'так завариваю';

  @override
  String get recipesPastVersion => 'прошлая версия';

  @override
  String get recipesBrewAgain => 'Заварить снова';

  @override
  String get recipesEditRecipe => 'Править рецепт';

  @override
  String get coffeeTitle => 'Кофе';

  @override
  String get coffeeNotFound => 'Такого кода нет';

  @override
  String get coffeeNotFoundNoCode => 'Такого кофе нет в системе.';

  @override
  String get coffeeNotFoundNote =>
      'Код набран без опечаток — контрольный символ сходится, — но в системе его нет. Возможно, обжарщик ещё не выложил эту партию.';

  @override
  String get coffeeScanAgain => 'Сканировать ещё раз';

  @override
  String get coffeeToPacks => 'К моим пачкам';

  @override
  String get coffeeRoasterPromises => 'Обжарщик обещает';

  @override
  String get coffeeWithdrawnTitle => 'Этой партии больше нет в продаже. ';

  @override
  String coffeeWithdrawnNote(String what) {
    return 'Обжарщик снял её$what — обычно это значит, что зерно кончилось. Рецепты остаются: заварить пачку, которая уже стоит у вас на полке, ничто не мешает.';
  }

  @override
  String get coffeeOfflineNoCache =>
      'Сети нет, и сохранённого рецепта в памяти тоже: заваривать пока не из чего.';

  @override
  String coffeeOfflineCached(String when) {
    return 'Сети нет. В памяти лежит рецепт, сохранённый $when, — заваривать по нему можно. Обновится сам, когда появится связь.';
  }

  @override
  String get coffeeOfflineCantTitle => 'Что сейчас нельзя';

  @override
  String get coffeeOfflineScan => 'Сканировать новую пачку';

  @override
  String get coffeeOfflineScanNote => 'код проверяется на сервере';

  @override
  String get coffeeOfflineRating => 'Отправить оценку';

  @override
  String get coffeeOfflineRatingNote => 'поставить можно, отправится позже';

  @override
  String get coffeeOfflineCorrection => 'Получить поправку';

  @override
  String get coffeeOfflineCorrectionNote => 'считает сервер, не телефон';

  @override
  String get coffeeBrewCached => 'Заварить по сохранённому';

  @override
  String coffeeLastBrewed(String date) {
    return 'так вы заваривали $date';
  }

  @override
  String coffeeBrewOn(String method) {
    return 'Заварить на $method';
  }

  @override
  String get coffeeMethodsFailed => 'Способы заваривания не загрузились';

  @override
  String get dateMonth1 => 'января';

  @override
  String get dateMonth2 => 'февраля';

  @override
  String get dateMonth3 => 'марта';

  @override
  String get dateMonth4 => 'апреля';

  @override
  String get dateMonth5 => 'мая';

  @override
  String get dateMonth6 => 'июня';

  @override
  String get dateMonth7 => 'июля';

  @override
  String get dateMonth8 => 'августа';

  @override
  String get dateMonth9 => 'сентября';

  @override
  String get dateMonth10 => 'октября';

  @override
  String get dateMonth11 => 'ноября';

  @override
  String get dateMonth12 => 'декабря';

  @override
  String dateDayMonth(String day, String month) {
    return '$day $month';
  }

  @override
  String dateDayMonthYear(String day, String month, String year) {
    return '$day $month $year';
  }

  @override
  String get rateTitle => 'Как получилось';

  @override
  String get rateOnTarget => 'Получилось как задумано';

  @override
  String rateSaid(String strength, String taste) {
    return '$strength $taste';
  }

  @override
  String get rateDegreeSlight => 'чуть';

  @override
  String get rateDegreeNoticeable => 'заметно';

  @override
  String get rateDegreeStrong => 'сильно';

  @override
  String get rateTasteSour => 'кисло';

  @override
  String get rateTasteBitter => 'горько';

  @override
  String get rateTasteStrong => 'крепко';

  @override
  String get rateTasteWeak => 'слабо';

  @override
  String rateMapSemantics(String summary) {
    return 'Карта вкуса. $summary';
  }

  @override
  String get rateOverall => 'Общее';

  @override
  String rateStarsOf(int stars) {
    return '$stars из 5';
  }

  @override
  String get rateOptional => 'Необязательно';

  @override
  String get rateAxesTitle => 'Разобрать по осям';

  @override
  String get rateAxesHint =>
      'Можно не трогать — уедет только то, что подвинете';

  @override
  String get rateAxisAroma => 'Аромат';

  @override
  String get rateAxisFlavor => 'Вкус';

  @override
  String get rateAxisAftertaste => 'Послевкусие';

  @override
  String get rateAxisAcidity => 'Кислотность';

  @override
  String get rateAxisBitterness => 'Горечь';

  @override
  String get rateAxisSweetness => 'Сладость';

  @override
  String rateAxesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оси',
      many: '$count осей',
      few: '$count оси',
      one: '$count ось',
    );
    return '$_temp0';
  }

  @override
  String get rateSave => 'Сохранить';

  @override
  String get rateFixRecipe => 'Поправить рецепт';

  @override
  String get rateJustSave => 'Просто сохранить отзыв';

  @override
  String get rateSavedOffline =>
      'Оценка сохранена и уедет, когда появится связь';

  @override
  String get rateSavedCorrectionLater =>
      'Оценка сохранена. Поправку посчитает сервер — она будет, когда появится связь';

  @override
  String get rateNothingToChange =>
      'Менять нечего: рецепт уже на границе своих значений';

  @override
  String get rateParamGrind => 'Помол';

  @override
  String get rateParamTemperature => 'Температура';

  @override
  String get rateParamRatio => 'Соотношение';

  @override
  String get rateParamAgitation => 'Размешивание';

  @override
  String get rateParamContactTime => 'Время контакта';

  @override
  String get rateParamDose => 'Доза';

  @override
  String get packFormTitle => 'Пачка без кода';

  @override
  String get packFormIntro =>
      'Впишите, что написано на пачке. Обязательна только страна — из неё и региона соберётся название.';

  @override
  String get packFormPhotoTitle => 'Сфотографируйте пачку';

  @override
  String get packFormPhotoNote =>
      'Снимок сохранится вместе с пачкой — по нему вы узнаете её в списке';

  @override
  String get packFormPhotoTake => 'Сфотографировать';

  @override
  String get packFormPhotoRetake => 'Переснять';

  @override
  String get packFormPhotoFromGallery => 'Из галереи';

  @override
  String get packFormPhotoFailed => 'Снимок не получился — попробуйте ещё раз';

  @override
  String get packFormCountry => 'Страна';

  @override
  String get packFormCountryHint => 'Бразилия';

  @override
  String get packFormCountryRequired => 'Без страны пачку нечем назвать';

  @override
  String get packFormRegion => 'Регион — если знаете';

  @override
  String get packFormRegionHint => 'Серрадо';

  @override
  String get packFormVariety => 'Сорт';

  @override
  String get packFormVarietyHint => 'бурбон';

  @override
  String get packFormScaScore => 'Оценка SCA';

  @override
  String get packFormRoastDate => 'Дата обжарки';

  @override
  String get packFormDateHint => 'дд.мм.гггг';

  @override
  String get packFormDateInvalid => 'Такой даты не бывает';

  @override
  String get packFormDateEmptyNote =>
      'Не знаете — оставьте пустым, поставим сегодняшнюю';

  @override
  String get packFormToday => 'Сегодня';

  @override
  String get packFormDescriptors => 'Дескрипторы';

  @override
  String get packFormDescriptorsNote =>
      'Чем пахнет и какой на вкус — по слову в строке';

  @override
  String packFormDescriptorNumbered(int number) {
    return 'Дескриптор $number';
  }

  @override
  String get packFormDescriptorHint => 'малина';

  @override
  String get packFormAddDescriptor => 'Добавить дескриптор';

  @override
  String get packFormProcessing => 'Способ обработки';

  @override
  String get packFormProcessingNote => 'Обычно написан на пачке рядом с сортом';

  @override
  String packFormProcessingNumbered(int number) {
    return 'Обработка $number';
  }

  @override
  String get packFormProcessingHint => 'мытая';

  @override
  String get packFormAddProcessing => 'Добавить обработку';

  @override
  String get packFormRemoveLine => 'Убрать строку';

  @override
  String get packFormSubmit => 'Отправить';

  @override
  String get packFormSubmitFailed => 'Пачка не отправилась';

  @override
  String packFormSubmitFailedNote(String reason) {
    return '$reason. Набранное осталось — попробуйте ещё раз.';
  }

  @override
  String get packFormShowPassword => 'Показать пароль';

  @override
  String get packFormHidePassword => 'Скрыть пароль';

  @override
  String get brewAbortTitle => 'Прервать заваривание?';

  @override
  String get brewAbortNote =>
      'Отсчёт остановится, и вернуться к нему на этой же секунде не выйдет.';

  @override
  String get brewAbort => 'Прервать';

  @override
  String get brewStay => 'Остаться';

  @override
  String get brewEditRecipe => 'Править рецепт';

  @override
  String brewStepOf(int number, int count) {
    return 'шаг $number из $count';
  }

  @override
  String get brewGrindAndStart => 'Смолол, начинаем';

  @override
  String get brewStart => 'Начать';

  @override
  String get brewPause => 'Пауза';

  @override
  String get brewResume => 'Продолжить';

  @override
  String get brewDidIt => 'Сделал';

  @override
  String get brewRate => 'Оценить';

  @override
  String get brewSkip => 'Пропустить';

  @override
  String get brewHappened => 'Случилось';

  @override
  String get brewTitle => 'Заваривание';

  @override
  String get brewNoSteps => 'В рецепте нет шагов';

  @override
  String get brewNoStepsNote =>
      'Проигрывать нечего. Соберите рецепт заново или выберите другой.';

  @override
  String get brewSteepingOver =>
      'Настаивание закончилось, пока приложение было закрыто. Доделайте оставшиеся шаги — дальше кофе только горчит.';

  @override
  String brewSteepingGoes(String away) {
    return 'Настаивание идёт: прошло $away. Экран можно закрывать — время считается по часам, а не по таймеру на экране.';
  }

  @override
  String get brewToRemainingSteps => 'К оставшимся шагам';

  @override
  String get brewCallItFinished => 'Считать законченным';

  @override
  String brewAwayTitle(String away) {
    return 'Прошло $away';
  }

  @override
  String brewStoppedAtStep(String step) {
    return 'Вы остановились на шаге «$step». Столько кофе уже не стоит на месте: вода остыла, воронка проливается.';
  }

  @override
  String get brewStartOver => 'Начать заново';

  @override
  String get brewStartOverNote =>
      'Обычно правильный выбор: 15 г кофе дешевле испорченной чашки';

  @override
  String get brewContinueFromHere => 'Продолжить с этого места';

  @override
  String get brewContinueFromHereNote =>
      'Если вы всё это время лили и просто выключили экран';

  @override
  String get brewCallItFinishedNote =>
      'Заварилось, но до оценки руки не дошли — оценим сейчас';

  @override
  String brewAwayHours(int hours) {
    return '$hours ч';
  }

  @override
  String brewAwayHoursMinutes(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String brewAwayMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes минут',
      many: '$minutes минут',
      few: '$minutes минуты',
      one: '$minutes минута',
    );
    return '$_temp0';
  }

  @override
  String brewAwaySeconds(int seconds) {
    return '$seconds с';
  }

  @override
  String get brewGrindCoffee => 'Смелите кофе';

  @override
  String get brewWaitingForYou => 'ждём вас';

  @override
  String brewReadyAt(String time) {
    return 'в $time';
  }

  @override
  String brewPouredOf(String poured, String total) {
    return 'налито $poured из $total г';
  }

  @override
  String brewTargetInCup(String grams) {
    return 'цель — $grams г в чашке';
  }

  @override
  String brewTargetInCupDone(String grams) {
    return 'готово · $grams г в чашке';
  }

  @override
  String brewTargetInCupFirstDrops(String grams) {
    return 'цель — $grams г в чашке · первые капли на 5–7 с';
  }

  @override
  String get brewTimeIsAGuide => 'время — ориентир, смотрите на признак';

  @override
  String brewTimeIsAGuideWithWater(String water) {
    return 'время — ориентир · $water';
  }

  @override
  String brewReadyIn(String time) {
    return 'готово через $time';
  }

  @override
  String get brewStepNotStarted => 'шаг ещё не начат';

  @override
  String get brewLeft => 'осталось';

  @override
  String get brewOnPause => 'на паузе';

  @override
  String get brewTapDidIt => 'нажмите «Сделал», когда закончите';

  @override
  String get brewFinished => 'готово';

  @override
  String get brewOptional => 'не обязательно';

  @override
  String get brewTipExpand => 'Показать подсказку целиком';

  @override
  String get brewTipCollapse => 'Свернуть подсказку';

  @override
  String get brewPhasePrep => 'подготовка';

  @override
  String get brewPhaseBrewing => 'заваривание';

  @override
  String get brewPhaseFinish => 'финал';

  @override
  String get brewEndsBySign => 'по признаку';

  @override
  String get brewEndsByTap => 'по кнопке';

  @override
  String get brewUntilYouSayDidIt => 'пока не скажете «сделал»';

  @override
  String get grinderTitle => 'Кофемолка';

  @override
  String get grinderSearchHint => 'Найти кофемолку';

  @override
  String get grinderKindManual => 'Ручные';

  @override
  String get grinderKindElectric => 'Электрические';

  @override
  String get grinderKindOther => 'Прочие';

  @override
  String get grinderMakePrimary => 'сделать основной';

  @override
  String get grinderSave => 'Сохранить';

  @override
  String get grinderNotFound => 'Такой кофемолки нет';

  @override
  String get grinderCatalogEmpty => 'Справочник пуст — проверьте связь';

  @override
  String grinderCatalogSize(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count модели',
      many: '$count моделей',
      few: '$count модели',
      one: '$count модель',
    );
    return 'Проверьте написание — в справочнике $_temp0';
  }

  @override
  String get grinderShowAll => 'Показать все';

  @override
  String get grinderDidYouMean => 'Вы имели в виду';

  @override
  String get grinderSaveFailed => 'Не удалось сохранить кофемолки';

  @override
  String get grinderSaveOffline =>
      'Без сети кофемолку не сохранить — она хранится в аккаунте';

  @override
  String grinderApproximately(String value) {
    return 'примерно $value';
  }

  @override
  String get grinderPickPrompt => 'выберите кофемолку';

  @override
  String get grinderPickPromptHint => 'выберите кофемолку — покажем деление';

  @override
  String grinderScaleOf(String name) {
    return 'делений $name';
  }

  @override
  String grinderClicks(String value) {
    return '$value щ.';
  }

  @override
  String get builderTitle => 'Ваш рецепт';

  @override
  String get builderParams => 'Параметры';

  @override
  String get builderDose => 'Доза';

  @override
  String get builderWater => 'Вода';

  @override
  String get builderTemperature => 'Температура';

  @override
  String get builderGrind => 'Помол';

  @override
  String get builderRatio => 'Соотношение';

  @override
  String get builderGram => 'г';

  @override
  String get builderMillilitre => 'мл';

  @override
  String get builderSteps => 'Шаги';

  @override
  String get builderDragHint => 'потяните за ручку';

  @override
  String get builderAddStep => 'Добавить шаг';

  @override
  String get builderStep => 'Шаг';

  @override
  String get builderStepName => 'Название';

  @override
  String get builderStepTip => 'Подсказка';

  @override
  String get builderChoose => 'выбрать';

  @override
  String get builderEndsLabel => 'Заканчивается';

  @override
  String get builderDuration => 'Длительность';

  @override
  String get builderNoTip => 'Подсказки нет';

  @override
  String builderTipValue(String tip) {
    return 'Подсказка · $tip';
  }

  @override
  String get builderRemoveStep => 'Убрать шаг';

  @override
  String get builderStepWater => 'Вода по шагам';

  @override
  String builderStepWaterValue(int done, int total) {
    return '$done из $total г';
  }

  @override
  String get builderTotalTime => 'Общее время';

  @override
  String get builderSave => 'Сохранить';

  @override
  String get builderBrew => 'Заварить';

  @override
  String get builderToHome => 'На главную';

  @override
  String get builderCancel => 'Отмена';

  @override
  String get builderDone => 'Готово';

  @override
  String get builderMinutesSeconds => 'минуты и секунды';

  @override
  String get builderDecrease => 'убавить';

  @override
  String get builderIncrease => 'прибавить';

  @override
  String builderCorrectedFor(String label) {
    return 'Поправлено под «$label»';
  }

  @override
  String get builderCorrectedNote => 'изменения помечены точкой';

  @override
  String get builderUndo => 'Отменить';

  @override
  String get builderLeaveTitle => 'Уйти без сохранения?';

  @override
  String get builderLeaveNote =>
      'Правки не сохранены — новая версия не появится.';

  @override
  String get builderLeave => 'Уйти';

  @override
  String get builderSavedOffline =>
      'Сохранено на телефоне — уедет, когда появится связь';

  @override
  String get builderSavedVersion => 'Сохранено новой версией';

  @override
  String builderSaveFailed(String error) {
    return 'Не сохранилось: $error';
  }

  @override
  String get builderEndsTimer => 'по времени';

  @override
  String get builderEndsUser => 'по кнопке';

  @override
  String get builderEndsSign => 'по признаку';

  @override
  String get builderEndsTimerHint => 'идёт по таймеру и кончается сам';

  @override
  String get builderEndsUserHint =>
      'заваривание ждёт, пока вы нажмёте «дальше»';

  @override
  String get builderEndsSignHint =>
      'та же кнопка, но жмёте её по признаку: пена осела, вода стекла';

  @override
  String get svcAuthBadFields => 'Проверьте почту и пароль';

  @override
  String get svcAuthWrongCredentials => 'Неверная почта или пароль';

  @override
  String get svcAuthEmailNotVerified => 'Почта не подтверждена';

  @override
  String get svcAuthUnknownEmail => 'Такой почты у нас нет';

  @override
  String get svcAuthEmailTaken => 'Эта почта уже занята';

  @override
  String get svcAuthTooOften => 'Слишком часто. Подождите минуту';

  @override
  String get svcAuthServerDown => 'Сервер не отвечает. Попробуйте ещё раз';

  @override
  String get svcAuthWrongCode => 'Код не подошёл. Проверьте письмо ещё раз';

  @override
  String get svcAuthNoTokens => 'Сервер ответил без токенов';

  @override
  String get svcAuthOffline => 'Нет связи. Проверьте интернет';

  @override
  String get svcAuthFailedLogin => 'Не удалось войти';

  @override
  String get svcAuthFailedSendLetter => 'Не удалось отправить письмо';

  @override
  String get svcAuthFailedChangePassword => 'Не удалось сменить пароль';

  @override
  String get svcAuthFailedRegister => 'Не удалось зарегистрироваться';

  @override
  String get svcAuthFailedVerifyEmail => 'Не удалось подтвердить почту';

  @override
  String svcSyncSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Отправлено, что ждало связи: $count',
      one: 'Отправлено то, что ждало связи',
    );
    return '$_temp0';
  }

  @override
  String svcSyncDropped(int count) {
    return 'Сервер не принял отложенное ($count) — оно устарело';
  }

  @override
  String svcSyncMixed(int sent, int dropped) {
    return 'Отправлено: $sent. Не принято сервером: $dropped';
  }

  @override
  String get svcLegalClose => 'Закрыть';

  @override
  String svcLegalUnavailable(String link) {
    return 'Документ сейчас недоступен. Он опубликован на сайте — откройте его там: $link';
  }

  @override
  String svcLegalVersion(String version) {
    return 'Редакция от $version';
  }

  @override
  String get svcLegalUserAgreement => 'Пользовательское соглашение';

  @override
  String get svcLegalPrivacy => 'Политика обработки данных';

  @override
  String get svcLegalConsent => 'Согласие на обработку данных';

  @override
  String get svcCodeEmpty => 'Введите код с упаковки';

  @override
  String svcCodeLength(int expected, int actual) {
    String _temp0 = intl.Intl.pluralLogic(
      expected,
      locale: localeName,
      other: 'В коде $expected символов, а введено $actual',
      many: 'В коде $expected символов, а введено $actual',
      few: 'В коде $expected символа, а введено $actual',
      one: 'В коде $expected символ, а введено $actual',
    );
    return '$_temp0';
  }

  @override
  String svcCodeUnknownSymbol(String symbol) {
    return 'Символа «$symbol» в кодах не бывает — проверьте, не 0 ли это вместо O';
  }

  @override
  String get svcCodeChecksum => 'Код набран с ошибкой — проверьте символы';
}
