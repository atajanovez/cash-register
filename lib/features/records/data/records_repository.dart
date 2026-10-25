import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/offline/offline_providers.dart';
import '../../../core/util/uuid.dart';
import '../../registers/domain/cash_register.dart';
import '../domain/cash_record.dart';
import '../domain/record_type.dart';

final recordsRepositoryProvider = Provider<RecordsRepository>(
  (ref) => RecordsRepository(ref.watch(offlineProvider.future)),
);

class RecordQuery {
  const RecordQuery({this.search = '', this.type, this.onlyUnsettled = false});

  final String search;
  final RecordType? type;
  final bool onlyUnsettled;

  bool get isDefault => search.isEmpty && type == null && !onlyUnsettled;

  RecordQuery copyWith({
    String? search,
    RecordType? Function()? type,
    bool? onlyUnsettled,
  }) => RecordQuery(
    search: search ?? this.search,
    type: type != null ? type() : this.type,
    onlyUnsettled: onlyUnsettled ?? this.onlyUnsettled,
  );

  @override
  bool operator ==(Object other) =>
      other is RecordQuery &&
      other.search == search &&
      other.type == type &&
      other.onlyUnsettled == onlyUnsettled;

  @override
  int get hashCode => Object.hash(search, type, onlyUnsettled);
}

/// What the "add record" form submits.
class RecordDraft {
  const RecordDraft({
    required this.type,
    required this.amount,
    this.note = '',
    this.deadline,
    this.parentRecordId,
    this.destinationRegisterId,
  });

  final RecordType type;
  final int amount;
  final String note;
  final DateTime? deadline;
  final String? parentRecordId;
  final String? destinationRegisterId;

  Map<String, Object?> toJson() => {
    'type': type.wire,
    'amount': amount,
    if (note.trim().isNotEmpty) 'note': note.trim(),
    if (deadline != null) 'deadline': deadline!.toUtc().toIso8601String(),
    if (parentRecordId != null) 'parent_record_id': parentRecordId,
    if (destinationRegisterId != null)
      'destination_cash_register_id': destinationRegisterId,
  };
}

/// Records, read from the device and created through the sync outbox, so
/// they work offline. The server's rules are checked here first so mistakes
/// show in the form even without a connection.
class RecordsRepository {
  RecordsRepository(this._offline);

  final Future<Offline?> _offline;

  static const pageSize = 50;

  Future<Offline> get _local async =>
      await _offline ??
      (throw const ApiException(
        code: 'unauthorized',
        message: 'Not signed in.',
        statusCode: 401,
      ));

  /// Newest first. A page shorter than [limit] means there is nothing more.
  Future<List<CashRecord>> list(
    String registerId,
    RecordQuery query, {
    int offset = 0,
    int limit = pageSize,
  }) async {
    final local = await _local;
    final all = local.store.view.records(
      local.store.resolve(registerId),
      query,
    );
    return all.skip(offset).take(limit).toList();
  }

  Future<CashRecord> create(String registerId, RecordDraft draft) async {
    final local = await _local;
    final view = local.store.view;
    final id = local.store.resolve(registerId);
    final register = view.register(id);
    if (register == null) {
      throw const ApiException(
        code: 'not_found',
        message: 'resource not found',
        statusCode: 404,
      );
    }
    _check(register, draft, view.records(id, const RecordQuery()));

    final recordId = uuidV4();
    await local.engine.submit(
      'record.create',
      entityId: recordId,
      payload: {'cash_register_id': id, ...draft.toJson()},
    );
    final records = local.store.view.records(
      local.store.resolve(id),
      const RecordQuery(),
    );
    final mapped = local.store.resolve(recordId);
    return records.firstWhere(
      (r) => r.id == mapped || r.id == recordId,
      orElse: () => records.first,
    );
  }

  /// The checks the server would make, with its wording (see
  /// `describeError`).
  static void _check(
    CashRegister register,
    RecordDraft draft,
    List<CashRecord> records,
  ) {
    Never conflict(String message) =>
        throw ApiException(code: 'conflict', message: message, statusCode: 409);
    if (!draft.type.allowedIn(register.status)) {
      conflict('cash register status does not accept this record type');
    }
    if (draft.type.needsFunds && register.currentAmount < draft.amount) {
      conflict('current amount is insufficient for this record');
    }
    if (draft.type.needsParent) {
      final parent = records
          .where((r) => r.id == draft.parentRecordId)
          .firstOrNull;
      if (parent == null || parent.type != draft.type.settles) {
        conflict('parent record type does not match');
      }
      if (draft.amount > parent.remaining) {
        conflict("amount exceeds the parent's unsettled amount");
      }
    }
  }
}
