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

  @override
  String get retry => 'Try again';

  @override
  String get methodsTitle => 'What to brew with';

  @override
  String get methodsFailed => 'The list of methods did not open';

  @override
  String get conflictTitle => 'What to check';

  @override
  String get conflictBrewAgain => 'Brew it the same way again';

  @override
  String get conflictOpenBuilder => 'Open the builder anyway';

  @override
  String unitGrams(String value) {
    return '$value g';
  }

  @override
  String unitMillilitres(String value) {
    return '$value ml';
  }

  @override
  String get edit => 'Edit';

  @override
  String get recipesTitle => 'Recipes';

  @override
  String get chooseFailed => 'The recipes did not open';

  @override
  String get chooseNoBase => 'This method has no reference recipe';

  @override
  String chooseBaseFailed(String error) {
    return 'The recipe did not open: $error';
  }

  @override
  String get chooseRoaster => 'From the roaster';

  @override
  String get chooseRoasterNote => 'made for this coffee';

  @override
  String get chooseBase => 'Basic';

  @override
  String get chooseBaseNote => 'from the reference book';

  @override
  String get chooseMethodRecipe => 'The method\'s recipe';

  @override
  String get chooseMethodRecipeNote => 'does not account for the coffee';

  @override
  String get chooseMine => 'Your recipes';

  @override
  String get chooseMineNote => 'past versions';

  @override
  String chooseBrewWithTime(String time) {
    return 'Brew · $time';
  }

  @override
  String get stepTypeLabel => 'Step type';

  @override
  String get stepTypesFailed => 'The reference book did not arrive';

  @override
  String get stepTypesFailedNote =>
      'Without it there is no telling which steps this device can do.';

  @override
  String stepTypesCount(int shown, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      shown,
      locale: localeName,
      other: '$shown types',
      one: '$shown type',
    );
    return '$_temp0 of $total';
  }

  @override
  String stepTypesCountWithOwn(int shown, int total, int own) {
    String _temp0 = intl.Intl.pluralLogic(
      shown,
      locale: localeName,
      other: '$shown types',
      one: '$shown type',
    );
    String _temp1 = intl.Intl.pluralLogic(
      own,
      locale: localeName,
      other: '$own presets of your own',
      one: '$own preset of your own',
    );
    return '$_temp0 of $total and $_temp1';
  }

  @override
  String get stepTypesOwnGroup => 'Your types';

  @override
  String get stepTypesOwnGroupOnly => 'Your types · only for this device';

  @override
  String stepTypesStateful(String name) {
    return '$name · changes the state of the device';
  }

  @override
  String get stepTypeNew => 'new';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileStatsTitle => 'What you have gathered';

  @override
  String get profileCounting => 'Counting your packs and recipes…';

  @override
  String get profileNothingYet =>
      'Nothing to count yet. Scan a pack and brew a recipe — your numbers will show up here.';

  @override
  String profileRecipes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'recipes',
      one: 'recipe',
    );
    return '$_temp0';
  }

  @override
  String profileVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'versions',
      one: 'version',
    );
    return '$_temp0';
  }

  @override
  String profilePacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'packs',
      one: 'pack',
    );
    return '$_temp0';
  }

  @override
  String profileCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'countries',
      one: 'country',
    );
    return '$_temp0';
  }

  @override
  String profileVarieties(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'varieties',
      one: 'variety',
    );
    return '$_temp0';
  }

  @override
  String get profileFavourite => 'Most often';

  @override
  String profileFavouriteValue(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '$count recipe',
    );
    return '$name · $_temp0';
  }

  @override
  String get profileFirstRecipe => 'First recipe';

  @override
  String get profileGrindersTitle => 'My grinders';

  @override
  String get profileNoGrinder =>
      'No grinder selected. Without one a recipe shows grind size in words instead of the clicks of your grinder.';

  @override
  String get profileGrinderPrimary => 'primary';

  @override
  String get profileChooseGrinder => 'Choose a grinder';

  @override
  String get profileChangeGrinders => 'Change the set';

  @override
  String get profileAccountTitle => 'Account';

  @override
  String get profileLogout => 'Sign out';

  @override
  String get profileLogoutTitle => 'Sign out without sending?';

  @override
  String profileLogoutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items are',
      one: '$count item is',
    );
    return 'There was no connection, and $_temp0 waiting to be sent — ratings and recipe edits. Signing out will erase them along with the account.';
  }

  @override
  String get profileStay => 'Stay';

  @override
  String get clear => 'Clear';

  @override
  String get scanTitle => 'The code from the pack';

  @override
  String get scanOpenCamera => 'Open the camera';

  @override
  String get scanTapToAim => 'tap to aim';

  @override
  String get scanCodeIsSmall =>
      'The code is small — look for it in the corner of the pack';

  @override
  String get scanManualTitle => 'Enter the code by hand';

  @override
  String get scanOpenRecipe => 'Open the recipe';

  @override
  String get scanNoCode => 'There is no code on the pack';

  @override
  String get saving => 'Saving…';

  @override
  String get customStepTitle => 'A step type of your own';

  @override
  String customStepForMethod(String method) {
    return 'it will stay with you for $method';
  }

  @override
  String get customStepNoLabel =>
      'Without a name the step will not go into the list';

  @override
  String get customStepLabelField =>
      'Name · the way it will show up in the list';

  @override
  String get customStepLabelHint => 'Blow through with the plunger';

  @override
  String get customStepIcon => 'Icon · from the set, no pictures of your own';

  @override
  String get stepEndsWith => 'How the step ends';

  @override
  String get customStepThisDevice => 'this device';

  @override
  String customStepNote(String device) {
    return 'The step is tied to $device: it will not show up in recipes for other devices. A step like this does not count water — water has its own «pour».';
  }

  @override
  String get customStepSave => 'Save the type';

  @override
  String get remove => 'Remove';

  @override
  String get packsTitle => 'My packs';

  @override
  String get packsEmpty => 'No packs yet';

  @override
  String get packsEmptyNote =>
      'Scan the code on the packaging — the roaster\'s recipe will follow on its own';

  @override
  String get packsScanCode => 'Scan the code';

  @override
  String get packsAdd => 'Add a pack';

  @override
  String get packsChangeGrinder => 'Change the grinder';

  @override
  String get packsFinished => 'finished';

  @override
  String get roastLight => 'light';

  @override
  String get roastMedium => 'medium';

  @override
  String get roastDark => 'dark';

  @override
  String get ratingDraftTitle => 'The rating is unfinished';

  @override
  String get ratingDraftContinue => 'continue where you left off';

  @override
  String ratingDraftContinueWith(String summary) {
    return '$summary — continue';
  }

  @override
  String get recipesFailed => 'The recipes did not load';

  @override
  String get recipesEmpty => 'Not a single brew yet';

  @override
  String get recipesEmptyNote =>
      'Brew a coffee by a recipe — it will show up here along with your rating';

  @override
  String get recipesToPacks => 'To the packs';

  @override
  String recipesVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versions',
      one: '$count version',
    );
    return '$_temp0';
  }

  @override
  String get recipesNow => 'now';

  @override
  String get recipesNowSwipe => 'now · swipe sideways';

  @override
  String recipesVersionOf(int number, int count) {
    return 'version $number of $count';
  }

  @override
  String get recipesDraft => 'not saved';

  @override
  String get recipesCurrent => 'this is how I brew it';

  @override
  String get recipesPastVersion => 'an earlier version';

  @override
  String get recipesBrewAgain => 'Brew it again';

  @override
  String get recipesEditRecipe => 'Edit the recipe';

  @override
  String get coffeeTitle => 'Coffee';

  @override
  String get coffeeNotFound => 'There is no such code';

  @override
  String get coffeeNotFoundNoCode => 'There is no such coffee in the system.';

  @override
  String get coffeeNotFoundNote =>
      'The code has no typos — the check character matches — but it is not in the system. The roaster may not have published this batch yet.';

  @override
  String get coffeeScanAgain => 'Scan again';

  @override
  String get coffeeToPacks => 'To my packs';

  @override
  String get coffeeRoasterPromises => 'The roaster promises';

  @override
  String get coffeeWithdrawnTitle => 'This batch is no longer on sale. ';

  @override
  String coffeeWithdrawnNote(String what) {
    return 'The roaster has pulled it$what — usually that means the beans have run out. The recipes stay: nothing stops you brewing the pack already standing on your shelf.';
  }

  @override
  String get coffeeOfflineNoCache =>
      'There is no connection, and no saved recipe in memory either: there is nothing to brew by yet.';

  @override
  String coffeeOfflineCached(String when) {
    return 'There is no connection. Memory holds a recipe saved on $when — you can brew by it. It will refresh itself once the connection is back.';
  }

  @override
  String get coffeeOfflineCantTitle => 'What is not possible right now';

  @override
  String get coffeeOfflineScan => 'Scan a new pack';

  @override
  String get coffeeOfflineScanNote => 'the code is checked on the server';

  @override
  String get coffeeOfflineRating => 'Send a rating';

  @override
  String get coffeeOfflineRatingNote =>
      'you can give one, it will be sent later';

  @override
  String get coffeeOfflineCorrection => 'Get a correction';

  @override
  String get coffeeOfflineCorrectionNote =>
      'the server does the maths, not the phone';

  @override
  String get coffeeBrewCached => 'Brew by the saved one';

  @override
  String coffeeLastBrewed(String date) {
    return 'this is how you brewed it on $date';
  }

  @override
  String coffeeBrewOn(String method) {
    return 'Brew with $method';
  }

  @override
  String get coffeeMethodsFailed => 'The brewing methods did not load';

  @override
  String get dateMonth1 => 'January';

  @override
  String get dateMonth2 => 'February';

  @override
  String get dateMonth3 => 'March';

  @override
  String get dateMonth4 => 'April';

  @override
  String get dateMonth5 => 'May';

  @override
  String get dateMonth6 => 'June';

  @override
  String get dateMonth7 => 'July';

  @override
  String get dateMonth8 => 'August';

  @override
  String get dateMonth9 => 'September';

  @override
  String get dateMonth10 => 'October';

  @override
  String get dateMonth11 => 'November';

  @override
  String get dateMonth12 => 'December';

  @override
  String dateDayMonth(String day, String month) {
    return '$month $day';
  }

  @override
  String dateDayMonthYear(String day, String month, String year) {
    return '$month $day, $year';
  }
}
