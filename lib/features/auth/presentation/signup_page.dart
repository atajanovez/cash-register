import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/password_field.dart';
import '../../../core/widgets/platform.dart';
import '../../../l10n/l10n.dart';
import '../application/auth_controller.dart';
import 'validators.dart';
import 'widgets/auth_layout.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _submitting = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  /// Off until the first submit, then errors update live as the user types.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  /// Server errors describe the values that were sent; drop them on edit.
  void _clearServerErrors() {
    if (_error == null && _fieldErrors.isEmpty) return;
    setState(() {
      _error = null;
      _fieldErrors = const {};
    });
  }

  @override
  void dispose() {
    for (final c in [_company, _fullName, _username, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _error = null;
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
          .createCompany(
            companyName: _company.text,
            fullName: _fullName.text,
            username: _username.text,
            password: _password.text,
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        final l = context.l10n;
        _fieldErrors = {
          ...describeFieldErrors(l, e),
          // The only 409 signup can return; the server sends no field for it.
          if (e.statusCode == 409 && e.fields.isEmpty)
            'company_name': l.companyNameTaken,
        };
        // Field-level problems are shown under the fields; only repeat the
        // message when it is not attached to a specific field.
        _error = _fieldErrors.isEmpty ? describeError(l, e) : l.fixHighlighted;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _backToLogin() =>
      context.canPop() ? context.pop() : context.go('/login');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AuthLayout(
      title: l.signupTitle,
      subtitle: l.signupSubtitle,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          onChanged: _clearServerErrors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel(l.sectionCompany),
              TextFormField(
                controller: _company,
                enabled: !_submitting,
                autofocus: shouldAutofocus(context),
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.organizationName],
                decoration: InputDecoration(
                  labelText: l.companyName,
                  helperText: l.companyNameHelper,
                  prefixIcon: const Icon(LucideIcons.store),
                  errorText: _fieldErrors['company_name'],
                ),
                validator: Validators.required(l.enterCompanyName),
              ),
              const SizedBox(height: 24),
              _SectionLabel(l.sectionManagerAccount),
              TextFormField(
                controller: _fullName,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: InputDecoration(
                  labelText: l.fullName,
                  prefixIcon: const Icon(LucideIcons.idCard),
                  errorText: _fieldErrors['full_name'],
                ),
                validator: Validators.required(l.enterFullName),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _username,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.newUsername],
                decoration: InputDecoration(
                  labelText: l.username,
                  prefixIcon: const Icon(LucideIcons.userRound),
                  errorText: _fieldErrors['username'],
                ),
                validator: Validators.username(l),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                helperText: l.passwordHelper('${Validators.passwordMin}'),
                errorText: _fieldErrors['password'],
                validator: Validators.newPassword(l),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirm,
                enabled: !_submitting,
                label: l.confirmPassword,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) =>
                    v != _password.text ? l.passwordsDontMatch : null,
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                ErrorBanner(message: _error!),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const ButtonSpinner()
                    : Text(l.createCompany),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    l.alreadyHaveCompany,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: _submitting ? null : _backToLogin,
                    child: Text(l.logIn),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
