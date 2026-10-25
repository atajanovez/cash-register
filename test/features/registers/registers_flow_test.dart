import 'package:cash_register/app/app.dart';
import 'package:cash_register/core/storage/storage_providers.dart';
import 'package:cash_register/features/auth/data/auth_repository.dart';
import 'package:cash_register/features/auth/domain/session.dart';
import 'package:cash_register/features/records/data/records_repository.dart';
import 'package:cash_register/features/records/domain/record_type.dart';
import 'package:cash_register/features/registers/domain/cash_register.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cash_register/l10n/l10n.dart';
import 'package:cash_register/core/format/dates.dart';
import 'package:cash_register/core/format/money.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_backend.dart';
import '../auth/auth_flow_test.dart' show FakeAuthRepository;

Session _session({bool manager = true, String memberId = 'm1'}) => Session(
  token: 't',
  memberId: memberId,
  companyId: 'c1',
  companyName: 'Acme',
  username: 'ada',
  fullName: 'Ada Lovelace',
  isManager: manager,
);

Future<FakeBackend> _pump(
  WidgetTester tester, {
  FakeBackend? backend,
  Session? session,
  Size size = const Size(420, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final b = backend ?? FakeBackend();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository()..stored = session ?? _session(),
        ),
        ...b.overrides,
      ],
      child: const CashRegisterApp(),
    ),
  );
  await tester.pumpAndSettle();
  return b;
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _addRecord(
  WidgetTester tester,
  String type,
  String amount, {
  Future<void> Function()? extra,
}) async {
  await _tapText(tester, l.addRecord);
  await _tapText(tester, type);
  if (extra != null) await extra();
  await tester.enterText(_field(l.amount), amount);
  await tester.enterText(_field(l.noteLabel), 'Test');
  await _tapText(tester, l.saveRecord);
}

final l = lookupAppLocalizations(appLocale);

