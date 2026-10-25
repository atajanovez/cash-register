// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkmen (`tk`).
class AppLocalizationsTk extends AppLocalizations {
  AppLocalizationsTk([String locale = 'tk']) : super(locale);

  @override
  String get appName => 'Kassa';

  @override
  String get cancel => 'Ýatyr';

  @override
  String get retry => 'Gaýtadan synanyş';

  @override
  String get couldNotLoad => 'Ýüklenip bilinmedi';

  @override
  String get clear => 'Arassala';

  @override
  String get refresh => 'Täzele';

  @override
  String get loading => 'Ýüklenýär…';

  @override
  String get logoLabel => 'Kassa nyşany';

  @override
  String get none => 'Ýok';

  @override
  String get navRegisters => 'Kassalar';

  @override
  String get navMembers => 'Agzalar';

  @override
  String get navAccount => 'Profil';

  @override
  String get welcomeBack => 'Hoş geldiňiz';

  @override
  String get loginSubtitle =>
      'Kassalaryňyzy dolandyrmak üçin kompaniýaňyza giriň.';

  @override
  String get companyName => 'Kompaniýanyň ady';

  @override
  String get username => 'Ulanyjy ady';

  @override
  String get password => 'Açar sözi';

  @override
  String get logIn => 'Giriş';

  @override
  String get newHere => 'Täze ulanyjymy?';

  @override
  String get createCompany => 'Kompaniýa döret';

  @override
  String get enterCompanyName => 'Kompaniýanyň adyny giriziň';

  @override
  String get enterUsername => 'Ulanyjy adyňyzy giriziň';

  @override
  String get enterPassword => 'Açar sözüňizi giriziň';

  @override
  String get invalidCredentials =>
      'Kompaniýanyň ady, ulanyjy ady ýa-da açar sözi nädogry.';

  @override
  String get sessionExpired => 'Sessiýaňyzyň möhleti gutardy. Täzeden giriň.';

  @override
  String get accountDeactivated =>
      'Hasabyňyz işjeň däl. Dolandyryjyňyza ýüz tutuň.';

  @override
  String get showPassword => 'Açar sözüni görkez';

  @override
  String get hidePassword => 'Açar sözüni gizle';

  @override
  String get signupTitle => 'Kompaniýaňyzy dörediň';

  @override
  String get signupSubtitle =>
      'Siz dolandyryjy bolarsyňyz. Soňra agzalary we kassalary goşup bilersiňiz.';

  @override
  String get sectionCompany => 'Kompaniýa';

  @override
  String get sectionManagerAccount => 'Dolandyryjynyň hasaby';

  @override
  String get companyNameHelper => 'Agzalaryňyz ulgama girende şu ady ulanarlar';

  @override
  String get fullName => 'Ady we familiýasy';

  @override
  String get enterFullName => 'Ady we familiýany giriziň';

  @override
  String get chooseUsername => 'Ulanyjy adyny saýlaň';

  @override
  String get usernameNoSpaces => 'Ulanyjy adynda boşluk bolmaly däl';

  @override
  String get choosePassword => 'Açar sözüni saýlaň';

  @override
  String passwordTooShort(String count) {
    return 'Iň azyndan $count simwol bolmaly';
  }

  @override
  String passwordTooLong(String count) {
    return 'Iň köp $count simwol bolup biler';
  }

  @override
  String passwordHelper(String count) {
    return 'Iň azyndan $count simwol';
  }

  @override
  String get confirmPassword => 'Açar sözüni gaýtalaň';

  @override
  String get passwordsDontMatch => 'Açar sözler gabat gelmeýär';

  @override
  String get fixHighlighted => 'Bellenen meýdançalary düzediň.';

  @override
  String get companyNameTaken => 'Bu at bilen kompaniýa eýýäm bar';

  @override
  String get alreadyHaveCompany => 'Kompaniýaňyz barmy?';

  @override
  String get brandHeadline => 'Her teňňe —\nher kassada.';

  @override
  String get brandBody =>
      'Girdejileri, çykdajylary, geçirimleri we bergileri ähli kassalaryňyz boýunça bütin toparyňyz bilen bile hasaba alyň.';

  @override
  String get featureDevices => 'Telefonda we kompýuterde işleýär';

  @override
  String get featureRoles =>
      'Dolandyryjy we agza rollary, her kassa üçin aýratyn rugsat';

  @override
  String get featureAudit => 'Üýtgedilmeýän ýazgylar — doly hasabat taryhy';

