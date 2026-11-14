import 'package:flutter/material.dart' show DateUtils;

import '../../features/members/domain/member.dart';
import '../../features/records/data/records_repository.dart'
    show RecordQuery, RecordSort, RegisterRecord;
import '../../features/records/domain/cash_record.dart';
import '../../features/records/domain/record_type.dart';
import '../../features/registers/domain/cash_register.dart';
import '../../features/registers/domain/register_query.dart';
import 'local_store.dart';

/// The data screens show: the server [Snapshot] with every unconfirmed
/// change from the outbox applied on top, using the same balance rules as
/// the server (docs/api.md). Rebuilt whenever the store changes.
class LocalView {
  LocalView._(this._registers, this._access, this._records, this._members);

  final Map<String, Json> _registers;
  final Map<String, Map<String, Json>> _access;
  final Map<String, Map<String, Json>> _records;
  final Map<String, Json> _members;

  factory LocalView.build(LocalStore store) {
    final s = store.snapshot;
    final view = LocalView._(
      Map.of(s.registers),
      Map.of(s.access),
      Map.of(s.records),
      s.members,
    );
    final replay = _Replay(view, store);
    for (final op in store.outbox) {
      if (op.status != OutboxStatus.rejected) replay.apply(op);
    }
    return view;
  }

  // ─── Queries ──────────────────────────────────────────────────────────

  CashRegister? register(String id) {
    final json = _registers[id];
    return json == null ? null : CashRegister.fromJson(json);
  }

  List<CashRegister> registers(RegisterQuery query) {
    final search = query.search.trim().toLowerCase();
    final list = [
      for (final json in _registers.values) CashRegister.fromJson(json),
    ].where((r) => search.isEmpty || r.name.toLowerCase().contains(search));

    final filtered = switch (query.filter) {
      RegisterFilter.all => list,
      RegisterFilter.open => list.where((r) => r.status == RegisterStatus.open),
      RegisterFilter.checked => list.where(
        (r) => r.status == RegisterStatus.checked,
      ),
      RegisterFilter.closed => list.where(
        (r) => r.status == RegisterStatus.closed,
      ),
      RegisterFilter.unsettled => list.where((r) => r.difference != 0),
    }.toList();

    Comparable<Object>? key(CashRegister r) =>
        switch (query.sort) {
              RegisterSort.createdAt => r.createdAt,
              RegisterSort.currentAmount => r.currentAmount,
              RegisterSort.realAmount => r.realAmount,
              RegisterSort.checkedAt => r.checkedAt,
              RegisterSort.closedAt => r.closedAt,
            }
            as Comparable<Object>?;

    filtered.sort((a, b) {
      final ka = key(a), kb = key(b);
      // Missing dates go last either way.
      if (ka == null || kb == null) {
        return ka == null && kb == null ? 0 : (ka == null ? 1 : -1);
      }
      final c = ka.compareTo(kb);
      return query.descending ? -c : c;
    });
    return query.applyLocally(filtered);
  }

  RegisterDetail? detail(String id) {
    final register = _registers[id];
    if (register == null) return null;
    return RegisterDetail.fromJson({
      'cash_register': register,
      'members': [
        for (final row in (_access[id] ?? const {}).values)
          {...?_members[row['id']], ...row},
      ],
    });
  }

  List<Member> members() => [
    for (final json in _members.values) Member.fromJson(json),
  ];

