import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Prints every request (method, URL, headers, body) and its response
/// (status, time, headers, body) to the console.
///
/// Secrets never reach the log: the bearer token, passwords and access tokens
/// are replaced with `***`.
class HttpLogger extends Interceptor {
  HttpLogger({this.log = _print});

  final void Function(String line) log;

  static const _startedAt = 'http_logger.started_at';
  static const _secretKeys = {'password', 'access_token', 'token'};
  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAt] = DateTime.now();
    log(
      [
        '→ ${options.method} ${options.uri}',
        _headers(options.headers),
        if (options.data != null) _body(options.data),
      ].join('\n'),
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log(_response(response.requestOptions, response));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    log(
      response != null
          ? _response(err.requestOptions, response)
          : '✕ ${err.requestOptions.method} ${err.requestOptions.uri} '
                '${_elapsed(err.requestOptions)}\n'
                '${err.type.name}: ${err.message ?? err.error}',
    );
    handler.next(err);
  }

  String _response(RequestOptions options, Response response) {
    final status = response.statusCode ?? 0;
    final mark = status >= 400 ? '✕' : '←';
    return [
      '$mark $status ${options.method} ${options.uri} ${_elapsed(options)}',
      _headers(response.headers.map.map((k, v) => MapEntry(k, v.join(', ')))),
      if (response.data != null && '${response.data}'.isNotEmpty)
        _body(response.data),
    ].join('\n');
  }

  String _elapsed(RequestOptions options) {
    final started = options.extra[_startedAt];
    if (started is! DateTime) return '';
    return '(${DateTime.now().difference(started).inMilliseconds} ms)';
  }

  String _headers(Map<String, dynamic> headers) => [
    for (final MapEntry(:key, :value) in headers.entries)
      '  $key: ${key.toLowerCase() == 'authorization' ? 'Bearer ***' : value}',
  ].join('\n');

  String _body(Object? data) {
    try {
      final decoded = data is String ? jsonDecode(data) : data;
      return _encoder.convert(_redact(decoded));
    } catch (_) {
      return '$data';
    }
  }

  static Object? _redact(Object? value) => switch (value) {
    Map() => {
      for (final MapEntry(:key, value: v) in value.entries)
        '$key': _secretKeys.contains(key) ? '***' : _redact(v),
    },
    List() => [for (final v in value) _redact(v)],
    _ => value,
  };

  // debugPrint splits long lines so Android's logcat doesn't cut them off.
  static void _print(String line) => debugPrint(line, wrapWidth: 1000);
}
