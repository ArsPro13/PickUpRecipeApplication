// Тексты правил формы.
//
// Правила живут в домене и отвечают кодом: язык экрана домену неизвестен, а
// фраза у каждого языка своя. Перевод кода в текст — здесь, на границе с
// экраном, и это единственное место, где он делается: одно правило нарушают
// на трёх экранах, и объяснение у него должно быть одно.

import '../../l10n/app_localizations.dart';
import '../features/authentication/domain/auth_rules.dart';

extension EmailProblemText on EmailProblem {
  String text(AppLocalizations texts) => switch (this) {
        EmailProblem.empty => texts.ruleEmailEmpty,
        EmailProblem.atSign => texts.ruleEmailAtSign,
        EmailProblem.domain => texts.ruleEmailDomain,
        EmailProblem.spaces => texts.ruleEmailSpaces,
      };
}

extension PasswordProblemText on PasswordProblem {
  String text(AppLocalizations texts) => switch (this) {
        PasswordProblem.empty => texts.rulePasswordEmpty,
        PasswordProblem.tooShort => texts.rulePasswordTooShort(AuthRules.minPasswordLength),
      };
}

extension RepeatProblemText on RepeatProblem {
  String text(AppLocalizations texts) => switch (this) {
        RepeatProblem.empty => texts.ruleRepeatEmpty,
        RepeatProblem.mismatch => texts.ruleRepeatMismatch,
      };
}

extension CodeProblemText on CodeProblem {
  String text(AppLocalizations texts) => switch (this) {
        CodeProblem.empty => texts.ruleCodeEmpty,
        CodeProblem.length => texts.ruleCodeLength,
        CodeProblem.notDigits => texts.ruleCodeDigits,
      };
}

/// Текст ошибки сервера.
///
/// Слово сервера, если оно осмысленное, важнее нашего: «отправка писем не
/// настроена» объясняет человеку больше, чем «сервер не отвечает». Переводить
/// его нечем — это строка сервера, и она показывается как есть.
extension AuthFailureText on AuthFailure {
  String text(AppLocalizations texts) =>
      detail ??
      switch (reason) {
        AuthReason.badFields => texts.svcAuthBadFields,
        AuthReason.wrongCredentials => texts.svcAuthWrongCredentials,
        AuthReason.emailNotVerified => texts.svcAuthEmailNotVerified,
        AuthReason.unknownEmail => texts.svcAuthUnknownEmail,
        AuthReason.emailTaken => texts.svcAuthEmailTaken,
        AuthReason.tooOften => texts.svcAuthTooOften,
        AuthReason.serverDown => texts.svcAuthServerDown,
        AuthReason.wrongCode => texts.svcAuthWrongCode,
        AuthReason.noTokens => texts.svcAuthNoTokens,
        AuthReason.offline => texts.svcAuthOffline,
        AuthReason.actionFailed => action.failedText(texts),
      };
}

/// «Не удалось <действие>» — целой фразой на каждое действие.
///
/// Склейка «Не удалось» с глаголом держится только на русской грамматике:
/// в английском у каждого действия свой глагол со своим дополнением, и
/// собирать фразу из двух кусков там нечем.
extension AuthActionText on AuthAction {
  String failedText(AppLocalizations texts) => switch (this) {
        AuthAction.login => texts.svcAuthFailedLogin,
        AuthAction.sendLetter => texts.svcAuthFailedSendLetter,
        AuthAction.changePassword => texts.svcAuthFailedChangePassword,
        AuthAction.register => texts.svcAuthFailedRegister,
        AuthAction.verifyEmail => texts.svcAuthFailedVerifyEmail,
      };
}