  /// Filtered like the server's records endpoint (plus a period), newest
  /// first unless the query asks otherwise.
  List<CashRecord> records(String registerId, RecordQuery query) {
    final raw = _records[registerId];
    if (raw == null) return const [];
    final children = <String, List<Json>>{};
    for (final r in raw.values) {
      final parent = r['parent_record_id'] as String?;
      if (parent != null) children.putIfAbsent(parent, () => []).add(r);
    }
    final search = query.search.trim().toLowerCase();
    final period = query.period;
    // Local days: the period's last day counts up to its midnight.
    final from = period == null ? null : DateUtils.dateOnly(period.start);
    final until = period == null
        ? null
        : DateUtils.addDaysToDate(DateUtils.dateOnly(period.end), 1);

    final out = <CashRecord>[];
    for (final r in raw.values) {
      if (query.type != null && r['type'] != query.type!.wire) continue;
      if (query.memberId != null && r['created_by'] != query.memberId) {
        continue;
      }
      final record = CashRecord.fromJson(_enrich(r, raw, children));
      if (query.onlyUnsettled && record.remaining <= 0) continue;
      if (from != null) {
        final at = record.createdAt.toLocal();
        if (at.isBefore(from) || !at.isBefore(until!)) continue;
      }
      if (search.isNotEmpty) {
        final hay = [
          record.note,
          record.creator?.displayName ?? '',
          record.creator?.username ?? '',
        ].join(' ').toLowerCase();
        if (!hay.contains(search)) continue;
      }
      out.add(record);
    }
    out.sort((a, b) {
      final c = switch (query.sort) {
        RecordSort.time => a.createdAt.compareTo(b.createdAt),
        RecordSort.amount => a.amount.compareTo(b.amount),
      };
      // Same amount: newest first, so the order stays stable.
      final tie = c == 0 ? b.createdAt.compareTo(a.createdAt) : 0;
      return c == 0 ? tie : (query.ascending ? c : -c);
    });
    return out;
  }

  /// Borrows, loans and accrued income with something left to settle and a
  /// due date, across every register this member can see; earliest first.
  List<RegisterRecord> openObligations() {
    final out = <RegisterRecord>[];
    for (final registerId in _records.keys) {
      final register = this.register(registerId);
      if (register == null) continue;
      for (final record in records(
        registerId,
        const RecordQuery(onlyUnsettled: true),
      )) {
        if (record.deadline != null) {
          out.add((register: register, record: record));
        }
      }
    }
    out.sort((a, b) => a.record.deadline!.compareTo(b.record.deadline!));
    return out;
  }

  /// The newest records of every visible register, for the overview.
  List<RegisterRecord> recentRecords(int limit) {
    final out = <RegisterRecord>[];
    for (final registerId in _records.keys) {
      final register = this.register(registerId);
      if (register == null) continue;
      for (final record in records(
        registerId,
        const RecordQuery(),
      ).take(limit)) {
        out.add((register: register, record: record));
      }
    }
    out.sort((a, b) => b.record.createdAt.compareTo(a.record.createdAt));
    return out.take(limit).toList();
  }

  /// Fills in what list responses embed (creator, parent, children, the
  /// other register of a transfer) from what we have locally, so records
  /// from any source look the same.
  Json _enrich(
    Json r,
    Map<String, Json> sameRegister,
    Map<String, List<Json>> children,
  ) {
    final out = Map<String, Object?>.of(r);
    out['creator'] ??= _members[r['created_by']];
    if (out['destination'] == null) {
      final id = r['destination_cash_register_id'] as String?;
      final reg = id == null ? null : _registers[id];
      if (reg != null) out['destination'] = {'id': id, 'name': reg['name']};
    }
    if (out['source'] == null) {
      final id = r['source_cash_register_id'] as String?;
      final reg = id == null ? null : _registers[id];
      if (reg != null) out['source'] = {'id': id, 'name': reg['name']};
    }
    final parentId = r['parent_record_id'] as String?;
    if (parentId != null && sameRegister[parentId] != null) {
      out['parent'] = _plain(sameRegister[parentId]!);
    }
    out['children'] = [
      for (final c in children[r['id']] ?? const <Json>[]) _plain(c),
    ];
    return out;
  }

  static Json _plain(Json r) => {
    for (final e in r.entries)
      if (!const {
        'creator',
        'parent',
        'children',
        'destination',
        'source',
      }.contains(e.key))
        e.key: e.value,
  };
}

/// Applies outbox operations to a [LocalView] under construction. Maps are
/// copied the first time they are changed, so the snapshot stays untouched.
class _Replay {
  _Replay(this.view, this.store);

