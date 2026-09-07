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
}
