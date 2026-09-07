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
