import 'dart:convert';

import 'package:cash_register/features/auth/domain/session.dart';
import 'package:flutter_test/flutter_test.dart';

String _jwt(Map<String, Object?> claims) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part(claims)}.sig';
}

const _memberId = 'b9798786-ff23-40b0-b617-17ba6d37596e';
const _companyId = 'aaf6b711-f7d9-484b-8d2a-5675d71421c3';

Map<String, Object?> _member() => {
  'id': _memberId,
  'full_name': 'Ada Lovelace',
  'username': 'ada',
  'company_id': _companyId,
  'is_active': true,
  'created_at': '2026-10-21T12:47:52.635035Z',
};

String _token({bool manager = true}) => _jwt({
  'sub': _memberId,
  'company_id': _companyId,
  'manager': manager,
  'exp': 4102444800, // 2100-01-01
});

void main() {
  test('parses the signup response', () {
    final session = Session.fromSignup({
      'company': {
        'id': _companyId,
        'name': 'Acme',
        'manager_id': _memberId,
        'created_at': '2026-10-21T12:47:52.635035Z',
      },
      'manager': _member(),
      'access_token': _token(),
    });

    expect(session.companyName, 'Acme');
    expect(session.companyId, _companyId);
    expect(session.memberId, _memberId);
    expect(session.username, 'ada');
    expect(session.fullName, 'Ada Lovelace');
    expect(session.isManager, isTrue);
    expect(session.expiresAt, DateTime.utc(2100).toLocal());
  });

  test('parses the login response and reads the role from the token', () {
    final manager = Session.fromLogin({
      'member': _member(),
      'access_token': _token(),
    }, companyName: 'Acme');
    final member = Session.fromLogin({
      'member': _member(),
      'access_token': _token(manager: false),
    }, companyName: 'Acme');

    expect(manager.companyName, 'Acme');
    expect(manager.isManager, isTrue);
    expect(member.isManager, isFalse);
    expect(member.isExpired, isFalse);
  });

  test('rejects responses without a token or member', () {
    expect(
      () => Session.fromLogin({'member': _member()}, companyName: 'Acme'),
      throwsFormatException,
    );
    expect(
      () => Session.fromLogin({'access_token': _token()}, companyName: 'Acme'),
      throwsFormatException,
    );
  });

  test('survives a JSON round trip', () {
    final original = Session.fromLogin({
      'member': _member(),
      'access_token': _token(),
    }, companyName: 'Acme');
    expect(Session.fromJson(original.toJson()).toJson(), original.toJson());
  });
}
