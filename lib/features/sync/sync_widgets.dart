import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/network/api_exception.dart';
import '../../core/offline/local_store.dart';
import '../../core/offline/offline_providers.dart';
import '../../core/offline/sync_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../l10n/l10n.dart';
import '../records/domain/record_type.dart';
import '../settings/server_widgets.dart';

/// Icon, colour and one-line label for the current sync state.
({IconData icon, Color color, String label}) _describe(
  BuildContext context,
  SyncStatus s,
) {
  final l = context.l10n;
  final p = context.palette;
  if (s.rejected.isNotEmpty) {
    return (
      icon: LucideIcons.circleAlert,
      color: p.negative,
      label: l.syncRejected('${s.rejected.length}'),
    );
  }
  return switch (s.phase) {
    SyncPhase.offline => (
      icon: LucideIcons.cloudOff,
      color: p.warning,
      label: s.pending > 0
          ? l.syncOfflineWaiting('${s.pending}')
          : l.syncOffline,
    ),
    SyncPhase.syncing => (
      icon: LucideIcons.refreshCw,
      color: p.brand,
      label: l.syncSyncing,
    ),
    SyncPhase.error => (
      icon: LucideIcons.triangleAlert,
      color: p.negative,
      label: l.syncError,
    ),
    SyncPhase.idle when s.pending > 0 => (
      icon: LucideIcons.cloudUpload,
      color: p.brand,
      label: l.syncPending('${s.pending}'),
    ),
    SyncPhase.idle => (
      icon: LucideIcons.cloudCheck,
      color: p.positive,
      label: l.syncUpToDate,
    ),
  };
}

/// Desktop sidebar row; tapping opens the sync details.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key, this.compact = false});

  /// Icon only, for the narrow sidebar.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final d = _describe(context, status);
    final p = context.palette;
    final icon = Icon(d.icon, size: 16, color: d.color);

    if (compact) {
      return Tooltip(
        message: d.label,
        child: IconButton(onPressed: () => showSyncSheet(context), icon: icon),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showSyncSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  d.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: p.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phone: a slim bar above the page while offline, sending, or when
/// something needs attention. Hidden when everything is in sync.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final visible =
        status.isOffline ||
        status.pending > 0 ||
        status.rejected.isNotEmpty ||
        status.phase == SyncPhase.error;
    final d = _describe(context, status);
    final p = context.palette;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Material(
              color: d.color.withValues(alpha: .10),
              child: InkWell(
                onTap: () => showSyncSheet(context),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(d.icon, size: 16, color: d.color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            d.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.text,
                            ),
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: p.textSubtle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

Future<void> showSyncSheet(BuildContext context) =>
    showAdaptiveSheet<void>(context, builder: (_) => const _SyncSheet());

class _SyncSheet extends ConsumerWidget {
  const _SyncSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = context.palette;
    final status = ref.watch(syncStatusProvider);
    final store = ref.watch(offlineProvider).value?.store;
    final d = _describe(context, status);
    final pending = store?.pending ?? const <OutboxEntry>[];

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, isWide(context) ? 24 : 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.syncTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: d.color.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: d.color.withValues(alpha: .25)),
              ),
              child: Row(
                children: [
                  Icon(d.icon, color: d.color, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.label, style: theme.textTheme.titleSmall),
                        Text(
                          status.lastSyncedAt == null
                              ? l.syncNever
                              : l.syncLastAt(
                                  Dates.dateTime(status.lastSyncedAt!),
                                ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (status.isOffline) ...[
              const SizedBox(height: 10),
              Text(
                l.syncOfflineHint,
                style: theme.textTheme.bodyMedium?.copyWith(color: p.textMuted),
              ),
            ],
            if (status.rejected.isNotEmpty) ...[
              const SizedBox(height: 20),
              SectionTitle(l.syncRejectedTitle),
              const SizedBox(height: 4),
              Text(l.syncRejectedHint, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              for (final e in status.rejected)
                _OpRow(
                  entry: e,
                  store: store,
                  error: describeError(
                    l,
                    ApiException(
                      code: e.errorCode ?? 'conflict',
                      message: e.errorMessage ?? '',
                      statusCode: 409,
                    ),
                  ),
                  onDiscard: () =>
                      ref.read(syncControllerProvider).discard(e.operationId),
                ),
            ],
            const SizedBox(height: 20),
            SectionTitle(l.syncPendingTitle),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              Text(l.syncNothingWaiting, style: theme.textTheme.bodyMedium)
            else
              for (final e in pending) _OpRow(entry: e, store: store),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
              onPressed: status.phase == SyncPhase.syncing
                  ? null
                  : () => ref.read(syncControllerProvider).refresh(),
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(l.syncNow),
            ),
            if (showSyncServers(ref)) ...[
              const SizedBox(height: 10),
              const SyncServersButton(expanded: true),
            ],
          ],
        ),
      ),
    );
  }
}

/// One queued change, described in words.
class _OpRow extends StatelessWidget {
  const _OpRow({
    required this.entry,
    required this.store,
    this.error,
    this.onDiscard,
  });

  final OutboxEntry entry;
  final LocalStore? store;
  final String? error;
  final VoidCallback? onDiscard;

  String _label(AppLocalizations l) {
    final p = entry.payload ?? const {};
    String registerName(Object? id) {
      final s = store;
      if (s == null || id is! String) return '—';
      return s.view.register(s.resolve(id))?.name ?? '—';
    }

    return switch (entry.type) {
      'record.create' => l.opRecordCreate(
        RecordType.fromWire(p['type'] as String).label(l),
        Money.format((p['amount'] as num).toInt()),
      ),
      'cash_register.create' => l.opRegisterCreate('${p['name']}'),
      'cash_register.check' => l.opRegisterCheck(registerName(entry.entityId)),
      'cash_register.close' => l.opRegisterClose(registerName(entry.entityId)),
      'cash_register.delete' => l.opRegisterDelete(
        registerName(entry.entityId),
      ),
      'cash_register.access_set' => l.opRegisterAccess(
        registerName(entry.entityId),
      ),
      _ => entry.type,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = context.palette;
    final failed = error != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            failed ? LucideIcons.circleAlert : LucideIcons.clock,
            size: 16,
            color: failed ? p.negative : p.textSubtle,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label(l), style: theme.textTheme.bodyMedium),
                Text(
                  error ?? Dates.dateTime(entry.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: failed ? p.negative : null,
                  ),
                ),
              ],
            ),
          ),
          if (onDiscard != null)
            TextButton(onPressed: onDiscard, child: Text(l.syncDiscard)),
        ],
      ),
    );
  }
}

/// Small "not sent yet" mark for items made offline.
class PendingMark extends StatelessWidget {
  const PendingMark({super.key, this.label = true});

  final bool label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final icon = Icon(LucideIcons.cloudUpload, size: 13, color: p.textSubtle);
    if (!label) {
      return Tooltip(message: context.l10n.pendingBadge, child: icon);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 4),
        Text(
          context.l10n.pendingBadge,
          style: TextStyle(fontSize: 12, color: p.textSubtle),
        ),
      ],
    );
  }
}