  @override
  String get registersTitle => 'Kassalar';

  @override
  String get searchRegisters => 'Kassany gözle';

  @override
  String get filterAll => 'Ählisi';

  @override
  String get filterOpen => 'Açyk';

  @override
  String get filterChecked => 'Barlanan';

  @override
  String get filterClosed => 'Ýapyk';

  @override
  String get filterUnsettled => 'Hasaplaşylmadyk';

  @override
  String get sort => 'Tertiple';

  @override
  String get sortCreated => 'Döredilen senesi';

  @override
  String get sortCurrent => 'Nagt pul';

  @override
  String get sortReal => 'Hakyky mukdar';

  @override
  String get sortChecked => 'Barlanan senesi';

  @override
  String get sortClosed => 'Ýapylan senesi';

  @override
  String get sortDescending => 'Iň täzesi / iň ulusy öňde';

  @override
  String get sortAscending => 'Iň könesi / iň kiçisi öňde';

  @override
  String get newRegister => 'Täze kassa';

  @override
  String get totalCash => 'Jemi nagt pul';

  @override
  String registerCount(String count) {
    return '$count kassa';
  }

  @override
  String get noRegisters => 'Entek kassa ýok';

  @override
  String get noRegistersManager =>
      'Girdejileri we çykdajylary ýazmak üçin ilkinji kassaňyzy dörediň.';

  @override
  String get noRegistersMember =>
      'Kassa rugsat bermegini dolandyryjyňyzdan haýyş ediň.';

  @override
  String get noMatchingRegisters => 'Gabat gelýän kassa ýok';

  @override
  String get tryAnotherSearch => 'Başga gözleg ýa-da süzgüç synap görüň.';

  @override
  String get selectRegister => 'Kassany saýlaň';

  @override
  String get selectRegisterHint =>
      'Onuň galyndysy we ýazgylary şu ýerde görüner.';

  @override
  String get cashOnHand => 'Kassadaky nagt pul';

  @override
  String get cashFullySettled => 'Kassadaky nagt pul · hemmesi hasaplaşyldy';

  @override
  String cashWithReal(String amount) {
    return 'Kassadaky nagt pul · hakyky $amount';
  }

  @override
  String get realAmount => 'Hakyky mukdar';

  @override
  String get outstanding => 'Açyk galan';

  @override
  String get realAmountHelp =>
      'Nagt pul, üstüne bu kassa berilmeli bergiler, aýrylan bu kassanyň öz bergileri';

  @override
  String get outstandingHelp =>
      'Hakyky mukdar bilen nagt pulyň tapawudy: açyk garaşylýan girdejiler we berlen karzlar, aýrylan alnan karzlar';

  @override
  String get statusOpen => 'Açyk';

  @override
  String get statusChecked => 'Barlanan';

  @override
  String get statusClosed => 'Ýapyk';

  @override
  String get ruleOpen => 'Ähli görnüşli ýazgylary goşup bolýar.';

  @override
  String get ruleChecked =>
      'Barlanan: diňe geçirimleri we hasaplaşyklary goşup bolýar.';

  @override
  String get ruleClosed => 'Ýapyk: diňe çykýan geçirimleri goşup bolýar.';

  @override
  String get registerNotAvailable => 'Kassa elýeterli däl';

  @override
  String get registerNotAvailableHint =>
      'Ol pozuldy ýa-da size oňa rugsat ýok.';

  @override
  String get backToRegisters => 'Kassalara dolan';

  @override
  String get addRecord => 'Ýazgy goş';

  @override
  String get recordSaved => 'Ýazgy ýatda saklandy';

  @override
  String get records => 'Ýazgylar';

  @override
  String get searchRecords => 'Bellik ýa-da adam boýunça gözle';

  @override
  String get allTypes => 'Ähli görnüşler';

  @override
  String get unsettledOnly => 'Diňe hasaplaşylmadyk';

  @override
  String get noRecords => 'Entek ýazgy ýok';

  @override
  String get noRecordsCanAdd =>
      'Girdeji, çykdajy ýa-da geçirim ýazmak üçin «Ýazgy goş» düwmesine basyň.';

  @override
  String get noRecordsViewOnly => 'Bu kassa goşulan ýazgylar şu ýerde görüner.';

  @override
  String get noMatchingRecords => 'Gabat gelýän ýazgy ýok';

  @override
  String get clearFilters => 'Süzgüçleri arassala';

