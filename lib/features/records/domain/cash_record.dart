import '../../members/domain/member.dart';
import '../../registers/domain/cash_register.dart';
import 'record_type.dart';

/// An immutable ledger entry. Named `CashRecord` because `Record` is a Dart
/// built-in type.
///
/// List responses embed `creator`, `parent`, `children` and
/// `destination`/`source`; create responses and embedded parent/children do
/// not, so those are optional.
class CashRecord {
  const CashRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.createdBy,
    required this.createdAt,
    this.deadline,
    this.parentRecordId,
    this.counterpartRecordId,
    this.creator,
    this.parent,
    this.children = const [],
    this.destination,
    this.source,
    this.isPending = false,
  });

  final String id;
  final RecordType type;
  final int amount;
  final String note;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? deadline;
  final String? parentRecordId;
  final String? counterpartRecordId;
  final Member? creator;
  final CashRecord? parent;
  final List<CashRecord> children;
  final RegisterRef? destination;
  final RegisterRef? source;

  /// Made on this device and not yet confirmed by the server.
  final bool isPending;

  /// Settled so far (direct children are the settlements).
  int get settledAmount => children.fold(0, (sum, c) => sum + c.amount);

  /// What is still open on an obligation; 0 for other types.
  int get remaining => type.isOpening ? amount - settledAmount : 0;

  bool get isFullySettled => type.isOpening && remaining <= 0;

  bool isOverdue([DateTime? now]) =>
      type.isOpening &&
      remaining > 0 &&
      deadline != null &&
      deadline!.isBefore(now ?? DateTime.now());

  /// The other register of a transfer.
  RegisterRef? get counterparty => destination ?? source;

  factory CashRecord.fromJson(Map<String, Object?> json) {
    final creator = json['creator'];
    final parent = json['parent'];
    return CashRecord(
      id: json['id'] as String,
      type: RecordType.fromWire(json['type'] as String),
      amount: (json['amount'] as num).toInt(),
      note: json['note'] as String? ?? '',
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      deadline: _date(json['deadline']),
      parentRecordId: json['parent_record_id'] as String?,
      counterpartRecordId: json['counterpart_record_id'] as String?,
      creator: creator is Map
          ? Member.fromJson(Map<String, Object?>.from(creator))
          : null,
      parent: parent is Map
          ? CashRecord.fromJson(Map<String, Object?>.from(parent))
          : null,
      children: [
        for (final c in json['children'] as List? ?? const [])
          CashRecord.fromJson(Map<String, Object?>.from(c as Map)),
      ],
      destination: RegisterRef.fromJson(json['destination']),
      source: RegisterRef.fromJson(json['source']),
      isPending: json['_pending'] == true,
    );
  }
}

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;
