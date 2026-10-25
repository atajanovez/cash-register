import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/format/dates.dart';

/// Flutter ships no Turkmen translations for its own widgets (date picker,
/// text selection menu, dialog buttons, tooltips). These cover everything the
/// app shows; anything not overridden falls back to English.

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

class TkMaterialLocalizations extends DefaultMaterialLocalizations {
  const TkMaterialLocalizations();

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _TkDelegate<MaterialLocalizations>(TkMaterialLocalizations());

  // Dates and the date picker.
  @override
  int get firstDayOfWeekIndex => 1; // Monday.

  @override
  List<String> get narrowWeekdays => const ['Ý', 'D', 'S', 'Ç', 'P', 'A', 'Ş'];

  @override
  String formatYear(DateTime date) => '${date.year}';

  @override
  String formatCompactDate(DateTime date) => Dates.date(date);

  @override
  String formatShortDate(DateTime date) =>
      '${date.day} ${Dates.months[date.month - 1]} ${date.year}';

  @override
  String formatMediumDate(DateTime date) =>
      '${_cap(Dates.weekdays[date.weekday - 1])}, '
      '${date.day} ${Dates.months[date.month - 1]}';

  @override
  String formatFullDate(DateTime date) =>
      '${_cap(Dates.weekdays[date.weekday - 1])}, '
      '${date.day} ${Dates.months[date.month - 1]} ${date.year}';

  @override
  String formatMonthYear(DateTime date) =>
      '${_cap(Dates.months[date.month - 1])} ${date.year}';

  @override
  String formatShortMonthDay(DateTime date) =>
      '${date.day} ${Dates.months[date.month - 1]}';

  @override
  String get dateSeparator => '.';

  @override
  String get dateHelpText => 'gg.aa.ýýýý';

  @override
  String get datePickerHelpText => 'Senäni saýlaň';

  @override
  String get dateInputLabel => 'Senäni giriziň';

  @override
  String get invalidDateFormatLabel => 'Nädogry format.';

  @override
  String get dateOutOfRangeLabel => 'Ýol berilýän aralykdan daşarda.';

  @override
  String get calendarModeButtonLabel => 'Senenama geç';

  @override
  String get inputDateModeButtonLabel => 'Girizmä geç';

  @override
  String get selectYearSemanticsLabel => 'Ýyly saýlaň';

  @override
  String get unspecifiedDate => 'Sene';

  @override
  String get currentDateLabel => 'Şu gün';

  @override
  String get selectedDateLabel => 'Saýlanan';

  @override
  String get nextMonthTooltip => 'Indiki aý';

  @override
  String get previousMonthTooltip => 'Öňki aý';

  // Buttons.
  @override
  String get okButtonLabel => 'Bolýar';

  @override
  String get cancelButtonLabel => 'Ýatyr';

  @override
  String get closeButtonLabel => 'Ýap';

  @override
  String get continueButtonLabel => 'Dowam et';

  @override
  String get saveButtonLabel => 'Ýatda sakla';

  // Text selection menu.
  @override
  String get copyButtonLabel => 'Göçür';

  @override
  String get cutButtonLabel => 'Kes';

  @override
  String get pasteButtonLabel => 'Goý';

  @override
  String get selectAllButtonLabel => 'Hemmesini saýla';

  @override
  String get lookUpButtonLabel => 'Gözle';

  @override
  String get searchWebButtonLabel => 'Internetde gözle';

  @override
  String get shareButtonLabel => 'Paýlaş';

  @override
  String get scanTextButtonLabel => 'Teksti skanirle';

  // Tooltips and accessibility labels.
  @override
  String get backButtonTooltip => 'Yza';

  @override
  String get closeButtonTooltip => 'Ýap';

  @override
  String get clearButtonTooltip => 'Arassala';

  @override
  String get deleteButtonTooltip => 'Poz';

  @override
  String get moreButtonTooltip => 'Has köp';

  @override
  String get showMenuTooltip => 'Menýuny görkez';

  @override
  String get searchFieldLabel => 'Gözleg';

  @override
  String get dialogLabel => 'Dialog';

  @override
  String get alertDialogLabel => 'Duýduryş';

  @override
  String get popupMenuLabel => 'Menýu';

  @override
  String get bottomSheetLabel => 'Aşaky panel';

  @override
  String get scrimLabel => 'Fon';

  @override
  String scrimOnTapHint(String modalRouteContentName) =>
      '$modalRouteContentName ýap';

  @override
  String get modalBarrierDismissLabel => 'Ýap';

  @override
  String get menuDismissLabel => 'Menýuny ýap';

  @override
  String get refreshIndicatorSemanticLabel => 'Täzele';

  @override
  String remainingTextFieldCharacterCount(int remaining) =>
      '$remaining simwol galdy';
}

class TkCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const TkCupertinoLocalizations();

  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      _TkDelegate<CupertinoLocalizations>(TkCupertinoLocalizations());

  @override
  String datePickerMonth(int monthIndex) => _cap(Dates.months[monthIndex - 1]);

  @override
  String datePickerStandaloneMonth(int monthIndex) =>
      datePickerMonth(monthIndex);

  @override
  String datePickerMediumDate(DateTime date) =>
      '${_cap(Dates.weekdays[date.weekday - 1])}, '
      '${date.day} ${Dates.months[date.month - 1]}';

  @override
  String get todayLabel => 'Şu gün';

  @override
  String get alertDialogLabel => 'Duýduryş';

  @override
  String get copyButtonLabel => 'Göçür';

  @override
  String get cutButtonLabel => 'Kes';

  @override
  String get pasteButtonLabel => 'Goý';

  @override
  String get selectAllButtonLabel => 'Hemmesini saýla';

  @override
  String get lookUpButtonLabel => 'Gözle';

  @override
  String get searchWebButtonLabel => 'Internetde gözle';

  @override
  String get shareButtonLabel => 'Paýlaş';

  @override
  String get clearButtonLabel => 'Arassala';

  @override
  String get cancelButtonLabel => 'Ýatyr';

  @override
  String get backButtonLabel => 'Yza';

  @override
  String get searchTextFieldPlaceholderLabel => 'Gözleg';

  @override
  String get modalBarrierDismissLabel => 'Ýap';

  @override
  String get menuDismissLabel => 'Menýuny ýap';
}

class _TkDelegate<T> extends LocalizationsDelegate<T> {
  const _TkDelegate(this.value);

  final T value;

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tk';

  @override
  Future<T> load(Locale locale) => SynchronousFuture(value);

  @override
  bool shouldReload(_TkDelegate<T> old) => false;
}