  @override
  String get loadMoreFailed => 'Ýüklenmedi. Gaýtadan synanyşyň';

  @override
  String get youCanModify => 'Bu kassa ýazgy goşup bilersiňiz';

  @override
  String get youCanView => 'Bu kassany diňe görüp bilersiňiz';

  @override
  String get giveAccess => 'Rugsat ber';

  @override
  String membersCount(String count) {
    return '$count agza';
  }

  @override
  String get check => 'Barla';

  @override
  String get close => 'Ýap';

  @override
  String get pin => 'Ýokarda berkit';

  @override
  String get unpin => 'Berkitmäni aýyr';

  @override
  String get pinned => 'Ýokarda berkidilen';

  @override
  String get registerPinned => 'Kassa sanawyň ýokarsynda berkidildi';

  @override
  String get registerUnpinned => 'Kassa berkitmeden aýryldy';

  @override
  String get delete => 'Poz';

  @override
  String settleBeforeClosing(String amount) {
    return 'Ýapmazdan öň açyk galan $amount hasaplaşyň.';
  }

  @override
  String checkTitle(String name) {
    return '«$name» barlansynmy?';
  }

  @override
  String get checkMessage =>
      'Barlanandan soň diňe geçirimleri we hasaplaşyklary goşup bolar. Muny yzyna gaýtaryp bolmaýar.';

  @override
  String get checkConfirm => 'Kassany barla';

  @override
  String closeTitle(String name) {
    return '«$name» ýapylsynmy?';
  }

  @override
  String get closeMessage =>
      'Ýapyk kassa diňe çykýan geçirimlere rugsat berýär. Muny yzyna gaýtaryp bolmaýar.';

  @override
  String get closeConfirm => 'Kassany ýap';

  @override
  String deleteTitle(String name) {
    return '«$name» pozulsynmy?';
  }

  @override
  String get deleteMessage =>
      'Kassa we onuň ähli ýazgylary, beýleki kassalara iberen geçirimleri bilen bilelikde, hemişelik pozular.';

  @override
  String get registerChecked => 'Kassa barlandy';

  @override
  String get registerClosed => 'Kassa ýapyldy';

  @override
  String get registerDeleted => 'Kassa pozuldy';

  @override
  String get accessUpdated => 'Rugsatlar täzelendi';

  @override
  String get name => 'Ady';

  @override
  String get registerNameHint => 'meselem, Esasy kassa, Dükan 2, Seýf';

  @override
  String get enterName => 'Adyny giriziň';

  @override
  String get registerNameTaken => 'Bu at bilen kassa eýýäm bar';

  @override
  String get teamAccess => 'Agzalaryň rugsady';

  @override
  String get createRegister => 'Kassa döret';

  @override
  String get accessView => 'Görmek';

  @override
  String get accessModify => 'Üýtgetmek';

  @override
  String get noTeamMembers =>
      'Entek agza ýok. Agzalary «Agzalar» bölüminde goşuň, soňra şu ýerde rugsat beriň.';

  @override
  String usernameInactive(String username) {
    return '@$username · işjeň däl';
  }

  @override
  String accessTitle(String name) {
    return '«$name» kassasyna kim girip biler';
  }

  @override
  String get accessSubtitle =>
      'Görmek: galyndyny we ýazgylary görýär. Üýtgetmek: ýazgy hem goşup bilýär.';

  @override
  String get saveAccess => 'Rugsatlary ýatda sakla';

  @override
  String get typeIncome => 'Girdeji';

  @override
  String get typeIncomeHint => 'Alnan pul';

  @override
  String get typeExpense => 'Çykdajy';

  @override
  String get typeExpenseHint => 'Harçlanan pul';

  @override
  String get typeTransferOut => 'Geçirim';

  @override
  String get typeTransferOutHint => 'Puly başga kassa geçirmek';

  @override
  String get typeTransferIn => 'Gelen geçirim';

  @override
  String get typeTransferInHint => 'Başga kassadan geçirilen pul';

  @override
  String get typeAccrualIncome => 'Garaşylýan girdeji';

  @override
  String get typeAccrualIncomeHint => 'Gazanylan, ýöne entek alynmadyk pul';

  @override
  String get typeReceivableOpened => 'Berlen karz';

  @override
  String get typeReceivableOpenedHint => 'Yzyna gaýtarylmaly berlen pul';

  @override
  String get typePayableOpened => 'Alnan karz';

  @override
  String get typePayableOpenedHint => 'Yzyna tölenmeli karz alnan pul';

