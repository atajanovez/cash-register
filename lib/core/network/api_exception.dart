import 'package:dio/dio.dart';

/// Normalized API failure. Mirrors the server's
/// `{"error": {"code", "message", "fields"}}` envelope.
///
/// [message] is English (the server's, or ours for transport errors) and meant
/// for logs; the UI shows `describeError` from `l10n.dart` instead.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fields = const {},
  });

  final String code;
  final String message;
  final int? statusCode;

  /// Field name (as sent in the request body) to error message.
  final Map<String, String> fields;

  bool get isNetwork => code == 'network' || code == 'timeout';
  bool get isUnauthorized => statusCode == 401;

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          code: 'timeout',
          message: 'The server took too long to respond. Please try again.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          code: 'bad_certificate',
          message: "The server's security certificate is not valid.",
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        final detail = '${e.error}';
        if (detail.contains('CERTIFICATE_VERIFY_FAILED') ||
            detail.contains('HandshakeException')) {
          return const ApiException(
            code: 'bad_certificate',
            message: "The server's security certificate is not valid.",
          );
        }
        return const ApiException(
          code: 'network',
          message: "Can't reach the server. Check your internet connection.",
        );
      case DioExceptionType.cancel:
        return const ApiException(code: 'cancelled', message: 'Cancelled.');
      case DioExceptionType.badResponse:
        return _fromResponse(e.response);
    }
  }

  static ApiException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    final data = response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      final fields = <String, String>{};
      if (error['fields'] is Map) {
        (error['fields'] as Map).forEach((k, v) => fields['$k'] = '$v');
      }
      return ApiException(
        code: '${error['code'] ?? 'http_$status'}',
        message: '${error['message'] ?? 'Request failed.'}',
        statusCode: status,
        fields: fields,
      );
    }
    return ApiException(
      code: 'http_$status',
      message: status != null && status >= 500
          ? 'The server ran into a problem ($status). Please try again later.'
          : 'Unexpected server response ($status).',
      statusCode: status,
    );
  }

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
