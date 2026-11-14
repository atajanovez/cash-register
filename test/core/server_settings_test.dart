import 'dart:convert';

import 'package:cash_register/core/config/app_config.dart';
import 'package:cash_register/core/config/server_settings.dart';
import 'package:cash_register/core/network/api_client.dart';
import 'package:cash_register/core/network/api_exception.dart';
import 'package:cash_register/core/offline/offline_providers.dart';
import 'package:cash_register/core/storage/storage_providers.dart';
import 'package:cash_register/features/auth/application/auth_controller.dart';
import 'package:cash_register/features/auth/data/auth_repository.dart';
import 'package:cash_register/features/auth/domain/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/auth_flow_test.dart' show FakeAuthRepository;

/// Answers every request with `{}` (or what [reply] says) and remembers
/// where it went and with which token.
class _Recorder implements HttpClientAdapter {
  final urls = <String>[];
  final tokens = <String?>[];
  (int, Object?) Function(RequestOptions options)? reply;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    urls.add('${options.method} ${options.uri}');
    tokens.add(options.headers['Authorization'] as String?);
    final (status, body) = reply?.call(options) ?? (200, const {});
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('normalize', () {
    test('accepts what people type', () {
      expect(
        ServerSettings.normalize('192.168.1.158:8083'),
        'http://192.168.1.158:8083/api',
      );
      expect(
        ServerSettings.normalize(' https://cashregister.adyl.org/ '),
        'https://cashregister.adyl.org/api',
      );
      expect(
        ServerSettings.normalize('http://10.0.0.2/api'),
        'http://10.0.0.2/api',
      );
      expect(ServerSettings.normalize(''), '');
    });

    test('rejects what is not an address', () {
      expect(ServerSettings.normalize('ftp://host'), isNull);
      expect(ServerSettings.normalize('http://'), isNull);
    });

    test('shows addresses without the /api suffix', () {
      expect(
        ServerSettings.display('http://10.0.0.2:8083/api'),
        'http://10.0.0.2:8083',
      );
    });
  });

  group('requests', () {
    late ProviderContainer container;
    late _Recorder recorder;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          offlineProvider.overrideWith((ref) async => null),
        ],
      );
      recorder = _Recorder();
      container.read(dioProvider).httpClientAdapter = recorder;
    });
    tearDown(() => container.dispose());

    test('go to the saved server, which can change at any time', () async {
      final dio = container.read(dioProvider);
      await dio.get<Object?>('/v1/members');
      await container
          .read(serverSettingsProvider.notifier)
          .save(apiUrl: 'http://10.0.0.2:8083/api', syncUrl: '');
      await dio.get<Object?>('/v1/members');

      expect(recorder.urls, [
        'GET ${AppConfig.baseUrl}/v1/members',
        'GET http://10.0.0.2:8083/api/v1/members',
      ]);
    });

    test('settings survive a restart', () async {
      await container
          .read(serverSettingsProvider.notifier)
          .save(apiUrl: 'http://10.0.0.2/api', syncUrl: 'http://10.0.0.9/api');
      final prefs = await SharedPreferences.getInstance();
      final again = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(again.dispose);

      final s = again.read(serverSettingsProvider);
      expect(s.apiUrl, 'http://10.0.0.2/api');
      expect(s.syncUrl, 'http://10.0.0.9/api');
    });
  });

  group('sync button', () {
    const local = 'http://10.0.0.9:8083/api';
    late ProviderContainer container;
    late _Recorder recorder;
    late FakeAuthRepository auth;

    Future<void> setUpWith({required String apiUrl}) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      auth = FakeAuthRepository()
        ..stored = const Session(
          token: 'main-token',
          memberId: 'm1',
          companyId: 'c1',
          companyName: 'Acme',
          username: 'ada',
          fullName: 'Ada',
          isManager: true,
        );
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
          offlineProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);
      recorder = _Recorder();
      container.read(dioProvider).httpClientAdapter = recorder;
      await container.read(authControllerProvider.future);
      await container
          .read(serverSettingsProvider.notifier)
          .save(apiUrl: apiUrl, syncUrl: local);
    }

    SyncController sync() => container.read(syncControllerProvider);

    test('asks for the sync server login before the first sync', () async {
      await setUpWith(apiUrl: AppConfig.baseUrl);
      await expectLater(
        sync().syncServers(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'sync_login_required',
          ),
        ),
      );
      expect(recorder.urls, isEmpty);
    });

    test('logs in to the sync server and syncs with its token', () async {
      await setUpWith(apiUrl: AppConfig.baseUrl);
      recorder.reply = (o) => o.path.endsWith('/auth/login')
          ? (200, {'access_token': 'local-token'})
          : (200, {'status': 'synced', 'companies': 1});

      await sync().loginToSyncServer('secret');
      await sync().syncServers();

      expect(recorder.urls, [
        'POST $local/v1/auth/login',
        'POST $local/v1/server-sync',
      ]);
      // The main server's token never goes to another server.
      expect(recorder.tokens, [null, 'Bearer local-token']);
    });

    test('one server for everything uses the main login', () async {
      await setUpWith(apiUrl: local);
      await sync().syncServers();

      expect(recorder.urls, ['POST $local/v1/server-sync']);
      expect(recorder.tokens, ['Bearer main-token']);
    });

    test('a refused sync token asks again and keeps the session', () async {
      await setUpWith(apiUrl: AppConfig.baseUrl);
      recorder.reply = (o) => o.path.endsWith('/auth/login')
          ? (200, {'access_token': 'old'})
          : (
              401,
              {
                'error': {'code': 'unauthorized', 'message': 'invalid token'},
              },
            );
      await sync().loginToSyncServer('secret');

      await expectLater(
        sync().syncServers(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'sync_login_required',
          ),
        ),
      );
      expect(container.read(authControllerProvider).value, isNotNull);
      // The bad token is forgotten.
      recorder.urls.clear();
      await expectLater(sync().syncServers(), throwsA(isA<ApiException>()));
      expect(recorder.urls, isEmpty);
    });
  });
}
