import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/offline_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../records/application/records_controller.dart';
import '../data/registers_repository.dart';
import '../domain/cash_register.dart';
import '../domain/register_query.dart';

final registerQueryProvider =
    NotifierProvider<RegisterQueryNotifier, RegisterQuery>(
      RegisterQueryNotifier.new,
    );

class RegisterQueryNotifier extends Notifier<RegisterQuery> {
  @override
  RegisterQuery build() => const RegisterQuery();

  void update(RegisterQuery Function(RegisterQuery) change) =>
      state = change(state);
}

// Each read provider watches [dataRevisionProvider], so screens follow the
// local data as offline changes and syncs land.
final registersProvider = FutureProvider.autoDispose<List<CashRegister>>((ref) {
  ref.watch(dataRevisionProvider);
  return ref
      .watch(registersRepositoryProvider)
      .list(ref.watch(registerQueryProvider));
});

/// Every visible register, unfiltered (e.g. transfer destinations).
final allRegistersProvider = FutureProvider.autoDispose<List<CashRegister>>((
  ref,
) {
  ref.watch(dataRevisionProvider);
  return ref.watch(registersRepositoryProvider).list(const RegisterQuery());
});

final registerDetailProvider = FutureProvider.autoDispose
    .family<RegisterDetail, String>((ref, id) {
      ref.watch(dataRevisionProvider);
      return ref.watch(registersRepositoryProvider).get(id);
    });

/// What the signed-in member may do with one register.
class RegisterPermissions {
  const RegisterPermissions({
    required this.isManager,
    required this.access,
    required this.status,
  });

  final bool isManager;
  final RegisterAccess? access;
  final RegisterStatus status;

  bool get canModify => isManager || access == RegisterAccess.modify;
  bool get canAddRecords => canModify;
  bool get canCheck => isManager && status == RegisterStatus.open;
  bool get canClose => isManager && status == RegisterStatus.checked;
  bool get canDelete => isManager && status == RegisterStatus.closed;
  bool get canManageAccess => isManager;
  bool get canPin => isManager;
}

final registerPermissionsProvider = Provider.autoDispose
    .family<RegisterPermissions?, String>((ref, id) {
      final session = ref.watch(authControllerProvider).value;
      final detail = ref.watch(registerDetailProvider(id)).value;
      if (session == null || detail == null) return null;
      return RegisterPermissions(
        isManager: session.isManager,
        access: detail.accessOf(session.memberId),
        status: detail.register.status,
      );
    });

/// Register mutations that also refresh every view showing the result.
final registerActionsProvider = Provider<RegisterActions>(RegisterActions.new);

class RegisterActions {
  RegisterActions(this._ref);

  final Ref _ref;

  RegistersRepository get _repo => _ref.read(registersRepositoryProvider);

  Future<CashRegister> create({
    required String name,
    Map<String, RegisterAccess> access = const {},
  }) async {
    final register = await _repo.create(name: name, access: access);
    _ref.invalidate(registersProvider);
    return register;
  }

  Future<void> setAccess(String id, Map<String, RegisterAccess> access) async {
    await _repo.setAccess(id, access);
    _ref.invalidate(registerDetailProvider(id));
  }

  Future<void> setPinned(String id, {required bool pinned}) async {
    await _repo.setPinned(id, pinned: pinned);
    _refresh(id);
    _ref.invalidate(allRegistersProvider);
  }

  Future<void> check(String id) async {
    await _repo.check(id);
    _refresh(id);
  }

  Future<void> close(String id) async {
    await _repo.close(id);
    _refresh(id);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _ref.invalidate(registersProvider);
  }

  /// After records change: both balances and the list move.
  void refreshAfterRecord(String id, {String? otherRegisterId}) {
    _refresh(id);
    _ref.invalidate(recordsControllerProvider);
    _ref.invalidate(unsettledOpeningsProvider);
    _ref.invalidate(allRegistersProvider);
    if (otherRegisterId != null) {
      _ref.invalidate(registerDetailProvider(otherRegisterId));
    }
  }

  void _refresh(String id) {
    _ref.invalidate(registerDetailProvider(id));
    _ref.invalidate(registersProvider);
  }
}
