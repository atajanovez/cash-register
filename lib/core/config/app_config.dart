import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'http://192.168.1.158:8083/api',
    defaultValue: 'https://cashregister.adyl.org/api',
  );

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 30);

  static const logHttp = bool.fromEnvironment(
    'HTTP_LOG',
    defaultValue: kDebugMode,
  );
}
