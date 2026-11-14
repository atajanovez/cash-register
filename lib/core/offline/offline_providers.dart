import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/auth/application/auth_controller.dart';
import '../config/server_settings.dart';
import '../network/api_call.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../storage/storage_providers.dart';
import 'local_store.dart';
import 'remote_api.dart';
import 'sync_engine.dart';

/// The local data and the sync engine of the signed-in member.
class Offline {
  const Offline(this.store, this.engine);

  final LocalStore store;
  final SyncEngine engine;
}

/// Where local data files live. Overridden in tests.
final localDataDirProvider = Provider<Future<Directory>>(
  (ref) => getApplicationSupportDirectory(),
);

/// Opened once per signed-in member (company and member make the file name),
/// closed on logout. Null while signed out.
final offlineProvider = FutureProvider<Offline?>((ref) async {
  final key = ref.watch(
    authControllerProvider.select((s) {
      final session = s.value;
      return session == null ? null : (session.companyId, session.memberId);
    }),
  );
  if (key == null) return null;
  final (companyId, memberId) = key;

  final dir = await ref.watch(localDataDirProvider);
  final store = await LocalStore.open(
    File('${dir.path}/kassa_${companyId}_$memberId.json'),
    memberId: memberId,
  );
  final engine = SyncEngine(
    store,
    RemoteApi(ref.read(dioProvider)),
    connectivity: Connectivity().onConnectivityChanged.map(
      (results) => results.any((r) => r != ConnectivityResult.none),
    ),
  )..start();
  // Coming back to the app is a good moment to catch up.
  final lifecycle = AppLifecycleListener(onResume: engine.sync);

  ref.onDispose(() {
    lifecycle.dispose();
    engine.dispose();
    store.dispose();
  });
  return Offline(store, engine);
});

/// Bumps whenever local data changes, so providers that read it rebuild.
final dataRevisionProvider = NotifierProvider<DataRevision, int>(
  DataRevision.new,
);

class DataRevision extends Notifier<int> {
  @override
  int build() {
    final store = ref.watch(offlineProvider).value?.store;
    if (store == null) return 0;
    void bump() => state++;
    store.addListener(bump);
    ref.onDispose(() => store.removeListener(bump));
    return 0;
  }
}

/// Offline / syncing / waiting changes, for the status indicator.
final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus>(
  SyncStatusNotifier.new,
);

class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() {
    final offline = ref.watch(offlineProvider).value;
    if (offline == null) return const SyncStatus();
    void update() => state = offline.engine.status;
    offline.engine.addListener(update);
    offline.store.addListener(update);
    ref.onDispose(() {
      offline.engine.removeListener(update);
      offline.store.removeListener(update);
    });
    return offline.engine.status;
  }
}

/// User-triggered sync actions.
final syncControllerProvider = Provider<SyncController>(SyncController.new);

class SyncController {
  SyncController(this._ref);

  final Ref _ref;

  Future<SyncEngine?> get _engine async =>
      (await _ref.read(offlineProvider.future))?.engine;

  /// Pull-to-refresh and the refresh buttons.
  Future<void> refresh() async => (await _engine)?.sync();

  /// The "sync servers" button (managers only): sends this device's waiting
  /// changes, asks the server at the sync address to exchange data with the
  /// cloud (`POST /v1/server-sync`), then downloads the result.
  ///
  /// The sync server only accepts its own login. Throws
  /// `sync_login_required` until [loginToSyncServer] has run for it.
  Future<void> syncServers() async {
    final settings = _ref.read(serverSettingsProvider);
    final url = settings.syncUrl;
    if (url.isEmpty) {
      throw const ApiException(code: 'sync_url_missing', message: '');
    }
    final token = await _syncToken(settings);
    if (token == null) throw _loginRequired;
    final engine = await _engine;
    await engine?.sync(pull: false);
    try {
      await apiCall(
        () => _ref
            .read(dioProvider)
            .post<Object?>(
              '$url/v1/server-sync',
              options: Options(
                headers: {'Authorization': 'Bearer $token'},
                // The server gives up after 3 minutes.
                receiveTimeout: const Duration(minutes: 4),
              ),
            ),
        (_) {},
      );
    } on ApiException catch (e) {
      if (e.statusCode != 401) rethrow;
      await _storage.delete(key: _syncTokenKey);
      throw _loginRequired;
    }
    await engine?.sync();
  }

  /// Logs in to the sync server as the signed-in member and keeps the token.
  Future<void> loginToSyncServer(String password) async {
    final session = _ref.read(authControllerProvider).value;
    final url = _ref.read(serverSettingsProvider).syncUrl;
    if (session == null || url.isEmpty) return;
    final token = await apiCall(
      () => _ref
          .read(dioProvider)
          .post<Object?>(
            '$url/v1/auth/login',
            data: {
              'company_name': session.companyName,
              'username': session.username,
              'password': password,
            },
          ),
      (body) => asMap(body)['access_token']! as String,
    );
    await _storage.write(
      key: _syncTokenKey,
      value: jsonEncode({
        'url': url,
        'member_id': session.memberId,
        'token': token,
      }),
    );
  }

  static const _syncTokenKey = 'sync_server_token';
  static const _loginRequired = ApiException(
    code: 'sync_login_required',
    message: '',
  );

  FlutterSecureStorage get _storage => _ref.read(secureStorageProvider);

  Future<String?> _syncToken(ServerSettings settings) async {
    final session = _ref.read(authControllerProvider).value;
    if (session == null) return null;
    try {
      final raw = await _storage.read(key: _syncTokenKey);
      if (raw != null) {
        final saved = Map<String, Object?>.from(jsonDecode(raw) as Map);
        if (saved['url'] == settings.syncUrl &&
            saved['member_id'] == session.memberId) {
          return saved['token'] as String?;
        }
      }
    } on Object {
      // Unreadable: log in again.
    }
    // One server for everything: the main login belongs to it.
    return settings.syncUrl == settings.apiUrl ? session.token : null;
  }

  Future<void> discard(String operationId) async =>
      (await _engine)?.discard(operationId);

  /// Changes not yet on the server, for the logout warning.
  int get unsentCount => _ref.read(syncStatusProvider).pending;

  /// Deletes this member's local data (on logout).
  Future<void> wipe() async {
    final offline = await _ref.read(offlineProvider.future);
    await offline?.store.wipe();
    await _storage.delete(key: _syncTokenKey);
  }
}
