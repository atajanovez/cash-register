import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/auth_repository.dart';
import '../domain/session.dart';

/// `null` data means signed out. Loading only happens at startup while the
/// stored session is read; login/signup errors are thrown to the caller so the
/// form can show them without tearing down the router state.
final authControllerProvider = AsyncNotifierProvider<AuthController, Session?>(
  AuthController.new,
);

enum AuthNotice { sessionExpired, deactivated }

class AuthController extends AsyncNotifier<Session?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  AuthNotice? _notice;

  /// One-shot reason for the login screen (why the user was signed out).
  AuthNotice? takeNotice() {
    final notice = _notice;
    _notice = null;
    return notice;
  }

  @override
  Future<Session?> build() async {
    final session = await _repo.readSession();
    if (session == null) return null;
    if (session.isExpired) {
      await _repo.clearSession();
      _notice = AuthNotice.sessionExpired;
      return null;
    }
    return session;
  }

  Future<void> login({
    required String companyName,
    required String username,
    required String password,
  }) async {
    final session = await _repo.login(
      companyName: companyName.trim(),
      username: username.trim(),
      password: password,
    );
    await _signedIn(session);
  }

  Future<void> createCompany({
    required String companyName,
    required String fullName,
    required String username,
    required String password,
  }) async {
    final session = await _repo.createCompany(
      companyName: companyName.trim(),
      fullName: fullName.trim(),
      username: username.trim(),
      password: password,
    );
    await _signedIn(session);
  }

  Future<void> logout() async {
    await _repo.clearSession();
    state = const AsyncData(null);
  }

  /// Called by the HTTP layer when an authenticated request gets a 401.
  void sessionExpired({bool deactivated = false}) {
    if (state.value == null) return;
    _notice = deactivated ? AuthNotice.deactivated : AuthNotice.sessionExpired;
    logout();
  }

  Future<void> _signedIn(Session session) async {
    await _repo.saveSession(session);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(PrefKeys.lastCompany, session.companyName);
    await prefs.setString(PrefKeys.lastUsername, session.username);
    state = AsyncData(session);
  }
}
