import 'package:dio/dio.dart';

import '../network/api_call.dart';
import 'local_store.dart';

/// The server calls the sync engine needs, as raw JSON.
class RemoteApi {
  RemoteApi(this._dio);

  final Dio _dio;

  Future<Json> sync(Json body) =>
      apiCall(() => _dio.post('/v1/sync', data: body), asMap);

  Future<List<Json>> members() =>
      apiCall(() => _dio.get('/v1/members'), asList);

  Future<List<Json>> registers() => apiCall(
    () => _dio.get(
      '/v1/cash-registers',
      queryParameters: {'sort': 'created_at', 'order': 'desc'},
    ),
    asList,
  );

  Future<Json> registerDetail(String id) =>
      apiCall(() => _dio.get('/v1/cash-registers/$id'), asMap);

  /// Every record of a register, page by page.
  Future<List<Json>> allRecords(String registerId) async {
    const limit = 200;
    final all = <Json>[];
    while (true) {
      final page = await apiCall(
        () => _dio.get(
          '/v1/cash-registers/$registerId/records',
          queryParameters: {'limit': limit, 'offset': all.length},
        ),
        asList,
      );
      all.addAll(page);
      if (page.length < limit) return all;
    }
  }

  Future<Json> createRecord(String registerId, Json body) => apiCall(
    () => _dio.post('/v1/cash-registers/$registerId/records', data: body),
    asMap,
  );

  Future<Json> createRegister(Json body) =>
      apiCall(() => _dio.post('/v1/cash-registers', data: body), asMap);

  Future<void> setAccess(String id, List<Object?> members) => apiCall(
    () =>
        _dio.put('/v1/cash-registers/$id/members', data: {'members': members}),
    (_) {},
  );

  Future<void> check(String id) =>
      apiCall(() => _dio.post('/v1/cash-registers/$id/check'), (_) {});

  Future<void> close(String id) =>
      apiCall(() => _dio.post('/v1/cash-registers/$id/close'), (_) {});

  Future<void> delete(String id) =>
      apiCall(() => _dio.delete('/v1/cash-registers/$id'), (_) {});
}
