import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/l10n.dart';
import '../domain/cash_record.dart';
import 'record_tile.dart';

/// Read-only view of one record. Pops with `true` when the user taps
/// the settle button so the caller can open the settlement form.
class RecordDetailsSheet extends StatelessWidget {
  const RecordDetailsSheet({
    super.key,
    required this.record,
    required this.canSettle,
  });

  final CashRecord record;
  final bool canSettle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final sign = record.type.displaySign;
    final parent = record.parent;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, isWide(context) ? 24 : 0, 24, 24),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                RecordTypeIcon(type: record.type, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.title(l), style: theme.textTheme.titleLarge),
                      Text(
                        record.type.hint(l),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              sign == 0
                  ? Money.format(record.amount)
                  : Money.signed(sign * record.amount),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: amountColor(context, sign),
                fontFeatures: tabularFigures,
              ),
            ),
            if (record.type.isOpening) ...[
              const SizedBox(height: 16),
              _SettlementProgress(record: record),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            if (record.note.isNotEmpty)
              _Row(
                icon: LucideIcons.stickyNote,
                label: l.detailNote,
                value: record.note,
              ),
            _Row(
              icon: LucideIcons.calendar,
              label: l.detailRecorded,
              value: Dates.dateTime(record.createdAt),
            ),
            if (record.creator != null)
              _Row(
                icon: LucideIcons.userRound,
                label: l.detailBy,
                value:
                    '${record.creator!.displayName} '
                    '(@${record.creator!.username})',
              ),
            if (record.counterparty != null)
              _Row(
                icon: LucideIcons.arrowRightLeft,
                label: record.destination != null ? l.detailTo : l.detailFrom,
                value: record.counterparty!.name,
              ),
            if (record.deadline != null)
              _Row(
                icon: LucideIcons.flag,
                label: l.detailDue,
                value: Dates.date(record.deadline!),
                valueColor: record.isOverdue() ? theme.colorScheme.error : null,
              ),
            if (parent != null)
              _Row(
                icon: LucideIcons.link,
                label: l.detailSettles,
                value: [
                  parent.type.label(l),
                  Money.format(parent.amount),
                  if (parent.note.isNotEmpty) parent.note,
                ].join(' · '),
              ),
            if (record.children.isNotEmpty) ...[
              const SizedBox(height: 12),
              SectionTitle(l.payments('${record.children.length}')),
              const SizedBox(height: 4),
              for (final child in record.children)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          [
                            Dates.dateTime(child.createdAt),
                            if (child.note.isNotEmpty) child.note,
                          ].join(' · '),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        Money.format(child.amount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (canSettle) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(LucideIcons.circleCheck),
                label: Text(record.type.settledBy!.label(l)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettlementProgress extends StatelessWidget {
  const _SettlementProgress({required this.record});

  final CashRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settled = record.settledAmount.clamp(0, record.amount);
    final done = record.isFullySettled;
    final color = done ? context.palette.positive : context.palette.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: record.amount == 0 ? 1 : settled / record.amount,
            minHeight: 6,
            color: color,
            backgroundColor: color.withValues(alpha: .18),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          done
              ? context.l10n.fullySettled
              : context.l10n.settledAndLeft(
                  Money.format(settled),
                  Money.format(record.remaining),
                ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: p.textSubtle),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: p.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
