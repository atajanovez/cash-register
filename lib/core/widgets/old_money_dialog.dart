import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/l10n.dart';
import '../format/money.dart';
import '../theme/app_theme.dart';

/// Lets someone who counts in old manats type that amount and see it in new
/// money. Pops with the amount in minor units of TMT, or null.
Future<int?> showOldMoneyConverter(BuildContext context) =>
    showDialog<int>(context: context, builder: (_) => const _OldMoneyDialog());

class _OldMoneyDialog extends StatefulWidget {
  const _OldMoneyDialog();

  @override
  State<_OldMoneyDialog> createState() => _OldMoneyDialogState();
}

class _OldMoneyDialogState extends State<_OldMoneyDialog> {
  final _controller = TextEditingController();

  int? get _old {
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : int.parse(digits);
  }

  int? get _converted {
    final old = _old;
    return old == null || old == 0 ? null : Money.fromOld(old);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _use() {
    final value = _converted;
    if (value != null && value > 0) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final converted = _converted;

    return AlertDialog(
      title: Text(l.oldMoneyTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.oldMoneyRate, style: TextStyle(color: muted)),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [_GroupedDigitsFormatter()],
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _use(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFeatures: tabularFigures,
              ),
              decoration: InputDecoration(
                labelText: l.oldMoneyLabel,
                hintText: '1 000 000',
                suffixText: l.oldMoneySuffix,
                suffixStyle: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Icon(LucideIcons.arrowDown)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.palette.brandSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(l.oldMoneyResult, style: TextStyle(color: muted)),
                  const SizedBox(height: 4),
                  Text(
                    converted == null ? '—' : Money.format(converted),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                  if (converted == null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l.oldMoneyEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: converted == null || converted == 0 ? null : _use,
          child: Text(l.oldMoneyUse),
        ),
      ],
    );
  }
}

/// Digits only, shown in groups of three (`1 000 000`) so large old-money
/// amounts are easy to read while typing.
class _GroupedDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 15) return oldValue;
    if (digits.isEmpty) return const TextEditingValue();
    final text = Money.groupDigits(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
