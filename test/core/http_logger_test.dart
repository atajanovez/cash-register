import 'package:cash_register/core/network/http_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with a fixed response, without a network.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.status, this.body);

  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  late List<String> lines;
  Dio dio(int status, String body) {
    lines = [];
    return Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = _StubAdapter(status, body)
      ..interceptors.add(HttpLogger(log: lines.add));
  }

  test('logs request and response, hiding token and passwords', () async {
    await dio(
      200,
      '{"member":{"username":"ada"},"access_token":"jwt-secret"}',
    ).post(
      '/v1/auth/login',
      data: {'company_name': 'Acme', 'username': 'ada', 'password': 'pw-1'},
      options: Options(headers: {'Authorization': 'Bearer jwt-secret'}),
    );

    final all = lines.join('\n');
    expect(
      lines.first,
      startsWith('→ POST https://example.test/api/v1/auth/login'),
    );
    expect(all, contains('"username": "ada"'));
    expect(all, contains('Authorization: Bearer ***'));
    expect(all, contains('"password": "***"'));
    expect(all, contains('"access_token": "***"'));
    expect(lines.last, startsWith('← 200 POST'));
    expect(all, isNot(contains('jwt-secret')));
    expect(all, isNot(contains('pw-1')));
  });

  test('logs error responses with their body', () async {
    final client = dio(
      500,
      '{"error":{"code":"internal_error","message":"an unexpected error occurred"}}',
    );
    await expectLater(
      client.post('/v1/sync', data: {'device_id': 'd', 'cursor': 0}),
      throwsA(isA<DioException>()),
    );

    expect(
      lines.last,
      startsWith('✕ 500 POST https://example.test/api/v1/sync'),
    );
    expect(lines.last, contains('"code": "internal_error"'));
  });
}
