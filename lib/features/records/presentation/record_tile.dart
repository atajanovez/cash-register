import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/l10n.dart';
import '../../sync/sync_widgets.dart';
import '../domain/cash_record.dart';
import '../domain/record_type.dart';

extension CashRecordUi on CashRecord {
  /// "«Seýf» kassasyna" for transfers, otherwise the type label.
  String title(AppLocalizations l) => switch (type) {
    RecordType.transferOut => l.transferTo(
      destination?.name ?? l.anotherRegister,
    ),
    RecordType.transferIn => l.transferFrom(source?.name ?? l.anotherRegister),
    _ => type.label(l),
  };

  String amountLabel() {
    final sign = type.displaySign;
    return sign == 0 ? Money.format(amount) : Money.signed(sign * amount);
  }
}

/// Amber for obligations, green for money in, red for money out.
Color recordTypeTint(BuildContext context, RecordType type) => type.isOpening
    ? context.palette.warning
    : amountColor(context, type.displaySign);

class RecordTypeIcon extends StatelessWidget {
  const RecordTypeIcon({super.key, required this.type, this.size = 40});

  final RecordType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = recordTypeTint(context, type);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? .16 : .09),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(type.icon, size: size * 0.48, color: color),
    );
  }
}

/// A record on phones: icon, title and note, time and author, amount.
class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.record, required this.onTap});

  final CashRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final meta = [
      Dates.time(record.createdAt),
      if (record.creator != null) record.creator!.displayName,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecordTypeIcon(type: record.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          record.title(l),
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _Amount(record: record),
                    ],
                  ),
                  if (record.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      record.note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.palette.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(meta, style: theme.textTheme.bodySmall),
                      ),
                      if (record.isPending) ...[
                        const SizedBox(width: 8),
                        const PendingMark(),
                      ],
                    ],
                  ),
                  if (record.type.isOpening) ...[
                    const SizedBox(height: 8),
                    ObligationStatus(record: record),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A record on desktop, as a table row: record, member, time, amount.
class RecordRow extends StatefulWidget {
  const RecordRow({
    super.key,
    required this.record,
    required this.onTap,
    this.onMenu,
    this.selected = false,
  });

  final CashRecord record;
  final VoidCallback onTap;

  /// Shown in the side panel.
  final bool selected;

  /// Right-click, with the pointer position.
  final void Function(Offset at)? onMenu;

  @override
  State<RecordRow> createState() => _RecordRowState();
}

class _RecordRowState extends State<RecordRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = context.palette;
    final record = widget.record;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: widget.selected
            ? p.brandSoft
            : _hover
            ? p.surfaceMuted
            : Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onSecondaryTapUp: widget.onMenu == null
              ? null
              : (d) => widget.onMenu!(d.globalPosition),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                RecordTypeIcon(type: record.type, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title(l),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (record.note.isNotEmpty)
                        Text(
                          record.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      if (record.type.isOpening) ...[
                        const SizedBox(height: 6),
                        ObligationStatus(record: record),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(
                    record.creator?.displayName ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: p.textMuted,
                    ),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: record.isPending
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: PendingMark(label: false),
                        )
                      : Text(
                          Dates.time(record.createdAt),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: p.textMuted,
                            fontFeatures: tabularFigures,
                          ),
                        ),
                ),
                SizedBox(
                  width: 150,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _Amount(record: record),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.record});

  final CashRecord record;

  @override
  Widget build(BuildContext context) => Text(
    record.amountLabel(),
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: amountColor(context, record.type.displaySign),
      fontFeatures: tabularFigures,
    ),
  );
}

/// What is left of a loan or accrual, and whether it is due or overdue.
class ObligationStatus extends StatelessWidget {
  const ObligationStatus({super.key, required this.record});

  final CashRecord record;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    if (record.isFullySettled) {
      return Pill(label: l.settled, icon: LucideIcons.check, color: p.positive);
    }
    final overdue = record.isOverdue();
    final left = Money.format(record.remaining);
    final deadline = record.deadline;
    return Pill(
      label: deadline == null
          ? l.amountLeft(left)
          : overdue
          ? l.amountLeftOverdue(left, Dates.short(deadline))
          : l.amountLeftDue(left, Dates.short(deadline)),
      icon: overdue ? LucideIcons.triangleAlert : LucideIcons.clock,
      color: overdue ? p.negative : p.warning,
    );
  }
}

/// "Şu gün", "Düýn", ... above each day's records, with the day's net cash
/// movement on the right.
class DayHeader extends StatelessWidget {
  const DayHeader(this.date, {super.key, this.records = const []});

  final DateTime date;
  final List<CashRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final net = records.fold(
      0,
      (sum, r) => sum + r.type.currentSign * r.amount,
    );
    final style = theme.textTheme.labelMedium?.copyWith(
      color: p.textMuted,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              Dates.dayHeader(
                date,
                today: context.l10n.today,
                yesterday: context.l10n.yesterday,
              ),
              style: style,
            ),
          ),
          if (records.isNotEmpty && net != 0)
            Text(
              Money.signed(net),
              style: style?.copyWith(
                color: amountColor(context, net.sign),
                fontFeatures: tabularFigures,
              ),
            ),
        ],
      ),
    );
  }
}
