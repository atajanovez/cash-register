import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/session.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    dio: ref.watch(dioProvider),
    storage: ref.watch(secureStorageProvider),
  ),
);

class AuthRepository {
  AuthRepository({required this._dio, required this._storage});

  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _sessionKey = 'session';

  /// `POST /v1/companies`: creates the company with the caller as manager
  /// and returns a session for them.
  Future<Session> createCompany({
    required String companyName,
    required String fullName,
    required String username,
    required String password,
  }) async {
    final body = await _post('/v1/companies', {
      'company_name': companyName,
      'full_name': fullName,
      'username': username,
      'password': password,
    });
    return _parse(() => Session.fromSignup(body));
  }

  /// `POST /v1/auth/login`
  Future<Session> login({
    required String companyName,
    required String username,
    required String password,
  }) async {
    final body = await _post('/v1/auth/login', {
      'company_name': companyName,
      'username': username,
      'password': password,
    });
    return _parse(() => Session.fromLogin(body, companyName: companyName));
  }

  /// Turns a malformed success response into an [ApiException] the UI can show.
  Session _parse(Session Function() build) {
    try {
      return build();
    } on Object {
      throw const ApiException(
        code: 'bad_response',
        message: 'The server sent an unexpected response. Please try again.',
      );
    }
  }

  Future<Session?> readSession() async {
    try {
      final raw = await _storage.read(key: _sessionKey);
      if (raw == null) return null;
      return Session.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> saveSession(Session session) =>
      _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));

  Future<void> clearSession() => _storage.delete(key: _sessionKey);

  Future<Map<String, Object?>> _post(
    String path,
    Map<String, Object?> data,
  ) async {
    try {
      final response = await _dio.post<Object?>(path, data: data);
      final body = response.data;
      return body is Map ? Map<String, Object?>.from(body) : const {};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
