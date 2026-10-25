import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_call.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/offline/offline_providers.dart';
import '../../../core/util/uuid.dart';
import '../domain/cash_register.dart';
import '../domain/register_query.dart';

final registersRepositoryProvider = Provider<RegistersRepository>(
  (ref) => RegistersRepository(
    ref.watch(offlineProvider.future),
    ref.watch(dioProvider),
  ),
);

/// Registers, read from the device and changed through the sync outbox, so
/// everything here works offline. Pinning still needs the server.
class RegistersRepository {
  RegistersRepository(this._offline, this._dio);

  final Future<Offline?> _offline;
  final Dio _dio;

  Future<Offline> get _local async =>
      await _offline ??
      (throw const ApiException(
        code: 'unauthorized',
        message: 'Not signed in.',
        statusCode: 401,
      ));

  Future<List<CashRegister>> list(RegisterQuery query) async =>
      (await _local).store.view.registers(query);

  Future<RegisterDetail> get(String id) async {
    final local = await _local;
    final detail = local.store.view.detail(local.store.resolve(id));
    if (detail == null) {
      throw const ApiException(
        code: 'not_found',
        message: 'resource not found',
        statusCode: 404,
      );
    }
    return detail;
  }

  Future<CashRegister> create({
    required String name,
    Map<String, RegisterAccess> access = const {},
  }) async {
    final local = await _local;
    final taken = local.store.view
        .registers(const RegisterQuery())
        .any((r) => r.name.trim().toLowerCase() == name.trim().toLowerCase());
    if (taken) {
      throw const ApiException(
        code: 'cash_register_name_taken',
        message: 'cash register name is already in use in this company',
        statusCode: 409,
        fields: {'name': 'cash register name is already in use'},
      );
    }
    final id = uuidV4();
    await local.engine.submit(
      'cash_register.create',
      entityId: id,
      payload: {'name': name, 'members': _accessJson(access)},
    );
    return local.store.view.register(local.store.resolve(id))!;
  }

  /// Replaces the whole access list.
  Future<void> setAccess(String id, Map<String, RegisterAccess> access) async {
    final local = await _local;
    await local.engine.submit(
      'cash_register.access_set',
      entityId: local.store.resolve(id),
      payload: {'members': _accessJson(access)},
    );
  }

  Future<void> setPinned(String id, {required bool pinned}) async {
    final local = await _local;
    await apiCall(
      () => _dio.patch(
        '/v1/cash-registers/${local.store.resolve(id)}',
        data: {'is_pinned': pinned},
      ),
      (_) {},
    );
    await local.engine.sync();
  }

  Future<CashRegister> check(String id) => _lifecycle('check', id);

  Future<CashRegister> close(String id) async {
    final local = await _local;
    final register = local.store.view.register(local.store.resolve(id));
    if (register != null && register.difference != 0) {
      throw const ApiException(
        code: 'conflict',
        message: 'current amount and real amount must be equal',
        statusCode: 409,
      );
    }
    return _lifecycle('close', id);
  }

  Future<void> delete(String id) => _lifecycle('delete', id);

  Future<CashRegister> _lifecycle(String action, String id) async {
    final local = await _local;
    final resolved = local.store.resolve(id);
    final before = local.store.view.register(resolved);
    await local.engine.submit('cash_register.$action', entityId: resolved);
    return local.store.view.register(local.store.resolve(resolved)) ?? before!;
  }

  static List<Map<String, String>> _accessJson(
    Map<String, RegisterAccess> access,
  ) => [
    for (final e in access.entries)
      {'member_id': e.key, 'access': e.value.wire},
  ];
}
