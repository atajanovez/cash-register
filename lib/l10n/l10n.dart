import 'package:flutter/widgets.dart';

import '../core/network/api_exception.dart';
import '../features/records/domain/record_type.dart';
import '../features/registers/domain/cash_register.dart';
import '../features/registers/domain/register_query.dart';
import 'generated/app_localizations.dart';
import 'tk_framework_localizations.dart';

export 'generated/app_localizations.dart';

/// The app is Turkmen-only for now. To add a language: add `app_xx.arb`,
/// framework delegates for it if Flutter lacks them, and list it here.
const appLocale = Locale('tk');

const appLocalizationsDelegates = <LocalizationsDelegate<Object>>[
  AppLocalizations.delegate,
  TkMaterialLocalizations.delegate,
  TkCupertinoLocalizations.delegate,
  DefaultWidgetsLocalizations.delegate,
];

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension RecordTypeL10n on RecordType {
  String label(AppLocalizations l) => switch (this) {
    RecordType.income => l.typeIncome,
    RecordType.expense => l.typeExpense,
    RecordType.transferOut => l.typeTransferOut,
    RecordType.transferIn => l.typeTransferIn,
    RecordType.accrualIncome => l.typeAccrualIncome,
    RecordType.receivableOpened => l.typeReceivableOpened,
    RecordType.payableOpened => l.typePayableOpened,
    RecordType.accrualIncomeSettled => l.typeAccrualIncomeSettled,
    RecordType.receivableSettled => l.typeReceivableSettled,
    RecordType.payableSettled => l.typePayableSettled,
  };

  String hint(AppLocalizations l) => switch (this) {
    RecordType.income => l.typeIncomeHint,
    RecordType.expense => l.typeExpenseHint,
    RecordType.transferOut => l.typeTransferOutHint,
    RecordType.transferIn => l.typeTransferInHint,
    RecordType.accrualIncome => l.typeAccrualIncomeHint,
    RecordType.receivableOpened => l.typeReceivableOpenedHint,
    RecordType.payableOpened => l.typePayableOpenedHint,
    RecordType.accrualIncomeSettled => l.typeAccrualIncomeSettledHint,
    RecordType.receivableSettled => l.typeReceivableSettledHint,
    RecordType.payableSettled => l.typePayableSettledHint,
  };
}

extension RecordGroupL10n on RecordGroup {
  String label(AppLocalizations l) => switch (this) {
    RecordGroup.cash => l.groupCash,
    RecordGroup.transfer => l.groupTransfer,
    RecordGroup.obligation => l.groupObligation,
    RecordGroup.settlement => l.groupSettlement,
  };
}

extension RegisterStatusL10n on RegisterStatus {
  String label(AppLocalizations l) => switch (this) {
    RegisterStatus.open => l.statusOpen,
    RegisterStatus.checked => l.statusChecked,
    RegisterStatus.closed => l.statusClosed,
  };

  /// What can still be recorded, in plain words.
  String rule(AppLocalizations l) => switch (this) {
    RegisterStatus.open => l.ruleOpen,
    RegisterStatus.checked => l.ruleChecked,
    RegisterStatus.closed => l.ruleClosed,
  };
}

extension RegisterFilterL10n on RegisterFilter {
  String label(AppLocalizations l) => switch (this) {
    RegisterFilter.all => l.filterAll,
    RegisterFilter.open => l.filterOpen,
    RegisterFilter.checked => l.filterChecked,
    RegisterFilter.closed => l.filterClosed,
    RegisterFilter.unsettled => l.filterUnsettled,
  };
}

extension RegisterSortL10n on RegisterSort {
  String label(AppLocalizations l) => switch (this) {
    RegisterSort.createdAt => l.sortCreated,
    RegisterSort.currentAmount => l.sortCurrent,
    RegisterSort.realAmount => l.sortReal,
    RegisterSort.checkedAt => l.sortChecked,
    RegisterSort.closedAt => l.sortClosed,
  };
}

/// The server answers in English; known errors are shown in Turkmen and
/// unknown ones fall back to a generic message with the server's wording.
String describeError(AppLocalizations l, Object error) {
  if (error is! ApiException) return l.errUnexpected;
  final message = error.message;
  bool says(String fragment) => message.contains(fragment);

  return switch (error.code) {
    'network' => l.errNetwork,
    'timeout' => l.errTimeout,
    'bad_certificate' => l.errCertificate,
    'bad_response' => l.errBadResponse,
    'unauthorized' => l.errUnauthorized,
    'forbidden' => l.errForbidden,
    'not_found' => l.errNotFound,
    'username_taken' => l.errUsernameTaken,
    'cash_register_name_taken' => l.registerNameTaken,
    'deadline_required' => l.errDeadlineRequired,
    'wrong_server' => l.errWrongServer,
    'invalid_request' => l.errInvalidRequest(message),
    'conflict' when says('insufficient') => l.errInsufficientFunds,
    'conflict' when says("parent's unsettled") => l.errSettlementTooLarge,
    'conflict' when says('does not match') => l.errSettlementMismatch,
    'conflict' when says('does not accept') => l.errRecordNotAllowed,
    'conflict' when says('destination') => l.errDestinationUnavailable,
    'conflict' when says('must be checked') => l.errMustBeChecked,
    'conflict' when says('must be equal') => l.errAmountsMustMatch,
    'conflict' when says('settled') => l.errNotSettled,
    'conflict' when says('must be closed') => l.errMustBeClosed,
    'conflict' when says('cannot be deactivated') =>
      l.errManagerCannotDeactivate,
    'conflict' when says('company name') => l.companyNameTaken,
    'conflict' => l.errConflict(message),
    _ when (error.statusCode ?? 0) >= 500 => l.errServer,
    _ => l.errUnexpected,
  };
}

/// Per-field server errors, translated where the field and code are known.
Map<String, String> describeFieldErrors(
  AppLocalizations l,
  ApiException error,
) => {
  for (final entry in error.fields.entries)
    entry.key: switch (entry.key) {
      'username' => l.errUsernameTaken,
      'name' => l.registerNameTaken,
      'deadline' => l.errDeadlineRequired,
      _ => entry.value,
    },
};
