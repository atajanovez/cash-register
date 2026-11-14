import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_tk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[Locale('tk')];

  /// No description provided for @appName.
  ///
  /// In tk, this message translates to:
  /// **'Kassa'**
  String get appName;

  /// No description provided for @cancel.
  ///
  /// In tk, this message translates to:
  /// **'Ýatyr'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In tk, this message translates to:
  /// **'Gaýtadan synanyş'**
  String get retry;

  /// No description provided for @couldNotLoad.
  ///
  /// In tk, this message translates to:
  /// **'Ýüklenip bilinmedi'**
  String get couldNotLoad;

  /// No description provided for @clear.
  ///
  /// In tk, this message translates to:
  /// **'Arassala'**
  String get clear;

  /// No description provided for @refresh.
  ///
  /// In tk, this message translates to:
  /// **'Täzele'**
  String get refresh;

  /// No description provided for @loading.
  ///
  /// In tk, this message translates to:
  /// **'Ýüklenýär…'**
  String get loading;

  /// No description provided for @logoLabel.
  ///
  /// In tk, this message translates to:
  /// **'Kassa nyşany'**
  String get logoLabel;

  /// No description provided for @none.
  ///
  /// In tk, this message translates to:
  /// **'Ýok'**
  String get none;

  /// No description provided for @navRegisters.
  ///
  /// In tk, this message translates to:
  /// **'Kassalar'**
  String get navRegisters;

  /// No description provided for @navMembers.
  ///
  /// In tk, this message translates to:
  /// **'Agzalar'**
  String get navMembers;

  /// No description provided for @navAccount.
  ///
  /// In tk, this message translates to:
  /// **'Profil'**
  String get navAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In tk, this message translates to:
  /// **'Hoş geldiňiz'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In tk, this message translates to:
  /// **'Kassalaryňyzy dolandyrmak üçin kompaniýaňyza giriň.'**
  String get loginSubtitle;

  /// No description provided for @companyName.
  ///
  /// In tk, this message translates to:
  /// **'Kompaniýanyň ady'**
  String get companyName;

  /// No description provided for @username.
  ///
  /// In tk, this message translates to:
  /// **'Ulanyjy ady'**
  String get username;

  /// No description provided for @password.
  ///
  /// In tk, this message translates to:
  /// **'Açar sözi'**
  String get password;

  /// No description provided for @logIn.
  ///
  /// In tk, this message translates to:
  /// **'Giriş'**
  String get logIn;

  /// No description provided for @newHere.
  ///
  /// In tk, this message translates to:
  /// **'Täze ulanyjymy?'**
  String get newHere;

  /// No description provided for @createCompany.
  ///
  /// In tk, this message translates to:
  /// **'Kompaniýa döret'**
  String get createCompany;

  /// No description provided for @enterCompanyName.
  ///
  /// In tk, this message translates to:
  /// **'Kompaniýanyň adyny giriziň'**
  String get enterCompanyName;

  /// No description provided for @enterUsername.
  ///
  /// In tk, this message translates to:
  /// **'Ulanyjy adyňyzy giriziň'**
  String get enterUsername;

  /// No description provided for @enterPassword.
  ///
  /// In tk, this message translates to:
  /// **'Açar sözüňizi giriziň'**
  String get enterPassword;

  /// No description provided for @invalidCredentials.
  ///
  /// In tk, this message translates to:
  /// **'Kompaniýanyň ady, ulanyjy ady ýa-da açar sözi nädogry.'**
  String get invalidCredentials;

  /// No description provided for @sessionExpired.
  ///
  /// In tk, this message translates to:
  /// **'Sessiýaňyzyň möhleti gutardy. Täzeden giriň.'**
  String get sessionExpired;

  /// No description provided for @accountDeactivated.
  ///
  /// In tk, this message translates to:
  /// **'Hasabyňyz işjeň däl. Dolandyryjyňyza ýüz tutuň.'**
  String get accountDeactivated;

  /// No description provided for @showPassword.
  ///
  /// In tk, this message translates to:
  /// **'Açar sözüni görkez'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In tk, this message translates to:
  /// **'Açar sözüni gizle'**
  String get hidePassword;

  /// No description provided for @signupTitle.
  ///
  /// In tk, this message translates to:
  /// **'Kompaniýaňyzy dörediň'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In tk, this message translates to:
  /// **'Siz dolandyryjy bolarsyňyz. Soňra agzalary we kassalary goşup bilersiňiz.'**
  String get signupSubtitle;

  /// No description provided for @sectionCompany.
  ///
  /// In tk, this message translates to:
  /// **'Kompaniýa'**
  String get sectionCompany;

  /// No description provided for @sectionManagerAccount.
  ///
  /// In tk, this message translates to:
  /// **'Dolandyryjynyň hasaby'**
  String get sectionManagerAccount;

  /// No description provided for @companyNameHelper.
  ///
  /// In tk, this message translates to:
  /// **'Agzalaryňyz ulgama girende şu ady ulanarlar'**
  String get companyNameHelper;

  /// No description provided for @fullName.
  ///
  /// In tk, this message translates to:
  /// **'Ady we familiýasy'**
  String get fullName;

  /// No description provided for @enterFullName.
  ///
  /// In tk, this message translates to:
  /// **'Ady we familiýany giriziň'**
  String get enterFullName;

  /// No description provided for @chooseUsername.
  ///
  /// In tk, this message translates to:
  /// **'Ulanyjy adyny saýlaň'**
  String get chooseUsername;

  /// No description provided for @usernameNoSpaces.
  ///
  /// In tk, this message translates to:
  /// **'Ulanyjy adynda boşluk bolmaly däl'**
  String get usernameNoSpaces;

  /// No description provided for @choosePassword.
  ///
  /// In tk, this message translates to:
  /// **'Açar sözüni saýlaň'**
  String get choosePassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In tk, this message translates to:
  /// **'Iň azyndan {count} simwol bolmaly'**
  String passwordTooShort(String count);

  /// No description provided for @passwordTooLong.
  ///
  /// In tk, this message translates to:
  /// **'Iň köp {count} simwol bolup biler'**
  String passwordTooLong(String count);

  /// No description provided for @passwordHelper.
  ///
  /// In tk, this message translates to:
  /// **'Iň azyndan {count} simwol'**
  String passwordHelper(String count);

  /// No description provided for @confirmPassword.
  ///
  /// In tk, this message translates to:
  /// **'Açar sözüni gaýtalaň'**
  String get confirmPassword;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In tk, this message translates to:
  /// **'Açar sözler gabat gelmeýär'**
  String get passwordsDontMatch;

  /// No description provided for @fixHighlighted.
  ///
  /// In tk, this message translates to:
  /// **'Bellenen meýdançalary düzediň.'**
  String get fixHighlighted;

  /// No description provided for @companyNameTaken.
  ///
  /// In tk, this message translates to:
  /// **'Bu at bilen kompaniýa eýýäm bar'**
  String get companyNameTaken;

  /// No description provided for @alreadyHaveCompany.
  ///
  /// In tk, this message translates to:
  /// **'Kompaniýaňyz barmy?'**
  String get alreadyHaveCompany;

  /// No description provided for @brandHeadline.
  ///
  /// In tk, this message translates to:
  /// **'Her teňňe —\nher kassada.'**
  String get brandHeadline;

  /// No description provided for @brandBody.
  ///
  /// In tk, this message translates to:
  /// **'Girdejileri, çykdajylary, geçirimleri we bergileri ähli kassalaryňyz boýunça bütin toparyňyz bilen bile hasaba alyň.'**
  String get brandBody;

  /// No description provided for @featureDevices.
  ///
  /// In tk, this message translates to:
  /// **'Telefonda we kompýuterde işleýär'**
  String get featureDevices;

  /// No description provided for @featureRoles.
  ///
  /// In tk, this message translates to:
  /// **'Dolandyryjy we agza rollary, her kassa üçin aýratyn rugsat'**
  String get featureRoles;

  /// No description provided for @featureAudit.
  ///
  /// In tk, this message translates to:
  /// **'Üýtgedilmeýän ýazgylar — doly hasabat taryhy'**
  String get featureAudit;

  /// No description provided for @registersTitle.
  ///
  /// In tk, this message translates to:
  /// **'Kassalar'**
  String get registersTitle;

  /// No description provided for @searchRegisters.
  ///
  /// In tk, this message translates to:
  /// **'Kassany gözle'**
  String get searchRegisters;

  /// No description provided for @filterAll.
  ///
  /// In tk, this message translates to:
  /// **'Ählisi'**
  String get filterAll;

  /// No description provided for @filterOpen.
  ///
  /// In tk, this message translates to:
  /// **'Açyk'**
  String get filterOpen;

  /// No description provided for @filterChecked.
  ///
  /// In tk, this message translates to:
  /// **'Barlanan'**
  String get filterChecked;

  /// No description provided for @filterClosed.
  ///
  /// In tk, this message translates to:
  /// **'Ýapyk'**
  String get filterClosed;

  /// No description provided for @filterUnsettled.
  ///
  /// In tk, this message translates to:
  /// **'Hasaplaşylmadyk'**
  String get filterUnsettled;

  /// No description provided for @sort.
  ///
  /// In tk, this message translates to:
  /// **'Tertiple'**
  String get sort;

  /// No description provided for @sortCreated.
  ///
  /// In tk, this message translates to:
  /// **'Döredilen senesi'**
  String get sortCreated;

  /// No description provided for @sortCurrent.
  ///
  /// In tk, this message translates to:
  /// **'Nagt pul'**
  String get sortCurrent;

  /// No description provided for @sortReal.
  ///
  /// In tk, this message translates to:
  /// **'Hakyky mukdar'**
  String get sortReal;

  /// No description provided for @sortChecked.
  ///
  /// In tk, this message translates to:
  /// **'Barlanan senesi'**
  String get sortChecked;

  /// No description provided for @sortClosed.
  ///
  /// In tk, this message translates to:
  /// **'Ýapylan senesi'**
  String get sortClosed;

  /// No description provided for @sortDescending.
  ///
  /// In tk, this message translates to:
  /// **'Iň täzesi / iň ulusy öňde'**
  String get sortDescending;

  /// No description provided for @sortAscending.
  ///
  /// In tk, this message translates to:
  /// **'Iň könesi / iň kiçisi öňde'**
  String get sortAscending;

  /// No description provided for @newRegister.
  ///
  /// In tk, this message translates to:
  /// **'Täze kassa'**
  String get newRegister;

  /// No description provided for @totalCash.
  ///
  /// In tk, this message translates to:
  /// **'Jemi nagt pul'**
  String get totalCash;

  /// No description provided for @registerCount.
  ///
  /// In tk, this message translates to:
  /// **'{count} kassa'**
  String registerCount(String count);

  /// No description provided for @noRegisters.
  ///
  /// In tk, this message translates to:
  /// **'Entek kassa ýok'**
  String get noRegisters;

  /// No description provided for @noRegistersManager.
  ///
  /// In tk, this message translates to:
  /// **'Girdejileri we çykdajylary ýazmak üçin ilkinji kassaňyzy dörediň.'**
  String get noRegistersManager;

  /// No description provided for @noRegistersMember.
  ///
  /// In tk, this message translates to:
  /// **'Kassa rugsat bermegini dolandyryjyňyzdan haýyş ediň.'**
  String get noRegistersMember;

  /// No description provided for @noMatchingRegisters.
  ///
  /// In tk, this message translates to:
  /// **'Gabat gelýän kassa ýok'**
  String get noMatchingRegisters;

  /// No description provided for @tryAnotherSearch.
  ///
  /// In tk, this message translates to:
  /// **'Başga gözleg ýa-da süzgüç synap görüň.'**
  String get tryAnotherSearch;

  /// No description provided for @selectRegister.
  ///
  /// In tk, this message translates to:
  /// **'Kassany saýlaň'**
  String get selectRegister;

  /// No description provided for @selectRegisterHint.
  ///
  /// In tk, this message translates to:
  /// **'Onuň galyndysy we ýazgylary şu ýerde görüner.'**
  String get selectRegisterHint;

  /// No description provided for @cashOnHand.
  ///
  /// In tk, this message translates to:
  /// **'Kassadaky nagt pul'**
  String get cashOnHand;

  /// No description provided for @cashFullySettled.
  ///
  /// In tk, this message translates to:
  /// **'Kassadaky nagt pul · hemmesi hasaplaşyldy'**
  String get cashFullySettled;

  /// No description provided for @cashWithReal.
  ///
  /// In tk, this message translates to:
  /// **'Kassadaky nagt pul · hakyky {amount}'**
  String cashWithReal(String amount);

  /// No description provided for @realAmount.
  ///
  /// In tk, this message translates to:
  /// **'Hakyky mukdar'**
  String get realAmount;

  /// No description provided for @outstanding.
  ///
  /// In tk, this message translates to:
  /// **'Açyk galan'**
  String get outstanding;

  /// No description provided for @realAmountHelp.
  ///
  /// In tk, this message translates to:
  /// **'Nagt pul, üstüne bu kassa berilmeli bergiler, aýrylan bu kassanyň öz bergileri'**
  String get realAmountHelp;

  /// No description provided for @outstandingHelp.
  ///
  /// In tk, this message translates to:
  /// **'Hakyky mukdar bilen nagt pulyň tapawudy: açyk garaşylýan girdejiler we berlen karzlar, aýrylan alnan karzlar'**
  String get outstandingHelp;

  /// No description provided for @statusOpen.
  ///
  /// In tk, this message translates to:
  /// **'Açyk'**
  String get statusOpen;

  /// No description provided for @statusChecked.
  ///
  /// In tk, this message translates to:
  /// **'Barlanan'**
  String get statusChecked;

  /// No description provided for @statusClosed.
  ///
  /// In tk, this message translates to:
  /// **'Ýapyk'**
  String get statusClosed;

  /// No description provided for @ruleOpen.
  ///
  /// In tk, this message translates to:
  /// **'Ähli görnüşli ýazgylary goşup bolýar.'**
  String get ruleOpen;

  /// No description provided for @ruleChecked.
  ///
  /// In tk, this message translates to:
  /// **'Barlanan: diňe geçirimleri we hasaplaşyklary goşup bolýar.'**
  String get ruleChecked;

  /// No description provided for @ruleClosed.
  ///
  /// In tk, this message translates to:
  /// **'Ýapyk: diňe çykýan geçirimleri goşup bolýar.'**
  String get ruleClosed;

  /// No description provided for @registerNotAvailable.
  ///
  /// In tk, this message translates to:
  /// **'Kassa elýeterli däl'**
  String get registerNotAvailable;

  /// No description provided for @registerNotAvailableHint.
  ///
  /// In tk, this message translates to:
  /// **'Ol pozuldy ýa-da size oňa rugsat ýok.'**
  String get registerNotAvailableHint;

  /// No description provided for @backToRegisters.
  ///
  /// In tk, this message translates to:
  /// **'Kassalara dolan'**
  String get backToRegisters;

  /// No description provided for @addRecord.
  ///
  /// In tk, this message translates to:
  /// **'Ýazgy goş'**
  String get addRecord;

  /// No description provided for @recordSaved.
  ///
  /// In tk, this message translates to:
  /// **'Ýazgy ýatda saklandy'**
  String get recordSaved;

  /// No description provided for @records.
  ///
  /// In tk, this message translates to:
  /// **'Ýazgylar'**
  String get records;

  /// No description provided for @searchRecords.
  ///
  /// In tk, this message translates to:
  /// **'Bellik ýa-da adam boýunça gözle'**
  String get searchRecords;

  /// No description provided for @allTypes.
  ///
  /// In tk, this message translates to:
  /// **'Ähli görnüşler'**
  String get allTypes;

  /// No description provided for @unsettledOnly.
  ///
  /// In tk, this message translates to:
  /// **'Diňe hasaplaşylmadyk'**
  String get unsettledOnly;

  /// No description provided for @noRecords.
  ///
  /// In tk, this message translates to:
  /// **'Entek ýazgy ýok'**
  String get noRecords;

  /// No description provided for @noRecordsCanAdd.
  ///
  /// In tk, this message translates to:
  /// **'Girdeji, çykdajy ýa-da geçirim ýazmak üçin «Ýazgy goş» düwmesine basyň.'**
  String get noRecordsCanAdd;

  /// No description provided for @noRecordsViewOnly.
  ///
  /// In tk, this message translates to:
  /// **'Bu kassa goşulan ýazgylar şu ýerde görüner.'**
  String get noRecordsViewOnly;

  /// No description provided for @noMatchingRecords.
  ///
  /// In tk, this message translates to:
  /// **'Gabat gelýän ýazgy ýok'**
  String get noMatchingRecords;

  /// No description provided for @clearFilters.
  ///
  /// In tk, this message translates to:
  /// **'Süzgüçleri arassala'**
  String get clearFilters;

  /// No description provided for @loadMoreFailed.
  ///
  /// In tk, this message translates to:
  /// **'Ýüklenmedi. Gaýtadan synanyşyň'**
  String get loadMoreFailed;

  /// No description provided for @youCanModify.
  ///
  /// In tk, this message translates to:
  /// **'Bu kassa ýazgy goşup bilersiňiz'**
  String get youCanModify;

  /// No description provided for @youCanView.
  ///
  /// In tk, this message translates to:
  /// **'Bu kassany diňe görüp bilersiňiz'**
  String get youCanView;

  /// No description provided for @giveAccess.
  ///
  /// In tk, this message translates to:
  /// **'Rugsat ber'**
  String get giveAccess;

  /// No description provided for @membersCount.
  ///
  /// In tk, this message translates to:
  /// **'{count} agza'**
  String membersCount(String count);

  /// No description provided for @check.
  ///
  /// In tk, this message translates to:
  /// **'Barla'**
  String get check;

  /// No description provided for @close.
  ///
  /// In tk, this message translates to:
  /// **'Ýap'**
  String get close;

  /// No description provided for @pin.
  ///
  /// In tk, this message translates to:
  /// **'Ýokarda berkit'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In tk, this message translates to:
  /// **'Berkitmäni aýyr'**
  String get unpin;

  /// No description provided for @pinned.
  ///
  /// In tk, this message translates to:
  /// **'Ýokarda berkidilen'**
  String get pinned;

  /// No description provided for @registerPinned.
  ///
  /// In tk, this message translates to:
  /// **'Kassa sanawyň ýokarsynda berkidildi'**
  String get registerPinned;

  /// No description provided for @registerUnpinned.
  ///
  /// In tk, this message translates to:
  /// **'Kassa berkitmeden aýryldy'**
  String get registerUnpinned;

  /// No description provided for @delete.
  ///
  /// In tk, this message translates to:
  /// **'Poz'**
  String get delete;

  /// No description provided for @settleBeforeClosing.
  ///
  /// In tk, this message translates to:
  /// **'Ýapmazdan öň açyk galan {amount} hasaplaşyň.'**
  String settleBeforeClosing(String amount);

  /// No description provided for @checkTitle.
  ///
  /// In tk, this message translates to:
  /// **'«{name}» barlansynmy?'**
  String checkTitle(String name);

  /// No description provided for @checkMessage.
  ///
  /// In tk, this message translates to:
  /// **'Barlanandan soň diňe geçirimleri we hasaplaşyklary goşup bolar. Muny yzyna gaýtaryp bolmaýar.'**
  String get checkMessage;

  /// No description provided for @checkConfirm.
  ///
  /// In tk, this message translates to:
  /// **'Kassany barla'**
  String get checkConfirm;

  /// No description provided for @closeTitle.
  ///
  /// In tk, this message translates to:
  /// **'«{name}» ýapylsynmy?'**
  String closeTitle(String name);

  /// No description provided for @closeMessage.
  ///
  /// In tk, this message translates to:
  /// **'Ýapyk kassa diňe çykýan geçirimlere rugsat berýär. Muny yzyna gaýtaryp bolmaýar.'**
  String get closeMessage;

  /// No description provided for @closeConfirm.
  ///
  /// In tk, this message translates to:
  /// **'Kassany ýap'**
  String get closeConfirm;

  /// No description provided for @deleteTitle.
  ///
  /// In tk, this message translates to:
  /// **'«{name}» pozulsynmy?'**
  String deleteTitle(String name);

  /// No description provided for @deleteMessage.
  ///
  /// In tk, this message translates to:
  /// **'Kassa we onuň ähli ýazgylary, beýleki kassalara iberen geçirimleri bilen bilelikde, hemişelik pozular.'**
  String get deleteMessage;

  /// No description provided for @registerChecked.
  ///
  /// In tk, this message translates to:
  /// **'Kassa barlandy'**
  String get registerChecked;

  /// No description provided for @registerClosed.
  ///
  /// In tk, this message translates to:
  /// **'Kassa ýapyldy'**
  String get registerClosed;

  /// No description provided for @registerDeleted.
  ///
  /// In tk, this message translates to:
  /// **'Kassa pozuldy'**
  String get registerDeleted;

  /// No description provided for @accessUpdated.
  ///
  /// In tk, this message translates to:
  /// **'Rugsatlar täzelendi'**
  String get accessUpdated;

  /// No description provided for @name.
  ///
  /// In tk, this message translates to:
  /// **'Ady'**
  String get name;

  /// No description provided for @registerNameHint.
  ///
  /// In tk, this message translates to:
  /// **'meselem, Esasy kassa, Dükan 2, Seýf'**
  String get registerNameHint;

  /// No description provided for @enterName.
  ///
  /// In tk, this message translates to:
  /// **'Adyny giriziň'**
  String get enterName;

  /// No description provided for @registerNameTaken.
  ///
  /// In tk, this message translates to:
  /// **'Bu at bilen kassa eýýäm bar'**
  String get registerNameTaken;

  /// No description provided for @teamAccess.
  ///
  /// In tk, this message translates to:
  /// **'Agzalaryň rugsady'**
  String get teamAccess;

  /// No description provided for @createRegister.
  ///
  /// In tk, this message translates to:
  /// **'Kassa döret'**
  String get createRegister;

  /// No description provided for @accessView.
  ///
  /// In tk, this message translates to:
  /// **'Görmek'**
  String get accessView;

  /// No description provided for @accessModify.
  ///
  /// In tk, this message translates to:
  /// **'Üýtgetmek'**
  String get accessModify;

  /// No description provided for @noTeamMembers.
  ///
  /// In tk, this message translates to:
  /// **'Entek agza ýok. Agzalary «Agzalar» bölüminde goşuň, soňra şu ýerde rugsat beriň.'**
  String get noTeamMembers;

  /// No description provided for @usernameInactive.
  ///
  /// In tk, this message translates to:
  /// **'@{username} · işjeň däl'**
  String usernameInactive(String username);

  /// No description provided for @accessTitle.
  ///
  /// In tk, this message translates to:
  /// **'«{name}» kassasyna kim girip biler'**
  String accessTitle(String name);

  /// No description provided for @accessSubtitle.
  ///
  /// In tk, this message translates to:
  /// **'Görmek: galyndyny we ýazgylary görýär. Üýtgetmek: ýazgy hem goşup bilýär.'**
  String get accessSubtitle;

  /// No description provided for @saveAccess.
  ///
  /// In tk, this message translates to:
  /// **'Rugsatlary ýatda sakla'**
  String get saveAccess;

  /// No description provided for @typeIncome.
  ///
  /// In tk, this message translates to:
  /// **'Girdeji'**
  String get typeIncome;

  /// No description provided for @typeIncomeHint.
  ///
  /// In tk, this message translates to:
  /// **'Alnan pul'**
  String get typeIncomeHint;

  /// No description provided for @typeExpense.
  ///
  /// In tk, this message translates to:
  /// **'Çykdajy'**
  String get typeExpense;

  /// No description provided for @typeExpenseHint.
  ///
  /// In tk, this message translates to:
  /// **'Harçlanan pul'**
  String get typeExpenseHint;

  /// No description provided for @typeTransferOut.
  ///
  /// In tk, this message translates to:
  /// **'Geçirim'**
  String get typeTransferOut;

  /// No description provided for @typeTransferOutHint.
  ///
  /// In tk, this message translates to:
  /// **'Puly başga kassa geçirmek'**
  String get typeTransferOutHint;

  /// No description provided for @typeTransferIn.
  ///
  /// In tk, this message translates to:
  /// **'Gelen geçirim'**
  String get typeTransferIn;

  /// No description provided for @typeTransferInHint.
  ///
  /// In tk, this message translates to:
  /// **'Başga kassadan geçirilen pul'**
  String get typeTransferInHint;

  /// No description provided for @typeAccrualIncome.
  ///
  /// In tk, this message translates to:
  /// **'Garaşylýan girdeji'**
  String get typeAccrualIncome;

  /// No description provided for @typeAccrualIncomeHint.
  ///
  /// In tk, this message translates to:
  /// **'Gazanylan, ýöne entek alynmadyk pul'**
  String get typeAccrualIncomeHint;

  /// No description provided for @typeReceivableOpened.
  ///
  /// In tk, this message translates to:
  /// **'Berlen karz'**
  String get typeReceivableOpened;

  /// No description provided for @typeReceivableOpenedHint.
  ///
  /// In tk, this message translates to:
  /// **'Yzyna gaýtarylmaly berlen pul'**
  String get typeReceivableOpenedHint;

  /// No description provided for @typePayableOpened.
  ///
  /// In tk, this message translates to:
  /// **'Alnan karz'**
  String get typePayableOpened;

  /// No description provided for @typePayableOpenedHint.
  ///
  /// In tk, this message translates to:
  /// **'Yzyna tölenmeli karz alnan pul'**
  String get typePayableOpenedHint;

  /// No description provided for @typeAccrualIncomeSettled.
  ///
  /// In tk, this message translates to:
  /// **'Girdeji alyndy'**
  String get typeAccrualIncomeSettled;

  /// No description provided for @typeAccrualIncomeSettledHint.
  ///
  /// In tk, this message translates to:
  /// **'Garaşylýan girdeji alyndy'**
  String get typeAccrualIncomeSettledHint;

  /// No description provided for @typeReceivableSettled.
  ///
  /// In tk, this message translates to:
  /// **'Karz gaýtaryldy'**
  String get typeReceivableSettled;

  /// No description provided for @typeReceivableSettledHint.
  ///
  /// In tk, this message translates to:
  /// **'Berlen karz yzyna alyndy'**
  String get typeReceivableSettledHint;

  /// No description provided for @typePayableSettled.
  ///
  /// In tk, this message translates to:
  /// **'Karz tölendi'**
  String get typePayableSettled;

  /// No description provided for @typePayableSettledHint.
  ///
  /// In tk, this message translates to:
  /// **'Alnan karz yzyna tölendi'**
  String get typePayableSettledHint;

  /// No description provided for @groupCash.
  ///
  /// In tk, this message translates to:
  /// **'Nagt pul'**
  String get groupCash;

  /// No description provided for @groupTransfer.
  ///
  /// In tk, this message translates to:
  /// **'Geçirim'**
  String get groupTransfer;

  /// No description provided for @groupObligation.
  ///
  /// In tk, this message translates to:
  /// **'Borçnama açmak'**
  String get groupObligation;

  /// No description provided for @groupSettlement.
  ///
  /// In tk, this message translates to:
  /// **'Borçnamany ýapmak'**
  String get groupSettlement;

  /// No description provided for @transferTo.
  ///
  /// In tk, this message translates to:
  /// **'«{name}» kassasyna'**
  String transferTo(String name);

  /// No description provided for @transferFrom.
  ///
  /// In tk, this message translates to:
  /// **'«{name}» kassasyndan'**
  String transferFrom(String name);

  /// No description provided for @anotherRegister.
  ///
  /// In tk, this message translates to:
  /// **'başga kassa'**
  String get anotherRegister;

  /// No description provided for @settled.
  ///
  /// In tk, this message translates to:
  /// **'Hasaplaşyldy'**
  String get settled;

  /// No description provided for @amountLeft.
  ///
  /// In tk, this message translates to:
  /// **'{amount} galdy'**
  String amountLeft(String amount);

  /// No description provided for @amountLeftDue.
  ///
  /// In tk, this message translates to:
  /// **'{amount} galdy · möhleti {date}'**
  String amountLeftDue(String amount, String date);

  /// No description provided for @amountLeftOverdue.
  ///
  /// In tk, this message translates to:
  /// **'{amount} galdy · möhleti {date} geçdi'**
  String amountLeftOverdue(String amount, String date);

  /// No description provided for @today.
  ///
  /// In tk, this message translates to:
  /// **'Şu gün'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In tk, this message translates to:
  /// **'Düýn'**
  String get yesterday;

  /// No description provided for @detailNote.
  ///
  /// In tk, this message translates to:
  /// **'Bellik'**
  String get detailNote;

  /// No description provided for @detailRecorded.
  ///
  /// In tk, this message translates to:
  /// **'Senesi'**
  String get detailRecorded;

  /// No description provided for @detailBy.
  ///
  /// In tk, this message translates to:
  /// **'Kim'**
  String get detailBy;

  /// No description provided for @detailTo.
  ///
  /// In tk, this message translates to:
  /// **'Nirä'**
  String get detailTo;

  /// No description provided for @detailFrom.
  ///
  /// In tk, this message translates to:
  /// **'Nireden'**
  String get detailFrom;

  /// No description provided for @detailDue.
  ///
  /// In tk, this message translates to:
  /// **'Möhleti'**
  String get detailDue;

  /// No description provided for @detailSettles.
  ///
  /// In tk, this message translates to:
  /// **'Degişli'**
  String get detailSettles;

  /// No description provided for @payments.
  ///
  /// In tk, this message translates to:
  /// **'Tölegler ({count})'**
  String payments(String count);

  /// No description provided for @fullySettled.
  ///
  /// In tk, this message translates to:
  /// **'Doly hasaplaşyldy'**
  String get fullySettled;

  /// No description provided for @settledAndLeft.
  ///
  /// In tk, this message translates to:
  /// **'{settled} hasaplaşyldy · {left} galdy'**
  String settledAndLeft(String settled, String left);

  /// No description provided for @addARecord.
  ///
  /// In tk, this message translates to:
  /// **'Ýazgy goş'**
  String get addARecord;

  /// No description provided for @typesWhenChecked.
  ///
  /// In tk, this message translates to:
  /// **'Bu kassa barlanan: diňe geçirimleri we hasaplaşyklary goşup bolýar.'**
  String get typesWhenChecked;

  /// No description provided for @typesWhenClosed.
  ///
  /// In tk, this message translates to:
  /// **'Bu kassa ýapyk: diňe çykýan geçirimleri goşup bolýar.'**
  String get typesWhenClosed;

  /// No description provided for @changeType.
  ///
  /// In tk, this message translates to:
  /// **'Görnüşi üýtget'**
  String get changeType;

  /// No description provided for @saveRecord.
  ///
  /// In tk, this message translates to:
  /// **'Ýazgyny ýatda sakla'**
  String get saveRecord;

  /// No description provided for @amount.
  ///
  /// In tk, this message translates to:
  /// **'Möçber'**
  String get amount;

  /// No description provided for @availableCash.
  ///
  /// In tk, this message translates to:
  /// **'Kassada {amount} bar'**
  String availableCash(String amount);

  /// No description provided for @enterAmount.
  ///
  /// In tk, this message translates to:
  /// **'Noldan uly möçber giriziň'**
  String get enterAmount;

  /// No description provided for @onlyCash.
  ///
  /// In tk, this message translates to:
  /// **'Kassada diňe {amount} bar'**
  String onlyCash(String amount);

  /// No description provided for @onlyLeftToSettle.
  ///
  /// In tk, this message translates to:
  /// **'Hasaplaşmak üçin diňe {amount} galdy'**
  String onlyLeftToSettle(String amount);

  /// No description provided for @dueDate.
  ///
  /// In tk, this message translates to:
  /// **'Möhleti'**
  String get dueDate;

  /// No description provided for @chooseDate.
  ///
  /// In tk, this message translates to:
  /// **'Senäni saýlaň'**
  String get chooseDate;

  /// No description provided for @noteLabel.
  ///
  /// In tk, this message translates to:
  /// **'Bellik'**
  String get noteLabel;

  /// No description provided for @errNoteRequired.
  ///
  /// In tk, this message translates to:
  /// **'Bellik ýazyň'**
  String get errNoteRequired;

  /// No description provided for @noteHint.
  ///
  /// In tk, this message translates to:
  /// **'Näme üçin?'**
  String get noteHint;

  /// No description provided for @toRegister.
  ///
  /// In tk, this message translates to:
  /// **'Haýsy kassa'**
  String get toRegister;

  /// No description provided for @loadingRegisters.
  ///
  /// In tk, this message translates to:
  /// **'Kassalar ýüklenýär…'**
  String get loadingRegisters;

  /// No description provided for @noTransferTargets.
  ///
  /// In tk, this message translates to:
  /// **'Geçirim edip boljak başga açyk kassa ýok'**
  String get noTransferTargets;

  /// No description provided for @chooseDestination.
  ///
  /// In tk, this message translates to:
  /// **'Pul geçiriljek kassany saýlaň'**
  String get chooseDestination;

  /// No description provided for @whichObligation.
  ///
  /// In tk, this message translates to:
  /// **'Haýsy borçnama'**
  String get whichObligation;

  /// No description provided for @nothingToSettle.
  ///
  /// In tk, this message translates to:
  /// **'Bu kassada hasaplaşylmaly zat ýok'**
  String get nothingToSettle;

  /// No description provided for @chooseObligation.
  ///
  /// In tk, this message translates to:
  /// **'Haýsy borçnamanyň hasaplaşylýandygyny saýlaň'**
  String get chooseObligation;

  /// No description provided for @dueOn.
  ///
  /// In tk, this message translates to:
  /// **'möhleti {date}'**
  String dueOn(String date);

  /// No description provided for @oldMoneyButton.
  ///
  /// In tk, this message translates to:
  /// **'Köne puldan geçir'**
  String get oldMoneyButton;

  /// No description provided for @oldMoneyTitle.
  ///
  /// In tk, this message translates to:
  /// **'Köne puldan täze pula'**
  String get oldMoneyTitle;

  /// No description provided for @oldMoneyRate.
  ///
  /// In tk, this message translates to:
  /// **'5 000 köne manat = 1 TMT'**
  String get oldMoneyRate;

  /// No description provided for @oldMoneyLabel.
  ///
  /// In tk, this message translates to:
  /// **'Köne pul'**
  String get oldMoneyLabel;

  /// No description provided for @oldMoneySuffix.
  ///
  /// In tk, this message translates to:
  /// **'köne manat'**
  String get oldMoneySuffix;

  /// No description provided for @oldMoneyResult.
  ///
  /// In tk, this message translates to:
  /// **'Täze pulda'**
  String get oldMoneyResult;

  /// No description provided for @oldMoneyEmpty.
  ///
  /// In tk, this message translates to:
  /// **'Köne pul möçberini giriziň'**
  String get oldMoneyEmpty;

  /// No description provided for @oldMoneyUse.
  ///
  /// In tk, this message translates to:
  /// **'Ulan'**
  String get oldMoneyUse;

  /// No description provided for @membersTitle.
  ///
  /// In tk, this message translates to:
  /// **'Agzalar'**
  String get membersTitle;

  /// No description provided for @addMember.
  ///
  /// In tk, this message translates to:
  /// **'Agza goş'**
  String get addMember;

  /// No description provided for @memberAdded.
  ///
  /// In tk, this message translates to:
  /// **'{name} goşuldy'**
  String memberAdded(String name);

  /// No description provided for @membersHint.
  ///
  /// In tk, this message translates to:
  /// **'Kassirleriňizi şu ýerde goşuň, soňra olara kassalara rugsat beriň. Olar kompaniýanyň ady, öz ulanyjy ady we açar sözi bilen girýärler.'**
  String get membersHint;

  /// No description provided for @roleManager.
  ///
  /// In tk, this message translates to:
  /// **'Dolandyryjy'**
  String get roleManager;

  /// No description provided for @roleMember.
  ///
  /// In tk, this message translates to:
  /// **'Agza'**
  String get roleMember;

  /// No description provided for @you.
  ///
  /// In tk, this message translates to:
  /// **'Siz'**
  String get you;

  /// No description provided for @inactive.
  ///
  /// In tk, this message translates to:
  /// **'Işjeň däl'**
  String get inactive;

  /// No description provided for @addMemberSubtitle.
  ///
  /// In tk, this message translates to:
  /// **'Olar siziň kompaniýaňyzyň ady we şu maglumatlar bilen girerler.'**
  String get addMemberSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In tk, this message translates to:
  /// **'Täze açar sözi'**
  String get newPassword;

  /// No description provided for @newPasswordHelper.
  ///
  /// In tk, this message translates to:
  /// **'Täze açar sözüni oňa ýüzbe-ýüz aýdyň'**
  String get newPasswordHelper;

  /// No description provided for @changePassword.
  ///
  /// In tk, this message translates to:
  /// **'Açar sözüni üýtget'**
  String get changePassword;

  /// No description provided for @passwordChanged.
  ///
  /// In tk, this message translates to:
  /// **'{name} üçin açar sözi üýtgedildi'**
  String passwordChanged(String name);

  /// No description provided for @access.
  ///
  /// In tk, this message translates to:
  /// **'Rugsat'**
  String get access;

  /// No description provided for @active.
  ///
  /// In tk, this message translates to:
  /// **'Işjeň'**
  String get active;

  /// No description provided for @activeOn.
  ///
  /// In tk, this message translates to:
  /// **'Ulgama girip, öz kassalary bilen işläp bilýär'**
  String get activeOn;

  /// No description provided for @activeOff.
  ///
  /// In tk, this message translates to:
  /// **'Ulgama girip bilmeýär'**
  String get activeOff;

  /// No description provided for @deactivateTitle.
  ///
  /// In tk, this message translates to:
  /// **'{name} işjeň däl edilsinmi?'**
  String deactivateTitle(String name);

  /// No description provided for @deactivateMessage.
  ///
  /// In tk, this message translates to:
  /// **'Ol derrew ulgamdan çykarylar we siz ony täzeden işjeňleşdirýänçäňiz girip bilmez. Onuň ýazgylary saklanýar.'**
  String get deactivateMessage;

  /// No description provided for @deactivate.
  ///
  /// In tk, this message translates to:
  /// **'Işjeň däl et'**
  String get deactivate;

  /// No description provided for @memberActivated.
  ///
  /// In tk, this message translates to:
  /// **'{name} işjeňleşdirildi'**
  String memberActivated(String name);

  /// No description provided for @memberDeactivated.
  ///
  /// In tk, this message translates to:
  /// **'{name} işjeň däl edildi'**
  String memberDeactivated(String name);

  /// No description provided for @accountTitle.
  ///
  /// In tk, this message translates to:
  /// **'Profil'**
  String get accountTitle;

  /// No description provided for @company.
  ///
  /// In tk, this message translates to:
  /// **'Kompaniýa'**
  String get company;

  /// No description provided for @sessionValidUntil.
  ///
  /// In tk, this message translates to:
  /// **'Sessiýanyň möhleti'**
  String get sessionValidUntil;

  /// No description provided for @theme.
  ///
  /// In tk, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In tk, this message translates to:
  /// **'Ulgam'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In tk, this message translates to:
  /// **'Ýagty'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In tk, this message translates to:
  /// **'Garaňky'**
  String get themeDark;

  /// No description provided for @themeSystemHint.
  ///
  /// In tk, this message translates to:
  /// **'Telefonyňyzyň ýa-da kompýuteriňiziň sazlamasy boýunça'**
  String get themeSystemHint;

  /// No description provided for @logOut.
  ///
  /// In tk, this message translates to:
  /// **'Ulgamdan çyk'**
  String get logOut;

  /// No description provided for @logOutTitle.
  ///
  /// In tk, this message translates to:
  /// **'Ulgamdan çykmalymy?'**
  String get logOutTitle;

  /// No description provided for @logOutMessage.
  ///
  /// In tk, this message translates to:
  /// **'Täzeden girmek üçin açar sözüňiz gerek bolar.'**
  String get logOutMessage;

  /// No description provided for @errNetwork.
  ///
  /// In tk, this message translates to:
  /// **'Serwere birigip bolmady. Internet birikmäňizi barlaň.'**
  String get errNetwork;

  /// No description provided for @errTimeout.
  ///
  /// In tk, this message translates to:
  /// **'Serwer gaty uzak jogap berdi. Gaýtadan synanyşyň.'**
  String get errTimeout;

  /// No description provided for @errCertificate.
  ///
  /// In tk, this message translates to:
  /// **'Serweriň howpsuzlyk şahadatnamasy nädogry.'**
  String get errCertificate;

  /// No description provided for @errBadResponse.
  ///
  /// In tk, this message translates to:
  /// **'Serwerden garaşylmadyk jogap geldi. Gaýtadan synanyşyň.'**
  String get errBadResponse;

  /// No description provided for @errServer.
  ///
  /// In tk, this message translates to:
  /// **'Serwerde näsazlyk ýüze çykdy. Soňrak synanyşyň.'**
  String get errServer;

  /// No description provided for @errUnexpected.
  ///
  /// In tk, this message translates to:
  /// **'Garaşylmadyk ýalňyşlyk ýüze çykdy.'**
  String get errUnexpected;

  /// No description provided for @errUnauthorized.
  ///
  /// In tk, this message translates to:
  /// **'Sessiýaňyzyň möhleti gutardy. Täzeden giriň.'**
  String get errUnauthorized;

  /// No description provided for @errForbidden.
  ///
  /// In tk, this message translates to:
  /// **'Bu hereket üçin rugsadyňyz ýok.'**
  String get errForbidden;

  /// No description provided for @errNotFound.
  ///
  /// In tk, this message translates to:
  /// **'Tapylmady ýa-da size rugsat ýok.'**
  String get errNotFound;

  /// No description provided for @errInsufficientFunds.
  ///
  /// In tk, this message translates to:
  /// **'Kassada ýeterlik nagt pul ýok.'**
  String get errInsufficientFunds;

  /// No description provided for @errSettlementTooLarge.
  ///
  /// In tk, this message translates to:
  /// **'Hasaplaşyk möçberi galan bergiden köp.'**
  String get errSettlementTooLarge;

  /// No description provided for @errSettlementMismatch.
  ///
  /// In tk, this message translates to:
  /// **'Hasaplaşygyň görnüşi borçnama gabat gelmeýär.'**
  String get errSettlementMismatch;

  /// No description provided for @errRecordNotAllowed.
  ///
  /// In tk, this message translates to:
  /// **'Kassanyň häzirki ýagdaýynda bu ýazgyny goşup bolmaýar.'**
  String get errRecordNotAllowed;

  /// No description provided for @errDestinationUnavailable.
  ///
  /// In tk, this message translates to:
  /// **'Geçirim edilýän kassa elýeterli däl ýa-da oňa üýtgetmek rugsadyňyz ýok.'**
  String get errDestinationUnavailable;

  /// No description provided for @errMustBeChecked.
  ///
  /// In tk, this message translates to:
  /// **'Kassany ýapmazdan öň ony barlamaly.'**
  String get errMustBeChecked;

  /// No description provided for @errAmountsMustMatch.
  ///
  /// In tk, this message translates to:
  /// **'Ýapmak üçin nagt pul bilen hakyky mukdar deň bolmaly.'**
  String get errAmountsMustMatch;

  /// No description provided for @errNotSettled.
  ///
  /// In tk, this message translates to:
  /// **'Ýapmazdan öň ähli borçnamalary hasaplaşmaly.'**
  String get errNotSettled;

  /// No description provided for @errMustBeClosed.
  ///
  /// In tk, this message translates to:
  /// **'Kassany pozmazdan öň ony ýapmaly.'**
  String get errMustBeClosed;

  /// No description provided for @errManagerCannotDeactivate.
  ///
  /// In tk, this message translates to:
  /// **'Kompaniýanyň dolandyryjysyny işjeň däl edip bolmaýar.'**
  String get errManagerCannotDeactivate;

  /// No description provided for @errUsernameTaken.
  ///
  /// In tk, this message translates to:
  /// **'Bu ulanyjy ady eýýäm ulanylýar'**
  String get errUsernameTaken;

  /// No description provided for @errDeadlineRequired.
  ///
  /// In tk, this message translates to:
  /// **'Möhleti görkeziň'**
  String get errDeadlineRequired;

  /// No description provided for @errInvalidRequest.
  ///
  /// In tk, this message translates to:
  /// **'Maglumatlar nädogry: {details}'**
  String errInvalidRequest(String details);

  /// No description provided for @errConflict.
  ///
  /// In tk, this message translates to:
  /// **'Amaly ýerine ýetirip bolmady: {details}'**
  String errConflict(String details);

  /// No description provided for @realShort.
  ///
  /// In tk, this message translates to:
  /// **'hakyky {amount}'**
  String realShort(String amount);

  /// No description provided for @open.
  ///
  /// In tk, this message translates to:
  /// **'Aç'**
  String get open;

  /// No description provided for @more.
  ///
  /// In tk, this message translates to:
  /// **'Başga hereketler'**
  String get more;

  /// No description provided for @createdOn.
  ///
  /// In tk, this message translates to:
  /// **'Döredilen senesi: {date}'**
  String createdOn(String date);

  /// No description provided for @colRecord.
  ///
  /// In tk, this message translates to:
  /// **'Ýazgy'**
  String get colRecord;

  /// No description provided for @colMember.
  ///
  /// In tk, this message translates to:
  /// **'Agza'**
  String get colMember;

  /// No description provided for @colTime.
  ///
  /// In tk, this message translates to:
  /// **'Wagt'**
  String get colTime;

  /// No description provided for @colAmount.
  ///
  /// In tk, this message translates to:
  /// **'Mukdar'**
  String get colAmount;

  /// No description provided for @dayRecordCount.
  ///
  /// In tk, this message translates to:
  /// **'{count} ýazgy'**
  String dayRecordCount(String count);

  /// No description provided for @membersSubtitle.
  ///
  /// In tk, this message translates to:
  /// **'Kassalara girip bilýän adamlar'**
  String get membersSubtitle;

  /// No description provided for @syncTitle.
  ///
  /// In tk, this message translates to:
  /// **'Sinhronlama'**
  String get syncTitle;

  /// No description provided for @syncOffline.
  ///
  /// In tk, this message translates to:
  /// **'Internet ýok'**
  String get syncOffline;

  /// No description provided for @syncOfflineWaiting.
  ///
  /// In tk, this message translates to:
  /// **'Internet ýok · {count} garaşýar'**
  String syncOfflineWaiting(String count);

  /// No description provided for @syncSyncing.
  ///
  /// In tk, this message translates to:
  /// **'Sinhronlanýar…'**
  String get syncSyncing;

  /// No description provided for @syncUpToDate.
  ///
  /// In tk, this message translates to:
  /// **'Hemmesi sinhronlandy'**
  String get syncUpToDate;

  /// No description provided for @syncPending.
  ///
  /// In tk, this message translates to:
  /// **'{count} üýtgeşme ugradylýar'**
  String syncPending(String count);

  /// No description provided for @syncRejected.
  ///
  /// In tk, this message translates to:
  /// **'{count} üýtgeşme kabul edilmedi'**
  String syncRejected(String count);

  /// No description provided for @syncError.
  ///
  /// In tk, this message translates to:
  /// **'Sinhronlamak başartmady'**
  String get syncError;

  /// No description provided for @syncLastAt.
  ///
  /// In tk, this message translates to:
  /// **'Soňky sinhronlama: {time}'**
  String syncLastAt(String time);

  /// No description provided for @syncNever.
  ///
  /// In tk, this message translates to:
  /// **'Entek sinhronlanmady'**
  String get syncNever;

  /// No description provided for @syncNow.
  ///
  /// In tk, this message translates to:
  /// **'Häzir sinhronla'**
  String get syncNow;

  /// No description provided for @syncOfflineHint.
  ///
  /// In tk, this message translates to:
  /// **'Işläp bilersiňiz: üýtgeşmeler enjamda saklanýar we internet gelende özbaşdak ugradylar.'**
  String get syncOfflineHint;

  /// No description provided for @syncPendingTitle.
  ///
  /// In tk, this message translates to:
  /// **'Ugradylmadyk üýtgeşmeler'**
  String get syncPendingTitle;

  /// No description provided for @syncRejectedTitle.
  ///
  /// In tk, this message translates to:
  /// **'Serwer kabul etmedi'**
  String get syncRejectedTitle;

  /// No description provided for @syncRejectedHint.
  ///
  /// In tk, this message translates to:
  /// **'Bu üýtgeşmeler ugradylmady. Aýyryň we gerek bolsa täzeden giriziň.'**
  String get syncRejectedHint;

  /// No description provided for @syncDiscard.
  ///
  /// In tk, this message translates to:
  /// **'Aýyr'**
  String get syncDiscard;

  /// No description provided for @syncNothingWaiting.
  ///
  /// In tk, this message translates to:
  /// **'Ugradylmadyk üýtgeşme ýok.'**
  String get syncNothingWaiting;

  /// No description provided for @pendingBadge.
  ///
  /// In tk, this message translates to:
  /// **'Ugradylmady'**
  String get pendingBadge;

  /// No description provided for @savedOffline.
  ///
  /// In tk, this message translates to:
  /// **'Enjamda saklandy — internet gelende ugradylar'**
  String get savedOffline;

  /// No description provided for @noDataOffline.
  ///
  /// In tk, this message translates to:
  /// **'Maglumat entek ýok'**
  String get noDataOffline;

  /// No description provided for @noDataOfflineHint.
  ///
  /// In tk, this message translates to:
  /// **'Ilkinji gezek maglumatlary almak üçin internete birikiň. Soňra internetsiz hem işläp bilersiňiz.'**
  String get noDataOfflineHint;

  /// No description provided for @logOutUnsent.
  ///
  /// In tk, this message translates to:
  /// **'Ugradylmadyk {count} üýtgeşme bar. Häzir çyksaňyz, olar ýiter.'**
  String logOutUnsent(String count);

  /// No description provided for @opRecordCreate.
  ///
  /// In tk, this message translates to:
  /// **'{type} · {amount}'**
  String opRecordCreate(String type, String amount);

  /// No description provided for @opRegisterCreate.
  ///
  /// In tk, this message translates to:
  /// **'Täze kassa: {name}'**
  String opRegisterCreate(String name);

  /// No description provided for @opRegisterCheck.
  ///
  /// In tk, this message translates to:
  /// **'Barlamak: {name}'**
  String opRegisterCheck(String name);

  /// No description provided for @opRegisterClose.
  ///
  /// In tk, this message translates to:
  /// **'Ýapmak: {name}'**
  String opRegisterClose(String name);

  /// No description provided for @opRegisterDelete.
  ///
  /// In tk, this message translates to:
  /// **'Pozmak: {name}'**
  String opRegisterDelete(String name);

  /// No description provided for @opRegisterAccess.
  ///
  /// In tk, this message translates to:
  /// **'Rugsatlar: {name}'**
  String opRegisterAccess(String name);

  /// No description provided for @needsInternet.
  ///
  /// In tk, this message translates to:
  /// **'Munuň üçin internet gerek.'**
  String get needsInternet;

  /// No description provided for @serverTitle.
  ///
  /// In tk, this message translates to:
  /// **'Serwer'**
  String get serverTitle;

  /// No description provided for @serverSubtitle.
  ///
  /// In tk, this message translates to:
  /// **'Programmanyň haýsy serwere ýüz tutýandygy.'**
  String get serverSubtitle;

  /// No description provided for @serverApiUrl.
  ///
  /// In tk, this message translates to:
  /// **'Esasy serwer'**
  String get serverApiUrl;

  /// No description provided for @serverApiUrlHelp.
  ///
  /// In tk, this message translates to:
  /// **'Giriş, kassalar, ýazgylar we agzalar şu salga gidýär.'**
  String get serverApiUrlHelp;

  /// No description provided for @serverSyncUrl.
  ///
  /// In tk, this message translates to:
  /// **'Sinhronlamak üçin serwer'**
  String get serverSyncUrl;

  /// No description provided for @serverSyncUrlHelp.
  ///
  /// In tk, this message translates to:
  /// **'Diňe «Serwerleri sinhronla» düwmesi şu salga ýüz tutýar. Boş goýsaňyz, düwme görünmeýär.'**
  String get serverSyncUrlHelp;

  /// No description provided for @serverUrlHint.
  ///
  /// In tk, this message translates to:
  /// **'Mysal: http://192.168.1.158:8083'**
  String get serverUrlHint;

  /// No description provided for @serverInvalidUrl.
  ///
  /// In tk, this message translates to:
  /// **'Dogry salga ýazyň, mysal: http://192.168.1.158:8083'**
  String get serverInvalidUrl;

  /// No description provided for @serverUseDefault.
  ///
  /// In tk, this message translates to:
  /// **'Adaty serweri ulan'**
  String get serverUseDefault;

  /// No description provided for @serverSaved.
  ///
  /// In tk, this message translates to:
  /// **'Serwer sazlamalary ýatda saklandy'**
  String get serverSaved;

  /// No description provided for @serverNotSet.
  ///
  /// In tk, this message translates to:
  /// **'Goýulmady'**
  String get serverNotSet;

  /// No description provided for @serverEdit.
  ///
  /// In tk, this message translates to:
  /// **'Üýtget'**
  String get serverEdit;

  /// No description provided for @serverSave.
  ///
  /// In tk, this message translates to:
  /// **'Ýatda sakla'**
  String get serverSave;

  /// No description provided for @serverSyncNow.
  ///
  /// In tk, this message translates to:
  /// **'Serwerleri sinhronla'**
  String get serverSyncNow;

  /// No description provided for @serverSyncRunning.
  ///
  /// In tk, this message translates to:
  /// **'Serwerler sinhronlanýar…'**
  String get serverSyncRunning;

  /// No description provided for @serverSyncDone.
  ///
  /// In tk, this message translates to:
  /// **'Serwerler sinhronlandy'**
  String get serverSyncDone;

  /// No description provided for @serverSyncHint.
  ///
  /// In tk, this message translates to:
  /// **'Ýerli serwer bulut serweri bilen maglumat çalşýar, soňra täze maglumatlar şu ýere ýüklenýär.'**
  String get serverSyncHint;

  /// No description provided for @errWrongServer.
  ///
  /// In tk, this message translates to:
  /// **'Bu kompaniýanyň maglumatlary başga serwerde üýtgedilýär. Şol serwere birikiň.'**
  String get errWrongServer;

  /// No description provided for @syncLoginTitle.
  ///
  /// In tk, this message translates to:
  /// **'Sinhron serwerine giriş'**
  String get syncLoginTitle;

  /// No description provided for @syncLoginMessage.
  ///
  /// In tk, this message translates to:
  /// **'{server} serweriniň öz girişi bar. @{username} üçin açar sözüni giriziň.'**
  String syncLoginMessage(String server, String username);

  /// No description provided for @syncLoginButton.
  ///
  /// In tk, this message translates to:
  /// **'Gir we sinhronla'**
  String get syncLoginButton;

  /// No description provided for @serverChangeTitle.
  ///
  /// In tk, this message translates to:
  /// **'Serwer üýtgeýär'**
  String get serverChangeTitle;

  /// No description provided for @serverChangeMessage.
  ///
  /// In tk, this message translates to:
  /// **'Täze serwere geçmek üçin hasapdan çykyp, gaýtadan girmeli. Bu enjamdaky maglumatlar täzeden ýüklener.'**
  String get serverChangeMessage;

  /// No description provided for @serverChangeUnsent.
  ///
  /// In tk, this message translates to:
  /// **'Ugradylmadyk {count} üýtgeşme bar. Serweri häzir üýtgetseňiz, olar ýiter.'**
  String serverChangeUnsent(String count);

  /// No description provided for @serverChangeConfirm.
  ///
  /// In tk, this message translates to:
  /// **'Çyk we üýtget'**
  String get serverChangeConfirm;

  /// No description provided for @periodAll.
  ///
  /// In tk, this message translates to:
  /// **'Ähli wagt'**
  String get periodAll;

  /// No description provided for @periodToday.
  ///
  /// In tk, this message translates to:
  /// **'Şu gün'**
  String get periodToday;

  /// No description provided for @periodWeek.
  ///
  /// In tk, this message translates to:
  /// **'Şu hepde'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In tk, this message translates to:
  /// **'Şu aý'**
  String get periodMonth;

  /// No description provided for @periodCustom.
  ///
  /// In tk, this message translates to:
  /// **'Senäni saýla…'**
  String get periodCustom;

  /// No description provided for @allMembers.
  ///
  /// In tk, this message translates to:
  /// **'Ähli agzalar'**
  String get allMembers;

  /// No description provided for @totalsIn.
  ///
  /// In tk, this message translates to:
  /// **'Girdi {amount}'**
  String totalsIn(String amount);

  /// No description provided for @totalsOut.
  ///
  /// In tk, this message translates to:
  /// **'Çykdy {amount}'**
  String totalsOut(String amount);

  /// No description provided for @overviewTitle.
  ///
  /// In tk, this message translates to:
  /// **'Umumy syn'**
  String get overviewTitle;

  /// No description provided for @overviewHint.
  ///
  /// In tk, this message translates to:
  /// **'Jikme-jiklikler üçin çepden kassa saýlaň.'**
  String get overviewHint;

  /// No description provided for @dueTitle.
  ///
  /// In tk, this message translates to:
  /// **'Möhletli bergiler'**
  String get dueTitle;

  /// No description provided for @dueEmpty.
  ///
  /// In tk, this message translates to:
  /// **'Ýakyn {days} günde möhleti ýetýän bergi ýok.'**
  String dueEmpty(String days);

  /// No description provided for @overdueCount.
  ///
  /// In tk, this message translates to:
  /// **'{count} möhleti geçdi'**
  String overdueCount(String count);

  /// No description provided for @dueSoonCount.
  ///
  /// In tk, this message translates to:
  /// **'{count} ýakynda'**
  String dueSoonCount(String count);

  /// No description provided for @recentTitle.
  ///
  /// In tk, this message translates to:
  /// **'Soňky ýazgylar'**
  String get recentTitle;

  /// No description provided for @recentEmpty.
  ///
  /// In tk, this message translates to:
  /// **'Entek hiç bir kassada ýazgy ýok.'**
  String get recentEmpty;

  /// No description provided for @copyAmount.
  ///
  /// In tk, this message translates to:
  /// **'Mukdary göçür'**
  String get copyAmount;

  /// No description provided for @amountCopied.
  ///
  /// In tk, this message translates to:
  /// **'Mukdar göçürildi'**
  String get amountCopied;

  /// No description provided for @statusFilter.
  ///
  /// In tk, this message translates to:
  /// **'Ýagdaýy boýunça süz'**
  String get statusFilter;

  /// No description provided for @sortBy.
  ///
  /// In tk, this message translates to:
  /// **'{column} boýunça tertiple'**
  String sortBy(String column);

  /// No description provided for @pickRegister.
  ///
  /// In tk, this message translates to:
  /// **'Haýsy kassa ýazgy goşmaly?'**
  String get pickRegister;
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
      <String>['tk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'tk':
      return AppLocalizationsTk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
