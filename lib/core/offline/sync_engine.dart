import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';
import 'local_store.dart';
import 'remote_api.dart';

enum SyncPhase { idle, syncing, offline, error }

@immutable
class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.pending = 0,
    this.rejected = const [],
    this.lastSyncedAt,
    this.error,
    this.hasData = true,
  });

  final SyncPhase phase;

  /// Changes made on this device that the server has not taken yet.
  final int pending;

  /// Changes the server refused; the user decides what to do with them.
  final List<OutboxEntry> rejected;
  final DateTime? lastSyncedAt;
  final ApiException? error;

  /// False until the first successful download on this device.
  final bool hasData;

  bool get isOffline => phase == SyncPhase.offline;
}

/// Moves changes between the device and the server.
///
/// - Changes are queued in the [LocalStore] outbox and shown at once.
/// - [sync] pushes them with `POST /v1/sync` and pulls the company's changes
///   after the stored cursor, repeating while `has_more` is true.
/// - While the sync endpoint fails on the server (it answers 500 as of
///   2026-10-25, see docs/sync.md), the same work is done through the REST
///   endpoints instead: each queued change is replayed as its REST call and
///   the data is downloaded again.
/// - Runs when the app starts, when a connection comes back, every few
///   minutes, and right after a change is made.
class SyncEngine extends ChangeNotifier {
  SyncEngine(this.store, this.remote, {this.connectivity});

  final LocalStore store;
  final RemoteApi remote;

  /// True when the device has a network connection, false when it lost it.
  final Stream<bool>? connectivity;

  static const _period = Duration(minutes: 3);
  static const _endpointRetryAfter = Duration(minutes: 10);

  SyncPhase _phase = SyncPhase.idle;
  ApiException? _error;
  DateTime? _endpointBrokenUntil;
  Future<void>? _running;
  bool _again = false;
  bool _wantPull = false;
  Timer? _timer;
  StreamSubscription<bool>? _connectivitySub;
  bool _disposed = false;

  SyncStatus get status => SyncStatus(
    phase: _phase,
    pending: store.outbox.where((e) => e.status == OutboxStatus.pending).length,
    rejected: store.rejected,
    lastSyncedAt: store.lastSyncedAt,
    error: _error,
    hasData: store.hasData,
  );

  void start() {
    _connectivitySub = connectivity?.listen((online) {
      if (online) {
        unawaited(sync());
      } else {
        _setPhase(SyncPhase.offline);
      }
    });
    _timer = Timer.periodic(_period, (_) => sync());
    unawaited(sync());
  }

  /// Queues a change and, when online, sends it straight away. Throws the
  /// server's [ApiException] if it refuses the change, so a form can show
  /// the reason; offline it returns at once and the change waits.
  Future<void> submit(String type, {String? entityId, Json? payload}) async {
    final entry = store.add(type, entityId: entityId, payload: payload);
    if (_phase == SyncPhase.offline) {
      // The connection may be back already; this does not block the form.
      unawaited(sync());
      return;
    }
    await sync(
      pull: false,
    ).timeout(const Duration(seconds: 12), onTimeout: () {});
    if (entry.status == OutboxStatus.rejected) {
      store.remove(entry.operationId);
      throw ApiException(
        code: entry.errorCode ?? 'conflict',
        message: entry.errorMessage ?? '',
        statusCode: 409,
      );
    }
    // Pull what else changed, unless the connection just turned out gone.
    if (_phase != SyncPhase.offline) unawaited(sync());
  }

  /// Drops a refused change; its effect disappears from the screens.
  void discard(String operationId) => store.remove(operationId);

  /// Runs a sync now, or joins the one already running.
  Future<void> sync({bool pull = true}) async {
    _wantPull |= pull;
    if (_running != null) {
      _again = true;
      return _running;
    }
    final done = Completer<void>();
    _running = done.future;
    try {
      do {
        _again = false;
        final withPull = _wantPull;
        _wantPull = false;
        await _once(pull: withPull);
      } while (_again && !_disposed);
    } finally {
      _running = null;
      done.complete();
    }
  }

  bool get _useEndpoint =>
      _endpointBrokenUntil == null ||
      DateTime.now().isAfter(_endpointBrokenUntil!);

