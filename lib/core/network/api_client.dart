import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../config/app_config.dart';
import '../config/server_settings.dart';
import 'http_logger.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Absolute URLs go to the sync server, which has its own login:
        // they keep their host and never get the main server's token.
        if (_toSyncServer(options)) return handler.next(options);
        // Read per request so a changed server address applies at once.
        options.baseUrl = ref.read(serverSettingsProvider).apiUrl;
        final token = ref.read(authControllerProvider).value?.token;
        if (token != null && !options.headers.containsKey('Authorization')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final options = error.requestOptions;
        final sentToken = options.headers['Authorization'] != null;
        if (!_toSyncServer(options) &&
            sentToken &&
            error.response?.statusCode == 401) {
          // The server says "member is inactive or no longer exists" when a
          // manager deactivates someone mid-session.
          final message = '${error.response?.data}';
          ref
              .read(authControllerProvider.notifier)
              .sessionExpired(deactivated: message.contains('inactive'));
        }
        handler.next(error);
      },
    ),
  );
  // Added after the auth interceptor so the log shows the final headers.
  if (AppConfig.logHttp) dio.interceptors.add(HttpLogger());

  ref.onDispose(dio.close);
  return dio;
});

bool _toSyncServer(RequestOptions options) => options.path.contains('://');
