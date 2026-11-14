import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/l10n.dart';
import '../data/records_repository.dart';
import 'record_tile.dart';

/// One row of a list that spans registers (overview, due obligations):
/// tapping opens the record's register.
class _RegisterRecordTile extends StatelessWidget {
  const _RegisterRecordTile({
    required this.entry,
    required this.detail,
    required this.amount,
    this.detailColor,
    this.amountColor,
    this.onTap,
  });

  final RegisterRecord entry;
  final VoidCallback? onTap;
  final String detail;
  final String amount;
  final Color? detailColor;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final record = entry.record;
    return InkWell(
      onTap: onTap ?? () => context.go('/registers/${entry.register.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            RecordTypeIcon(type: record.type, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.note.isNotEmpty
                        ? record.note
                        : record.title(context.l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    '${entry.register.name} · $detail',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: detailColor ?? p.textMuted,
                      fontWeight: detailColor == null ? null : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amount,
              style: theme.textTheme.titleSmall?.copyWith(
                color: amountColor,
                fontFeatures: tabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An obligation with what is left and when it is due; red when overdue.
class DueObligationTile extends StatelessWidget {
  const DueObligationTile({super.key, required this.entry, this.onTap});

  final RegisterRecord entry;

  /// Defaults to opening the register.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final record = entry.record;
    return _RegisterRecordTile(
      entry: entry,
      detail: context.l10n.dueOn(Dates.short(record.deadline!)),
      detailColor: record.isOverdue() ? context.palette.negative : null,
      amount: Money.format(record.remaining),
      onTap: onTap,
    );
  }
}

/// A recent record with its register and time.
class RecentRecordTile extends StatelessWidget {
  const RecentRecordTile({super.key, required this.entry});

  final RegisterRecord entry;

  @override
  Widget build(BuildContext context) {
    final record = entry.record;
    return _RegisterRecordTile(
      entry: entry,
      detail:
          '${Dates.short(record.createdAt)}, ${Dates.time(record.createdAt)}',
      amount: record.amountLabel(),
      amountColor: amountColor(context, record.type.displaySign),
    );
  }
}