  @override
  String get typeAccrualIncomeSettled => 'Girdeji alyndy';

  @override
  String get typeAccrualIncomeSettledHint => 'Garaşylýan girdeji alyndy';

  @override
  String get typeReceivableSettled => 'Karz gaýtaryldy';

  @override
  String get typeReceivableSettledHint => 'Berlen karz yzyna alyndy';

  @override
  String get typePayableSettled => 'Karz tölendi';

  @override
  String get typePayableSettledHint => 'Alnan karz yzyna tölendi';

  @override
  String get groupCash => 'Nagt pul';

  @override
  String get groupTransfer => 'Geçirim';

  @override
  String get groupObligation => 'Borçnama açmak';

  @override
  String get groupSettlement => 'Borçnamany ýapmak';

  @override
  String transferTo(String name) {
    return '«$name» kassasyna';
  }

  @override
  String transferFrom(String name) {
    return '«$name» kassasyndan';
  }

  @override
  String get anotherRegister => 'başga kassa';

  @override
  String get settled => 'Hasaplaşyldy';

  @override
  String amountLeft(String amount) {
    return '$amount galdy';
  }

  @override
  String amountLeftDue(String amount, String date) {
    return '$amount galdy · möhleti $date';
  }

  @override
  String amountLeftOverdue(String amount, String date) {
    return '$amount galdy · möhleti $date geçdi';
  }

  @override
  String get today => 'Şu gün';

  @override
  String get yesterday => 'Düýn';

  @override
  String get detailNote => 'Bellik';

  @override
  String get detailRecorded => 'Senesi';

  @override
  String get detailBy => 'Kim';

  @override
  String get detailTo => 'Nirä';

  @override
  String get detailFrom => 'Nireden';

  @override
  String get detailDue => 'Möhleti';

  @override
  String get detailSettles => 'Degişli';

  @override
  String payments(String count) {
    return 'Tölegler ($count)';
  }

  @override
  String get fullySettled => 'Doly hasaplaşyldy';

  @override
  String settledAndLeft(String settled, String left) {
    return '$settled hasaplaşyldy · $left galdy';
  }

  @override
  String get addARecord => 'Ýazgy goş';

  @override
  String get typesWhenChecked =>
      'Bu kassa barlanan: diňe geçirimleri we hasaplaşyklary goşup bolýar.';

  @override
  String get typesWhenClosed =>
      'Bu kassa ýapyk: diňe çykýan geçirimleri goşup bolýar.';

  @override
  String get changeType => 'Görnüşi üýtget';

  @override
  String get saveRecord => 'Ýazgyny ýatda sakla';

  @override
  String get amount => 'Möçber';

  @override
  String availableCash(String amount) {
    return 'Kassada $amount bar';
  }

  @override
  String get enterAmount => 'Noldan uly möçber giriziň';

  @override
  String onlyCash(String amount) {
    return 'Kassada diňe $amount bar';
  }

  @override
  String onlyLeftToSettle(String amount) {
    return 'Hasaplaşmak üçin diňe $amount galdy';
  }

  @override
  String get dueDate => 'Möhleti';

  @override
  String get chooseDate => 'Senäni saýlaň';

  @override
  String get noteLabel => 'Bellik';

  @override
  String get errNoteRequired => 'Bellik ýazyň';

  @override
  String get noteHint => 'Näme üçin?';

  @override
  String get toRegister => 'Haýsy kassa';

  @override
  String get loadingRegisters => 'Kassalar ýüklenýär…';

  @override
  String get noTransferTargets => 'Geçirim edip boljak başga açyk kassa ýok';

  @override
  String get chooseDestination => 'Pul geçiriljek kassany saýlaň';

  @override
  String get whichObligation => 'Haýsy borçnama';

  @override
  String get nothingToSettle => 'Bu kassada hasaplaşylmaly zat ýok';

  @override
  String get chooseObligation => 'Haýsy borçnamanyň hasaplaşylýandygyny saýlaň';

  @override
  String dueOn(String date) {
    return 'möhleti $date';
  }

  @override
  String get oldMoneyButton => 'Köne puldan geçir';

  @override
  String get oldMoneyTitle => 'Köne puldan täze pula';

  @override
  String get oldMoneyRate => '5 000 köne manat = 1 TMT';

  @override
  String get oldMoneyLabel => 'Köne pul';

  @override
  String get oldMoneySuffix => 'köne manat';

  @override
  String get oldMoneyResult => 'Täze pulda';

