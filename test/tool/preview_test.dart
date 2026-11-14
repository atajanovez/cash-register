// Renders the main screens to build/preview/*.png for a visual check.
//
//   PREVIEW=1 flutter test test/tool/preview_test.dart
@Tags(['tool'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:cash_register/app/app.dart';
import 'package:cash_register/core/storage/storage_providers.dart';
import 'package:cash_register/features/auth/data/auth_repository.dart';
import 'package:cash_register/features/auth/domain/session.dart';
import 'package:cash_register/features/records/data/records_repository.dart';
import 'package:cash_register/features/records/domain/record_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/auth_flow_test.dart' show FakeAuthRepository;
import '../support/fake_backend.dart';

final _skip = Platform.environment['PREVIEW'] == null;

Future<void> _loadFonts() async {
  ByteData bytes(File f) => ByteData.sublistView(f.readAsBytesSync());
  final inter = FontLoader('Inter');
  for (final w in ['400Regular', '500Medium', '600SemiBold', '700Bold']) {
    inter.addFont(Future.value(bytes(File('assets/fonts/Inter_$w.ttf'))));
  }
  await inter.load();
  final cache = Directory(
    '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev',
  );
  final lucide = cache.listSync().whereType<Directory>().lastWhere(
    (d) => d.path.contains('lucide_icons_flutter'),
  );
  final ttf = lucide
      .listSync(recursive: true)
      .whereType<File>()
      .firstWhere((f) => f.path.endsWith('.ttf'));
  final icons = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(Future.value(bytes(ttf)));
  await icons.load();
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('preview')),
  );
  final image = await tester.runAsync(() => boundary.toImage());
  final png = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  Directory('build/preview').createSync(recursive: true);
  File('build/preview/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

FakeBackend _backend() {
  final b = FakeBackend();
  final main = b.addRegister('Esasy kassa', current: 0, real: 0);
  final bazar = b.addRegister('Bazar', current: 0, real: 0);
  b.addRegister('Ammar');
  void add(String id, RecordType type, int amount, String note, {int? dueIn}) =>
      b.addRecord(
        id,
        RecordDraft(
          type: type,
          amount: amount,
          note: note,
          deadline: dueIn == null
              ? null
              : DateTime.now().add(Duration(days: dueIn)),
        ),
      );
  add(main.id, RecordType.income, 1500000, 'Satyş');
  add(main.id, RecordType.expense, 34000, 'Kärende');
  add(main.id, RecordType.receivableOpened, 120000, 'Merdana karz', dueIn: -2);
  add(main.id, RecordType.payableOpened, 80000, 'Üpjünçi', dueIn: 4);
  add(main.id, RecordType.income, 250000, 'Nagt töleg');
  add(bazar.id, RecordType.income, 34000, 'Bazar satyşy');
  return b;
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  Session? session,
  ThemeMode mode = ThemeMode.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'theme_mode': mode.name});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('preview'),
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository()..stored = session,
          ),
          ..._backend().overrides,
        ],
        child: const CashRegisterApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _manager = Session(
  token: 't',
  memberId: 'm1',
  companyId: 'c1',
  companyName: 'Acme',
  username: 'ada',
  fullName: 'Ada Lovelace',
  isManager: true,
);

const _sizes = {
  'desktop': Size(1280, 800),
  'laptop': Size(1000, 700),
  'tablet': Size(800, 1100),
  'phone': Size(400, 860),
};

void main() {
  setUpAll(_loadFonts);

  testWidgets('record panel', skip: _skip, (tester) async {
    await _pump(tester, size: const Size(1680, 940), session: _manager);
    await tester.tap(find.text('Esasy kassa').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Merdana karz').last);
    await _shot(tester, 'panel_wide_light');
  });

  testWidgets('phone detail scrolled', skip: _skip, (tester) async {
    await _pump(tester, size: _sizes['phone']!, session: _manager);
    await tester.tap(find.text('Esasy kassa').first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await _shot(tester, 'detail_phone_scrolled');
  });

  for (final name in ['desktop', 'phone']) {
    testWidgets('type picker $name', skip: _skip, (tester) async {
      await _pump(tester, size: _sizes[name]!, session: _manager);
      await tester.tap(find.text('Esasy kassa').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ýazgy goş').last);
      await _shot(tester, 'picker_${name}_light');
    });
  }

  for (final MapEntry(key: name, value: size) in _sizes.entries) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      final tag = '${name}_${mode.name}';
      testWidgets('registers $tag', skip: _skip, (tester) async {
        await _pump(tester, size: size, session: _manager, mode: mode);
        await _shot(tester, 'registers_$tag');
      });
      testWidgets('detail $tag', skip: _skip, (tester) async {
        await _pump(tester, size: size, session: _manager, mode: mode);
        await tester.tap(find.text('Esasy kassa').first);
        await _shot(tester, 'detail_$tag');
      });
    }
  }
}
