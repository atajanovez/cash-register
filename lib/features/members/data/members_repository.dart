import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_call.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/offline/offline_providers.dart';
import '../domain/member.dart';

final membersRepositoryProvider = Provider<MembersRepository>(
  (ref) => MembersRepository(
    ref.watch(offlineProvider.future),
    ref.watch(dioProvider),
  ),
);

/// The member list is read from the device. Adding members and changing
/// them carries passwords, so those go straight to the server and need a
/// connection.
class MembersRepository {
  MembersRepository(this._offline, this._dio);

  final Future<Offline?> _offline;
  final Dio _dio;

  Future<Offline> get _local async =>
      await _offline ??
      (throw const ApiException(
        code: 'unauthorized',
        message: 'Not signed in.',
        statusCode: 401,
      ));

  Future<List<Member>> list() async => (await _local).store.view.members();

  Future<Member> create({
    required String fullName,
    required String username,
    required String password,
  }) => _save(
    () => _dio.post(
      '/v1/members',
      data: {'full_name': fullName, 'username': username, 'password': password},
    ),
  );

  /// At least one of [password] or [isActive] must be given.
  Future<Member> update(String id, {String? password, bool? isActive}) => _save(
    () => _dio.patch(
      '/v1/members/$id',
      data: {'password': ?password, 'is_active': ?isActive},
    ),
  );

  /// Sends the request and keeps the returned member on the device.
  Future<Member> _save(Future<Response<Object?>> Function() request) async {
    final local = await _local;
    final json = await apiCall(request, asMap);
    final member = Member.fromJson(json);
    local.store.snapshot.members[member.id] = {
      ...?local.store.snapshot.members[member.id],
      ...json,
    };
    local.store.changed();
    return member;
  }
}
