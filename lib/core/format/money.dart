import 'package:flutter/services.dart';

/// Amounts travel as integer minor units (1/100 manat). These helpers are the
/// only place that converts between those and what people read and type.
///
/// Turkmen style: space between thousands, comma before decimals, currency
/// after the number: `1 154,00 TMT`.
abstract final class Money {
  static const scale = 100;
  static const currency = 'TMT';

  /// Non-breaking, so an amount never wraps across lines.
  static const _space = '\u00A0';

  /// `115400` → `1 154,00`
  static String number(int minor) {
    final abs = minor.abs();
    final cents = (abs % scale).toString().padLeft(2, '0');
    return '${minor < 0 ? '\u2212' : ''}${groupDigits(abs ~/ scale)},$cents';
  }

  /// `115400` → `1 154,00 TMT`
  static String format(int minor) => '${number(minor)}$_space$currency';

  /// Prefixes `+` / `−` (a real minus sign, which reads better than `-`).
  static String signed(int minor) =>
      minor > 0 ? '+${format(minor)}' : format(minor);

  /// Parses what [AmountInputFormatter] allows: `1234`, `1234,5`, `1234.56`.
  /// Returns null when empty or invalid.
  static int? parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s ]'), '').replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(cleaned);
    if (match == null) return null;
    final whole = int.parse(match.group(1)!);
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    return whole * scale + int.parse(fraction);
  }

  /// Old manats per new manat since the 2009 redenomination. Many people
  /// still count in old money (1 000 000 old = 200 TMT).
  static const oldPerNew = 5000;

  /// Old manats → minor units of new money, rounded to the nearest teňňe:
  /// `1000000` → `20000` (200,00 TMT), `1000` → `20` (0,20 TMT).
  static int fromOld(int oldManat) => (oldManat * scale / oldPerNew).round();

  /// `1234567` → `1 234 567`, for showing whole old-manat amounts.
  static String groupDigits(int value) {
    final digits = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(_space);
      out.write(digits[i]);
    }
    return out.toString();
  }

  /// `12345` → `123,45`, for prefilling an editable field.
  static String toInput(int minor) {
    final whole = minor ~/ scale;
    final cents = minor % scale;
    return cents == 0 ? '$whole' : '$whole,${cents.toString().padLeft(2, '0')}';
  }
}

/// Digits plus one decimal separator with at most two decimals. A dot is
/// accepted too (some keyboards only offer it) and shown as a comma.
class AmountInputFormatter extends TextInputFormatter {
  static final _valid = RegExp(r'^\d{0,13}(,\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('.', ',');
    if (!_valid.hasMatch(text)) return oldValue;
    return newValue.copyWith(text: text);
  }
}