  Future<void> _once({required bool pull}) async {
    if (_disposed) return;
    _setPhase(SyncPhase.syncing);
    try {
      if (_useEndpoint) {
        try {
          await _viaEndpoint(pull: pull);
          _endpointBrokenUntil = null;
        } on ApiException catch (e) {
          if (!_endpointUnavailable(e)) rethrow;
          debugPrint('Sync endpoint unavailable (${e.statusCode}), using REST');
          _endpointBrokenUntil = DateTime.now().add(_endpointRetryAfter);
          await _viaRest(pull: pull);
        }
      } else {
        await _viaRest(pull: pull);
      }
      _error = null;
      _setPhase(SyncPhase.idle);
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _setPhase(SyncPhase.offline);
      } else {
        _error = e;
        _setPhase(SyncPhase.error);
      }
    } on Object catch (e, st) {
      debugPrint('Sync failed: $e\n$st');
      _error = ApiException(code: 'unknown', message: '$e');
      _setPhase(SyncPhase.error);
    }
  }

  static bool _endpointUnavailable(ApiException e) {
    final s = e.statusCode;
    return s != null && (s >= 500 || s == 404 || s == 405);
  }

  // ─── /v1/sync ─────────────────────────────────────────────────────────

  Future<void> _viaEndpoint({required bool pull}) async {
    final started = DateTime.now();
    while (true) {
      final ops = store.pending.take(200).toList();
      if (!pull && ops.isEmpty) return;

      final response = await remote.sync({
        'device_id': store.deviceId,
        'cursor': store.cursor,
        'pull_limit': 500,
        'operations': [for (final op in ops) op.toSyncJson()],
      });

      var resolved = 0;
      for (final r in response['results'] as List? ?? const []) {
        final result = Map<String, Object?>.from(r as Map);
        final op = _find(result['operation_id']);
        if (op == null) continue;
        resolved++;
        if (result['status'] == 'accepted') {
          store.outbox.remove(op);
        } else {
          op
            ..status = OutboxStatus.rejected
            ..errorCode = result['error_code'] as String?
            ..errorMessage = result['message'] as String?;
        }
      }
      for (final c in response['changes'] as List? ?? const []) {
        store.applyChange(Map<String, Object?>.from(c as Map));
      }
      final next = response['next_cursor'];
      if (next is num) store.cursor = next.toInt();
      store.changed();

      final hasMore = response['has_more'] == true;
      if (hasMore) continue;
      // More queued than one batch takes; stop if the server answered none
      // of them so a misbehaving response cannot loop forever.
      if (store.pending.isNotEmpty && resolved > 0) continue;
      break;
    }
    if (pull) {
      // Changes sent through REST earlier are in the pulled data now.
      store.outbox.removeWhere(
        (e) =>
            e.status == OutboxStatus.sent &&
            e.sentAt != null &&
            e.sentAt!.isBefore(started),
      );
      store.lastSyncedAt = DateTime.now();
      store.changed();
    }
  }

  OutboxEntry? _find(Object? operationId) {
    for (final e in store.outbox) {
      if (e.operationId == operationId) return e;
    }
    return null;
  }

  // ─── REST fallback ────────────────────────────────────────────────────

  Future<void> _viaRest({required bool pull}) async {
    await _pushRest();
    if (pull) await _pullRest();
  }

  Future<void> _pushRest() async {
    for (final op in store.pending) {
      try {
        await _execute(op);
        op
          ..status = OutboxStatus.sent
          ..sentAt = DateTime.now();
      } on ApiException catch (e) {
        final s = e.statusCode;
        // Connection, auth and server trouble: keep it and try later.
        if (e.isNetwork ||
            s == null ||
            s == 401 ||
            s == 408 ||
            s == 429 ||
            s >= 500) {
          rethrow;
        }
        op
          ..status = OutboxStatus.rejected
          ..errorCode = e.code
          ..errorMessage = e.message;
      }
      store.changed();
    }
  }

  Future<void> _execute(OutboxEntry op) async {
    String? id(Object? value) => value is String ? store.resolve(value) : null;
    List<Object?> members(Object? list) => [
      for (final m in list as List? ?? const [])
        {'member_id': id((m as Map)['member_id']), 'access': m['access']},
    ];
    void remember(Object? created) {
      final serverId = created is Map ? created['id'] : null;
      final local = op.entityId;
      if (local != null && serverId is String && serverId != local) {
        store.idMap[local] = serverId;
      }
    }

    final p = op.payload ?? const {};
    switch (op.type) {
      case 'record.create':
        remember(
          await remote.createRecord(id(p['cash_register_id'])!, {
            'type': p['type'],
            'amount': p['amount'],
            'note': ?p['note'],
            'deadline': ?p['deadline'],
            'parent_record_id': ?id(p['parent_record_id']),
            'destination_cash_register_id': ?id(
              p['destination_cash_register_id'],
            ),
          }),
        );
      case 'cash_register.create':
        remember(
          await remote.createRegister({
            'name': p['name'],
            'members': members(p['members']),
          }),
        );
      case 'cash_register.check':
        await remote.check(id(op.entityId)!);
      case 'cash_register.close':
        await remote.close(id(op.entityId)!);
      case 'cash_register.delete':
        await remote.delete(id(op.entityId)!);
      case 'cash_register.access_set':
        await remote.setAccess(id(op.entityId)!, members(p['members']));
      default:
        throw ApiException(
          code: 'unsupported',
          message: 'Unknown operation ${op.type}',
          statusCode: 400,
        );
    }
  }

  /// Downloads everything this member can see and replaces the snapshot.
  Future<void> _pullRest() async {
    final started = DateTime.now();
    final members = await remote.members();
    final registers = await remote.registers();
    final next = Snapshot(
      members: {for (final m in members) m['id'] as String: m},
      registers: {for (final r in registers) r['id'] as String: r},
    );

    Future<void> load(String id) async {
      try {
        final detail = await remote.registerDetail(id);
        final register = detail['cash_register'];
        if (register is Map) {
          next.registers[id] = Map<String, Object?>.from(register);
        }
        next.access[id] = {
          for (final row in detail['members'] as List? ?? const [])
            (row as Map)['id'] as String: Map<String, Object?>.from(row),
        };
        next.records[id] = {
          for (final r in await remote.allRecords(id))
            r['id'] as String: {...r, 'cash_register_id': id},
        };
      } on ApiException catch (e) {
        // Access was taken away between the two calls.
        if (e.statusCode == 404) {
          next.registers.remove(id);
          return;
        }
        rethrow;
      }
    }

    // A few registers at a time.
    final ids = registers.map((r) => r['id'] as String).toList();
    for (var i = 0; i < ids.length; i += 4) {
      await Future.wait(ids.skip(i).take(4).map(load));
    }
    store.replaceSnapshot(next, started);
  }

  void _setPhase(SyncPhase phase) {
    if (_disposed) return;
    _phase = phase;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }
}
