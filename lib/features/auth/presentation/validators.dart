import 'package:flutter/widgets.dart';

import '../../../l10n/l10n.dart';

abstract final class Validators {
  /// Server rule: 8..72 characters (bcrypt input limit).
  static const passwordMin = 8;
  static const passwordMax = 72;

  static FormFieldValidator<String> required(String message) =>
      (value) => (value == null || value.trim().isEmpty) ? message : null;

  static FormFieldValidator<String> username(AppLocalizations l) => (value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l.chooseUsername;
    if (v.contains(RegExp(r'\s'))) return l.usernameNoSpaces;
    return null;
  };

  static FormFieldValidator<String> newPassword(AppLocalizations l) => (value) {
    final v = value ?? '';
    if (v.isEmpty) return l.choosePassword;
    if (v.length < passwordMin) return l.passwordTooShort('$passwordMin');
    if (v.length > passwordMax) return l.passwordTooLong('$passwordMax');
    return null;
  };
}
