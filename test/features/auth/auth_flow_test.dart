import 'package:cash_register/app/app.dart';
import 'package:cash_register/core/network/api_exception.dart';
import 'package:cash_register/core/storage/storage_providers.dart';
import 'package:cash_register/features/auth/data/auth_repository.dart';
import 'package:cash_register/features/auth/domain/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cash_register/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_backend.dart';

class FakeAuthRepository implements AuthRepository {
  Session? stored;
  Map<String, String>? lastLogin;
  Map<String, String>? lastSignup;
  ApiException? failWith;

  Session _session(String company, String username, {bool manager = false}) =>
      _testSession(company: company, username: username, manager: manager);

  @override
  Future<Session> login({
    required String companyName,
    required String username,
    required String password,
  }) async {
    lastLogin = {
      'company': companyName,
      'username': username,
      'password': password,
    };
    if (failWith != null) throw failWith!;
    return _session(companyName, username);
  }

  @override
  Future<Session> createCompany({
    required String companyName,
    required String fullName,
    required String username,
    required String password,
  }) async {
    lastSignup = {
      'company': companyName,
      'full_name': fullName,
      'username': username,
    };
    if (failWith != null) throw failWith!;
    return _session(companyName, username, manager: true);
  }

  @override
  Future<Session?> readSession() async => stored;

  @override
  Future<void> saveSession(Session session) async => stored = session;

  @override
  Future<void> clearSession() async => stored = null;
}

