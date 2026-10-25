import 'dart:io';

import 'package:cash_register/core/network/api_exception.dart';
import 'package:cash_register/core/offline/local_store.dart';
import 'package:cash_register/core/offline/remote_api.dart';
import 'package:cash_register/core/offline/sync_engine.dart';
import 'package:cash_register/features/records/data/records_repository.dart';
import 'package:cash_register/features/registers/domain/cash_register.dart';
import 'package:cash_register/features/registers/domain/register_query.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = 'm1';

Json _register(String id, String name, {int current = 0, int real = 0}) => {
  'id': id,
  'name': name,
  'current_amount': current,
  'real_amount': real,
  'created_at': '2026-10-20T10:00:00Z',
  'checked_at': null,
  'closed_at': null,
};

/// A server in memory. `syncWorks` switches between the sync endpoint and
/// the REST fallback; `online` simulates the connection.
class FakeRemote extends RemoteApi {
  FakeRemote() : super(Dio());

  bool online = true;
  bool syncWorks = true;
  final serverRegisters = <String, Json>{};
  final records = <String, List<Json>>{};
  final serverMembers = <Json>[
    {'id': _me, 'full_name': 'Ada Lovelace', 'username': 'ada'},
  ];
  final syncRequests = <Json>[];
  Json Function(Json body)? onSync;
  ApiException? rejectNextRecord;
  var _seq = 0;

  void _net() {
    if (!online) {
      throw const ApiException(code: 'network', message: 'offline');
    }
  }

  @override
  Future<Json> sync(Json body) async {
    _net();
    syncRequests.add(body);
    if (!syncWorks) {
      throw const ApiException(
        code: 'internal_error',
        message: 'an unexpected error occurred',
        statusCode: 500,
      );
    }
    return onSync!(body);
  }

  @override
  Future<List<Json>> members() async {
    _net();
    return serverMembers;
  }

  @override
  Future<List<Json>> registers() async {
    _net();
    return serverRegisters.values.toList();
  }

  @override
  Future<Json> registerDetail(String id) async {
    _net();
    return {'cash_register': serverRegisters[id], 'members': <Json>[]};
  }

  @override
  Future<List<Json>> allRecords(String registerId) async {
    _net();
    return records[registerId] ?? [];
  }

  @override
  Future<Json> createRegister(Json body) async {
    _net();
    final id = 'srv-r${++_seq}';
    serverRegisters[id] = _register(id, body['name'] as String);
    return serverRegisters[id]!;
  }