  @override
  String get oldMoneyEmpty => 'Köne pul möçberini giriziň';

  @override
  String get oldMoneyUse => 'Ulan';

  @override
  String get membersTitle => 'Agzalar';

  @override
  String get addMember => 'Agza goş';

  @override
  String memberAdded(String name) {
    return '$name goşuldy';
  }

  @override
  String get membersHint =>
      'Kassirleriňizi şu ýerde goşuň, soňra olara kassalara rugsat beriň. Olar kompaniýanyň ady, öz ulanyjy ady we açar sözi bilen girýärler.';

  @override
  String get roleManager => 'Dolandyryjy';

  @override
  String get roleMember => 'Agza';

  @override
  String get you => 'Siz';

  @override
  String get inactive => 'Işjeň däl';

  @override
  String get addMemberSubtitle =>
      'Olar siziň kompaniýaňyzyň ady we şu maglumatlar bilen girerler.';

  @override
  String get newPassword => 'Täze açar sözi';

  @override
  String get newPasswordHelper => 'Täze açar sözüni oňa ýüzbe-ýüz aýdyň';

  @override
  String get changePassword => 'Açar sözüni üýtget';

  @override
  String passwordChanged(String name) {
    return '$name üçin açar sözi üýtgedildi';
  }

  @override
  String get access => 'Rugsat';

  @override
  String get active => 'Işjeň';

  @override
  String get activeOn => 'Ulgama girip, öz kassalary bilen işläp bilýär';

  @override
  String get activeOff => 'Ulgama girip bilmeýär';

  @override
  String deactivateTitle(String name) {
    return '$name işjeň däl edilsinmi?';
  }

  @override
  String get deactivateMessage =>
      'Ol derrew ulgamdan çykarylar we siz ony täzeden işjeňleşdirýänçäňiz girip bilmez. Onuň ýazgylary saklanýar.';

  @override
  String get deactivate => 'Işjeň däl et';

  @override
  String memberActivated(String name) {
    return '$name işjeňleşdirildi';
  }

  @override
  String memberDeactivated(String name) {
    return '$name işjeň däl edildi';
  }

  @override
  String get accountTitle => 'Profil';

  @override
  String get company => 'Kompaniýa';

  @override
  String get sessionValidUntil => 'Sessiýanyň möhleti';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Ulgam';

  @override
  String get themeLight => 'Ýagty';

  @override
  String get themeDark => 'Garaňky';

  @override
  String get themeSystemHint =>
      'Telefonyňyzyň ýa-da kompýuteriňiziň sazlamasy boýunça';

  @override
  String get logOut => 'Ulgamdan çyk';

  @override
  String get logOutTitle => 'Ulgamdan çykmalymy?';

  @override
  String get logOutMessage => 'Täzeden girmek üçin açar sözüňiz gerek bolar.';

  @override
  String get errNetwork =>
      'Serwere birigip bolmady. Internet birikmäňizi barlaň.';

  @override
  String get errTimeout => 'Serwer gaty uzak jogap berdi. Gaýtadan synanyşyň.';

  @override
  String get errCertificate => 'Serweriň howpsuzlyk şahadatnamasy nädogry.';

  @override
  String get errBadResponse =>
      'Serwerden garaşylmadyk jogap geldi. Gaýtadan synanyşyň.';

  @override
  String get errServer => 'Serwerde näsazlyk ýüze çykdy. Soňrak synanyşyň.';

  @override
  String get errUnexpected => 'Garaşylmadyk ýalňyşlyk ýüze çykdy.';

  @override
  String get errUnauthorized => 'Sessiýaňyzyň möhleti gutardy. Täzeden giriň.';

  @override
  String get errForbidden => 'Bu hereket üçin rugsadyňyz ýok.';

  @override
  String get errNotFound => 'Tapylmady ýa-da size rugsat ýok.';

  @override
  String get errInsufficientFunds => 'Kassada ýeterlik nagt pul ýok.';

  @override
  String get errSettlementTooLarge => 'Hasaplaşyk möçberi galan bergiden köp.';

  @override
  String get errSettlementMismatch =>
      'Hasaplaşygyň görnüşi borçnama gabat gelmeýär.';

  @override
  String get errRecordNotAllowed =>
      'Kassanyň häzirki ýagdaýynda bu ýazgyny goşup bolmaýar.';

  @override
  String get errDestinationUnavailable =>
      'Geçirim edilýän kassa elýeterli däl ýa-da oňa üýtgetmek rugsadyňyz ýok.';

