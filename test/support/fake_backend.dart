import 'package:cash_register/core/network/api_exception.dart';
import 'package:cash_register/core/offline/offline_providers.dart';
import 'package:cash_register/features/members/data/members_repository.dart';
import 'package:cash_register/features/members/domain/member.dart';
import 'package:cash_register/features/records/data/records_repository.dart';
import 'package:cash_register/features/records/domain/cash_record.dart';
import 'package:cash_register/features/records/domain/record_type.dart';
import 'package:cash_register/features/registers/data/registers_repository.dart';
import 'package:cash_register/features/registers/domain/cash_register.dart';
import 'package:cash_register/features/registers/domain/register_query.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// In-memory stand-in for the API, following the rules in docs/api.md
/// closely enough for widget tests.
class FakeBackend {
  final registers = <CashRegister>[];
  final records = <String, List<CashRecord>>{};
  final access = <String, Map<String, RegisterAccess>>{};
  final members = <Member>[
    const Member(
      id: 'm1',
      fullName: 'Ada Lovelace',
      username: 'ada',
      isActive: true,
    ),
    const Member(
      id: 'm2',
      fullName: 'Grace Hopper',
      username: 'grace',
      isActive: true,
    ),
  ];
  var _seq = 0;

  String _id(String prefix) => '$prefix-${++_seq}';

  CashRegister addRegister(String name, {int current = 0, int real = 0}) {
    final r = CashRegister(
      id: _id('r'),
      name: name,
      currentAmount: current,
      realAmount: real,
      createdAt: DateTime.now(),
    );
    registers.add(r);
    records[r.id] = [];
    return r;
  }

  CashRegister register(String id) => registers.firstWhere(
    (r) => r.id == id,
    orElse: () => throw const ApiException(
      code: 'not_found',
      message: 'resource not found',
      statusCode: 404,
    ),
  );

  void _replace(CashRegister next) =>
      registers[registers.indexWhere((r) => r.id == next.id)] = next;

  CashRegister _with(
    CashRegister r, {
    int? current,
    int? real,
    DateTime? checkedAt,
    DateTime? closedAt,
    bool? pinned,
  }) => CashRegister(
    id: r.id,
    name: r.name,
    currentAmount: current ?? r.currentAmount,
    realAmount: real ?? r.realAmount,
    createdAt: r.createdAt,
    checkedAt: checkedAt ?? r.checkedAt,
    closedAt: closedAt ?? r.closedAt,
    isPinned: pinned ?? r.isPinned,
  );

  CashRecord addRecord(String registerId, RecordDraft draft) {
    final r = register(registerId);
    if (!draft.type.allowedIn(r.status)) {
      throw const ApiException(
        code: 'conflict',
        message: 'cash register does not accept this record type',
        statusCode: 409,
      );
    }
    if (draft.type.needsFunds && draft.amount > r.currentAmount) {
      throw const ApiException(
        code: 'conflict',
        message: 'current amount is insufficient for this record',
        statusCode: 409,
      );
    }
    final record = CashRecord(
      id: _id('rec'),
      type: draft.type,
      amount: draft.amount,
      note: draft.note,
      createdBy: 'm1',
      createdAt: DateTime.now(),
      deadline: draft.deadline,
      parentRecordId: draft.parentRecordId,
      creator: members.first,
      destination: draft.destinationRegisterId == null
          ? null
          : RegisterRef(
              id: draft.destinationRegisterId!,
              name: register(draft.destinationRegisterId!).name,
            ),
    );
    _apply(r, draft.type, draft.amount);
    records[registerId]!.insert(0, record);

    if (draft.parentRecordId != null) {
      final list = records[registerId]!;
      final i = list.indexWhere((x) => x.id == draft.parentRecordId);
      final p = list[i];
      list[i] = CashRecord(
        id: p.id,
        type: p.type,
        amount: p.amount,
        note: p.note,
        createdBy: p.createdBy,
        createdAt: p.createdAt,
        deadline: p.deadline,
        creator: p.creator,
        children: [...p.children, record],
      );
    }
    if (draft.destinationRegisterId != null) {
      final dest = register(draft.destinationRegisterId!);
      _apply(dest, RecordType.transferIn, draft.amount);
      records[dest.id]!.insert(
        0,
        CashRecord(
          id: _id('rec'),
          type: RecordType.transferIn,
          amount: draft.amount,
          note: draft.note,
          createdBy: 'm1',
          createdAt: DateTime.now(),
          source: RegisterRef(id: r.id, name: r.name),
        ),
      );
    }
    return record;
  }

  void _apply(CashRegister r, RecordType type, int amount) => _replace(
    _with(
      register(r.id),
      current: register(r.id).currentAmount + type.currentSign * amount,
      real: register(r.id).realAmount + type.realSign * amount,
    ),
  );

  List<Override> get overrides => [
    // The fakes replace the repositories, so no local store is opened.
    offlineProvider.overrideWith((ref) async => null),
    registersRepositoryProvider.overrideWithValue(_FakeRegisters(this)),
    recordsRepositoryProvider.overrideWithValue(_FakeRecords(this)),
    membersRepositoryProvider.overrideWithValue(_FakeMembers(this)),
  ];
}

