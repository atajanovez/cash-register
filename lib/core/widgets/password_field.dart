import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/l10n.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label,
    this.helperText,
    this.errorText,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.autofillHints = const [AutofillHints.password],
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController controller;

  /// Defaults to the localized "Password".
  final String? label;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String> autofillHints;
  final bool enabled;
  final bool autofocus;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;
  // Tab should go field to field, not stop on the show/hide toggle.
  final _toggleFocus = FocusNode(skipTraversal: true);

  @override
  void dispose() {
    _toggleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: _obscured,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label ?? context.l10n.password,
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefixIcon: const Icon(LucideIcons.lockKeyhole),
        suffixIcon: IconButton(
          focusNode: _toggleFocus,
          tooltip: _obscured
              ? context.l10n.showPassword
              : context.l10n.hidePassword,
          icon: Icon(_obscured ? LucideIcons.eye : LucideIcons.eyeOff),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
    );
  }
}
