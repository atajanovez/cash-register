import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../util/uuid.dart';
import 'local_view.dart';

typedef Json = Map<String, Object?>;

enum OutboxStatus {
  /// Waiting to be sent.
  pending,

  /// Accepted by the server through a REST call; kept (and still shown) until
  /// the next full refresh contains its result.
  sent,

  /// The server refused it; shown to the user until they discard it.
  rejected,
}

/// A change made on this device, in the `/v1/sync` operation format.
class OutboxEntry {
  OutboxEntry({
    required this.operationId,
    required this.type,
    required this.createdAt,
    this.entityId,
    this.payload,
    this.status = OutboxStatus.pending,
    this.sentAt,
    this.errorCode,
    this.errorMessage,
  });

  final String operationId;
  final String type;
  final String? entityId;
  final Json? payload;
  final DateTime createdAt;
  OutboxStatus status;
  DateTime? sentAt;
  String? errorCode;
  String? errorMessage;

  Json toSyncJson() => {
    'operation_id': operationId,
    'type': type,
    'entity_id': ?entityId,
    'payload': ?payload,
  };

  Json toJson() => {
    ...toSyncJson(),
    'created_at': createdAt.toIso8601String(),
    'status': status.name,
    'sent_at': sentAt?.toIso8601String(),
    'error_code': errorCode,
    'error_message': errorMessage,
  };

  factory OutboxEntry.fromJson(Json json) => OutboxEntry(
    operationId: json['operation_id'] as String,
    type: json['type'] as String,
    entityId: json['entity_id'] as String?,
    payload: json['payload'] == null
        ? null
        : Map<String, Object?>.from(json['payload'] as Map),
    createdAt: DateTime.parse(json['created_at'] as String),
    status: OutboxStatus.values.byName(json['status'] as String),
    sentAt: json['sent_at'] == null
        ? null
        : DateTime.parse(json['sent_at'] as String),
    errorCode: json['error_code'] as String?,
    errorMessage: json['error_message'] as String?,
  );
}

/// What the server last told us, in its own JSON shapes.
class Snapshot {
  Snapshot({
    Map<String, Json>? registers,
    Map<String, Map<String, Json>>? access,
    Map<String, Map<String, Json>>? records,
    Map<String, Json>? members,
  }) : registers = registers ?? {},
       access = access ?? {},
       records = records ?? {},
       members = members ?? {};

  /// Register id → register.
  final Map<String, Json> registers;

  /// Register id → member id → access row (member fields plus `access`).
  final Map<String, Map<String, Json>> access;

  /// Register id → record id → record.
  final Map<String, Map<String, Json>> records;

  /// Member id → member.
  final Map<String, Json> members;

  Json toJson() => {
    'registers': registers,
    'access': access,
    'records': records,
    'members': members,
  };

  factory Snapshot.fromJson(Json json) {
    Map<String, Json> flat(Object? m) => {
      for (final e in (m as Map? ?? const {}).entries)
        e.key as String: Map<String, Object?>.from(e.value as Map),
    };
    Map<String, Map<String, Json>> nested(Object? m) => {
      for (final e in (m as Map? ?? const {}).entries)
        e.key as String: flat(e.value),
    };
    return Snapshot(
      registers: flat(json['registers']),
      access: nested(json['access']),
      records: nested(json['records']),
      members: flat(json['members']),
    );
  }

  /// Where a record lives, if we have it.
  String? registerOfRecord(String recordId) {
    for (final e in records.entries) {
      if (e.value.containsKey(recordId)) return e.key;
    }
    return null;
  }
}

/// Everything the app keeps on the device for one signed-in member: the
/// server snapshot, the changes not yet confirmed by the server, and sync
/// bookkeeping. Saved to a JSON file a moment after each change.
///
/// Screens read [view]: the snapshot with the outbox replayed on top, so
/// offline changes show immediately.
class LocalStore extends ChangeNotifier {
  LocalStore._({
    required this.file,
    required this.memberId,
    required this.snapshot,
    required this.outbox,
    required this.deviceId,
    required this.cursor,
    required this.idMap,
    this.lastSyncedAt,
  });

  final File? file;
  final String memberId;
  Snapshot snapshot;
  final List<OutboxEntry> outbox;
  final String deviceId;

  /// Last applied `/v1/sync` change sequence.
  int cursor;

  /// Ids chosen on this device → ids the server assigned, for items created
  /// through REST calls (the sync endpoint keeps the device's ids).
  final Map<String, String> idMap;
  DateTime? lastSyncedAt;

  LocalView? _view;
  Timer? _saveTimer;
  bool _disposed = false;
  bool _wiped = false;

  bool get hasData => lastSyncedAt != null;

  /// For tests and previews: nothing is written to disk.
  factory LocalStore.memory({required String memberId}) => LocalStore._(
    file: null,
    memberId: memberId,
    snapshot: Snapshot(),
    outbox: [],
    deviceId: uuidV4(),
    cursor: 0,
    idMap: {},
  );

