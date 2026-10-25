import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/password_field.dart';
import '../../../core/widgets/platform.dart';
import '../../../l10n/l10n.dart';
import '../application/auth_controller.dart';
import 'validators.dart';
import 'widgets/auth_layout.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _company;
  late final TextEditingController _username;
  final _password = TextEditingController();

  bool _submitting = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  /// Why the user was sent here (e.g. session expired); cleared on any edit.
  AuthNotice? _notice;

  /// Off until the first submit, then errors update live as the user types.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  /// Server errors describe the values that were sent; drop them on edit.
  void _clearServerErrors() {
    if (_error == null && _fieldErrors.isEmpty && _notice == null) return;
    setState(() {
      _error = null;
      _notice = null;
      _fieldErrors = const {};
    });
  }

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _company = TextEditingController(
      text: prefs.getString(PrefKeys.lastCompany),
    );
    _username = TextEditingController(
      text: prefs.getString(PrefKeys.lastUsername),
    );
    _notice = ref.read(authControllerProvider.notifier).takeNotice();
  }

  @override
  void dispose() {
    _company.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _error = null;
      _notice = null;
      _fieldErrors = const {};
      _autovalidate = AutovalidateMode.onUserInteraction;
    });
    if (!_formKey.currentState!.validate()) return;

    // Close the keyboard so the result (error banner or next page) is visible.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(
            companyName: _company.text,
            username: _username.text,
            password: _password.text,
          );
      // The router redirects to home once the session is set.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        final l = context.l10n;
        _fieldErrors = describeFieldErrors(l, e);
        _error = e.isUnauthorized ? l.invalidCredentials : describeError(l, e);
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final error =
        _error ??
        switch (_notice) {
          AuthNotice.sessionExpired => l.sessionExpired,
          AuthNotice.deactivated => l.accountDeactivated,
          null => null,
        };
    // Start on the first empty field so returning users go straight to password.
    final autofocus = shouldAutofocus(context);
    final focusPassword = _company.text.isNotEmpty && _username.text.isNotEmpty;

    return AuthLayout(
      title: l.welcomeBack,
      subtitle: l.loginSubtitle,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          onChanged: _clearServerErrors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _company,
                enabled: !_submitting,
                autofocus: autofocus && !focusPassword,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.organizationName],
                decoration: InputDecoration(
                  labelText: l.companyName,
                  prefixIcon: const Icon(LucideIcons.store),
                  errorText: _fieldErrors['company_name'],
                ),
                validator: Validators.required(l.enterCompanyName),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _username,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.username],
                decoration: InputDecoration(
                  labelText: l.username,
                  prefixIcon: const Icon(LucideIcons.userRound),
                  errorText: _fieldErrors['username'],
                ),
                validator: Validators.required(l.enterUsername),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                enabled: !_submitting,
                autofocus: autofocus && focusPassword,
                errorText: _fieldErrors['password'],
                validator: Validators.required(l.enterPassword),
                onSubmitted: (_) => _submit(),
              ),
              if (error != null) ...[
                const SizedBox(height: 20),
                ErrorBanner(message: error),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting ? const ButtonSpinner() : Text(l.logIn),
              ),
              const SizedBox(height: 32),
              _OrDivider(label: l.newHere),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _submitting ? null : () => context.push('/signup'),
                icon: const Icon(LucideIcons.building2),
                label: Text(l.createCompany),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
