import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/l10n.dart';
import '../../records/application/records_controller.dart';
import '../../records/presentation/register_record_tiles.dart';
import '../application/registers_providers.dart';
import '../domain/cash_register.dart';
import 'widgets/register_widgets.dart';

/// Desktop: what the company looks like while no register is selected —
/// registers by status, obligations coming due, and the latest records.
class OverviewPane extends ConsumerWidget {
  const OverviewPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final registers = ref.watch(allRegistersProvider).value ?? const [];
    int count(RegisterStatus s) => registers.where((r) => r.status == s).length;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: l.overviewTitle, subtitle: l.overviewHint),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 860;
                const due = _DueCard();
                const recent = _RecentCard();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                for (final (i, s)
                                    in RegisterStatus.values.indexed) ...[
                                  if (i > 0) const SizedBox(width: 12),
                                  Expanded(
                                    child: StatTile(
                                      icon: s.icon,
                                      label: s.label(l),
                                      value: '${count(s)}',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (twoColumns)
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: due),
                                  SizedBox(width: 16),
                                  Expanded(child: recent),
                                ],
                              )
                            else ...[
                              due,
                              const SizedBox(height: 24),
                              recent,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.children,
    this.empty,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final String? empty;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: SectionTitle(title, trailing: trailing),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: children.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    empty ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.palette.textMuted,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final (i, child) in children.indexed) ...[
                      if (i > 0) const Divider(indent: 62),
                      child,
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _DueCard extends ConsumerWidget {
  const _DueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final due =
        ref.watch(dueObligationsProvider).value ?? const DueObligations();
    return _Section(
      title: l.dueTitle,
      empty: l.dueEmpty('${DueObligations.soonDays}'),
      trailing: due.overdue.isEmpty
          ? null
          : Pill(
              label: l.overdueCount('${due.overdue.length}'),
              color: p.negative,
            ),
      children: [
        for (final e in [...due.overdue, ...due.soon])
          DueObligationTile(entry: e),
      ],
    );
  }
}

class _RecentCard extends ConsumerWidget {
  const _RecentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final recent = ref.watch(recentRecordsProvider).value ?? const [];
    return _Section(
      title: l.recentTitle,
      empty: l.recentEmpty,
      children: [for (final e in recent) RecentRecordTile(entry: e)],
    );
  }
}
