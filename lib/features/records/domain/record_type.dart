import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../registers/domain/cash_register.dart';

enum RecordGroup { cash, transfer, obligation, settlement }

/// Every record type with the server's rules (see docs/api.md). Labels are
/// in `l10n.dart`.
enum RecordType {
  income(
    wire: 'income',
    icon: LucideIcons.arrowDownLeft,
    group: RecordGroup.cash,
    currentSign: 1,
    realSign: 1,
  ),
  expense(
    wire: 'expense',
    icon: LucideIcons.arrowUpRight,
    group: RecordGroup.cash,
    currentSign: -1,
    realSign: -1,
    needsFunds: true,
  ),
  transferOut(
    wire: 'transfer_out',
    icon: LucideIcons.arrowRight,
    group: RecordGroup.transfer,
    currentSign: -1,
    realSign: -1,
    needsFunds: true,
  ),
  transferIn(
    wire: 'transfer_in',
    icon: LucideIcons.arrowLeft,
    group: RecordGroup.transfer,
    currentSign: 1,
    realSign: 1,
    creatable: false,
  ),
  accrualIncome(
    wire: 'accrual_income',
    icon: LucideIcons.hourglass,
    group: RecordGroup.obligation,
    currentSign: 0,
    realSign: 1,
  ),
  receivableOpened(
    wire: 'receivable_opened',
    icon: LucideIcons.handCoins,
    group: RecordGroup.obligation,
    currentSign: -1,
    realSign: 0,
    needsFunds: true,
  ),
  payableOpened(
    wire: 'payable_opened',
    icon: LucideIcons.handshake,
    group: RecordGroup.obligation,
    currentSign: 1,
    realSign: 0,
  ),
  accrualIncomeSettled(
    wire: 'accrual_income_settled',
    icon: LucideIcons.circleCheck,
    group: RecordGroup.settlement,
    currentSign: 1,
    realSign: 0,
  ),
  receivableSettled(
    wire: 'receivable_settled',
    icon: LucideIcons.circleCheck,
    group: RecordGroup.settlement,
    currentSign: 1,
    realSign: 0,
  ),
  payableSettled(
    wire: 'payable_settled',
    icon: LucideIcons.circleCheck,
    group: RecordGroup.settlement,
    currentSign: -1,
    realSign: 0,
    needsFunds: true,
  );

  const RecordType({
    required this.wire,
    required this.icon,
    required this.group,
    required this.currentSign,
    required this.realSign,
    this.needsFunds = false,
    this.creatable = true,
  });

  final String wire;
  final IconData icon;
  final RecordGroup group;

  /// Effect on `current_amount` / `real_amount`: +1, −1 or 0.
  final int currentSign;
  final int realSign;

  /// Server rejects it when `current_amount` is lower than the amount.
  final bool needsFunds;

  /// `transfer_in` is created by the server as the other side of a transfer.
  final bool creatable;

  bool get isOpening => group == RecordGroup.obligation;
  bool get isSettlement => group == RecordGroup.settlement;
  bool get isTransfer => group == RecordGroup.transfer;
  bool get needsDeadline => isOpening;
  bool get needsParent => isSettlement;
  bool get needsDestination => this == transferOut;

  /// The opening type this settlement closes, and the reverse.
  RecordType? get settles => switch (this) {
    accrualIncomeSettled => accrualIncome,
    receivableSettled => receivableOpened,
    payableSettled => payableOpened,
    _ => null,
  };

  RecordType? get settledBy => switch (this) {
    accrualIncome => accrualIncomeSettled,
    receivableOpened => receivableSettled,
    payableOpened => payableSettled,
    _ => null,
  };

  /// Sign shown next to the amount: the cash effect, or the real effect when
  /// the record does not move cash (accrued income).
  int get displaySign => currentSign != 0 ? currentSign : realSign;

  bool allowedIn(RegisterStatus status) => switch (status) {
    RegisterStatus.open => creatable,
    RegisterStatus.checked => this == transferOut || isSettlement,
    RegisterStatus.closed => this == transferOut,
  };

  static RecordType fromWire(String value) => values.firstWhere(
    (t) => t.wire == value,
    orElse: () => throw FormatException('Unknown record type $value'),
  );
}
