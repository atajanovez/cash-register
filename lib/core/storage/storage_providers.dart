import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` once the instance has been loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    // The legacy keychain needs no provisioning profile, so signed .dmg
    // builds run on any Mac.
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  ),
);

abstract final class PrefKeys {
  static const lastCompany = 'last_company_name';
  static const lastUsername = 'last_username';
  static const themeMode = 'theme_mode';
}
