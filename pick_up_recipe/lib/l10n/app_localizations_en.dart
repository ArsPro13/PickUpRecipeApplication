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
    return 'The step is tied to $device: it will not show up in recipes for other devices. A step like this does not count water — water has its own “pour”.';
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
  String get recipesEditRecipe => 'Edit recipe';

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

  @override
  String get rateTitle => 'How did it turn out';

  @override
  String get rateOnTarget => 'Turned out just as intended';

  @override
  String rateSaid(String strength, String taste) {
    return '$strength $taste';
  }

  @override
  String get rateDegreeSlight => 'slightly';

  @override
  String get rateDegreeNoticeable => 'noticeably';

  @override
  String get rateDegreeStrong => 'very';

  @override
  String get rateTasteSour => 'sour';

  @override
  String get rateTasteBitter => 'bitter';

  @override
  String get rateTasteStrong => 'strong';

  @override
  String get rateTasteWeak => 'weak';

  @override
  String rateMapSemantics(String summary) {
    return 'Taste map. $summary';
  }

  @override
  String get rateOverall => 'Overall';

  @override
  String rateStarsOf(int stars) {
    return '$stars of 5';
  }

  @override
  String get rateOptional => 'Optional';

  @override
  String get rateAxesTitle => 'Break it down by axis';

  @override
  String get rateAxesHint =>
      'You can leave these alone — only what you move gets sent';

  @override
  String get rateAxisAroma => 'Aroma';

  @override
  String get rateAxisFlavor => 'Flavor';

  @override
  String get rateAxisAftertaste => 'Aftertaste';

  @override
  String get rateAxisAcidity => 'Acidity';

  @override
  String get rateAxisBitterness => 'Bitterness';

  @override
  String get rateAxisSweetness => 'Sweetness';

  @override
  String rateAxesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count axes',
      one: '$count axis',
    );
    return '$_temp0';
  }

  @override
  String get rateSave => 'Save';

  @override
  String get rateFixRecipe => 'Adjust the recipe';

  @override
  String get rateJustSave => 'Just save the rating';

  @override
  String get rateSavedOffline =>
      'Rating saved — it will be sent once the connection is back';

  @override
  String get rateSavedCorrectionLater =>
      'Rating saved. The fix is worked out on the server — it will be there once the connection is back';

  @override
  String get rateNothingToChange =>
      'Nothing to change: the recipe is already at the edge of its range';

  @override
  String get rateParamGrind => 'Grind';

  @override
  String get rateParamTemperature => 'Temperature';

  @override
  String get rateParamRatio => 'Ratio';

  @override
  String get rateParamAgitation => 'Agitation';

  @override
  String get rateParamContactTime => 'Contact time';

  @override
  String get rateParamDose => 'Dose';

  @override
  String get packFormTitle => 'A pack without a code';

  @override
  String get packFormIntro =>
      'Type in what is printed on the pack. Only the country is required — the name is built from it and the region.';

  @override
  String get packFormPhotoTitle => 'Photograph the pack';

  @override
  String get packFormPhotoNote =>
      'The photo is kept with the pack — that is how you will recognize it in the list';

  @override
  String get packFormPhotoTake => 'Take a photo';

  @override
  String get packFormPhotoRetake => 'Retake';

  @override
  String get packFormPhotoFromGallery => 'From the gallery';

  @override
  String get packFormPhotoFailed => 'The photo did not work out — try again';

  @override
  String get packFormCountry => 'Country';

  @override
  String get packFormCountryHint => 'Brazil';

  @override
  String get packFormCountryRequired =>
      'Without a country there is nothing to name the pack after';

  @override
  String get packFormRegion => 'Region — if you know it';

  @override
  String get packFormRegionHint => 'Cerrado';

  @override
  String get packFormVariety => 'Variety';

  @override
  String get packFormVarietyHint => 'bourbon';

  @override
  String get packFormScaScore => 'SCA score';

  @override
  String get packFormRoastDate => 'Roast date';

  @override
  String get packFormDateHint => 'dd.mm.yyyy';

  @override
  String get packFormDateInvalid => 'There is no such date';

  @override
  String get packFormDateEmptyNote =>
      'Today\'s date is in — change it if the pack says otherwise';

  @override
  String get packFormPickDate => 'Pick in a calendar';

  @override
  String get packFormDescriptors => 'Descriptors';

  @override
  String get packFormDescriptorsNote =>
      'How it smells and tastes — one word per line';

  @override
  String packFormDescriptorNumbered(int number) {
    return 'Descriptor $number';
  }

  @override
  String get packFormDescriptorHint => 'raspberry';

  @override
  String get packFormAddDescriptor => 'Add a descriptor';

  @override
  String get packFormProcessing => 'Processing method';

  @override
  String get packFormProcessingNote =>
      'Usually printed on the pack next to the variety';

  @override
  String packFormProcessingNumbered(int number) {
    return 'Processing $number';
  }

  @override
  String get packFormProcessingHint => 'washed';

  @override
  String get packFormAddProcessing => 'Add a processing method';

  @override
  String get packFormRemoveLine => 'Remove the line';

  @override
  String get packFormSubmit => 'Send';

  @override
  String get packFormSubmitFailed => 'The pack was not sent';

  @override
  String packFormSubmitFailedNote(String reason) {
    return '$reason. What you typed is still here — try again.';
  }

  @override
  String get packFormShowPassword => 'Show the password';

  @override
  String get packFormHidePassword => 'Hide the password';

  @override
  String get brewAbortTitle => 'Stop brewing?';

  @override
  String get brewAbortNote =>
      'The timer stops, and you will not be able to pick it up at the same second.';

  @override
  String get brewAbort => 'Stop';

  @override
  String get brewStay => 'Stay';

  @override
  String get brewEditRecipe => 'Edit recipe';

  @override
  String brewStepOf(int number, int count) {
    return 'step $number of $count';
  }

  @override
  String get brewGrindAndStart => 'Ground it, let\'s go';

  @override
  String get brewStart => 'Start';

  @override
  String get brewPause => 'Pause';

  @override
  String get brewResume => 'Continue';

  @override
  String get brewDidIt => 'Did it';

  @override
  String get brewRate => 'Rate it';

  @override
  String get brewSkip => 'Skip';

  @override
  String get brewHappened => 'It happened';

  @override
  String get brewTitle => 'Brewing';

  @override
  String get brewNoSteps => 'This recipe has no steps';

  @override
  String get brewNoStepsNote =>
      'Nothing to play. Build the recipe again or pick another one.';

  @override
  String get brewSteepingOver =>
      'The steeping finished while the app was closed. Do the remaining steps — from here the coffee only turns bitter.';

  @override
  String brewSteepingGoes(String away) {
    return 'Steeping is under way: $away so far. You can close the screen — the time is counted by the clock, not by the timer on the screen.';
  }

  @override
  String get brewToRemainingSteps => 'To the remaining steps';

  @override
  String get brewCallItFinished => 'Call it finished';

  @override
  String brewAwayTitle(String away) {
    return 'It has been $away';
  }

  @override
  String brewStoppedAtStep(String step) {
    return 'You stopped at “$step”. Coffee does not wait that long: the water has cooled and the cone has drained.';
  }

  @override
  String get brewStartOver => 'Start over';

  @override
  String get brewStartOverNote =>
      'Usually the right call: 15 g of coffee costs less than a ruined cup';

  @override
  String get brewContinueFromHere => 'Continue from here';

  @override
  String get brewContinueFromHereNote =>
      'If you were pouring all this time and just switched the screen off';

  @override
  String get brewCallItFinishedNote =>
      'It brewed, you just never got to the rating — let\'s do it now';

  @override
  String brewAwayHours(int hours) {
    return '$hours h';
  }

  @override
  String brewAwayHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String brewAwayMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '$minutes minute',
    );
    return '$_temp0';
  }

  @override
  String brewAwaySeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get brewGrindCoffee => 'Grind the coffee';

  @override
  String get brewWaitingForYou => 'waiting for you';

  @override
  String brewReadyAt(String time) {
    return 'at $time';
  }

  @override
  String brewPouredOf(String poured, String total) {
    return '$poured of $total g poured';
  }

  @override
  String brewTargetInCup(String grams) {
    return 'target — $grams g in the cup';
  }

  @override
  String brewTargetInCupDone(String grams) {
    return 'done · $grams g in the cup';
  }

  @override
  String brewTargetInCupFirstDrops(String grams) {
    return 'target — $grams g in the cup · first drops at 5–7 s';
  }

  @override
  String get brewTimeIsAGuide => 'the time is a guide, watch for the sign';

  @override
  String brewTimeIsAGuideWithWater(String water) {
    return 'the time is a guide · $water';
  }

  @override
  String brewReadyIn(String time) {
    return 'ready in $time';
  }

  @override
  String get brewStepNotStarted => 'not started yet';

  @override
  String get brewLeft => 'left';

  @override
  String get brewOnPause => 'paused';

  @override
  String get brewTapDidIt => 'tap “Did it” when you finish';

  @override
  String get brewFinished => 'done';

  @override
  String get brewOptional => 'optional';

  @override
  String get brewTipExpand => 'Show the whole tip';

  @override
  String get brewTipCollapse => 'Collapse the tip';

  @override
  String get brewPhasePrep => 'preparation';

  @override
  String get brewPhaseBrewing => 'brewing';

  @override
  String get brewPhaseFinish => 'finish';

  @override
  String get brewEndsBySign => 'by a cue';

  @override
  String get brewEndsByTap => 'by button';

  @override
  String get brewUntilYouSayDidIt => 'until you say “did it”';

  @override
  String get grinderTitle => 'Grinder';

  @override
  String get grinderSearchHint => 'Find a grinder';

  @override
  String get grinderKindManual => 'Hand grinders';

  @override
  String get grinderKindElectric => 'Electric grinders';

  @override
  String get grinderKindOther => 'Other';

  @override
  String get grinderMakePrimary => 'make primary';

  @override
  String get grinderSave => 'Save';

  @override
  String get grinderNotFound => 'No such grinder';

  @override
  String get grinderCatalogEmpty =>
      'The catalog is empty — check the connection';

  @override
  String grinderCatalogSize(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count models',
      one: '$count model',
    );
    return 'Check the spelling — the catalog holds $_temp0';
  }

  @override
  String get grinderShowAll => 'Show all';

  @override
  String get grinderDidYouMean => 'Did you mean';

  @override
  String get grinderSaveFailed => 'Could not save the grinders';

  @override
  String get grinderSaveOffline =>
      'A grinder cannot be saved without a connection — it lives in your account';

  @override
  String grinderApproximately(String value) {
    return 'about $value';
  }

  @override
  String get grinderPickPrompt => 'pick a grinder';

  @override
  String get grinderPickPromptHint =>
      'pick a grinder and we will show the setting';

  @override
  String grinderScaleOf(String name) {
    return '$name scale';
  }

  @override
  String grinderClicks(String value) {
    return '$value clicks';
  }

  @override
  String get builderTitle => 'Your recipe';

  @override
  String get builderParams => 'Parameters';

  @override
  String get builderDose => 'Dose';

  @override
  String get builderWater => 'Water';

  @override
  String get builderTemperature => 'Temperature';

  @override
  String get builderGrind => 'Grind';

  @override
  String get builderClicks => 'clicks';

  @override
  String get builderRatio => 'Ratio';

  @override
  String get builderGram => 'g';

  @override
  String get builderMillilitre => 'ml';

  @override
  String get builderSteps => 'Steps';

  @override
  String get builderDragHint => 'drag by the handle';

  @override
  String get builderAddStep => 'Add a step';

  @override
  String get builderStep => 'Step';

  @override
  String get builderStepName => 'Name';

  @override
  String get builderStepTip => 'Tip';

  @override
  String get builderChoose => 'choose';

  @override
  String get builderEndsLabel => 'Ends';

  @override
  String get builderDuration => 'Duration';

  @override
  String get builderNoTip => 'No tip';

  @override
  String builderTipValue(String tip) {
    return 'Tip · $tip';
  }

  @override
  String get builderRemoveStep => 'Remove the step';

  @override
  String get builderStepWater => 'Water across steps';

  @override
  String builderStepWaterValue(int done, int total) {
    return '$done of $total g';
  }

  @override
  String get builderTotalTime => 'Total time';

  @override
  String get builderSave => 'Save';

  @override
  String get builderBrew => 'Brew';

  @override
  String get builderCancel => 'Cancel';

  @override
  String get builderDone => 'Done';

  @override
  String get builderHoursShort => 'h';

  @override
  String get builderMinutesShort => 'min';

  @override
  String get builderSecondsShort => 'sec';

  @override
  String get builderDecrease => 'decrease';

  @override
  String get builderIncrease => 'increase';

  @override
  String builderCorrectedFor(String label) {
    return 'Adjusted for “$label”';
  }

  @override
  String get builderCorrectedNote => 'the changes are marked with a dot';

  @override
  String get builderUndo => 'Undo';

  @override
  String get builderLeaveTitle => 'Leave without saving?';

  @override
  String get builderLeaveNote =>
      'The edits are not saved — no new version will appear.';

  @override
  String get builderLeave => 'Leave';

  @override
  String get builderSavedOffline =>
      'Saved on the phone — it will be sent once the connection is back';

  @override
  String get builderSavedVersion => 'Saved as a new version';

  @override
  String builderSaveFailed(String error) {
    return 'Not saved: $error';
  }

  @override
  String get builderEndsTimer => 'by time';

  @override
  String get builderEndsUser => 'by button';

  @override
  String get builderEndsSign => 'by a cue';

  @override
  String get builderEndsTimerHint => 'runs on a timer and ends by itself';

  @override
  String get builderEndsUserHint => 'the brew waits until you tap “next”';

  @override
  String get builderEndsSignHint =>
      'the same button, but you press it on a cue: foam settled, water drained';

  @override
  String get svcAuthBadFields => 'Check the email and the password';

  @override
  String get svcAuthWrongCredentials => 'Wrong email or password';

  @override
  String get svcAuthEmailNotVerified => 'The email is not confirmed';

  @override
  String get svcAuthUnknownEmail => 'We have no such email';

  @override
  String get svcAuthEmailTaken => 'This email is already taken';

  @override
  String get svcAuthTooOften => 'Too often. Wait a minute';

  @override
  String get svcAuthServerDown => 'The server is not responding. Try again';

  @override
  String get svcAuthWrongCode =>
      'That code did not work. Check the email again';

  @override
  String get svcAuthNoTokens => 'The server answered without tokens';

  @override
  String get svcAuthOffline => 'No connection. Check the internet';

  @override
  String get svcAuthFailedLogin => 'Could not sign in';

  @override
  String get svcAuthFailedSendLetter => 'Could not send the email';

  @override
  String get svcAuthFailedChangePassword => 'Could not change the password';

  @override
  String get svcAuthFailedRegister => 'Could not sign up';

  @override
  String get svcAuthFailedVerifyEmail => 'Could not confirm the email';

  @override
  String svcSyncSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sent what was waiting for a connection: $count',
      one: 'Sent what was waiting for a connection',
    );
    return '$_temp0';
  }

  @override
  String svcSyncDropped(int count) {
    return 'The server rejected what was waiting ($count) — it is out of date';
  }

  @override
  String svcSyncMixed(int sent, int dropped) {
    return 'Sent: $sent. Rejected by the server: $dropped';
  }

  @override
  String get svcLegalClose => 'Close';

  @override
  String svcLegalUnavailable(String link) {
    return 'The document is not available right now. It is published on the site — open it there: $link';
  }

  @override
  String svcLegalVersion(String version) {
    return 'Revision of $version';
  }

  @override
  String get svcLegalUserAgreement => 'User agreement';

  @override
  String get svcLegalPrivacy => 'Data processing policy';

  @override
  String get svcLegalConsent => 'Consent to data processing';

  @override
  String get svcCodeEmpty => 'Enter the code from the pack';

  @override
  String svcCodeLength(int expected, int actual) {
    String _temp0 = intl.Intl.pluralLogic(
      expected,
      locale: localeName,
      other: 'The code is $expected characters long, and you entered $actual',
      one: 'The code is $expected character long, and you entered $actual',
    );
    return '$_temp0';
  }

  @override
  String svcCodeUnknownSymbol(String symbol) {
    return 'There is no “$symbol” in codes — check whether it is a 0 instead of an O';
  }

  @override
  String get svcCodeChecksum =>
      'The code has a mistake in it — check the characters';

  @override
  String get svcGroupOther => 'Other';

  @override
  String get svcLoadFailedNote =>
      'Usually it is the connection. Check the internet and try again.';
}
