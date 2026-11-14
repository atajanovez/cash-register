import 'package:cash_register/app/app.dart';
import 'package:cash_register/core/storage/storage_providers.dart';
import 'package:cash_register/features/auth/data/auth_repository.dart';
import 'package:cash_register/features/auth/domain/session.dart';
import 'package:cash_register/features/records/data/records_repository.dart';
import 'package:cash_register/features/records/domain/record_type.dart';
import 'package:cash_register/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_backend.dart';
import '../auth/auth_flow_test.dart' show FakeAuthRepository;

final l = lookupAppLocalizations(appLocale);

const _manager = Session(
  token: 't',
  memberId: 'm1',
  companyId: 'c1',
  companyName: 'Acme',
  username: 'ada',
  fullName: 'Ada Lovelace',
  isManager: true,
);

Future<FakeBackend> _pump(
  WidgetTester tester, {
  Size size = const Size(1400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final b = FakeBackend()
    ..addRegister('Main cash', current: 0, real: 0)
    ..addRegister('Safe');
  final main = b.registers.first.id;
  b
    ..addRecord(
      main,
      const RecordDraft(type: RecordType.income, amount: 500, note: 'Small'),
    )
    ..addRecord(
      main,
      const RecordDraft(type: RecordType.income, amount: 9000, note: 'Big'),
    );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository()..stored = _manager,
        ),
        ...b.overrides,
      ],
      child: const CashRegisterApp(),
    ),
  );
  await tester.pumpAndSettle();
  return b;
}

Future<void> _ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

/// Top-to-bottom order of [texts] on screen.
List<String> _order(WidgetTester tester, List<String> texts) =>
    [...texts]..sort(
      (a, b) => tester
          .getTopLeft(find.text(a).first)
          .dy
          .compareTo(tester.getTopLeft(find.text(b).first).dy),
    );

void main() {
  testWidgets('arrow keys move through the registers', (tester) async {
    await _pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text(l.cashOnHand), findsOneWidget);
    expect(find.text('Small'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('Small'), findsNothing);
  });

  testWidgets('Ctrl+N opens the add record dialog on a register', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Main cash'));
    await tester.pumpAndSettle();
    await _ctrl(tester, LogicalKeyboardKey.keyN);
    expect(find.text(RecordType.income.hint(l)), findsOneWidget);

    // A digit picks a type.
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pumpAndSettle();
    expect(find.text(RecordType.expense.hint(l)), findsOneWidget);
  });

  testWidgets('Ctrl+K focuses the register search', (tester) async {
    await _pump(tester);
    await _ctrl(tester, LogicalKeyboardKey.keyK);
    await tester.enterText(find.byType(TextField).first, 'saf');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.text('Main cash'), findsNothing);
  });

  testWidgets('the amount column sorts and flips', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Main cash'));
    await tester.pumpAndSettle();
    expect(_order(tester, ['Small', 'Big']), ['Big', 'Small']); // newest

    await tester.tap(find.text(l.colAmount));
    await tester.pumpAndSettle();
    expect(_order(tester, ['Small', 'Big']), ['Big', 'Small']);

    await tester.tap(find.text(l.colAmount));
    await tester.pumpAndSettle();
    expect(_order(tester, ['Small', 'Big']), ['Small', 'Big']);
  });

  testWidgets('wide windows show a record in a side panel', (tester) async {
    await _pump(tester, size: const Size(1700, 950));
    await tester.tap(find.text('Main cash'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Big'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text(l.detailNote), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(l.detailNote), findsNothing);
  });
}
