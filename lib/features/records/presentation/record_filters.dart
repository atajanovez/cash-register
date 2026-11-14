import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format/dates.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/l10n.dart';
import '../../members/application/members_providers.dart';
import '../domain/record_type.dart';
import 'record_tile.dart';

/// A filter chip that opens a menu of choices. Highlighted while a choice
/// other than "all" is active.
class _MenuChip extends StatelessWidget {
  const _MenuChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.items,
  });

  final IconData icon;
  final String label;
  final bool active;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      menuChildren: items,
      builder: (context, controller, _) => FilterChip(
        avatar: Icon(icon, size: 15, color: active ? p.brand : null),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronDown, size: 14),
          ],
        ),
        selected: active,
        onSelected: (_) =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class RecordTypeFilter extends StatelessWidget {
  const RecordTypeFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final RecordType? selected;
  final ValueChanged<RecordType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _MenuChip(
      icon: selected?.icon ?? LucideIcons.listFilter,
      label: selected?.label(l) ?? l.allTypes,
      active: selected != null,
      items: [
        MenuItemButton(
          onPressed: () => onChanged(null),
          leadingIcon: const Icon(LucideIcons.layers),
          child: Text(l.allTypes),
        ),
        for (final type in RecordType.values)
          MenuItemButton(
            onPressed: () => onChanged(type),
            leadingIcon: Icon(type.icon, color: recordTypeTint(context, type)),
            child: Text(type.label(l)),
          ),
      ],
    );
  }
}

/// Quick periods, all ending today.
enum PeriodPreset {
  today,
  week,
  month;

  DateTimeRange range([DateTime? now]) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final start = switch (this) {
      PeriodPreset.today => today,
      PeriodPreset.week => DateUtils.addDaysToDate(
        today,
        -(today.weekday - DateTime.monday),
      ),
      PeriodPreset.month => DateTime(today.year, today.month),
    };
    return DateTimeRange(start: start, end: today);
  }

  String label(AppLocalizations l) => switch (this) {
    PeriodPreset.today => l.periodToday,
    PeriodPreset.week => l.periodWeek,
    PeriodPreset.month => l.periodMonth,
  };

  static PeriodPreset? of(DateTimeRange? range) {
    if (range == null) return null;
    for (final p in values) {
      if (p.range() == range) return p;
    }
    return null;
  }
}

String periodLabel(AppLocalizations l, DateTimeRange? period) {
  if (period == null) return l.periodAll;
  final preset = PeriodPreset.of(period);
  if (preset != null) return preset.label(l);
  return DateUtils.isSameDay(period.start, period.end)
      ? Dates.date(period.start)
      : '${Dates.date(period.start)} – ${Dates.date(period.end)}';
}

class RecordPeriodFilter extends StatelessWidget {
  const RecordPeriodFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final DateTimeRange? selected;
  final ValueChanged<DateTimeRange?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: selected,
      currentDate: today,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _MenuChip(
      icon: LucideIcons.calendarRange,
      label: periodLabel(l, selected),
      active: selected != null,
      items: [
        MenuItemButton(
          onPressed: () => onChanged(null),
          child: Text(l.periodAll),
        ),
        for (final preset in PeriodPreset.values)
          MenuItemButton(
            onPressed: () => onChanged(preset.range()),
            child: Text(preset.label(l)),
          ),
        const Divider(),
        MenuItemButton(
          leadingIcon: const Icon(LucideIcons.calendarDays),
          onPressed: () => _pick(context),
          child: Text(l.periodCustom),
        ),
      ],
    );
  }
}

/// Who made the record.
class RecordMemberFilter extends ConsumerWidget {
  const RecordMemberFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final members = ref.watch(membersProvider).value ?? const [];
    final current = members.where((m) => m.id == selected).firstOrNull;
    return _MenuChip(
      icon: LucideIcons.userRound,
      label: current?.displayName ?? l.allMembers,
      active: selected != null,
      items: [
        MenuItemButton(
          leadingIcon: const Icon(LucideIcons.users),
          onPressed: () => onChanged(null),
          child: Text(l.allMembers),
        ),
        for (final m in members)
          MenuItemButton(
            leadingIcon: Avatar(initials: m.initials, size: 24),
            onPressed: () => onChanged(m.id),
            child: Text(m.displayName),
          ),
      ],
    );
  }
}