  static Future<LocalStore> open(File file, {required String memberId}) async {
    if (await file.exists()) {
      try {
        final json = jsonDecode(await file.readAsString()) as Map;
        return LocalStore._(
          file: file,
          memberId: memberId,
          snapshot: Snapshot.fromJson(
            Map<String, Object?>.from(json['snapshot'] as Map),
          ),
          outbox: [
            for (final e in json['outbox'] as List)
              OutboxEntry.fromJson(Map<String, Object?>.from(e as Map)),
          ],
          deviceId: json['device_id'] as String,
          cursor: (json['cursor'] as num).toInt(),
          idMap: Map<String, String>.from(json['id_map'] as Map),
          lastSyncedAt: json['last_synced_at'] == null
              ? null
              : DateTime.parse(json['last_synced_at'] as String),
        );
      } on Object catch (e) {
        // A damaged file must not lock the user out; start fresh.
        debugPrint('Local data unreadable, starting over: $e');
      }
    }
    return LocalStore._(
      file: file,
      memberId: memberId,
      snapshot: Snapshot(),
      outbox: [],
      deviceId: uuidV4(),
      cursor: 0,
      idMap: {},
    );
  }

  LocalView get view => _view ??= LocalView.build(this);

  List<OutboxEntry> get pending =>
      outbox.where((e) => e.status == OutboxStatus.pending).toList();

  List<OutboxEntry> get rejected =>
      outbox.where((e) => e.status == OutboxStatus.rejected).toList();

  /// Follows [idMap] so offline ids keep working after the server renamed
  /// them.
  String resolve(String id) {
    var current = id;
    for (var i = 0; i < 4; i++) {
      final next = idMap[current];
      if (next == null) return current;
      current = next;
    }
    return current;
  }

  /// Call after any mutation: rebuilds the view, tells listeners, saves.
  void changed() {
    if (_disposed) return;
    _view = null;
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), save);
  }

  OutboxEntry add(String type, {String? entityId, Json? payload}) {
    final entry = OutboxEntry(
      operationId: uuidV4(),
      type: type,
      entityId: entityId,
      payload: payload,
      createdAt: DateTime.now(),
    );
    outbox.add(entry);
    changed();
    return entry;
  }

  void remove(String operationId) {
    outbox.removeWhere((e) => e.operationId == operationId);
    changed();
  }

  /// Replaces the snapshot with a full refresh that began at [startedAt];
  /// REST-sent changes from before then are now part of it.
  void replaceSnapshot(Snapshot next, DateTime startedAt) {
    snapshot = next;
    outbox.removeWhere(
      (e) =>
          e.status == OutboxStatus.sent &&
          e.sentAt != null &&
          e.sentAt!.isBefore(startedAt),
    );
    lastSyncedAt = DateTime.now();
    changed();
  }

  /// Applies one entry of a `/v1/sync` response's `changes`.
  void applyChange(Json change) {
    final type = change['entity_type'] as String?;
    final id = change['entity_id'] as String?;
    if (type == null || id == null) return;
    final delete = change['action'] == 'delete';
    final payload = change['payload'] is Map
        ? Map<String, Object?>.from(change['payload'] as Map)
        : <String, Object?>{};
    final s = snapshot;

    switch (type) {
      case 'members':
        delete
            ? s.members.remove(id)
            : s.members[id] = {...?s.members[id], ...payload};
      case 'cash_registers':
        if (delete) {
          s.registers.remove(id);
          s.access.remove(id);
          s.records.remove(id);
        } else {
          s.registers[id] = {...?s.registers[id], ...payload};
        }
      case 'records':
        final existingIn = s.registerOfRecord(id);
        if (delete) {
          if (existingIn != null) s.records[existingIn]!.remove(id);
          break;
        }
        final registerId = payload['cash_register_id'] as String? ?? existingIn;
        if (registerId == null) break;
        final records = s.records.putIfAbsent(registerId, () => {});
        records[id] = {...?records[id], ...payload};
      case 'cash_register_members':
        // Access-row ids are "<cash_register_id>:<member_id>".
        final parts = id.split(':');
        final registerId =
            payload['cash_register_id'] as String? ?? parts.first;
        final memberId =
            payload['member_id'] as String? ??
            (parts.length > 1 ? parts[1] : null);
        if (memberId == null) break;
        final rows = s.access.putIfAbsent(registerId, () => {});
        if (delete) {
          rows.remove(memberId);
        } else {
          rows[memberId] = {
            ...?s.members[memberId],
            ...?rows[memberId],
            'id': memberId,
            'access': payload['access'] ?? rows[memberId]?['access'],
          };
        }
    }
  }

  Json toJson() => {
    'version': 1,
    'snapshot': snapshot.toJson(),
    'outbox': [for (final e in outbox) e.toJson()],
    'device_id': deviceId,
    'cursor': cursor,
    'id_map': idMap,
    'last_synced_at': lastSyncedAt?.toIso8601String(),
  };

  /// Writes atomically: a crash mid-write leaves the previous file intact.
  Future<void> save() async {
    _saveTimer?.cancel();
    final f = file;
    if (f == null || _wiped) return;
    final tmp = File('${f.path}.tmp');
    await tmp.parent.create(recursive: true);
    await tmp.writeAsString(jsonEncode(toJson()), flush: true);
    await tmp.rename(f.path);
  }

  /// Forgets everything on this device (on logout).
  Future<void> wipe() async {
    _wiped = true;
    _saveTimer?.cancel();
    final f = file;
    if (f != null && await f.exists()) await f.delete();
  }

  @override
  void dispose() {
    _disposed = true;
    final pendingSave = _saveTimer?.isActive ?? false;
    _saveTimer?.cancel();
    if (pendingSave) unawaited(save());
    super.dispose();
  }
}
