import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';
import 'app_config.dart';

/// Where requests go, saved per device.
///
/// - [apiUrl]: every request (login, members, registers, records).
/// - [syncUrl]: only the "sync servers" button (`POST /v1/server-sync`),
///   which makes the local server exchange data with the cloud. Empty hides
///   the button.
///
/// Both are stored with the `/api` suffix the routes live under.
class ServerSettings {
  const ServerSettings({required this.apiUrl, this.syncUrl = ''});

  final String apiUrl;
  final String syncUrl;

  bool get hasSyncUrl => syncUrl.isNotEmpty;
  bool get isDefaultApi => apiUrl == AppConfig.baseUrl;

  /// Accepts what people type: `192.168.1.158:8083`, `http://host/`,
  /// `https://host/api`. Returns '' for blank input and null when it is not
  /// an address.
  static String? normalize(String input) {
    var url = input.trim();
    if (url.isEmpty) return '';
    if (!url.contains('://')) url = 'http://$url';
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return url.endsWith('/api') ? url : '$url/api';
  }

  /// The address as people write it, without the `/api` suffix.
  static String display(String url) =>
      url.endsWith('/api') ? url.substring(0, url.length - 4) : url;
}

final serverSettingsProvider =
    NotifierProvider<ServerSettingsNotifier, ServerSettings>(
      ServerSettingsNotifier.new,
    );

class ServerSettingsNotifier extends Notifier<ServerSettings> {
  @override
  ServerSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return ServerSettings(
      apiUrl: prefs.getString(PrefKeys.apiUrl) ?? AppConfig.baseUrl,
      syncUrl: prefs.getString(PrefKeys.syncUrl) ?? '',
    );
  }

  /// Both values already normalized; a blank [apiUrl] means the default.
  Future<void> save({required String apiUrl, required String syncUrl}) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final api = apiUrl.isEmpty ? AppConfig.baseUrl : apiUrl;
    state = ServerSettings(apiUrl: api, syncUrl: syncUrl);
    if (api == AppConfig.baseUrl) {
      await prefs.remove(PrefKeys.apiUrl);
    } else {
      await prefs.setString(PrefKeys.apiUrl, api);
    }
    if (syncUrl.isEmpty) {
      await prefs.remove(PrefKeys.syncUrl);
    } else {
      await prefs.setString(PrefKeys.syncUrl, syncUrl);
    }
  }
}
