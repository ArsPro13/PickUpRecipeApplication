// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get back => 'Indietro';

  @override
  String get noNetwork => 'Nessuna connessione';

  @override
  String get offlineCached => 'Nessuna connessione. Mostriamo quanto salvato';

  @override
  String get offlineSyncing => 'Di nuovo online — inviamo quanto salvato';

  @override
  String offlinePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi verranno inviati',
      one: '$count elemento verrà inviato',
    );
    return 'Nessuna connessione. $_temp0 al ritorno della rete';
  }

  @override
  String get authCreateAccount => 'Crea un account';

  @override
  String get authSignIn => 'Accedi';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get welcomeTagline => 'La ricetta di chi ha tostato questo caffè';

  @override
  String get welcomeKeepsTitle => 'Un account conserva';

  @override
  String get welcomeKeepsRecipes => 'Le tue ricette';

  @override
  String get welcomeKeepsRecipesNote =>
      'le versioni sopravvivono al cambio di telefono';

  @override
  String get welcomeKeepsGrinder => 'Il tuo macinacaffè';

  @override
  String get welcomeKeepsGrinderNote =>
      'la macinatura è convertita nei tuoi scatti';

  @override
  String get welcomeKeepsPacks => 'Lo storico delle confezioni';

  @override
  String get welcomeKeepsPacksNote =>
      'che cosa hai preparato sei mesi fa, e come';

  @override
  String get loginTitle => 'Accesso';

  @override
  String get loginForgot => 'Password dimenticata?';

  @override
  String get loginNoAccount => 'Non hai ancora un account?';

  @override
  String get loginCreate => 'Crealo';

  @override
  String get registerRepeat => 'Di nuovo';

  @override
  String registerPasswordRule(int length) {
    return 'almeno $length caratteri';
  }

  @override
  String get registerNextMail => 'Poi: un\'email con un codice';

  @override
  String get registerNextMailNote =>
      'sei caratteri per confermare l\'indirizzo';

  @override
  String get registerHaveAccount => 'Hai già un account?';

  @override
  String get registerConsentRequired =>
      'Senza il tuo consenso non possiamo creare un account';

  @override
  String get registerTermsUnavailable =>
      'Non è stato possibile caricare le condizioni. Controlla la connessione e riprova.';

  @override
  String get consentPrefix => 'Accetto la ';

  @override
  String get consentPrivacy => 'politica di trattamento dei dati';

  @override
  String get consentAnd => ' e le ';

  @override
  String get consentAgreement => 'condizioni d\'uso';

  @override
  String get verifyTitle => 'Conferma la tua email';

  @override
  String get verifySubtitle => 'Abbiamo inviato un codice di sei caratteri';

  @override
  String get verifyChangeEmail => 'Cambia l\'indirizzo';

  @override
  String get verifyConfirm => 'Conferma';

  @override
  String get verifyNotArrived => 'Non è arrivata?';

  @override
  String get verifySending => 'Invio in corso…';

  @override
  String get verifyResend => 'Invia di nuovo il codice';

  @override
  String verifyResendIn(String time) {
    return 'Di nuovo tra $time';
  }

  @override
  String get verifySentAgain => 'Abbiamo inviato un\'altra email';

  @override
  String verifyTooOften(String time) {
    return 'Un\'email è già partita. La prossima tra $time';
  }

  @override
  String get verifyAddressRejected =>
      'Il server non ha accettato questo indirizzo. Controlla che sia quello giusto';

  @override
  String get verifyHelpTitle => 'Se l\'email non è arrivata';

  @override
  String get verifyHelpSpam => 'Controlla la posta indesiderata';

  @override
  String get verifyHelpSpamNote =>
      'il mittente è nuovo e il tuo servizio di posta non lo conosce ancora';

  @override
  String get verifyHelpWait => 'Aspetta un minuto';

  @override
  String get verifyHelpWaitNote =>
      'la consegna non è immediata, di solito meno di un minuto';

  @override
  String get verifyHelpAddress => 'Controlla l\'indirizzo';

  @override
  String get verifyHelpAddressNote =>
      'un refuso nell\'indirizzo è la causa più frequente; puoi correggerlo con la matita qui sopra';

  @override
  String get verifyHelpResend => 'Invia di nuovo il codice';

  @override
  String get verifyHelpResendNote =>
      'il pulsante sopra questo elenco; le email partono al massimo una volta al minuto';

  @override
  String get verifyMailDownTitle => 'Le email non partono in questo momento';

  @override
  String get verifyMailDownNote =>
      'non dipende dal tuo indirizzo: il server non è riuscito a inviare l\'email';

  @override
  String get verifyMailDownWhatToDo =>
      'Il tuo account è già stato creato — non serve registrarsi di nuovo. Aspetta qualche minuto e invia di nuovo il codice: appena la posta funziona, l\'email arriverà allo stesso indirizzo.';

  @override
  String get resetTitle => 'Nuova password';

  @override
  String get resetDoneTitle => 'Fatto';

  @override
  String get resetSendCode => 'Invia il codice';

  @override
  String get resetChangePassword => 'Cambia password';

  @override
  String get resetToLogin => 'All\'accesso';

  @override
  String get resetStepWhere => 'Dove inviare il codice';

  @override
  String get resetSameAnswer => 'La risposta sarà la stessa';

  @override
  String get resetSameAnswerNote =>
      'sia che l\'indirizzo lo conosciamo, sia che non lo conosciamo — così il modulo non rivela chi è registrato';

  @override
  String get resetStepSent => 'Email inviata';

  @override
  String get resetStepNewPassword => 'Scegli una nuova password';

  @override
  String get resetFieldCode => 'Codice dall\'email';

  @override
  String get resetNotArrived => 'Non è arrivata?';

  @override
  String get resetResend => 'Invia di nuovo';

  @override
  String resetResendIn(String time) {
    return 'Invia di nuovo tra $time';
  }

  @override
  String get resetFieldNewPassword => 'Nuova password';

  @override
  String resetPasswordHelper(int length) {
    return 'Almeno $length caratteri';
  }

  @override
  String get resetDoneHeading => 'Password cambiata';

  @override
  String get resetDoneNote => 'Accedi con la nuova password';

  @override
  String get ruleEmailEmpty => 'Inserisci la tua email';

  @override
  String get ruleEmailAtSign =>
      'L\'indirizzo deve contenere una sola chiocciola';

  @override
  String get ruleEmailDomain =>
      'Dopo la chiocciola serve un dominio: example.it';

  @override
  String get ruleEmailSpaces => 'Un indirizzo non può contenere spazi';

  @override
  String get rulePasswordEmpty => 'Inserisci una password';

  @override
  String rulePasswordTooShort(int length) {
    return 'Almeno $length caratteri';
  }

  @override
  String get ruleRepeatEmpty => 'Ripeti la password';

  @override
  String get ruleRepeatMismatch => 'Le password non coincidono';

  @override
  String get ruleCodeEmpty => 'Inserisci il codice dall\'email';

  @override
  String get ruleCodeLength => 'Il codice ha sei cifre';

  @override
  String get ruleCodeDigits => 'Il codice è composto solo da cifre';

  @override
  String get tabPacks => 'Confezioni';

  @override
  String get tabRecipes => 'Ricette';

  @override
  String get tabScan => 'Scansiona';

  @override
  String get tabProfile => 'Profilo';

  @override
  String get retry => 'Riprova';

  @override
  String get methodsTitle => 'Con che cosa prepararlo';

  @override
  String get methodsFailed => 'L\'elenco dei metodi non si è aperto';

  @override
  String get conflictTitle => 'Che cosa controllare';

  @override
  String get conflictBrewAgain => 'Preparalo di nuovo allo stesso modo';

  @override
  String get conflictOpenBuilder => 'Apri comunque l\'editor';

  @override
  String unitGrams(String value) {
    return '$value g';
  }

  @override
  String unitMillilitres(String value) {
    return '$value ml';
  }

  @override
  String get edit => 'Modifica';

  @override
  String get recipesTitle => 'Ricette';

  @override
  String get chooseFailed => 'Le ricette non si sono aperte';

  @override
  String get chooseNoBase => 'Questo metodo non ha una ricetta di riferimento';

  @override
  String chooseBaseFailed(String error) {
    return 'La ricetta non si è aperta: $error';
  }

  @override
  String get chooseRoaster => 'Dal torrefattore';

  @override
  String get chooseRoasterNote => 'pensata per questo caffè';

  @override
  String get chooseBase => 'Di base';

  @override
  String get chooseBaseNote => 'dal prontuario';

  @override
  String get chooseMethodRecipe => 'La ricetta del metodo';

  @override
  String get chooseMethodRecipeNote => 'non tiene conto del caffè';

  @override
  String get chooseMine => 'Le tue ricette';

  @override
  String get chooseMineNote => 'versioni precedenti';

  @override
  String chooseBrewWithTime(String time) {
    return 'Prepara · $time';
  }

  @override
  String get stepTypeLabel => 'Tipo di passaggio';

  @override
  String get stepTypesFailed => 'Il prontuario non è arrivato';

  @override
  String get stepTypesFailedNote =>
      'Senza di esso non si sa quali passaggi sa fare questo strumento.';

  @override
  String stepTypesCount(int shown, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      shown,
      locale: localeName,
      other: '$shown tipi',
      one: '$shown tipo',
    );
    return '$_temp0 su $total';
  }

  @override
  String stepTypesCountWithOwn(int shown, int total, int own) {
    String _temp0 = intl.Intl.pluralLogic(
      shown,
      locale: localeName,
      other: '$shown tipi',
      one: '$shown tipo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      own,
      locale: localeName,
      other: '$own tuoi modelli',
      one: '$own tuo modello',
    );
    return '$_temp0 su $total e $_temp1';
  }

  @override
  String get stepTypesOwnGroup => 'I tuoi tipi';

  @override
  String get stepTypesOwnGroupOnly => 'I tuoi tipi · solo per questo strumento';

  @override
  String stepTypesStateful(String name) {
    return '$name · cambia lo stato dello strumento';
  }

  @override
  String get stepTypeNew => 'nuovo';

  @override
  String get profileTitle => 'Profilo';

  @override
  String get profileStatsTitle => 'Che cosa hai messo insieme';

  @override
  String get profileCounting => 'Contiamo le tue confezioni e le tue ricette…';

  @override
  String get profileNothingYet =>
      'Non c\'è ancora nulla da contare. Scansiona una confezione e prepara una ricetta — qui compariranno i tuoi numeri.';

  @override
  String profileRecipes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ricette',
      one: 'ricetta',
    );
    return '$_temp0';
  }

  @override
  String profileVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'versioni',
      one: 'versione',
    );
    return '$_temp0';
  }

  @override
  String profilePacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'confezioni',
      one: 'confezione',
    );
    return '$_temp0';
  }

  @override
  String profileCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'paesi',
      one: 'paese',
    );
    return '$_temp0';
  }

  @override
  String profileVarieties(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'varietà',
      one: 'varietà',
    );
    return '$_temp0';
  }

  @override
  String get profileFavourite => 'Più spesso';

  @override
  String profileFavouriteValue(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ricette',
      one: '$count ricetta',
    );
    return '$name · $_temp0';
  }

  @override
  String get profileFirstRecipe => 'Prima ricetta';

  @override
  String get profileGrindersTitle => 'I miei macinacaffè';

  @override
  String get profileNoGrinder =>
      'Nessun macinacaffè selezionato. Senza di esso la ricetta mostra la macinatura a parole invece che negli scatti del tuo macinacaffè.';

  @override
  String get profileGrinderPrimary => 'principale';

  @override
  String get profileChooseGrinder => 'Scegli un macinacaffè';

  @override
  String get profileChangeGrinders => 'Cambia la selezione';

  @override
  String get profileAccountTitle => 'Account';

  @override
  String get profileLogout => 'Esci';

  @override
  String get profileLogoutTitle => 'Uscire senza inviare?';

  @override
  String profileLogoutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi sono in attesa',
      one: '$count elemento è in attesa',
    );
    return 'Non c\'era connessione e $_temp0 di invio — valutazioni e modifiche alle ricette. Uscendo verranno cancellati insieme all\'account.';
  }

  @override
  String get profileLogoutConfirmTitle => 'Uscire dall\'account?';

  @override
  String get profileLogoutConfirm =>
      'Scaffale, ricette e cronologia restano nell\'account. Per rientrare serviranno email e password.';

  @override
  String get profileStay => 'Resta';

  @override
  String get clear => 'Cancella';

  @override
  String get scanTitle => 'Il codice sulla confezione';

  @override
  String get scanOpenCamera => 'Apri la fotocamera';

  @override
  String get scanTapToAim => 'tocca per inquadrare';

  @override
  String get scanCodeIsSmall =>
      'Il codice è piccolo — cercalo nell\'angolo della confezione';

  @override
  String get scanManualTitle => 'Inserisci il codice a mano';

  @override
  String get scanOpenRecipe => 'Apri la ricetta';

  @override
  String get scanNoCode => 'Sulla confezione non c\'è un codice';

  @override
  String get saving => 'Salvataggio…';

  @override
  String get customStepTitle => 'Un tuo tipo di passaggio';

  @override
  String customStepForMethod(String method) {
    return 'resterà tuo per il metodo $method';
  }

  @override
  String get customStepNoLabel =>
      'Senza un nome il passaggio non entra nell\'elenco';

  @override
  String get customStepLabelField => 'Nome · come comparirà nell\'elenco';

  @override
  String get customStepLabelHint => 'Soffia con lo stantuffo';

  @override
  String get customStepIcon =>
      'Icona · dal set, non si possono usare immagini proprie';

  @override
  String get stepEndsWith => 'Come finisce il passaggio';

  @override
  String get customStepThisDevice => 'questo strumento';

  @override
  String customStepNote(String device) {
    return 'Il passaggio è legato a $device: non comparirà nelle ricette per altri strumenti. Un passaggio così non conta l\'acqua — per l\'acqua c\'è la «versata».';
  }

  @override
  String get customStepSave => 'Salva il tipo';

  @override
  String get remove => 'Togli';

  @override
  String get packsTitle => 'Le mie confezioni';

  @override
  String get packsEmpty => 'Ancora nessuna confezione';

  @override
  String get packsEmptyNote =>
      'Scansiona il codice sulla confezione — la ricetta del torrefattore arriverà da sola';

  @override
  String get packsScanCode => 'Scansiona il codice';

  @override
  String get packsAdd => 'Aggiungi una confezione';

  @override
  String get packsChangeGrinder => 'Cambia macinacaffè';

  @override
  String get packsFinished => 'finita';

  @override
  String get roastLight => 'chiara';

  @override
  String get roastMedium => 'media';

  @override
  String get roastDark => 'scura';

  @override
  String get ratingDraftTitle => 'Valutazione incompleta';

  @override
  String get ratingDraftContinue => 'riprendi da dove eri rimasto';

  @override
  String ratingDraftContinueWith(String summary) {
    return '$summary — riprendi';
  }

  @override
  String get recipesFailed => 'Le ricette non si sono caricate';

  @override
  String get recipesEmpty => 'Ancora nessuna preparazione';

  @override
  String get recipesEmptyNote =>
      'Prepara un caffè seguendo una ricetta — comparirà qui insieme alla tua valutazione';

  @override
  String get recipesToPacks => 'Alle confezioni';

  @override
  String recipesVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versioni',
      one: '$count versione',
    );
    return '$_temp0';
  }

  @override
  String get recipesNow => 'adesso';

  @override
  String get recipesNowSwipe => 'adesso · scorri di lato';

  @override
  String recipesVersionOf(int number, int count) {
    return 'versione $number di $count';
  }

  @override
  String get recipesDraft => 'non salvata';

  @override
  String get recipesCurrent => 'così la preparo';

  @override
  String get recipesPastVersion => 'versione precedente';

  @override
  String get recipesBrewAgain => 'Preparalo di nuovo';

  @override
  String get recipesEditRecipe => 'Modifica la ricetta';

  @override
  String get coffeeTitle => 'Caffè';

  @override
  String get coffeeNotFound => 'Questo codice non esiste';

  @override
  String get coffeeNotFoundNoCode => 'Questo caffè non è nel sistema.';

  @override
  String get coffeeNotFoundNote =>
      'Il codice è scritto senza errori — il carattere di controllo torna — ma nel sistema non c\'è. Forse il torrefattore non ha ancora pubblicato questo lotto.';

  @override
  String get coffeeScanAgain => 'Scansiona di nuovo';

  @override
  String get coffeeToPacks => 'Alle mie confezioni';

  @override
  String get coffeeRoasterPromises => 'Il torrefattore promette';

  @override
  String get coffeeWithdrawnTitle => 'Questo lotto non è più in vendita. ';

  @override
  String coffeeWithdrawnNote(String what) {
    return 'Il torrefattore l\'ha ritirato$what — di solito significa che i chicchi sono finiti. Le ricette restano: nulla ti impedisce di preparare la confezione che hai già sullo scaffale.';
  }

  @override
  String get coffeeOfflineNoCache =>
      'Non c\'è connessione e in memoria non c\'è nemmeno una ricetta salvata: per ora non c\'è nulla con cui preparare.';

  @override
  String coffeeOfflineCached(String when) {
    return 'Non c\'è connessione. In memoria c\'è una ricetta salvata il $when — puoi prepararla. Si aggiornerà da sola al ritorno della rete.';
  }

  @override
  String get coffeeOfflineCantTitle => 'Che cosa non si può fare adesso';

  @override
  String get coffeeOfflineScan => 'Scansionare una nuova confezione';

  @override
  String get coffeeOfflineScanNote => 'il codice viene verificato sul server';

  @override
  String get coffeeOfflineRating => 'Inviare una valutazione';

  @override
  String get coffeeOfflineRatingNote => 'puoi darla, verrà inviata più tardi';

  @override
  String get coffeeOfflineCorrection => 'Ricevere una correzione';

  @override
  String get coffeeOfflineCorrectionNote =>
      'la calcola il server, non il telefono';

  @override
  String get coffeeBrewCached => 'Prepara con quella salvata';

  @override
  String coffeeLastBrewed(String date) {
    return 'così l\'hai preparato il $date';
  }

  @override
  String coffeeBrewOn(String method) {
    return 'Prepara con $method';
  }

  @override
  String get coffeeMethodsFailed =>
      'I metodi di preparazione non si sono caricati';

  @override
  String get dateMonth1 => 'gennaio';

  @override
  String get dateMonth2 => 'febbraio';

  @override
  String get dateMonth3 => 'marzo';

  @override
  String get dateMonth4 => 'aprile';

  @override
  String get dateMonth5 => 'maggio';

  @override
  String get dateMonth6 => 'giugno';

  @override
  String get dateMonth7 => 'luglio';

  @override
  String get dateMonth8 => 'agosto';

  @override
  String get dateMonth9 => 'settembre';

  @override
  String get dateMonth10 => 'ottobre';

  @override
  String get dateMonth11 => 'novembre';

  @override
  String get dateMonth12 => 'dicembre';

  @override
  String dateDayMonth(String day, String month) {
    return '$day $month';
  }

  @override
  String dateDayMonthYear(String day, String month, String year) {
    return '$day $month $year';
  }

  @override
  String get rateTitle => 'Com\'è venuto';

  @override
  String get rateOnTarget => 'Venuto proprio come previsto';

  @override
  String rateSaid(String strength, String taste) {
    return '$strength $taste';
  }

  @override
  String get rateDegreeSlight => 'un po\'';

  @override
  String get rateDegreeNoticeable => 'sensibilmente';

  @override
  String get rateDegreeStrong => 'molto';

  @override
  String get rateTasteSour => 'acido';

  @override
  String get rateTasteBitter => 'amaro';

  @override
  String get rateTasteStrong => 'forte';

  @override
  String get rateTasteWeak => 'debole';

  @override
  String rateMapSemantics(String summary) {
    return 'Mappa del gusto. $summary';
  }

  @override
  String get rateOverall => 'Generale';

  @override
  String rateStarsOf(int stars) {
    return '$stars su 5';
  }

  @override
  String get rateOptional => 'Facoltativo';

  @override
  String get rateAxesTitle => 'Scomponi per assi';

  @override
  String get rateAxesHint =>
      'Puoi non toccarli — verrà inviato solo ciò che sposti';

  @override
  String get rateAxisAroma => 'Aroma';

  @override
  String get rateAxisFlavor => 'Gusto';

  @override
  String get rateAxisAftertaste => 'Retrogusto';

  @override
  String get rateAxisAcidity => 'Acidità';

  @override
  String get rateAxisBitterness => 'Amarezza';

  @override
  String get rateAxisSweetness => 'Dolcezza';

  @override
  String rateAxesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assi',
      one: '$count asse',
    );
    return '$_temp0';
  }

  @override
  String get rateSave => 'Salva';

  @override
  String get rateFixRecipe => 'Correggi la ricetta';

  @override
  String get rateJustSave => 'Salva solo la valutazione';

  @override
  String get rateSavedOffline =>
      'Valutazione salvata — verrà inviata al ritorno della rete';

  @override
  String get rateSavedCorrectionLater =>
      'Valutazione salvata. La correzione la calcola il server — arriverà al ritorno della rete';

  @override
  String get rateNothingToChange =>
      'Non c\'è nulla da cambiare: la ricetta è già al limite dei suoi valori';

  @override
  String get rateParamGrind => 'Macinatura';

  @override
  String get rateParamTemperature => 'Temperatura';

  @override
  String get rateParamRatio => 'Rapporto';

  @override
  String get rateParamAgitation => 'Agitazione';

  @override
  String get rateParamContactTime => 'Tempo di contatto';

  @override
  String get rateParamDose => 'Dose';

  @override
  String get packFormTitle => 'Confezione senza codice';

  @override
  String get packFormIntro =>
      'Scrivi quello che c\'è sulla confezione. Solo il paese è obbligatorio — dal paese e dalla regione si compone il nome.';

  @override
  String get packFormPhotoTitle => 'Fotografa la confezione';

  @override
  String get packFormPhotoNote =>
      'La foto resta con la confezione — è così che la riconoscerai nell\'elenco';

  @override
  String get packFormPhotoTake => 'Scatta una foto';

  @override
  String get packFormPhotoRetake => 'Rifai la foto';

  @override
  String get packFormPhotoFromGallery => 'Dalla galleria';

  @override
  String get packFormPhotoFailed => 'La foto non è riuscita — riprova';

  @override
  String get packFormCountry => 'Paese';

  @override
  String get packFormCountryHint => 'Brasile';

  @override
  String get packFormCountryRequired =>
      'Senza il paese non c\'è da cosa ricavare il nome';

  @override
  String get packFormRegion => 'Regione — se la conosci';

  @override
  String get packFormRegionHint => 'Cerrado';

  @override
  String get packFormVariety => 'Varietà';

  @override
  String get packFormVarietyHint => 'bourbon';

  @override
  String get packFormScaScore => 'Punteggio SCA';

  @override
  String get packFormRoastDate => 'Data di tostatura';

  @override
  String get packFormDateHint => 'gg.mm.aaaa';

  @override
  String get packFormDateInvalid => 'Questa data non esiste';

  @override
  String get packFormDateEmptyNote =>
      'Se non la sai, lasciala vuota: metteremo la data di oggi';

  @override
  String get packFormToday => 'Oggi';

  @override
  String get packFormDescriptors => 'Descrittori';

  @override
  String get packFormDescriptorsNote =>
      'Che profumo e che gusto ha — una parola per riga';

  @override
  String packFormDescriptorNumbered(int number) {
    return 'Descrittore $number';
  }

  @override
  String get packFormDescriptorHint => 'lampone';

  @override
  String get packFormAddDescriptor => 'Aggiungi un descrittore';

  @override
  String get packFormProcessing => 'Metodo di lavorazione';

  @override
  String get packFormProcessingNote =>
      'Di solito è scritto sulla confezione accanto alla varietà';

  @override
  String packFormProcessingNumbered(int number) {
    return 'Lavorazione $number';
  }

  @override
  String get packFormProcessingHint => 'lavato';

  @override
  String get packFormAddProcessing => 'Aggiungi una lavorazione';

  @override
  String get packFormRemoveLine => 'Togli la riga';

  @override
  String get packFormSubmit => 'Invia';

  @override
  String get packFormSubmitFailed => 'La confezione non è stata inviata';

  @override
  String packFormSubmitFailedNote(String reason) {
    return '$reason. Quello che hai scritto è ancora qui — riprova.';
  }

  @override
  String get packFormShowPassword => 'Mostra la password';

  @override
  String get packFormHidePassword => 'Nascondi la password';

  @override
  String get brewAbortTitle => 'Interrompere la preparazione?';

  @override
  String get brewAbortNote =>
      'Il conteggio si ferma e non potrai riprenderlo dallo stesso secondo.';

  @override
  String get brewAbort => 'Interrompi';

  @override
  String get brewStay => 'Resta';

  @override
  String get brewEditRecipe => 'Modifica la ricetta';

  @override
  String brewStepOf(int number, int count) {
    return 'passaggio $number di $count';
  }

  @override
  String get brewGrindAndStart => 'Macinato, si parte';

  @override
  String get brewStart => 'Inizia';

  @override
  String get brewPause => 'Pausa';

  @override
  String get brewResume => 'Continua';

  @override
  String get brewDidIt => 'Fatto';

  @override
  String get brewRate => 'Valuta';

  @override
  String get brewSkip => 'Salta';

  @override
  String get brewHappened => 'È successo';

  @override
  String get brewTitle => 'Preparazione';

  @override
  String get brewNoSteps => 'Questa ricetta non ha passaggi';

  @override
  String get brewNoStepsNote =>
      'Non c\'è nulla da eseguire. Ricomponi la ricetta o scegline un\'altra.';

  @override
  String get brewSteepingOver =>
      'L\'infusione è finita mentre l\'app era chiusa. Completa i passaggi rimasti — da qui in poi il caffè diventa solo più amaro.';

  @override
  String brewSteepingGoes(String away) {
    return 'L\'infusione è in corso: sono passati $away. Puoi chiudere lo schermo — il tempo si conta con l\'orologio, non con il timer sullo schermo.';
  }

  @override
  String get brewToRemainingSteps => 'Ai passaggi rimasti';

  @override
  String get brewCallItFinished => 'Consideralo finito';

  @override
  String brewAwayTitle(String away) {
    return 'Sono passati $away';
  }

  @override
  String brewStoppedAtStep(String step) {
    return 'Ti sei fermato al passaggio «$step». Il caffè non aspetta tanto: l\'acqua si è raffreddata e il cono si è svuotato.';
  }

  @override
  String get brewStartOver => 'Ricomincia';

  @override
  String get brewStartOverNote =>
      'Di solito è la scelta giusta: 15 g di caffè costano meno di una tazza rovinata';

  @override
  String get brewContinueFromHere => 'Continua da qui';

  @override
  String get brewContinueFromHereNote =>
      'Se hai versato per tutto questo tempo e hai solo spento lo schermo';

  @override
  String get brewCallItFinishedNote =>
      'È venuto, solo che non sei arrivato alla valutazione — facciamola adesso';

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
      other: '$minutes minuti',
      one: '$minutes minuto',
    );
    return '$_temp0';
  }

  @override
  String brewAwaySeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get brewGrindCoffee => 'Macina il caffè';

  @override
  String get brewWaitingForYou => 'aspettiamo te';

  @override
  String brewReadyAt(String time) {
    return 'alle $time';
  }

  @override
  String brewPouredOf(String poured, String total) {
    return 'versati $poured di $total g';
  }

  @override
  String brewTargetInCup(String grams) {
    return 'obiettivo — $grams g in tazza';
  }

  @override
  String brewTargetInCupDone(String grams) {
    return 'fatto · $grams g in tazza';
  }

  @override
  String brewTargetInCupFirstDrops(String grams) {
    return 'obiettivo — $grams g in tazza · prime gocce a 5–7 s';
  }

  @override
  String get brewTimeIsAGuide =>
      'il tempo è un\'indicazione, guarda il segnale';

  @override
  String brewTimeIsAGuideWithWater(String water) {
    return 'il tempo è un\'indicazione · $water';
  }

  @override
  String brewReadyIn(String time) {
    return 'pronto tra $time';
  }

  @override
  String get brewStepNotStarted => 'non ancora iniziato';

  @override
  String get brewLeft => 'rimasti';

  @override
  String get brewOnPause => 'in pausa';

  @override
  String get brewTapDidIt => 'tocca «Fatto» quando hai finito';

  @override
  String get brewFinished => 'fatto';

  @override
  String get brewOptional => 'facoltativo';

  @override
  String get brewTipExpand => 'Mostra tutto il suggerimento';

  @override
  String get brewTipCollapse => 'Comprimi il suggerimento';

  @override
  String get brewPhasePrep => 'preparazione';

  @override
  String get brewPhaseBrewing => 'estrazione';

  @override
  String get brewPhaseFinish => 'finale';

  @override
  String get brewEndsBySign => 'a vista';

  @override
  String get brewEndsByTap => 'col pulsante';

  @override
  String get brewUntilYouSayDidIt => 'finché non dici «fatto»';

  @override
  String get grinderTitle => 'Macinacaffè';

  @override
  String get grinderSearchHint => 'Trova un macinacaffè';

  @override
  String get grinderKindManual => 'Manuali';

  @override
  String get grinderKindElectric => 'Elettrici';

  @override
  String get grinderKindOther => 'Altri';

  @override
  String get grinderCurrent => 'Selezionato ora';

  @override
  String get grinderChangeTo => 'Passa a un altro';

  @override
  String get grinderPick => 'Scegli il tuo';

  @override
  String grinderScale(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tacche',
      one: '$count tacca',
    );
    return '$_temp0 sulla scala';
  }

  @override
  String grinderApplied(String name) {
    return 'La macinatura ora è in tacche di $name';
  }

  @override
  String get undo => 'Annulla';

  @override
  String get grinderNotFound => 'Nessun macinacaffè trovato';

  @override
  String get grinderCatalogEmpty =>
      'Il catalogo è vuoto — controlla la connessione';

  @override
  String grinderCatalogSize(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ci sono $count modelli',
      one: 'c\'è $count modello',
    );
    return 'Controlla come l\'hai scritto — nel catalogo $_temp0';
  }

  @override
  String get grinderShowAll => 'Mostra tutti';

  @override
  String get grinderDidYouMean => 'Forse intendevi';

  @override
  String get grinderSaveFailed =>
      'Non è stato possibile salvare il macinacaffè';

  @override
  String get grinderSaveOffline =>
      'Senza connessione il macinacaffè non si salva — è legato al tuo account';

  @override
  String grinderApproximately(String value) {
    return 'circa $value';
  }

  @override
  String get grinderPickPrompt => 'scegli un macinacaffè';

  @override
  String get grinderPickPromptHint =>
      'scegli un macinacaffè e ti mostriamo la tacca';

  @override
  String grinderScaleOf(String name) {
    return 'tacche $name';
  }

  @override
  String grinderClicks(String value) {
    return '$value scatti';
  }

  @override
  String get builderTitle => 'La tua ricetta';

  @override
  String get builderParams => 'Parametri';

  @override
  String get builderDose => 'Dose';

  @override
  String get builderWater => 'Acqua';

  @override
  String get builderTemperature => 'Temperatura';

  @override
  String get builderGrind => 'Macinatura';

  @override
  String get builderRatio => 'Rapporto';

  @override
  String get builderGram => 'g';

  @override
  String get builderMillilitre => 'ml';

  @override
  String get builderSteps => 'Passaggi';

  @override
  String get builderDragHint => 'trascina dalla maniglia';

  @override
  String get builderAddStep => 'Aggiungi un passaggio';

  @override
  String get builderStep => 'Passaggio';

  @override
  String get builderStepName => 'Nome';

  @override
  String get builderStepTip => 'Suggerimento';

  @override
  String get builderChoose => 'scegli';

  @override
  String get builderEndsLabel => 'Finisce';

  @override
  String get builderDuration => 'Durata';

  @override
  String get builderNoTip => 'Nessun suggerimento';

  @override
  String builderTipValue(String tip) {
    return 'Suggerimento · $tip';
  }

  @override
  String get builderRemoveStep => 'Togli il passaggio';

  @override
  String get builderStepWater => 'Acqua per passaggio';

  @override
  String builderStepWaterValue(int done, int total) {
    return '$done di $total g';
  }

  @override
  String get builderTotalTime => 'Tempo totale';

  @override
  String get builderSave => 'Salva';

  @override
  String get builderBrew => 'Prepara';

  @override
  String get builderToHome => 'Alla schermata iniziale';

  @override
  String get builderCancel => 'Annulla';

  @override
  String get builderDone => 'Fatto';

  @override
  String get builderMinutesSeconds => 'minuti e secondi';

  @override
  String get builderDecrease => 'diminuisci';

  @override
  String get builderIncrease => 'aumenta';

  @override
  String builderCorrectedFor(String label) {
    return 'Corretto per «$label»';
  }

  @override
  String get builderCorrectedNote => 'le modifiche sono segnate con un punto';

  @override
  String get builderUndo => 'Annulla';

  @override
  String get builderLeaveTitle => 'Uscire senza salvare?';

  @override
  String get builderLeaveNote =>
      'Le modifiche non sono salvate — non comparirà nessuna nuova versione.';

  @override
  String get builderLeave => 'Esci';

  @override
  String get builderSavedOffline =>
      'Salvato sul telefono — verrà inviato al ritorno della rete';

  @override
  String get builderSavedVersion => 'Salvato come nuova versione';

  @override
  String builderSaveFailed(String error) {
    return 'Non salvato: $error';
  }

  @override
  String get builderEndsTimer => 'a tempo';

  @override
  String get builderEndsUser => 'col pulsante';

  @override
  String get builderEndsSign => 'a vista';

  @override
  String get builderEndsTimerHint => 'va a timer e finisce da solo';

  @override
  String get builderEndsUserHint =>
      'la preparazione aspetta finché non tocchi «avanti»';

  @override
  String get builderEndsSignHint =>
      'lo stesso pulsante, ma lo premi a vista: la schiuma si è posata, l\'acqua è scesa';

  @override
  String get svcAuthBadFields => 'Controlla l\'email e la password';

  @override
  String get svcAuthWrongCredentials => 'Email o password errate';

  @override
  String get svcAuthEmailNotVerified => 'L\'email non è confermata';

  @override
  String get svcAuthUnknownEmail => 'Questa email non risulta';

  @override
  String get svcAuthEmailTaken => 'Questa email è già in uso';

  @override
  String get svcAuthTooOften => 'Troppo spesso. Aspetta un minuto';

  @override
  String get svcAuthServerDown => 'Il server non risponde. Riprova';

  @override
  String get svcAuthWrongCode => 'Il codice non va bene. Ricontrolla l\'email';

  @override
  String get svcAuthNoTokens => 'Il server ha risposto senza token';

  @override
  String get svcAuthOffline => 'Nessuna connessione. Controlla internet';

  @override
  String get svcAuthFailedLogin => 'Accesso non riuscito';

  @override
  String get svcAuthFailedSendLetter => 'Invio dell\'email non riuscito';

  @override
  String get svcAuthFailedChangePassword => 'Cambio password non riuscito';

  @override
  String get svcAuthFailedRegister => 'Registrazione non riuscita';

  @override
  String get svcAuthFailedVerifyEmail => 'Conferma dell\'email non riuscita';

  @override
  String svcSyncSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Inviato ciò che aspettava la connessione: $count',
      one: 'Inviato ciò che aspettava la connessione',
    );
    return '$_temp0';
  }

  @override
  String svcSyncDropped(int count) {
    return 'Il server non ha accettato quanto era in attesa ($count) — è obsoleto';
  }

  @override
  String svcSyncMixed(int sent, int dropped) {
    return 'Inviati: $sent. Rifiutati dal server: $dropped';
  }

  @override
  String get svcLegalClose => 'Chiudi';

  @override
  String svcLegalUnavailable(String link) {
    return 'Il documento non è disponibile in questo momento. È pubblicato sul sito — aprilo lì: $link';
  }

  @override
  String svcLegalVersion(String version) {
    return 'Revisione del $version';
  }

  @override
  String get svcLegalUserAgreement => 'Condizioni d\'uso';

  @override
  String get svcLegalPrivacy => 'Politica di trattamento dei dati';

  @override
  String get svcLegalConsent => 'Consenso al trattamento dei dati';

  @override
  String get svcCodeEmpty => 'Inserisci il codice dalla confezione';

  @override
  String svcCodeLength(int expected, int actual) {
    String _temp0 = intl.Intl.pluralLogic(
      expected,
      locale: localeName,
      other: 'Il codice è di $expected caratteri, ne hai inseriti $actual',
      one: 'Il codice è di $expected carattere, ne hai inseriti $actual',
    );
    return '$_temp0';
  }

  @override
  String svcCodeUnknownSymbol(String symbol) {
    return 'Il carattere «$symbol» non compare nei codici — controlla se non sia uno 0 al posto di una O';
  }

  @override
  String get svcCodeChecksum =>
      'Il codice contiene un errore — controlla i caratteri';

  @override
  String get svcGroupOther => 'Altri';

  @override
  String get svcLoadFailedNote =>
      'Di solito è la connessione. Controlla internet e riprova.';

  @override
  String get recipesNotRated => 'Non valutato';

  @override
  String methodsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count strumenti',
      one: '$count strumento',
    );
    return '$_temp0';
  }

  @override
  String get chooseOtherPacks => 'Da confezioni precedenti';

  @override
  String get chooseOtherPacksNote => 'stesso strumento, caffè diverso';

  @override
  String get rateForYou =>
      'Questa è una tua nota. Grazie a essa l\'app correggerà macinatura e tempo la prossima volta — il torrefattore vede solo statistiche anonime.';

  @override
  String get rateOverallNote =>
      'Non cambia nulla — serve solo a ritrovare poi la tua tazza migliore';

  @override
  String get profileAppTitle => 'App';

  @override
  String get profileLanguage => 'Lingua';

  @override
  String get profileLanguageSystem => 'Come il sistema';
}
