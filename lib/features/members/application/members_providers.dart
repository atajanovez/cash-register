import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/offline_providers.dart';
import '../data/members_repository.dart';
import '../domain/member.dart';

/// Active members first, then by name.
final membersProvider = FutureProvider.autoDispose<List<Member>>((ref) async {
  ref.watch(dataRevisionProvider);
  final members = await ref.watch(membersRepositoryProvider).list();
  return members..sort((a, b) {
    if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });
});

final memberActionsProvider = Provider<MemberActions>(MemberActions.new);

class MemberActions {
  MemberActions(this._ref);

  final Ref _ref;

  MembersRepository get _repo => _ref.read(membersRepositoryProvider);

  Future<Member> create({
    required String fullName,
    required String username,
    required String password,
  }) async {
    final member = await _repo.create(
      fullName: fullName,
      username: username,
      password: password,
    );
    _ref.invalidate(membersProvider);
    return member;
  }

  Future<void> setActive(String id, bool active) async {
    await _repo.update(id, isActive: active);
    _ref.invalidate(membersProvider);
  }

  Future<void> resetPassword(String id, String password) =>
      _repo.update(id, password: password);
}
