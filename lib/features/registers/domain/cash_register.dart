import '../../members/domain/member.dart';

/// Lifecycle: open → checked → closed (→ deleted).
enum RegisterStatus { open, checked, closed }

enum RegisterAccess {
  view('view'),
  modify('modify');

  const RegisterAccess(this.wire);
  final String wire;

  static RegisterAccess fromWire(String value) =>
      values.firstWhere((a) => a.wire == value, orElse: () => view);
}

class CashRegister {
  const CashRegister({
    required this.id,
    required this.name,
    required this.currentAmount,
    required this.realAmount,
    required this.createdAt,
    this.checkedAt,
    this.closedAt,
    this.isPinned = false,
    this.isPending = false,
  });

  final String id;
  final String name;

  /// Cash physically in the register.
  final int currentAmount;

  /// Cash plus open accruals and receivables, minus open payables.
  final int realAmount;
  final DateTime createdAt;
  final DateTime? checkedAt;
  final DateTime? closedAt;

  /// Pinned registers are listed first, whatever the sort.
  final bool isPinned;

  /// Has changes made on this device that the server has not confirmed yet.
  final bool isPending;

  RegisterStatus get status => closedAt != null
      ? RegisterStatus.closed
      : checkedAt != null
      ? RegisterStatus.checked
      : RegisterStatus.open;

  /// What is still owed in or out; zero when everything is settled.
  int get difference => realAmount - currentAmount;

  factory CashRegister.fromJson(Map<String, Object?> json) => CashRegister(
    id: json['id'] as String,
    name: json['name'] as String,
    currentAmount: (json['current_amount'] as num).toInt(),
    realAmount: (json['real_amount'] as num).toInt(),
    createdAt: DateTime.parse(json['created_at'] as String),
    checkedAt: _date(json['checked_at']),
    closedAt: _date(json['closed_at']),
    isPinned: json['is_pinned'] == true,
    isPending: json['_pending'] == true,
  );
}

class RegisterMember {
  const RegisterMember({required this.member, required this.access});

  final Member member;
  final RegisterAccess access;

  factory RegisterMember.fromJson(Map<String, Object?> json) => RegisterMember(
    member: Member.fromJson(json),
    access: RegisterAccess.fromWire(json['access'] as String),
  );
}

/// `GET /v1/cash-registers/{id}`
class RegisterDetail {
  const RegisterDetail({required this.register, required this.members});

  final CashRegister register;
  final List<RegisterMember> members;

  /// Access of [memberId], or null when they are not assigned. Managers are
  /// never listed; they always have full access.
  RegisterAccess? accessOf(String memberId) {
    for (final m in members) {
      if (m.member.id == memberId) return m.access;
    }
    return null;
  }

  factory RegisterDetail.fromJson(Map<String, Object?> json) => RegisterDetail(
    register: CashRegister.fromJson(
      Map<String, Object?>.from(json['cash_register'] as Map),
    ),
    members: [
      for (final m in json['members'] as List? ?? const [])
        RegisterMember.fromJson(Map<String, Object?>.from(m as Map)),
    ],
  );
}

/// `{id, name}` as embedded in transfer records.
class RegisterRef {
  const RegisterRef({required this.id, required this.name});

  final String id;
  final String name;

  static RegisterRef? fromJson(Object? json) => json is Map
      ? RegisterRef(id: json['id'] as String, name: json['name'] as String)
      : null;
}

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;
