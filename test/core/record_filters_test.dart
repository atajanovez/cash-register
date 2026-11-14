import 'package:cash_register/core/offline/local_store.dart';
import 'package:cash_register/features/records/application/records_controller.dart';
import 'package:cash_register/features/records/data/records_repository.dart';
import 'package:cash_register/features/records/domain/record_type.dart';
import 'package:cash_register/features/records/presentation/record_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Json _register(String id, String name) => {
  'id': id,
  'name': name,
  'current_amount': 0,
  'real_amount': 0,
  'created_at': '2026-10-01T10:00:00Z',
  'checked_at': null,
  'closed_at': null,
};

Json _record(
  String id,
  RecordType type,
  int amount,
  DateTime at, {
  String by = 'm1',
  DateTime? deadline,
}) => {
  'id': id,
  'type': type.wire,
  'amount': amount,
  'note': id,
  'created_by': by,
  'created_at': at.toUtc().toIso8601String(),
  'deadline': deadline?.toUtc().toIso8601String(),
};

void main() {
  late LocalStore store;
  final day = DateTime(2026, 11, 2, 12);

  setUp(() {
    store = LocalStore.memory(memberId: 'm1');
    final s = store.snapshot;
    s.registers['r1'] = _register('r1', 'Main');
    s.registers['r2'] = _register('r2', 'Safe');
    s.records['r1'] = {
      'a': _record('a', RecordType.income, 500, day),
      'b': _record(
        'b',
        RecordType.expense,
        200,
        day.subtract(const Duration(days: 1)),
        by: 'm2',
      ),
      'c': _record(
        'c',
        RecordType.income,
        900,
        day.subtract(const Duration(days: 10)),
      ),
      'loan': _record(
        'loan',
        RecordType.receivableOpened,
        300,
        day.subtract(const Duration(days: 20)),
        deadline: day.subtract(const Duration(days: 2)),
      ),
    };
    s.records['r2'] = {
      'debt': _record(
        'debt',
        RecordType.payableOpened,
        100,
        day.subtract(const Duration(days: 3)),
        deadline: day.add(const Duration(days: 3)),
      ),
      'later': _record(
        'later',
        RecordType.accrualIncome,
        50,
        day.subtract(const Duration(days: 3)),
        deadline: day.add(const Duration(days: 30)),
      ),
    };
  });

  List<String> ids(RecordQuery q) =>
      store.view.records('r1', q).map((r) => r.id).toList();

  test('period keeps whole local days, both ends included', () {
    final yesterday = DateUtils.dateOnly(day.subtract(const Duration(days: 1)));
    expect(
      ids(
        RecordQuery(
          period: DateTimeRange(start: yesterday, end: DateUtils.dateOnly(day)),
        ),
      ),
      ['a', 'b'],
    );
  });

  test('member filter keeps what that member made', () {
    expect(ids(const RecordQuery(memberId: 'm2')), ['b']);
  });

  test('sorts by amount either way', () {
    expect(ids(const RecordQuery(sort: RecordSort.amount)), [
      'c',
      'a',
      'loan',
      'b',
    ]);
    expect(ids(const RecordQuery(sort: RecordSort.amount, ascending: true)), [
      'b',
      'loan',
      'a',
      'c',
    ]);
  });

  test('totals count cash in and out of every match', () {
    final t = RecordTotals.of(store.view.records('r1', const RecordQuery()));
    expect(t.count, 4);
    expect(t.moneyIn, 1400);
    // Lending money out takes cash too.
    expect(t.moneyOut, 500);
    expect(t.net, 900);
  });

  test('due obligations split into overdue and due soon', () {
    final due = DueObligations.of(store.view.openObligations(), day);
    expect(due.overdue.map((e) => e.record.id), ['loan']);
    expect(due.overdue.single.register.name, 'Main');
    expect(due.soon.map((e) => e.record.id), ['debt']);
  });

  test('recent records span registers, newest first', () {
    final recent = store.view.recentRecords(3);
    expect(recent.map((e) => e.record.id), ['a', 'b', 'debt']);
  });

  test('period presets end today', () {
    final now = DateTime(2026, 11, 5); // Thursday
    expect(PeriodPreset.week.range(now).start, DateTime(2026, 11, 2));
    expect(PeriodPreset.month.range(now).start, DateTime(2026, 11));
    expect(PeriodPreset.today.range(now).end, now);
  });
}
