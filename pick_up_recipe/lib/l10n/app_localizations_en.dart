// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get back => 'Back';

  @override
  String get noNetwork => 'No connection';

  @override
  String get offlineCached => 'No connection. Showing what was saved';

  @override
  String get offlineSyncing => 'Back online — sending what was saved';

  @override
  String offlinePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return 'No connection. $_temp0 will be sent once it is back';
  }

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get welcomeTagline =>
      'A recipe from the person who roasted this coffee';

  @override
  String get welcomeKeepsTitle => 'An account keeps';

  @override
  String get welcomeKeepsRecipes => 'Your recipes';

  @override
  String get welcomeKeepsRecipesNote => 'versions survive a change of phone';

  @override
  String get welcomeKeepsGrinder => 'Your grinder';

  @override
  String get welcomeKeepsGrinderNote =>
      'grind size is converted into your clicks';

  @override
  String get welcomeKeepsPacks => 'Your pack history';

  @override
  String get welcomeKeepsPacksNote => 'what you brewed six months ago, and how';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginForgot => 'Forgot your password?';

  @override
  String get loginNoAccount => 'No account yet?';

  @override
  String get loginCreate => 'Create one';

  @override
  String get registerRepeat => 'Again';

  @override
  String registerPasswordRule(int length) {
    return 'at least $length characters';
  }

  @override
  String get registerNextMail => 'Next: an email with a code';

  @override
  String get registerNextMailNote => 'six characters to confirm the address';

  @override
  String get registerHaveAccount => 'Already have an account?';

  @override
  String get registerConsentRequired =>
      'Without your consent we cannot create an account';

  @override
  String get registerTermsUnavailable =>
      'Could not load the terms. Check your connection and try again.';

  @override
  String get consentPrefix => 'I agree to the ';

  @override
  String get consentPrivacy => 'data processing policy';

  @override
  String get consentAnd => ' and the ';

  @override
  String get consentAgreement => 'user agreement';

  @override
  String get verifyTitle => 'Confirm your email';

  @override
  String get verifySubtitle => 'We sent a six-character code';

  @override
  String get verifyChangeEmail => 'Change the address';

  @override
  String get verifyConfirm => 'Confirm';

  @override
  String get verifyNotArrived => 'Did not arrive?';

  @override
  String get verifySending => 'Sending…';

  @override
  String get verifyResend => 'Send the code again';

  @override
  String verifyResendIn(String time) {
    return 'Again in $time';
  }

  @override
  String get verifySentAgain => 'We sent another email';

  @override
  String verifyTooOften(String time) {
    return 'An email has already gone out. The next one in $time';
  }

  @override
  String get verifyAddressRejected =>
      'The server did not accept this address. Check that it is the right one';

  @override
  String get verifyHelpTitle => 'If the email did not arrive';

  @override
  String get verifyHelpSpam => 'Check the spam folder';

  @override
  String get verifyHelpSpamNote =>
      'the sender is new, and your mail service does not know it yet';

  @override
  String get verifyHelpWait => 'Wait a minute';

  @override
  String get verifyHelpWaitNote =>
      'delivery is not instant, usually under a minute';

  @override
  String get verifyHelpAddress => 'Check the address';

  @override
  String get verifyHelpAddressNote =>
      'a typo in the address is the most common cause; you can fix it with the pencil above';

  @override
  String get verifyHelpResend => 'Send the code again';

  @override
  String get verifyHelpResendNote =>
      'the button above this list; emails go out no more than once a minute';

  @override
  String get verifyMailDownTitle => 'Emails are not going out right now';

  @override
  String get verifyMailDownNote =>
      'it is not your address: the server could not send the email';

  @override
  String get verifyMailDownWhatToDo =>
      'Your account is already created — there is no need to register again. Wait a few minutes and send the code again: as soon as mail is working, the email will arrive at the same address.';

  @override
  String get resetTitle => 'New password';

  @override
  String get resetDoneTitle => 'Done';

  @override
  String get resetSendCode => 'Send the code';

  @override
  String get resetChangePassword => 'Change password';

  @override
  String get resetToLogin => 'To sign-in';

  @override
  String get resetStepWhere => 'Where to send the code';

  @override
  String get resetSameAnswer => 'The answer will be the same';

  @override
  String get resetSameAnswerNote =>
      'whether or not we know the address — this way the form does not reveal who is registered';

  @override
  String get resetStepSent => 'Email sent';

  @override
  String get resetStepNewPassword => 'Come up with a new password';

  @override
  String get resetFieldCode => 'Code from the email';

  @override
  String get resetNotArrived => 'Did not arrive?';

  @override
  String get resetResend => 'Send again';

  @override
  String resetResendIn(String time) {
    return 'Send again in $time';
  }

  @override
  String get resetFieldNewPassword => 'New password';

  @override
  String resetPasswordHelper(int length) {
    return 'At least $length characters';
  }

  @override
  String get resetDoneHeading => 'Password changed';

  @override
  String get resetDoneNote => 'Sign in with the new password';

  @override
  String get ruleEmailEmpty => 'Enter your email';

  @override
  String get ruleEmailAtSign => 'The address must contain exactly one @';

  @override
  String get ruleEmailDomain =>
      'There must be a domain after the @: example.com';

  @override
  String get ruleEmailSpaces => 'An address cannot contain spaces';

  @override
  String get rulePasswordEmpty => 'Enter a password';

  @override
  String rulePasswordTooShort(int length) {
    return 'At least $length characters';
  }

  @override
  String get ruleRepeatEmpty => 'Repeat the password';

  @override
  String get ruleRepeatMismatch => 'The passwords do not match';

  @override
  String get ruleCodeEmpty => 'Enter the code from the email';

  @override
  String get ruleCodeLength => 'The code has six digits';

  @override
  String get ruleCodeDigits => 'The code is digits only';

  @override
  String get tabPacks => 'Packs';

  @override
  String get tabRecipes => 'Recipes';

  @override
  String get tabScan => 'Scan';

  @override
  String get tabProfile => 'Profile';
}