class _FakeRegisters implements RegistersRepository {
  _FakeRegisters(this.b);
  final FakeBackend b;

  @override
  Future<List<CashRegister>> list(RegisterQuery query) async {
    final q = query.search.toLowerCase();
    final found = b.registers
        .where((r) => r.name.toLowerCase().contains(q))
        .where(
          (r) => switch (query.filter) {
            RegisterFilter.closed => r.status == RegisterStatus.closed,
            RegisterFilter.unsettled => r.difference != 0,
            _ => true,
          },
        )
        .toList();
    return query.applyLocally(found);
  }

  @override
  Future<RegisterDetail> get(String id) async => RegisterDetail(
    register: b.register(id),
    members: [
      for (final e in (b.access[id] ?? const {}).entries)
        RegisterMember(
          member: b.members.firstWhere((m) => m.id == e.key),
          access: e.value,
        ),
    ],
  );

  @override
  Future<CashRegister> create({
    required String name,
    Map<String, RegisterAccess> access = const {},
  }) async {
    if (b.registers.any((r) => r.name == name)) {
      throw const ApiException(
        code: 'cash_register_name_taken',
        message: 'cash register name is already in use in this company',
        statusCode: 409,
        fields: {
          'name': 'cash register name is already in use in this company',
        },
      );
    }
    final r = b.addRegister(name);
    b.access[r.id] = {...access};
    return r;
  }

  @override
  Future<void> setAccess(String id, Map<String, RegisterAccess> access) async =>
      b.access[id] = {...access};

  @override
  Future<void> setPinned(String id, {required bool pinned}) async =>
      b._replace(b._with(b.register(id), pinned: pinned));

  @override
  Future<CashRegister> check(String id) async {
    b._replace(b._with(b.register(id), checkedAt: DateTime.now()));
    return b.register(id);
  }

  @override
  Future<CashRegister> close(String id) async {
    final r = b.register(id);
    if (r.difference != 0) {
      throw const ApiException(
        code: 'conflict',
        message: 'current amount and real amount must be equal',
        statusCode: 409,
      );
    }
    b._replace(b._with(r, closedAt: DateTime.now()));
    return b.register(id);
  }

  @override
  Future<void> delete(String id) async =>
      b.registers.removeWhere((r) => r.id == id);
}

class _FakeRecords implements RecordsRepository {
  _FakeRecords(this.b);
  final FakeBackend b;

  @override
  Future<List<CashRecord>> list(
    String registerId,
    RecordQuery query, {
    int offset = 0,
    int limit = RecordsRepository.pageSize,
  }) async {
    final q = query.search.toLowerCase();
    final found = (b.records[registerId] ?? const <CashRecord>[])
        .where((r) => query.type == null || r.type == query.type)
        .where(
          (r) => !query.onlyUnsettled || (r.type.isOpening && r.remaining > 0),
        )
        .where((r) => q.isEmpty || r.note.toLowerCase().contains(q))
        .where((r) => query.memberId == null || r.createdBy == query.memberId)
        .toList();
    // Stored newest first; a stable sort keeps that for equal keys.
    if (query.sort == RecordSort.amount) {
      final at = {for (final (i, r) in found.indexed) r.id: i};
      found.sort((a, b) {
        final c = query.ascending
            ? a.amount.compareTo(b.amount)
            : b.amount.compareTo(a.amount);
        return c != 0 ? c : at[a.id]!.compareTo(at[b.id]!);
      });
    } else if (query.ascending) {
      found.setAll(0, found.reversed.toList());
    }
    return found.skip(offset).take(limit).toList();
  }

  @override
  Future<RecordTotals> totals(String registerId, RecordQuery query) async =>
      RecordTotals.of(await list(registerId, query, limit: 1 << 30));

  List<RegisterRecord> get _all => [
    for (final r in b.registers)
      for (final record in b.records[r.id] ?? const <CashRecord>[])
        (register: r, record: record),
  ];

  @override
  Future<List<RegisterRecord>> openObligations() async =>
      _all
          .where((e) => e.record.remaining > 0 && e.record.deadline != null)
          .toList()
        ..sort((a, b) => a.record.deadline!.compareTo(b.record.deadline!));

  @override
  Future<List<RegisterRecord>> recent({int limit = 8}) async =>
      (_all..sort((a, b) => b.record.createdAt.compareTo(a.record.createdAt)))
          .take(limit)
          .toList();

  @override
  Future<CashRecord> create(String registerId, RecordDraft draft) async =>
      b.addRecord(registerId, draft);
}

class _FakeMembers implements MembersRepository {
  _FakeMembers(this.b);
  final FakeBackend b;

  @override
  Future<List<Member>> list() async => [...b.members];

  @override
  Future<Member> create({
    required String fullName,
    required String username,
    required String password,
  }) async {
    final m = Member(
      id: 'm${b.members.length + 1}',
      fullName: fullName,
      username: username,
      isActive: true,
    );
    b.members.add(m);
    return m;
  }

  @override
  Future<Member> update(String id, {String? password, bool? isActive}) async {
    final i = b.members.indexWhere((m) => m.id == id);
    final m = b.members[i];
    return b.members[i] = Member(
      id: m.id,
      fullName: m.fullName,
      username: m.username,
      isActive: isActive ?? m.isActive,
    );
  }
}