Future<FakeAuthRepository> _pumpApp(
  WidgetTester tester, {
  Size size = const Size(400, 900),
  Session? stored,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = FakeAuthRepository()..stored = stored;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(repo),
        ...FakeBackend().overrides,
      ],
      child: const CashRegisterApp(),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Session _testSession({
  String company = 'Acme',
  String username = 'ada',
  bool manager = false,
  DateTime? expiresAt,
}) => Session(
  token: 't',
  memberId: 'm1',
  companyId: 'c1',
  companyName: company,
  username: username,
  fullName: '',
  isManager: manager,
  expiresAt: expiresAt,
);

Future<void> _openAccount(WidgetTester tester) async {
  await tester.tap(find.text(l.navAccount));
  await tester.pumpAndSettle();
}

bool _textFieldFocused() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<EditableText>() !=
    null;

Finder _field(String label) => find.widgetWithText(TextFormField, label);

final l = lookupAppLocalizations(appLocale);

void main() {
  testWidgets('signed-out users land on login', (tester) async {
    await _pumpApp(tester);
    expect(find.text(l.welcomeBack), findsOneWidget);
    expect(find.text(l.createCompany), findsOneWidget);
  });

  testWidgets('login validates, then signs in and opens home', (tester) async {
    final repo = await _pumpApp(tester);

    await tester.tap(find.text(l.logIn));
    await tester.pumpAndSettle();
    expect(find.text(l.enterCompanyName), findsOneWidget);
    expect(repo.lastLogin, isNull);

    await tester.enterText(_field(l.companyName), ' Acme ');
    await tester.enterText(_field(l.username), 'ada');
    await tester.enterText(_field(l.password), 'password123');
    await tester.tap(find.text(l.logIn));
    await tester.pumpAndSettle();

    expect(repo.lastLogin, {
      'company': 'Acme',
      'username': 'ada',
      'password': 'password123',
    });
    expect(find.text(l.registersTitle), findsWidgets);
    await _openAccount(tester);
    expect(find.text(l.roleMember), findsOneWidget);
  });

  testWidgets('invalid credentials show a clear message', (tester) async {
    final repo = await _pumpApp(tester);
    repo.failWith = const ApiException(
      code: 'invalid_credentials',
      message: 'x',
      statusCode: 401,
    );

    await tester.enterText(_field(l.companyName), 'Acme');
    await tester.enterText(_field(l.username), 'ada');
    await tester.enterText(_field(l.password), 'wrong-pass');
    await tester.tap(find.text(l.logIn));
    await tester.pumpAndSettle();

    expect(find.text(l.invalidCredentials), findsOneWidget);
  });

  testWidgets('signup creates the company and signs in as manager', (
    tester,
  ) async {
    final repo = await _pumpApp(tester);
    await tester.tap(find.text(l.createCompany));
    await tester.pumpAndSettle();
    expect(find.text(l.signupTitle), findsOneWidget);

    await tester.enterText(_field(l.companyName), 'Acme');
    await tester.enterText(_field(l.fullName), 'Ada Lovelace');
    await tester.enterText(_field(l.username), 'ada');
    await tester.enterText(_field(l.password), 'short');
    await tester.enterText(_field(l.confirmPassword), 'different');
    await tester.ensureVisible(find.text(l.createCompany));
    await tester.tap(find.text(l.createCompany));
    await tester.pumpAndSettle();
    expect(find.text(l.passwordTooShort('8')), findsOneWidget);
    expect(find.text(l.passwordsDontMatch), findsOneWidget);
    expect(repo.lastSignup, isNull);

    await tester.enterText(_field(l.password), 'password123');
    await tester.enterText(_field(l.confirmPassword), 'password123');
    await tester.ensureVisible(find.text(l.createCompany));
    await tester.tap(find.text(l.createCompany));
    await tester.pumpAndSettle();

    expect(repo.lastSignup, {
      'company': 'Acme',
      'full_name': 'Ada Lovelace',
      'username': 'ada',
    });
    await _openAccount(tester);
    expect(find.text(l.roleManager), findsOneWidget);
  });

  testWidgets('server field errors appear under the field', (tester) async {
    final repo = await _pumpApp(tester);
    repo.failWith = const ApiException(
      code: 'username_taken',
      message: 'username is already in use in this company',
      statusCode: 400,
      fields: {'username': 'username is already in use in this company'},
    );
    await tester.tap(find.text(l.createCompany));
    await tester.pumpAndSettle();

    await tester.enterText(_field(l.companyName), 'Acme');
    await tester.enterText(_field(l.fullName), 'Ada');
    await tester.enterText(_field(l.username), 'ada');
    await tester.enterText(_field(l.password), 'password123');
    await tester.enterText(_field(l.confirmPassword), 'password123');
    await tester.ensureVisible(find.text(l.createCompany));
    await tester.tap(find.text(l.createCompany));
    await tester.pumpAndSettle();

    expect(find.text(l.errUsernameTaken), findsOneWidget);
  });

  testWidgets('wide windows show the brand panel', (tester) async {
    await _pumpApp(tester, size: const Size(1280, 800));
    expect(find.text(l.brandHeadline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('short desktop windows do not overflow', (tester) async {
    await _pumpApp(tester, size: const Size(960, 600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping outside a field removes focus', (tester) async {
    await _pumpApp(tester);
    await tester.tap(_field(l.username));
    await tester.pump();
    expect(_textFieldFocused(), isTrue);

    await tester.tapAt(const Offset(200, 40));
    await tester.pump();
    expect(_textFieldFocused(), isFalse);
  });

  testWidgets('back from signup returns to login', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text(l.createCompany));
    await tester.pumpAndSettle();
    expect(find.text(l.signupTitle), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(find.text(l.welcomeBack), findsOneWidget);
  });

  testWidgets('server error disappears once the user edits', (tester) async {
    final repo = await _pumpApp(tester);
    repo.failWith = const ApiException(
      code: 'unauthorized',
      message: 'invalid credentials',
      statusCode: 401,
    );
    await tester.enterText(_field(l.companyName), 'Acme');
    await tester.enterText(_field(l.username), 'ada');
    await tester.enterText(_field(l.password), 'wrong-pass');
    await tester.tap(find.text(l.logIn));
    await tester.pumpAndSettle();
    expect(find.text(l.invalidCredentials), findsOneWidget);

    await tester.enterText(_field(l.password), 'wrong-pass2');
    await tester.pump();
    expect(find.text(l.invalidCredentials), findsNothing);
  });

  testWidgets('an expired saved session explains why login is needed', (
    tester,
  ) async {
    final repo = await _pumpApp(
      tester,
      stored: _testSession(expiresAt: DateTime(2000)),
    );
    expect(find.text(l.sessionExpired), findsOneWidget);
    expect(repo.stored, isNull);
  });

  testWidgets('a valid saved session opens home directly', (tester) async {
    await _pumpApp(tester, stored: _testSession(manager: true));
    expect(find.text(l.registersTitle), findsWidgets);
    await _openAccount(tester);
    expect(find.text(l.roleManager), findsOneWidget);
  });

  testWidgets('a taken company name is flagged on the company field', (
    tester,
  ) async {
    final repo = await _pumpApp(tester);
    repo.failWith = const ApiException(
      code: 'conflict',
      message: 'company name is already in use',
      statusCode: 409,
    );
    await tester.tap(find.text(l.createCompany));
    await tester.pumpAndSettle();
    await tester.enterText(_field(l.companyName), 'Acme');
    await tester.enterText(_field(l.fullName), 'Ada');
    await tester.enterText(_field(l.username), 'ada');
    await tester.enterText(_field(l.password), 'password123');
    await tester.enterText(_field(l.confirmPassword), 'password123');
    await tester.ensureVisible(find.text(l.createCompany));
    await tester.tap(find.text(l.createCompany));
    await tester.pumpAndSettle();

    expect(find.text(l.companyNameTaken), findsOneWidget);
    expect(find.text(l.fixHighlighted), findsOneWidget);
  });

  testWidgets('theme can be switched from the profile and is remembered', (
    tester,
  ) async {
    await _pumpApp(tester, stored: _testSession());
    await _openAccount(tester);
    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.system);
    expect(find.text(l.themeSystemHint), findsOneWidget);

    await tester.tap(find.text(l.themeDark));
    await tester.pumpAndSettle();
    expect(app().themeMode, ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });
}
