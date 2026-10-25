import 'dart:convert';

/// The signed-in member and their access token.
///
/// API shapes:
/// - `POST /v1/companies` → `{company: {id, name, ...}, manager: Member, access_token}`
/// - `POST /v1/auth/login` → `{member: Member, access_token}`
///
/// The role and expiry live only in the JWT claims:
/// `{sub: memberId, company_id, manager: bool, exp}`.
class Session {
  const Session({
    required this.token,
    required this.memberId,
    required this.companyId,
    required this.companyName,
    required this.username,
    required this.fullName,
    this.isManager = false,
    this.expiresAt,
  });

  final String token;
  final String memberId;
  final String companyId;
  final String companyName;
  final String username;
  final String fullName;
  final bool isManager;
  final DateTime? expiresAt;

  String get displayName => fullName.trim().isNotEmpty ? fullName : username;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Login responses carry no company object, so the name comes from the form.
  factory Session.fromLogin(
    Map<String, Object?> json, {
    required String companyName,
  }) => Session._fromMember(
    json,
    member: _map(json['member']),
    companyName: companyName,
  );

  factory Session.fromSignup(Map<String, Object?> json) {
    final company = _map(json['company']);
    return Session._fromMember(
      json,
      member: _map(json['manager']),
      companyName: company['name'] as String,
    );
  }

  factory Session._fromMember(
    Map<String, Object?> json, {
    required Map<String, Object?> member,
    required String companyName,
  }) {
    final token = json['access_token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Auth response has no access_token');
    }
    final claims = _jwtClaims(token);
    final exp = claims['exp'];

    return Session(
      token: token,
      memberId: member['id'] as String,
      companyId: member['company_id'] as String,
      companyName: companyName,
      username: member['username'] as String,
      fullName: member['full_name'] as String? ?? '',
      isManager: claims['manager'] == true,
      expiresAt: exp is num
          ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000)
          : null,
    );
  }

  Map<String, Object?> toJson() => {
    'token': token,
    'member_id': memberId,
    'company_id': companyId,
    'company_name': companyName,
    'username': username,
    'full_name': fullName,
    'is_manager': isManager,
    'expires_at': expiresAt?.toIso8601String(),
  };

  factory Session.fromJson(Map<String, Object?> json) => Session(
    token: json['token'] as String,
    memberId: json['member_id'] as String,
    companyId: json['company_id'] as String,
    companyName: json['company_name'] as String,
    username: json['username'] as String,
    fullName: json['full_name'] as String? ?? '',
    isManager: json['is_manager'] as bool? ?? false,
    expiresAt: json['expires_at'] == null
        ? null
        : DateTime.tryParse(json['expires_at'] as String),
  );
}

Map<String, Object?> _map(Object? value) {
  if (value is Map) return Map<String, Object?>.from(value);
  throw const FormatException('Auth response is missing an expected object');
}

Map<String, Object?> _jwtClaims(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return const {};
  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final decoded = jsonDecode(payload);
    return decoded is Map ? Map<String, Object?>.from(decoded) : const {};
  } catch (_) {
    return const {};
  }
}
