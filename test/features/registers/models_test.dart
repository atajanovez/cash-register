import 'package:cash_register/features/members/domain/member.dart';
import 'package:cash_register/features/records/domain/cash_record.dart';
import 'package:cash_register/features/records/domain/record_type.dart';
import 'package:cash_register/features/registers/domain/cash_register.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fixtures.dart';

void main() {
  test('parses the member list', () {
    final members = fixtureList('members').map(Member.fromJson).toList();
    expect(members, hasLength(3));
    expect(members.first.initials, 'AT');
    expect(members.every((m) => m.isActive), isTrue);
  });

  test('parses registers and derives status', () {
    final list = fixtureList('reg_list').map(CashRegister.fromJson).toList();
    expect(list.map((r) => r.name), ['Safe', 'Main cash']);
    expect(list.first.status, RegisterStatus.open);

    final checked = CashRegister.fromJson(fixtureMap('check'));
    expect(checked.status, RegisterStatus.checked);
    expect(checked.difference, 115500 - 85500);

    // Older servers do not send is_pinned.
    expect(list.first.isPinned, isFalse);
    final pinned = CashRegister.fromJson({
      ...fixtureList('reg_list').first,
      'is_pinned': true,
    });
    expect(pinned.isPinned, isTrue);

    final closed = CashRegister.fromJson(fixtureMap('close'));
    expect(closed.status, RegisterStatus.closed);
    expect(closed.difference, 0);
  });

  test('parses register detail with member access', () {
    final detail = RegisterDetail.fromJson(fixtureMap('reg_get'));
    expect(detail.register.name, 'Main cash');
    final grace = detail.members.firstWhere(
      (m) => m.member.username == 'grace',
    );
    expect(grace.access, RegisterAccess.modify);
    expect(detail.accessOf(grace.member.id), RegisterAccess.modify);
    expect(detail.accessOf('someone-else'), isNull);
  });

  test('parses every record type with links', () {
    final records = fixtureList('recs').map(CashRecord.fromJson).toList();
    expect(records, hasLength(9));

    final accrual = records.firstWhere(
      (r) => r.type == RecordType.accrualIncome,
    );
    expect(accrual.children, hasLength(1));
    expect(accrual.settledAmount, 20000);
    expect(accrual.remaining, 30000);
    expect(accrual.isFullySettled, isFalse);
    expect(accrual.deadline, isNotNull);

    final paid = records.firstWhere((r) => r.type == RecordType.payableSettled);
    expect(paid.parent?.type, RecordType.payableOpened);
    expect(paid.creator?.username, 'manager');

    final transfer = records.firstWhere(
      (r) => r.type == RecordType.transferOut,
    );
    expect(transfer.destination?.name, 'Safe');
    expect(transfer.counterparty?.name, 'Safe');

    final transferIn = fixtureList('recs_r2').map(CashRecord.fromJson).first;
    expect(transferIn.type, RecordType.transferIn);
    expect(transferIn.source?.name, 'Main cash');
  });

  test('record type rules match the server', () {
    expect(RecordType.income.allowedIn(RegisterStatus.checked), isFalse);
    expect(RecordType.transferOut.allowedIn(RegisterStatus.checked), isTrue);
    expect(RecordType.payableSettled.allowedIn(RegisterStatus.checked), isTrue);
    expect(RecordType.transferOut.allowedIn(RegisterStatus.closed), isTrue);
    expect(
      RecordType.receivableSettled.allowedIn(RegisterStatus.closed),
      isFalse,
    );
    expect(RecordType.transferIn.allowedIn(RegisterStatus.open), isFalse);
    for (final t in RecordType.values) {
      expect(RecordType.fromWire(t.wire), t);
      if (t.isSettlement) expect(t.settles!.settledBy, t);
    }
  });
}
