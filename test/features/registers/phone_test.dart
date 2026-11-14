import 'package:cash_register/app/app.dart';
import 'package:cash_register/core/storage/storage_providers.dart';
import 'package:cash_register/features/auth/data/auth_repository.dart';
import 'package:cash_register/features/auth/domain/session.dart';
import 'package:cash_register/features/records/data/records_repository.dart';
import 'package:cash_register/features/records/domain/record_type.dart';
import 'package:cash_register/features/registers/domain/cash_register.dart';
import 'package:cash_register/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_backend.dart';
import '../auth/auth_flow_test.dart' show FakeAuthRepository;

final l = lookupAppLocalizations(appLocale);

Session _session({required bool manager}) => Session(
  token: 't',
  memberId: manager ? 'm1' : 'm2',
  companyId: 'c1',
  companyName: 'Acme',
  username: manager ? 'ada' : 'grace',
  fullName: manager ? 'Ada Lovelace' : 'Grace Hopper',
  isManager: manager,
);

Future<void> _pump(
  WidgetTester tester,
  FakeBackend b, {
  bool manager = true,
}) async {
  tester.view.physicalSize = const Size(400, 860);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository()..stored = _session(manager: manager),
        ),
        ...b.overrides,
      ],
      child: const CashRegisterApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a cashier adds a record from the list', (tester) async {
    final b = FakeBackend()
      ..addRegister('Main cash')
      ..addRegister('Safe');
    // Grace may add to Main cash only.
    b.access[b.registers.first.id] = {'m2': RegisterAccess.modify};
    await _pump(tester, b, manager: false);

    await tester.tap(find.text(l.addRecord));
    await tester.pumpAndSettle();
    // One register to add to: straight to the types.
    expect(find.text(RecordType.income.hint(l)), findsOneWidget);
  });

  testWidgets('overdue debts show on the list and open', (tester) async {
    final b = FakeBackend()..addRegister('Main cash', current: 1000);
    b.addRecord(
      b.registers.first.id,
      RecordDraft(
        type: RecordType.receivableOpened,
        amount: 300,
        note: 'Loan to Alan',
        deadline: DateTime.now().subtract(const Duration(days: 2)),
      ),
    );
    await _pump(tester, b);

    final banner = find.text(l.overdueCount('1'));
    expect(banner, findsOneWidget);
    await tester.tap(banner);
    await tester.pumpAndSettle();
    expect(find.text('Loan to Alan'), findsOneWidget);

    await tester.tap(find.text('Loan to Alan'));
    await tester.pumpAndSettle();
    expect(find.text(l.cashOnHand), findsOneWidget);
  });

  testWidgets('the add button shrinks while scrolling down', (tester) async {
    final b = FakeBackend()..addRegister('Main cash');
    for (var i = 0; i < 20; i++) {
      b.addRecord(
        b.registers.first.id,
        RecordDraft(type: RecordType.income, amount: 100 + i, note: 'R$i'),
      );
    }
    await _pump(tester, b);
    await tester.tap(find.text('Main cash'));
    await tester.pumpAndSettle();

    FloatingActionButton fab() =>
        tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
    expect(fab().isExtended, isTrue);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(fab().isExtended, isFalse);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(fab().isExtended, isTrue);
  });
}