void main() {
  testWidgets('manager creates a register and records income', (tester) async {
    final b = await _pump(tester);
    expect(find.text(l.noRegisters), findsOneWidget);

    await _tapText(tester, l.newRegister);
    await tester.enterText(_field(l.name), 'Main cash');
    await _tapText(tester, l.createRegister);

    // Lands on the new register.
    expect(find.text(l.cashOnHand), findsOneWidget);
    expect(find.text(l.noRecords), findsOneWidget);

    await _addRecord(tester, l.typeIncome, '125,50');
    expect(find.text(l.recordSaved), findsOneWidget);
    expect(find.text(Money.format(12550)), findsWidgets);
    expect(find.text(Money.signed(12550)), findsWidgets);
    expect(b.registers.single.currentAmount, 12550);
  });

  testWidgets('expense larger than the cash is stopped before sending', (
    tester,
  ) async {
    final b = FakeBackend()
      ..addRegister('Main cash', current: 1000, real: 1000);
    await _pump(tester, backend: b);
    await _tapText(tester, 'Main cash');

    await _addRecord(tester, l.typeExpense, '20');
    expect(find.text(l.onlyCash(Money.format(1000))), findsOneWidget);
    expect(b.records.values.expand((r) => r), isEmpty);
  });

  testWidgets('transfer moves money between registers', (tester) async {
    final b = FakeBackend()
      ..addRegister('Main cash', current: 10000, real: 10000)
      ..addRegister('Safe');
    await _pump(tester, backend: b);
    await _tapText(tester, 'Main cash');

    await _addRecord(
      tester,
      l.typeTransferOut,
      '40',
      extra: () async {
        await tester.tap(find.text(l.toRegister));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Safe ·').last);
        await tester.pumpAndSettle();
      },
    );

    expect(find.text(l.transferTo('Safe')), findsOneWidget);
    expect(b.registers.first.currentAmount, 6000);
    expect(b.registers.last.currentAmount, 4000);
  });

  testWidgets('accrued income can be settled from its details', (tester) async {
    final b = FakeBackend()..addRegister('Main cash');
    final id = b.registers.single.id;
    b.addRecord(
      id,
      RecordDraft(
        type: RecordType.accrualIncome,
        amount: 5000,
        note: 'Invoice 42',
        deadline: DateTime.now().add(const Duration(days: 5)),
      ),
    );
    await _pump(tester, backend: b);
    await _tapText(tester, 'Main cash');
    expect(
      find.textContaining(l.amountLeft(Money.format(5000))),
      findsOneWidget,
    );

    await _tapText(tester, 'Invoice 42');
    await _tapText(tester, l.typeAccrualIncomeSettled);
    // Amount is prefilled with what is left.
    expect(find.text('50'), findsOneWidget);
    await tester.enterText(_field(l.amount), '20');
    await tester.enterText(_field(l.noteLabel), 'Part payment');
    await _tapText(tester, l.saveRecord);

    expect(
      find.textContaining(l.amountLeft(Money.format(3000))),
      findsOneWidget,
    );
    expect(b.registers.single.currentAmount, 2000);
    expect(b.registers.single.realAmount, 5000);
  });

  testWidgets('checking limits the record types', (tester) async {
    final b = FakeBackend()..addRegister('Main cash', current: 500, real: 500);
    await _pump(tester, backend: b);
    await _tapText(tester, 'Main cash');

    await _tapText(tester, l.check);
    await _tapText(tester, l.checkConfirm);
    expect(find.text(l.registerChecked), findsOneWidget);
    expect(find.textContaining(l.ruleChecked), findsWidgets);

    await _tapText(tester, l.addRecord);
    expect(find.text(l.typeIncome), findsNothing);
    expect(find.text(l.typeExpense), findsNothing);
    expect(find.text(l.typeTransferOut), findsWidgets);
    expect(find.text(l.typePayableSettled), findsOneWidget);
  });

  testWidgets('a view-only member cannot add records', (tester) async {
    final b = FakeBackend()..addRegister('Main cash');
    b.access[b.registers.single.id] = {'m2': RegisterAccess.view};
    await _pump(
      tester,
      backend: b,
      session: _session(manager: false, memberId: 'm2'),
    );
    expect(find.text(l.newRegister), findsNothing);

    await _tapText(tester, 'Main cash');
    expect(find.text(l.youCanView), findsOneWidget);
    expect(find.text(l.addRecord), findsNothing);
    expect(find.text(l.check), findsNothing);
  });

  testWidgets('a modify member adds records but cannot check or close', (
    tester,
  ) async {
    final b = FakeBackend()..addRegister('Main cash');
    b.access[b.registers.single.id] = {'m2': RegisterAccess.modify};
    await _pump(
      tester,
      backend: b,
      session: _session(manager: false, memberId: 'm2'),
    );

    await _tapText(tester, 'Main cash');
    expect(find.text(l.youCanModify), findsOneWidget);
    expect(find.text(l.addRecord), findsOneWidget);
    expect(find.text(l.check), findsNothing);
    expect(find.text(l.close), findsNothing);
  });

  testWidgets('wide screens show list and detail side by side', (tester) async {
    final b = FakeBackend()
      ..addRegister('Main cash', current: 100, real: 100)
      ..addRegister('Safe');
    await _pump(tester, backend: b, size: const Size(1400, 900));
    expect(find.text(l.selectRegister), findsOneWidget);

    await tester.tap(find.text('Safe'));
    await tester.pumpAndSettle();
    expect(find.text(l.cashOnHand), findsOneWidget);
    // The list stays visible next to the detail.
    expect(find.text('Main cash'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manager adds a member', (tester) async {
    final b = await _pump(tester);
    await _tapText(tester, l.navMembers);
    await _tapText(tester, l.addMember);
    await tester.enterText(_field(l.fullName), 'Alan Turing');
    await tester.enterText(_field(l.username), 'alan');
    await tester.enterText(_field(l.password), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, l.addMember));
    await tester.pumpAndSettle();

    expect(find.text(l.memberAdded('Alan Turing')), findsOneWidget);
    expect(b.members.map((m) => m.username), contains('alan'));
  });

  testWidgets('settling a loan requires choosing which loan', (tester) async {
    final b = FakeBackend()
      ..addRegister('Main cash', current: 10000, real: 10000);
    final id = b.registers.single.id;
    b.addRecord(
      id,
      RecordDraft(
        type: RecordType.receivableOpened,
        amount: 3000,
        note: 'Loan to Bob',
        deadline: DateTime.now().add(const Duration(days: 10)),
      ),
    );
    await _pump(tester, backend: b);
    await _tapText(tester, 'Main cash');

    await _tapText(tester, l.addRecord);
    await _tapText(tester, l.typeReceivableSettled);
    expect(find.text(l.whichObligation), findsOneWidget);

    // Saving without picking the loan is refused.
    await _tapText(tester, l.saveRecord);
    expect(find.text(l.chooseObligation), findsOneWidget);
    expect(b.records[id], hasLength(1));

    // Picking it fills in what is left; the record points at it.
    await _tapText(tester, 'Loan to Bob');
    expect(find.text(Money.toInput(3000)), findsOneWidget);
    await tester.enterText(_field(l.noteLabel), 'Bob paid back');
    await _tapText(tester, l.saveRecord);

    final settlement = b.records[id]!.first;
    expect(settlement.type, RecordType.receivableSettled);
    expect(settlement.parentRecordId, b.records[id]!.last.id);
    expect(b.registers.single.currentAmount, 10000);
  });

  testWidgets('access is either view or modify', (tester) async {
    final b = await _pump(tester);
    await _tapText(tester, l.newRegister);
    await tester.enterText(_field(l.name), 'Main cash');

    // No access level until the member is ticked.
    expect(find.text(l.accessView), findsNothing);
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    expect(find.text(l.accessView), findsOneWidget);
    expect(find.text(l.accessModify), findsOneWidget);

    await _tapText(tester, l.accessModify);
    await _tapText(tester, l.createRegister);
    expect(b.access[b.registers.single.id], {'m2': RegisterAccess.modify});
  });

  testWidgets('old money converter fills in the new amount', (tester) async {
    final b = FakeBackend()..addRegister('Main cash');
    await _pump(tester, backend: b);
    await _tapText(tester, 'Main cash');
    await _tapText(tester, l.addRecord);
    await _tapText(tester, l.typeIncome);

    await _tapText(tester, l.oldMoneyButton);
    await tester.enterText(find.byType(TextField).last, '1000000');
    await tester.pump();
    // Typed digits are grouped, and the new amount shows live.
    expect(find.text('1\u00A0000\u00A0000'), findsOneWidget);
    expect(find.text(Money.format(20000)), findsOneWidget);

    await _tapText(tester, l.oldMoneyUse);
    expect(find.text('200'), findsOneWidget);
    await tester.enterText(_field(l.noteLabel), 'Old money');
    await _tapText(tester, l.saveRecord);
    expect(b.registers.single.currentAmount, 20000);
  });

  testWidgets('a record needs a note', (tester) async {
    final b = FakeBackend()..addRegister('Main cash');
    await _pump(tester, backend: b);
    await _tapText(tester, 'Main cash');
    await _tapText(tester, l.addRecord);
    await _tapText(tester, l.typeIncome);

    await tester.enterText(_field(l.amount), '10');
    await tester.enterText(_field(l.noteLabel), '   ');
    await _tapText(tester, l.saveRecord);
    expect(find.text(l.errNoteRequired), findsOneWidget);
    expect(b.registers.single.currentAmount, 0);

    await tester.enterText(_field(l.noteLabel), 'Morning sales');
    await _tapText(tester, l.saveRecord);
    expect(b.registers.single.currentAmount, 1000);
  });

  testWidgets('deadline defaults to a week from today', (tester) async {
    final b = FakeBackend()..addRegister('Main cash');
    await _pump(tester, backend: b);
    await _tapText(tester, 'Main cash');
    await _tapText(tester, l.addRecord);
    await _tapText(tester, l.typeReceivableOpened);

    final week = DateUtils.addDaysToDate(DateUtils.dateOnly(DateTime.now()), 7);
    expect(find.text(Dates.date(week)), findsOneWidget);
  });

  testWidgets('pinned registers stay at the top', (tester) async {
    final b = FakeBackend()
      ..addRegister('Alpha')
      ..addRegister('Bravo')
      ..addRegister('Charlie');
    await _pump(tester, backend: b);

    double top(String name) => tester.getTopLeft(find.text(name)).dy;
    expect(top('Alpha'), lessThan(top('Charlie')));

    await _tapText(tester, 'Charlie');
    await tester.tap(find.byTooltip(l.more));
    await tester.pumpAndSettle();
    await _tapText(tester, l.pin);
    expect(find.text(l.registerPinned), findsOneWidget);
    expect(b.registers.last.isPinned, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    // Pinned first; the rest keep their order.
    expect(top('Charlie'), lessThan(top('Alpha')));
    expect(top('Alpha'), lessThan(top('Bravo')));
    expect(find.byIcon(LucideIcons.pin), findsOneWidget);

    await _tapText(tester, 'Charlie');
    await tester.tap(find.byTooltip(l.more));
    await tester.pumpAndSettle();
    await _tapText(tester, l.unpin);
    expect(b.registers.last.isPinned, isFalse);
  });

  testWidgets('long press or right-click a register to pin it', (tester) async {
    final b = FakeBackend()
      ..addRegister('Alpha')
      ..addRegister('Bravo');
    await _pump(tester, backend: b);

    await tester.longPress(find.text('Bravo'));
    await tester.pumpAndSettle();
    await _tapText(tester, l.pin);
    expect(find.text(l.registerPinned), findsOneWidget);
    expect(b.registers.last.isPinned, isTrue);
    expect(
      tester.getTopLeft(find.text('Bravo')).dy,
      lessThan(tester.getTopLeft(find.text('Alpha')).dy),
    );

    await tester.tap(find.text('Bravo'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await _tapText(tester, l.unpin);
    expect(b.registers.last.isPinned, isFalse);
  });

  testWidgets('members get no pin menu', (tester) async {
    final b = FakeBackend()..addRegister('Main cash');
    b.access[b.registers.single.id] = {'m2': RegisterAccess.modify};
    await _pump(
      tester,
      backend: b,
      session: _session(manager: false, memberId: 'm2'),
    );

    await tester.longPress(find.text('Main cash'));
    await tester.pumpAndSettle();
    expect(find.text(l.pin), findsNothing);
  });
}