  @override
  String get errMustBeChecked => 'Kassany ýapmazdan öň ony barlamaly.';

  @override
  String get errAmountsMustMatch =>
      'Ýapmak üçin nagt pul bilen hakyky mukdar deň bolmaly.';

  @override
  String get errNotSettled => 'Ýapmazdan öň ähli borçnamalary hasaplaşmaly.';

  @override
  String get errMustBeClosed => 'Kassany pozmazdan öň ony ýapmaly.';

  @override
  String get errManagerCannotDeactivate =>
      'Kompaniýanyň dolandyryjysyny işjeň däl edip bolmaýar.';

  @override
  String get errUsernameTaken => 'Bu ulanyjy ady eýýäm ulanylýar';

  @override
  String get errDeadlineRequired => 'Möhleti görkeziň';

  @override
  String errInvalidRequest(String details) {
    return 'Maglumatlar nädogry: $details';
  }

  @override
  String errConflict(String details) {
    return 'Amaly ýerine ýetirip bolmady: $details';
  }

  @override
  String realShort(String amount) {
    return 'hakyky $amount';
  }

  @override
  String get open => 'Aç';

  @override
  String get more => 'Başga hereketler';

  @override
  String createdOn(String date) {
    return 'Döredilen senesi: $date';
  }

  @override
  String get colRecord => 'Ýazgy';

  @override
  String get colMember => 'Agza';

  @override
  String get colTime => 'Wagt';

  @override
  String get colAmount => 'Mukdar';

  @override
  String dayRecordCount(String count) {
    return '$count ýazgy';
  }

  @override
  String get membersSubtitle => 'Kassalara girip bilýän adamlar';

  @override
  String get syncTitle => 'Sinhronlama';

  @override
  String get syncOffline => 'Internet ýok';

  @override
  String syncOfflineWaiting(String count) {
    return 'Internet ýok · $count garaşýar';
  }

  @override
  String get syncSyncing => 'Sinhronlanýar…';

  @override
  String get syncUpToDate => 'Hemmesi sinhronlandy';

  @override
  String syncPending(String count) {
    return '$count üýtgeşme ugradylýar';
  }

  @override
  String syncRejected(String count) {
    return '$count üýtgeşme kabul edilmedi';
  }

  @override
  String get syncError => 'Sinhronlamak başartmady';

  @override
  String syncLastAt(String time) {
    return 'Soňky sinhronlama: $time';
  }

  @override
  String get syncNever => 'Entek sinhronlanmady';

  @override
  String get syncNow => 'Häzir sinhronla';

  @override
  String get syncOfflineHint =>
      'Işläp bilersiňiz: üýtgeşmeler enjamda saklanýar we internet gelende özbaşdak ugradylar.';

  @override
  String get syncPendingTitle => 'Ugradylmadyk üýtgeşmeler';

  @override
  String get syncRejectedTitle => 'Serwer kabul etmedi';

  @override
  String get syncRejectedHint =>
      'Bu üýtgeşmeler ugradylmady. Aýyryň we gerek bolsa täzeden giriziň.';

  @override
  String get syncDiscard => 'Aýyr';

  @override
  String get syncNothingWaiting => 'Ugradylmadyk üýtgeşme ýok.';

  @override
  String get pendingBadge => 'Ugradylmady';

  @override
  String get savedOffline => 'Enjamda saklandy — internet gelende ugradylar';

  @override
  String get noDataOffline => 'Maglumat entek ýok';

  @override
  String get noDataOfflineHint =>
      'Ilkinji gezek maglumatlary almak üçin internete birikiň. Soňra internetsiz hem işläp bilersiňiz.';

  @override
  String logOutUnsent(String count) {
    return 'Ugradylmadyk $count üýtgeşme bar. Häzir çyksaňyz, olar ýiter.';
  }

  @override
  String opRecordCreate(String type, String amount) {
    return '$type · $amount';
  }

  @override
  String opRegisterCreate(String name) {
    return 'Täze kassa: $name';
  }

  @override
  String opRegisterCheck(String name) {
    return 'Barlamak: $name';
  }

  @override
  String opRegisterClose(String name) {
    return 'Ýapmak: $name';
  }

  @override
  String opRegisterDelete(String name) {
    return 'Pozmak: $name';
  }

  @override
  String opRegisterAccess(String name) {
    return 'Rugsatlar: $name';
  }

  @override
  String get needsInternet => 'Munuň üçin internet gerek.';
}
