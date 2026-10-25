import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Runs a request and normalizes every failure into [ApiException]:
/// transport/HTTP errors via [ApiException.fromDio], and a success body that
/// does not match the expected shape as `bad_response`.
Future<T> apiCall<T>(
  Future<Response<Object?>> Function() request,
  T Function(Object? body) parse,
) async {
  final Response<Object?> response;
  try {
    response = await request();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
  try {
    return parse(response.data);
  } on Object {
    throw const ApiException(
      code: 'bad_response',
      message: 'The server sent an unexpected response. Please try again.',
    );
  }
}

Map<String, Object?> asMap(Object? body) =>
    Map<String, Object?>.from(body as Map);

List<Map<String, Object?>> asList(Object? body) => [
  for (final item in body as List) Map<String, Object?>.from(item as Map),
];