  @override
  Future<Json> createRecord(String registerId, Json body) async {
    _net();
    final reject = rejectNextRecord;
    if (reject != null) {
      rejectNextRecord = null;
      throw reject;
    }
    final register = serverRegisters[registerId]!;
    final amount = body['amount'] as int;
    final sign = body['type'] == 'expense' ? -1 : 1;
    register['current_amount'] =
        (register['current_amount'] as int) + sign * amount;
    register['real_amount'] = (register['real_amount'] as int) + sign * amount;
    final record = {
      'id': 'srv-rec${++_seq}',
      ...body,
      'created_by': _me,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    records.putIfAbsent(registerId, () => []).add(record);
    return record;
  }
}

void main() {
  late LocalStore store;
  late FakeRemote remote;
  late SyncEngine engine;

  setUp(() {
    store = LocalStore.memory(memberId: _me);
    remote = FakeRemote();
    engine = SyncEngine(store, remote);
  });
  tearDown(() => engine.dispose());

  group('local view', () {
    setUp(() {
      store.snapshot.registers['r1'] = _register(
        'r1',
        'Main',
        current: 1000,
        real: 1000,
      );
      store.snapshot.registers['r2'] = _register('r2', 'Safe');
      store.snapshot.members[_me] = remote.serverMembers.first;
    });

    test('offline records change balances and show as pending', () {
      store.add(
        'record.create',
        entityId: 'x1',
        payload: {
          'cash_register_id': 'r1',
          'type': 'expense',
          'amount': 300,
          'note': 'Rent',
        },
      );
      final main = store.view.register('r1')!;
      expect(main.currentAmount, 700);
      expect(main.isPending, isFalse);
      final record = store.view.records('r1', const RecordQuery()).single;
      expect(record.isPending, isTrue);
      expect(record.creator?.username, 'ada');
      // The snapshot itself is untouched.
      expect(store.snapshot.registers['r1']!['current_amount'], 1000);
    });

    test('a transfer moves money into the other register', () {
      store.add(
        'record.create',
        entityId: 't1',
        payload: {
          'cash_register_id': 'r1',
          'type': 'transfer_out',
          'amount': 400,
          'destination_cash_register_id': 'r2',
        },
      );
      expect(store.view.register('r1')!.currentAmount, 600);
      expect(store.view.register('r2')!.currentAmount, 400);
      final incoming = store.view.records('r2', const RecordQuery()).single;
      expect(incoming.source?.name, 'Main');
    });

    test('settlements reduce what is left on the opening', () {
      store.add(
        'record.create',
        entityId: 'a1',
        payload: {
          'cash_register_id': 'r1',
          'type': 'accrual_income',
          'amount': 500,
          'deadline': '2026-11-01T00:00:00Z',
        },
      );
      store.add(
        'record.create',
        entityId: 's1',
        payload: {
          'cash_register_id': 'r1',
          'type': 'accrual_income_settled',
          'amount': 200,
          'parent_record_id': 'a1',
        },
      );
      final opening = store.view
          .records('r1', const RecordQuery())
          .firstWhere((r) => r.id == 'a1');
      expect(opening.remaining, 300);
      expect(store.view.register('r1')!.realAmount, 1500);
    });

    test('registers can be created, checked and given access offline', () {
      store.add(
        'cash_register.create',
        entityId: 'new',
        payload: {
          'name': 'Bazar',
          'members': [
            {'member_id': _me, 'access': 'modify'},
          ],
        },
      );
      store.add('cash_register.check', entityId: 'r1');
      final names = store.view
          .registers(const RegisterQuery())
          .map((r) => r.name);
      expect(names, containsAll(['Main', 'Safe', 'Bazar']));
      expect(store.view.register('r1')!.status, RegisterStatus.checked);
      expect(store.view.detail('new')!.accessOf(_me), RegisterAccess.modify);
    });

    test('refused changes are not shown', () {
      final op = store.add('cash_register.check', entityId: 'r1');
      op.status = OutboxStatus.rejected;
      store.changed();
      expect(store.view.register('r1')!.status, RegisterStatus.open);
    });
  });

  group('sync endpoint', () {
    test('pushes operations and applies pulled changes page by page', () async {
      store.add(
        'cash_register.create',
        entityId: 'r9',
        payload: {'name': 'Bazar', 'members': <Json>[]},
      );
      var call = 0;
      remote.onSync = (body) {
        call++;
        if (call == 1) {
          final op = (body['operations'] as List).single as Map;
          return {
            'results': [
              {
                'operation_id': op['operation_id'],
                'status': 'accepted',
                'entity_id': 'r9',
              },
            ],
            'changes': [
              {
                'sequence': 1,
                'entity_type': 'cash_registers',
                'entity_id': 'r9',
                'action': 'upsert',
                'payload': _register('r9', 'Bazar'),
              },
            ],
            'next_cursor': 1,
            'has_more': true,
          };
        }
        expect(body['cursor'], 1);
        return {
          'results': <Json>[],
          'changes': [
            {
              'sequence': 2,
              'entity_type': 'records',
              'entity_id': 'rec1',
              'action': 'upsert',
              'payload': {
                'id': 'rec1',
                'cash_register_id': 'r9',
                'type': 'income',
                'amount': 50,
                'created_by': _me,
                'created_at': '2026-10-25T09:00:00Z',
              },
            },
          ],
          'next_cursor': 2,
          'has_more': false,
        };
      };

      await engine.sync();

      expect(call, 2);
      expect(store.outbox, isEmpty);
      expect(store.cursor, 2);
      expect(store.view.register('r9')!.isPending, isFalse);
      expect(store.view.records('r9', const RecordQuery()).single.amount, 50);
      expect(engine.status.phase, SyncPhase.idle);
      expect(store.hasData, isTrue);
    });

    test('refused operations are kept for the user', () async {
      store.snapshot.registers['r1'] = _register('r1', 'Main');
      store.add(
        'record.create',
        entityId: 'x',
        payload: {'cash_register_id': 'r1', 'type': 'expense', 'amount': 999},
      );
      remote.onSync = (body) => {
        'results': [
          {
            'operation_id':
                ((body['operations'] as List).single as Map)['operation_id'],
            'status': 'rejected',
            'error_code': 'conflict',
            'message': 'current amount is insufficient for this record',
          },
        ],
        'changes': <Json>[],
        'next_cursor': 0,
        'has_more': false,
      };

      await engine.sync();

      expect(
        engine.status.rejected.single.errorMessage,
        contains('insufficient'),
      );
      expect(store.view.records('r1', const RecordQuery()), isEmpty);
    });
  });

  group('REST fallback', () {
    test('replays offline changes with the ids the server gives', () async {
      remote.syncWorks = false;
      store.add(
        'cash_register.create',
        entityId: 'local-r',
        payload: {'name': 'Bazar', 'members': <Json>[]},
      );
      store.add(
        'record.create',
        entityId: 'local-rec',
        payload: {
          'cash_register_id': 'local-r',
          'type': 'income',
          'amount': 250,
        },
      );

      await engine.sync();

      expect(store.resolve('local-r'), 'srv-r1');
      // The record went into the register under its server id.
      expect(remote.records['srv-r1']!.single['amount'], 250);
      expect(store.outbox, isEmpty);
      final register = store.view.register('srv-r1')!;
      expect(register.currentAmount, 250);
      expect(register.isPending, isFalse);
      expect(
        store.view.records(store.resolve('local-r'), const RecordQuery()),
        hasLength(1),
      );
    });

    test(
      'offline: changes wait, then go out when the connection is back',
      () async {
        remote
          ..syncWorks = false
          ..online = false;
        remote.serverRegisters['r1'] = _register(
          'r1',
          'Main',
          current: 100,
          real: 100,
        );
        store.snapshot.registers['r1'] = Map.of(remote.serverRegisters['r1']!);

        await engine.submit(
          'record.create',
          entityId: 'x',
          payload: {'cash_register_id': 'r1', 'type': 'income', 'amount': 40},
        );
        expect(engine.status.phase, SyncPhase.offline);
        expect(engine.status.pending, 1);
        expect(store.view.register('r1')!.currentAmount, 140);

        remote.online = true;
        await engine.sync();

        expect(engine.status.pending, 0);
        expect(engine.status.phase, SyncPhase.idle);
        expect(remote.serverRegisters['r1']!['current_amount'], 140);
        expect(store.view.register('r1')!.currentAmount, 140);
      },
    );

    test('online, a refused change throws so the form can show why', () async {
      remote.syncWorks = false;
      remote.serverRegisters['r1'] = _register('r1', 'Main');
      store.snapshot.registers['r1'] = Map.of(remote.serverRegisters['r1']!);
      remote.rejectNextRecord = const ApiException(
        code: 'conflict',
        message: 'current amount is insufficient for this record',
        statusCode: 409,
      );

      await expectLater(
        engine.submit(
          'record.create',
          entityId: 'x',
          payload: {'cash_register_id': 'r1', 'type': 'expense', 'amount': 10},
        ),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'conflict')),
      );
      expect(store.outbox, isEmpty);
    });
  });

  test('local data survives a restart', () async {
    final dir = await Directory.systemTemp.createTemp('kassa_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/data.json');

    final first = await LocalStore.open(file, memberId: _me);
    first.snapshot.registers['r1'] = _register('r1', 'Main', current: 10);
    first.add('cash_register.check', entityId: 'r1');
    await first.save();
    final deviceId = first.deviceId;
    first.dispose();

    final second = await LocalStore.open(file, memberId: _me);
    expect(second.deviceId, deviceId);
    expect(second.pending.single.type, 'cash_register.check');
    expect(second.view.register('r1')!.status, RegisterStatus.checked);
    second.dispose();
  });
}
