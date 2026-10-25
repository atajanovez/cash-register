import 'package:cash_register/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _bad(int status, Object? data) {
  final options = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('parses the server error envelope with field errors', () {
    final e = ApiException.fromDio(
      _bad(400, {
        'error': {
          'code': 'username_taken',
          'message': 'username is already in use in this company',
          'fields': {'username': 'already taken'},
        },
      }),
    );
    expect(e.code, 'username_taken');
    expect(e.statusCode, 400);
    expect(e.fields, {'username': 'already taken'});
  });

  test('handles non-JSON error bodies', () {
    final e = ApiException.fromDio(_bad(404, '404 page not found'));
    expect(e.code, 'http_404');
    expect(e.message, contains('404'));
  });

  test('maps connection errors to a network error', () {
    final e = ApiException.fromDio(
      DioException.connectionError(
        requestOptions: RequestOptions(path: '/x'),
        reason: 'refused',
      ),
    );
    expect(e.isNetwork, isTrue);
  });

  test('detects certificate failures', () {
    final e = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.unknown,
        error: 'HandshakeException: CERTIFICATE_VERIFY_FAILED',
      ),
    );
    expect(e.code, 'bad_certificate');
  });
}