  final LocalView view;
  final LocalStore store;
  final _copiedRegisters = <String>{};
  final _copiedRecords = <String>{};
  final _copiedAccess = <String>{};

  String? _id(Object? id) => id is String ? store.resolve(id) : null;

  Json? _register(String id) {
    final json = view._registers[id];
    if (json == null) return null;
    if (_copiedRegisters.add(id)) view._registers[id] = Map.of(json);
    return view._registers[id];
  }

  Map<String, Json> _recordsOf(String registerId) {
    if (_copiedRecords.add(registerId)) {
      view._records[registerId] = Map.of(view._records[registerId] ?? {});
    }
    return view._records[registerId]!;
  }

  Map<String, Json> _accessOf(String registerId) {
    if (_copiedAccess.add(registerId)) {
      view._access[registerId] = Map.of(view._access[registerId] ?? {});
    }
    return view._access[registerId]!;
  }

  void _add(Json register, String field, int delta) {
    if (delta == 0) return;
    register[field] = ((register[field] as num?) ?? 0).toInt() + delta;
  }

  void apply(OutboxEntry op) {
    final p = op.payload ?? const {};
    final at = op.createdAt.toUtc().toIso8601String();
    final entity = _id(op.entityId);

    switch (op.type) {
      case 'record.create':
        final registerId = _id(p['cash_register_id']);
        final register = registerId == null ? null : _register(registerId);
        if (register == null || entity == null) return;
        final type = RecordType.fromWire(p['type'] as String);
        final amount = (p['amount'] as num).toInt();
        final destinationId = _id(p['destination_cash_register_id']);
        _recordsOf(registerId!)[entity] = {
          'id': entity,
          'type': type.wire,
          'amount': amount,
          'note': p['note'] ?? '',
          'deadline': p['deadline'],
          'parent_record_id': _id(p['parent_record_id']),
          'destination_cash_register_id': destinationId,
          'created_by': store.memberId,
          'created_at': at,
          '_pending': true,
        };
        _add(register, 'current_amount', type.currentSign * amount);
        _add(register, 'real_amount', type.realSign * amount);
        if (type == RecordType.transferOut && destinationId != null) {
          final destination = _register(destinationId);
          if (destination != null) {
            _recordsOf(destinationId)['$entity:in'] = {
              'id': '$entity:in',
              'type': RecordType.transferIn.wire,
              'amount': amount,
              'note': p['note'] ?? '',
              'source_cash_register_id': registerId,
              'counterpart_record_id': entity,
              'created_by': store.memberId,
              'created_at': at,
              '_pending': true,
            };
            _add(destination, 'current_amount', amount);
            _add(destination, 'real_amount', amount);
          }
        }
      case 'cash_register.create':
        if (entity == null) return;
        view._registers[entity] = {
          'id': entity,
          'name': p['name'],
          'current_amount': 0,
          'real_amount': 0,
          'created_at': at,
          'checked_at': null,
          'closed_at': null,
          '_pending': true,
        };
        _copiedRegisters.add(entity);
        _setAccess(entity, p['members']);
      case 'cash_register.check':
        final register = entity == null ? null : _register(entity);
        if (register != null) {
          register['checked_at'] ??= at;
          register['_pending'] = true;
        }
      case 'cash_register.close':
        final register = entity == null ? null : _register(entity);
        if (register != null) {
          register['closed_at'] ??= at;
          register['_pending'] = true;
        }
      case 'cash_register.delete':
        if (entity == null) return;
        view._registers.remove(entity);
        view._records.remove(entity);
        view._access.remove(entity);
      case 'cash_register.access_set':
        if (entity != null && view._registers.containsKey(entity)) {
          _setAccess(entity, p['members']);
        }
    }
  }

  void _setAccess(String registerId, Object? members) {
    final rows = _accessOf(registerId)..clear();
    for (final m in members as List? ?? const []) {
      final memberId = _id((m as Map)['member_id']);
      if (memberId == null) continue;
      rows[memberId] = {
        ...?view._members[memberId],
        'id': memberId,
        'access': m['access'],
      };
    }
  }
}
