import 'package:flutter/widgets.dart' show StringCharacters;

/// A company member as returned by `/v1/members`. Embedded copies (record
/// creator, register access rows) carry only some of these fields.
class Member {
  const Member({
    required this.id,
    required this.fullName,
    required this.username,
    required this.isActive,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String username;
  final bool isActive;
  final DateTime? createdAt;

  String get displayName => fullName.trim().isNotEmpty ? fullName : username;

  /// Up to two letters for an avatar.
  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  factory Member.fromJson(Map<String, Object?> json) => Member(
    id: json['id'] as String,
    fullName: json['full_name'] as String? ?? '',
    username: json['username'] as String,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: _date(json['created_at']),
  );
}

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;
