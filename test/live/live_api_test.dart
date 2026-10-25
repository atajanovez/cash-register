// Exercises the app's offline-first data layer against the real server:
// changes go through the sync outbox and are checked after a fresh download.
//
// Skipped unless LIVE_API is set, because it creates data:
//   LIVE_API=1 flutter test test/live
//
// Uses the dedicated test company (see docs/api.md), never a real one. The
// register it creates is closed and deleted at the end.
@Tags(['live'])
library;

import 'dart:io';

import 'package:cash_register/core/config/app_config.dart';
import 'package:cash_register/core/network/api_exception.dart';
import 'package:cash_register/core/offline/local_store.dart';
import 'package:cash_register/core/offline/offline_providers.dart';
import 'package:cash_register/core/offline/remote_api.dart';
import 'package:cash_register/core/offline/sync_engine.dart';
import 'package:cash_register/features/members/data/members_repository.dart';
import 'package:cash_register/features/records/data/records_repository.dart';
import 'package:cash_register/features/records/domain/record_type.dart';
import 'package:cash_register/features/registers/data/registers_repository.dart';
import 'package:cash_register/features/registers/domain/cash_register.dart';
import 'package:cash_register/features/registers/domain/register_query.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _company = 'ClaudeTest-10211838';

void main() {
  final enabled = Platform.environment['LIVE_API'] != null;

  late Dio dio;
  late SyncEngine engine;
  late RegistersRepository registers;
  late RecordsRepository records;
  late MembersRepository members;

  setUpAll(() async {
    if (!enabled) return;
    dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
    final login = await dio.post<Map<String, dynamic>>(
      '/v1/auth/login',
      data: {
        'company_name': _company,
        'username': 'manager',
        'password': 'password123',
      },
    );
    dio.options.headers['Authorization'] =
        'Bearer ${login.data!['access_token']}';
    final store = LocalStore.memory(
      memberId: (login.data!['member'] as Map)['id'] as String,
    );
    engine = SyncEngine(store, RemoteApi(dio));
    await engine.sync();
    final offline = Future.value(Offline(store, engine));
    registers = RegistersRepository(offline, dio);
    records = RecordsRepository(offline);
    members = MembersRepository(offline, dio);
  });

  test(
    'full register lifecycle',
    () async {
      final team = await members.list();
      final grace = team.firstWhere((m) => m.username == 'grace');

      final name = 'Live ${DateTime.now().millisecondsSinceEpoch}';
      final created = await registers.create(
        name: name,
        access: {grace.id: RegisterAccess.view},
      );
      expect(created.status, RegisterStatus.open);

      final detail = await registers.get(created.id);
      expect(detail.accessOf(grace.id), RegisterAccess.view);

      final id = created.id;
      await records.create(
        id,
        const RecordDraft(type: RecordType.income, amount: 10000, note: 'live'),
      );
      await records.create(
        id,
        const RecordDraft(type: RecordType.expense, amount: 2500),
      );
      final accrual = await records.create(
        id,
        RecordDraft(
          type: RecordType.accrualIncome,
          amount: 4000,
          deadline: DateTime.now().add(const Duration(days: 7)),
        ),
      );

      var register = (await registers.get(id)).register;
      expect(register.currentAmount, 7500);
      expect(register.realAmount, 11500);

      // Client-side rule matches the server: too large an expense is refused.
      await expectLater(
        records.create(
          id,
          const RecordDraft(type: RecordType.expense, amount: 999999),
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
      );

      final unsettled = await records.list(
        id,
        const RecordQuery(onlyUnsettled: true),
      );
      expect(unsettled.single.id, accrual.id);
      expect(unsettled.single.remaining, 4000);

      await records.create(
        id,
        RecordDraft(
          type: RecordType.accrualIncomeSettled,
          amount: 4000,
          parentRecordId: accrual.id,
        ),
      );

      final listed = await records.list(id, const RecordQuery());
      expect(listed, hasLength(4));
      expect(
        listed.firstWhere((r) => r.id == accrual.id).isFullySettled,
        isTrue,
      );

      final search = await registers.list(RegisterQuery(search: name));
      expect(search.single.id, id);

      expect((await registers.check(id)).status, RegisterStatus.checked);
      register = await registers.close(id);
      expect(register.status, RegisterStatus.closed);
      expect(register.currentAmount, register.realAmount);

      await registers.delete(id);
      await expectLater(
        registers.get(id),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)),
      );

      // Everything reached the server: a fresh download agrees.
      await engine.sync();
      expect(engine.status.pending, 0);
      expect(engine.status.rejected, isEmpty);
      expect(await registers.list(RegisterQuery(search: name)), isEmpty);
    },
    skip: enabled ? false : 'Set LIVE_API=1 to run against the server',
  );
}
