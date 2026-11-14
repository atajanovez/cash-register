import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/shortcuts.dart';
import '../../../core/offline/offline_providers.dart';
import '../../../l10n/l10n.dart';
import '../../records/application/records_controller.dart';
import '../../records/data/records_repository.dart';
import '../../records/domain/cash_record.dart';
import '../../records/domain/record_type.dart';
import '../../records/presentation/add_record_sheet.dart';
import '../../records/presentation/record_details_sheet.dart';
import '../../records/presentation/record_filters.dart';
import '../../records/presentation/record_tile.dart';
import '../application/registers_providers.dart';
import '../domain/cash_register.dart';
import 'widgets/access_editor.dart';
import 'widgets/register_widgets.dart';

class RegisterDetailPage extends ConsumerWidget {
  const RegisterDetailPage({
    super.key,
    required this.registerId,
    this.embedded = false,
  });

  final String registerId;

  /// Shown next to the list on wide screens: no back button.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(registerDetailProvider(registerId));
    final perms = ref.watch(registerPermissionsProvider(registerId));
    final register = detail.value?.register;
    final canAdd =
        register != null &&
        (perms?.canAddRecords ?? false) &&
        RecordType.values.any(
          (t) => t.creatable && t.allowedIn(register.status),
        );
    final wide = isWide(context);
    final commands = detail.value == null
        ? null
        : _Commands(context, ref, detail.value!);

    final notFound =
        detail.error is ApiException &&
        (detail.error! as ApiException).statusCode == 404;

    final body = notFound
        ? EmptyState(
            icon: LucideIcons.eyeOff,
            title: context.l10n.registerNotAvailable,
            message: context.l10n.registerNotAvailableHint,
            action: OutlinedButton(
              onPressed: () => context.go('/registers'),
              child: Text(context.l10n.backToRegisters),
            ),
          )
        : AsyncValueView(
            value: detail,
            onRetry: () => ref.invalidate(registerDetailProvider(registerId)),
            data: (d) => _Body(detail: d, perms: perms),
          );

    if (wide) {
      return KeyboardShortcuts(
        bindings: {
          if (canAdd)
            cmd(LogicalKeyboardKey.keyN): () =>
                showAddRecord(context, register),
        },
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (register != null)
                LayoutBuilder(
                  builder: (context, constraints) => PageHeader(
                    leading: embedded ? null : const BackButton(),
                    title: register.name,
                    badge: StatusPill(register.status),
                    subtitle: context.l10n.createdOn(
                      Dates.date(register.createdAt),
                    ),
                    actions: [
                      if (perms != null && commands != null)
                        ..._desktopActions(
                          context,
                          perms,
                          commands,
                          // Narrow panes keep only the main buttons visible.
                          compact: constraints.maxWidth < 980,
                        ),
                      if (canAdd)
                        AppBarPrimaryAction(
                          icon: LucideIcons.plus,
                          label: context.l10n.addRecord,
                          tooltip: shortcutLabel('N'),
                          onPressed: () => showAddRecord(context, register),
                        ),
                    ],
                  ),
                ),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return _PhoneChrome(
      builder: (collapsed, fabExtended) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !embedded,
          // Once the balance card scrolls away, the cash stays in view here.
          title: register == null
              ? null
              : ValueListenableBuilder(
                  valueListenable: collapsed,
                  builder: (context, on, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(register.name),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.topLeft,
                        child: on
                            ? Text(
                                Money.format(register.currentAmount),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: tabularFigures,
                                    ),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ),
          actions: [
            if ((perms?.isManager ?? false) && commands != null)
              IconButton(
                tooltip: context.l10n.more,
                icon: const Icon(LucideIcons.ellipsisVertical),
                onPressed: () => showActionMenu(
                  context,
                  title: register!.name,
                  actions: commands.overflow(perms!, includeLifecycle: true),
                ),
              ),
            const SizedBox(width: 4),
          ],
        ),
        // Shrinks to an icon while scrolling down, so it does not cover the
        // amounts.
        floatingActionButton: canAdd
            ? ValueListenableBuilder(
                valueListenable: fabExtended,
                builder: (context, extended, _) =>
                    FloatingActionButton.extended(
                      isExtended: extended,
                      tooltip: context.l10n.addRecord,
                      onPressed: () => showAddRecord(context, register),
                      icon: const Icon(LucideIcons.plus),
                      label: Text(context.l10n.addRecord),
                    ),
              )
            : null,
        body: body,
      ),
    );
  }

  List<Widget> _desktopActions(
    BuildContext context,
    RegisterPermissions perms,
    _Commands commands, {
    required bool compact,
  }) {
    final l = context.l10n;
    final register = commands.detail.register;
    final unsettled = register.difference != 0;
    final count = commands.detail.members.length;
    // Refreshing is ⌘R, or the sync status in the sidebar.
    return [
      if (perms.canManageAccess && !compact)
        OutlinedButton.icon(
          onPressed: commands.editAccess,
          icon: const Icon(LucideIcons.users, size: 17),
          label: Text(count == 0 ? l.giveAccess : l.membersCount('$count')),
        ),
      if (perms.canCheck)
        OutlinedButton.icon(
          onPressed: commands.check,
          icon: const Icon(LucideIcons.clipboardCheck, size: 17),
          label: Text(l.check),
        ),
      if (perms.canClose)
        Tooltip(
          message: unsettled
              ? l.settleBeforeClosing(Money.format(register.difference.abs()))
              : '',
          child: OutlinedButton.icon(
            onPressed: unsettled ? null : commands.close,
            icon: const Icon(LucideIcons.lock, size: 17),
            label: Text(l.close),
          ),
        ),
      if (perms.isManager)
        MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          menuChildren: [
            for (final a in commands.overflow(perms, includeLifecycle: compact))
              MenuItemButton(
                leadingIcon: Icon(
                  a.icon,
                  color: a.destructive ? context.palette.negative : null,
                ),
                onPressed: a.onSelected,
                child: Text(
                  a.label,
                  style: TextStyle(
                    color: a.destructive ? context.palette.negative : null,
                  ),
                ),
              ),
          ],
          builder: (context, controller, _) => ToolbarIconButton(
            icon: LucideIcons.ellipsis,
            tooltip: l.more,
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
        ),
    ];
  }
}

/// Register actions shared by the desktop header, the phone overflow menu
/// and the phone action row. Results show as snackbars.
class _Commands {
  _Commands(this.context, this.ref, this.detail);

  final BuildContext context;
  final WidgetRef ref;
  final RegisterDetail detail;

  CashRegister get register => detail.register;

  Future<bool> _run(
    Future<void> Function(RegisterActions actions) action, {
    required String done,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    try {
      await action(ref.read(registerActionsProvider));
      messenger.showSnackBar(SnackBar(content: Text(done)));
      return true;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(l, e))));
      return false;
    }
  }

  Future<void> refresh() => ref.read(syncControllerProvider).refresh();

  Future<void> check() async {
    final l = context.l10n;
    final ok = await confirm(
      context,
      title: l.checkTitle(register.name),
      message: l.checkMessage,
      confirmLabel: l.checkConfirm,
    );
    if (ok && context.mounted) {
      await _run((a) => a.check(register.id), done: l.registerChecked);
    }
  }

  Future<void> close() async {
    final l = context.l10n;
    final ok = await confirm(
      context,
      title: l.closeTitle(register.name),
      message: l.closeMessage,
      confirmLabel: l.closeConfirm,
    );
    if (ok && context.mounted) {
      await _run((a) => a.close(register.id), done: l.registerClosed);
    }
  }

  Future<void> delete() async {
    final l = context.l10n;
    final ok = await confirm(
      context,
      title: l.deleteTitle(register.name),
      message: l.deleteMessage,
      confirmLabel: l.delete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final router = GoRouter.of(context);
    final deleted = await _run(
      (a) => a.delete(register.id),
      done: l.registerDeleted,
    );
    if (deleted) router.go('/registers');
  }

  Future<void> togglePin() {
    final l = context.l10n;
    final pin = !register.isPinned;
    return _run(
      (a) => a.setPinned(register.id, pinned: pin),
      done: pin ? l.registerPinned : l.registerUnpinned,
    );
  }

  Future<void> editAccess() async {
    final saved = await showAdaptiveSheet<bool>(
      context,
      builder: (_) => AccessSheet(detail: detail),
    );
    if (saved == true && context.mounted) {
      showInfoSnack(context, context.l10n.accessUpdated);
    }
  }

  /// Less frequent actions, behind "⋯".
  List<MenuAction> overflow(
    RegisterPermissions perms, {
    bool includeLifecycle = false,
  }) {
    final l = context.l10n;
    return [
      if (includeLifecycle && perms.canManageAccess)
        MenuAction(
          icon: LucideIcons.users,
          label: l.access,
          onSelected: editAccess,
        ),
      if (perms.canPin)
        MenuAction(
          icon: register.isPinned ? LucideIcons.pinOff : LucideIcons.pin,
          label: register.isPinned ? l.unpin : l.pin,
          onSelected: togglePin,
        ),
      if (perms.canDelete)
        MenuAction(
          icon: LucideIcons.trash2,
          label: l.delete,
          destructive: true,
          onSelected: delete,
        ),
    ];
  }
}

/// Opens the add record form for [register]; shows the saved message.
Future<void> showAddRecord(
  BuildContext context,
  CashRegister register, {
  RecordType? type,
  CashRecord? parent,
}) async {
  final saved = await showAdaptiveSheet<bool>(
    context,
    maxWidth: 560,
    builder: (_) =>
        AddRecordSheet(register: register, type: type, parent: parent),
  );
  if (saved == true && context.mounted) {
    if (!isWide(context)) HapticFeedback.lightImpact();
    final offline = ProviderScope.containerOf(
      context,
    ).read(syncStatusProvider).isOffline;
    showInfoSnack(
      context,
      offline ? context.l10n.savedOffline : context.l10n.recordSaved,
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.detail, required this.perms});

  final RegisterDetail detail;
  final RegisterPermissions? perms;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  String get _id => widget.detail.register.id;

  /// Wide panes show the tapped record in a side panel instead of a dialog.
  bool _panelRoom = false;
  CashRecord? _inspected;

  bool _onScroll(ScrollNotification n) {
    // Only the page itself, not the sideways filter row.
    if (n.depth != 0) return false;
    // Load the next page a little before the end is reached.
    if (n.metrics.extentAfter < 600) {
      ref.read(recordsControllerProvider(_id).notifier).loadMore();
    }
    final chrome = _ScrollChrome.maybeOf(context);
    if (chrome != null) {
      chrome.collapsed.value = n.metrics.pixels > 190;
      if (n is UserScrollNotification) {
        if (n.direction == ScrollDirection.reverse) {
          chrome.fabExtended.value = false;
        } else if (n.direction == ScrollDirection.forward) {
          chrome.fabExtended.value = true;
        }
      }
    }
    return false;
  }

  Future<void> _refresh() => ref.read(syncControllerProvider).refresh();

  /// The settlement type this member may add for [record] now, if any.
  RecordType? _settleType(CashRecord record) {
    final type = record.type.settledBy;
    final ok =
        (widget.perms?.canAddRecords ?? false) &&
        type != null &&
        record.remaining > 0 &&
        type.allowedIn(widget.detail.register.status);
    return ok ? type : null;
  }

  void _settle(CashRecord record) => showAddRecord(
    context,
    widget.detail.register,
    type: _settleType(record),
    parent: record,
  );

  void _openRecord(CashRecord record) async {
    if (_panelRoom) {
      setState(() => _inspected = record);
      return;
    }
    final settle = await showAdaptiveSheet<bool>(
      context,
      builder: (_) => RecordDetailsSheet(
        record: record,
        canSettle: _settleType(record) != null,
      ),
    );
    if (settle == true && mounted) _settle(record);
  }

  /// Right-click on a desktop row.
  void _recordMenu(CashRecord record, Offset at) {
    final l = context.l10n;
    final settleType = _settleType(record);
    showActionMenu(
      context,
      at: at,
      title: record.title(l),
      actions: [
        MenuAction(
          icon: LucideIcons.squareArrowOutUpRight,
          label: l.open,
          onSelected: () => _openRecord(record),
        ),
        if (settleType != null)
          MenuAction(
            icon: settleType.icon,
            label: settleType.label(l),
            onSelected: () => _settle(record),
          ),
        MenuAction(
          icon: LucideIcons.copy,
          label: l.copyAmount,
          onSelected: () {
            Clipboard.setData(
              ClipboardData(text: Money.toInput(record.amount)),
            );
            showInfoSnack(context, l.amountCopied);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final register = widget.detail.register;
    final records = ref.watch(recordsControllerProvider(_id));
    final wide = isWide(context);
    final perms = widget.perms;

    final list = RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _box(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (register.status != RegisterStatus.open) ...[
                    _StatusBanner(status: register.status),
                    const SizedBox(height: 12),
                  ],
                  BalanceHeader(register: register),
                  if (!wide && perms != null) ...[
                    const SizedBox(height: 12),
                    _PhoneActions(
                      perms: perms,
                      commands: _Commands(context, ref, widget.detail),
                    ),
                  ],
                  if (wide && perms != null && !perms.isManager) ...[
                    const SizedBox(height: 12),
                    _AccessNote(perms: perms),
                  ],
                  SizedBox(height: wide ? 24 : 16),
                  _RecordsToolbar(registerId: _id),
                  if (wide) ...[
                    _FilteredTotals(registerId: _id),
                    _TableHeader(registerId: _id),
                  ],
                ],
              ),
              top: wide ? 0 : 8,
            ),
            if (!wide) ...[
              // Filters stay at hand while scrolling through records.
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedBar(
                  height: 52,
                  child: _pad(_PhoneFilterBar(registerId: _id)),
                ),
              ),
              _box(_FilteredTotals(registerId: _id), top: 0),
            ],
            ...switch (records) {
              AsyncValue(:final value?, hasValue: true) => _recordSlivers(
                value,
                wide,
              ),
              AsyncError(:final error) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorState(
                    message: errorMessage(context, error),
                    onRetry: () =>
                        ref.invalidate(recordsControllerProvider(_id)),
                  ),
                ),
              ],
              _ => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
            },
            const SliverToBoxAdapter(child: SizedBox(height: 104)),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        _panelRoom = wide && constraints.maxWidth >= 1000;
        final inspected = _panelRoom ? _inspected : null;
        if (inspected == null) return list;
        // The latest copy, so settlements show up in the panel.
        final current =
            records.value?.items
                .where((r) => r.id == inspected.id)
                .firstOrNull ??
            inspected;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: list),
            _RecordPanel(
              record: current,
              canSettle: _settleType(current) != null,
              onSettle: () => _settle(current),
              onClose: () => setState(() => _inspected = null),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _recordSlivers(RecordsPage page, bool wide) {
    final query = ref.watch(recordQueryProvider(_id));
    if (page.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: query.isDefault
              ? EmptyState(
                  icon: LucideIcons.receiptText,
                  title: context.l10n.noRecords,
                  message: (widget.perms?.canAddRecords ?? false)
                      ? context.l10n.noRecordsCanAdd
                      : context.l10n.noRecordsViewOnly,
                )
              : EmptyState(
                  icon: LucideIcons.filterX,
                  title: context.l10n.noMatchingRecords,
                  action: OutlinedButton(
                    onPressed: () =>
                        ref.read(recordQueryProvider(_id).notifier).reset(),
                    child: Text(context.l10n.clearFilters),
                  ),
                ),
        ),
      ];
    }

    // One card per day; one card in all when sorted by amount.
    final byAmount = query.sort == RecordSort.amount;
    final days = <List<CashRecord>>[];
    for (final record in page.items) {
      if (days.isEmpty ||
          (!byAmount &&
              !Dates.sameDay(days.last.first.createdAt, record.createdAt))) {
        days.add([record]);
      } else {
        days.last.add(record);
      }
    }
    // Each day's title sticks to the top while its records scroll by.
    final headerHeight = 28 + MediaQuery.textScalerOf(context).scale(18);
    return [
      for (final day in days)
        SliverMainAxisGroup(
          slivers: [
            if (byAmount)
              const SliverToBoxAdapter(child: SizedBox(height: 12))
            else
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedBar(
                  height: headerHeight,
                  border: false,
                  child: _pad(DayHeader(day.first.createdAt, records: day)),
                ),
              ),
            SliverToBoxAdapter(
              child: _pad(
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var j = 0; j < day.length; j++) ...[
                        if (j > 0) Divider(indent: wide ? 16 : 64),
                        if (wide)
                          RecordRow(
                            record: day[j],
                            onTap: () => _openRecord(day[j]),
                            onMenu: (at) => _recordMenu(day[j], at),
                            selected: _panelRoom && day[j].id == _inspected?.id,
                          )
                        else
                          RecordTile(
                            record: day[j],
                            onTap: () => _openRecord(day[j]),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      if (page.hasMore || page.loadMoreError != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: page.loadMoreError != null
                  ? TextButton.icon(
                      onPressed: () => ref
                          .read(recordsControllerProvider(_id).notifier)
                          .loadMore(),
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      label: Text(context.l10n.loadMoreFailed),
                    )
                  : const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
            ),
          ),
        ),
    ];
  }

  /// Phones: centred column. Desktop: wide content with page margins.
  double get _maxWidth => isWide(context) ? 1120 : 760;
  EdgeInsets get _sides => isWide(context)
      ? const EdgeInsets.symmetric(horizontal: 28)
      : const EdgeInsets.symmetric(horizontal: 16);

  Widget _pad(Widget child) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: _maxWidth),
      child: Padding(padding: _sides, child: child),
    ),
  );

  Widget _box(Widget child, {double top = 8}) => SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.only(top: top),
      child: _pad(child),
    ),
  );
}

/// Desktop side panel with the selected record; Esc or × closes it.
class _RecordPanel extends StatelessWidget {
  const _RecordPanel({
    required this.record,
    required this.canSettle,
    required this.onSettle,
    required this.onClose,
  });

  final CashRecord record;
  final bool canSettle;
  final VoidCallback onSettle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return KeyboardShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
      child: Container(
        width: 380,
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(left: BorderSide(color: p.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: onClose,
                ),
              ),
            ),
            Expanded(
              child: RecordDetailsSheet(
                key: ValueKey(record.id),
                record: record,
                canSettle: canSettle,
                onSettle: onSettle,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final RegisterStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = status.color(context);
    final background = status == RegisterStatus.checked
        ? p.warningSoft
        : p.surfaceMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(status.icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status.rule(context.l10n),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessNote extends StatelessWidget {
  const _AccessNote({required this.perms});

  final RegisterPermissions perms;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Icon(
          perms.canModify ? LucideIcons.pencil : LucideIcons.eye,
          size: 16,
          color: p.textSubtle,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            perms.canModify
                ? context.l10n.youCanModify
                : context.l10n.youCanView,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: p.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Phone: the register's frequent actions as a row under the balance.
class _PhoneActions extends StatelessWidget {
  const _PhoneActions({required this.perms, required this.commands});

  final RegisterPermissions perms;
  final _Commands commands;

  @override
  Widget build(BuildContext context) {
    if (!perms.isManager) return _AccessNote(perms: perms);

    final l = context.l10n;
    final register = commands.register;
    final unsettled = register.difference != 0;
    final count = commands.detail.members.length;
    final buttons = [
      _ActionButton(
        icon: LucideIcons.users,
        label: count == 0 ? l.giveAccess : l.membersCount('$count'),
        onPressed: commands.editAccess,
      ),
      if (perms.canCheck)
        _ActionButton(
          icon: LucideIcons.clipboardCheck,
          label: l.check,
          onPressed: commands.check,
        ),
      if (perms.canClose)
        _ActionButton(
          icon: LucideIcons.lock,
          label: l.close,
          onPressed: unsettled ? null : commands.close,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < buttons.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: buttons[i]),
            ],
          ],
        ),
        if (perms.canClose && unsettled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l.settleBeforeClosing(Money.format(register.difference.abs())),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// One line, icon beside the label: these are occasional actions, so
  /// they take little room above the records.
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(40),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
    ),
    onPressed: onPressed,
    icon: Icon(icon, size: 16),
    label: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

class _RecordsToolbar extends ConsumerStatefulWidget {
  const _RecordsToolbar({required this.registerId});

  final String registerId;

  @override
  ConsumerState<_RecordsToolbar> createState() => _RecordsToolbarState();
}

class _RecordsToolbarState extends ConsumerState<_RecordsToolbar> {
  late final _search = TextEditingController(
    text: ref.read(recordQueryProvider(widget.registerId)).search,
  );
  final _searchFocus = FocusNode();
  Timer? _debounce;

  /// Phones: the search field shows after tapping the search icon.
  late bool _searchOpen = _search.text.isNotEmpty;

  RecordQueryNotifier get _query =>
      ref.read(recordQueryProvider(widget.registerId).notifier);

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _query.update((q) => q.copyWith(search: value)),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(recordQueryProvider(widget.registerId));
    // Clear the field when filters are reset from elsewhere.
    if (query.search.isEmpty && _search.text.isNotEmpty && _debounce == null) {
      _search.clear();
    }
    final wide = isWide(context);

    final searchField = TextField(
      controller: _search,
      focusNode: _searchFocus,
      onChanged: _onSearch,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: wide
            ? '${context.l10n.searchRecords} (${shortcutLabel('F')})'
            : context.l10n.searchRecords,
        prefixIcon: const Icon(LucideIcons.search, size: 18),
        isDense: true,
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.l10n.clear,
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () {
                  _search.clear();
                  _debounce?.cancel();
                  _debounce = null;
                  _query.update((q) => q.copyWith(search: ''));
                  setState(() => _searchOpen = wide);
                },
              ),
      ),
    );
    final filters = _recordFilters(context, ref, widget.registerId);

    final title = Text(
      context.l10n.records,
      style: Theme.of(context).textTheme.titleLarge,
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: title),
              if (!_searchOpen)
                IconButton(
                  tooltip: context.l10n.searchRecords,
                  icon: const Icon(LucideIcons.search),
                  onPressed: () {
                    setState(() => _searchOpen = true);
                    _searchFocus.requestFocus();
                  },
                ),
            ],
          ),
          if (_searchOpen) ...[const SizedBox(height: 8), searchField],
        ],
      );
    }
    final stacked = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title,
        const SizedBox(height: 10),
        searchField,
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: filters),
      ],
    );
    return KeyboardShortcuts(
      bindings: {cmd(LogicalKeyboardKey.keyF): _searchFocus.requestFocus},
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 760
            ? stacked
            : Row(
                children: [
                  title,
                  const SizedBox(width: 20),
                  // Wraps to a second line instead of overflowing.
                  Expanded(
                    child: Wrap(spacing: 8, runSpacing: 6, children: filters),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(width: 260, child: searchField),
                ],
              ),
      ),
    );
  }
}

/// The record filters of a register, as chips.
List<Widget> _recordFilters(
  BuildContext context,
  WidgetRef ref,
  String registerId,
) {
  final query = ref.watch(recordQueryProvider(registerId));
  final notifier = ref.read(recordQueryProvider(registerId).notifier);
  return [
    RecordTypeFilter(
      selected: query.type,
      onChanged: (type) => notifier.update((q) => q.copyWith(type: () => type)),
    ),
    RecordPeriodFilter(
      selected: query.period,
      onChanged: (period) =>
          notifier.update((q) => q.copyWith(period: () => period)),
    ),
    RecordMemberFilter(
      selected: query.memberId,
      onChanged: (id) => notifier.update((q) => q.copyWith(memberId: () => id)),
    ),
    FilterChip(
      avatar: Icon(
        LucideIcons.circleDashed,
        size: 15,
        color: query.onlyUnsettled ? context.palette.brand : null,
      ),
      label: Text(context.l10n.unsettledOnly),
      selected: query.onlyUnsettled,
      onSelected: (v) => notifier.update((q) => q.copyWith(onlyUnsettled: v)),
    ),
  ];
}

/// Phones: the filters in one sideways-scrolling row.
class _PhoneFilterBar extends ConsumerWidget {
  const _PhoneFilterBar({required this.registerId});

  final String registerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = _recordFilters(context, ref, registerId);
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filters.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) => filters[i],
    );
  }
}

/// A fixed-height bar that stays at the top of the scroll view, with the
/// page colour behind it and a hairline once content slides underneath.
class _PinnedBar extends SliverPersistentHeaderDelegate {
  const _PinnedBar({
    required this.height,
    required this.child,
    this.border = true,
  });

  final double height;
  final Widget child;
  final bool border;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.canvas,
        border: border && overlaps
            ? Border(bottom: BorderSide(color: p.border))
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_PinnedBar old) =>
      old.height != height || old.child != child || old.border != border;
}

/// Phone register page: the app bar and the add button follow the scroll
/// of the records below them.
class _ScrollChrome extends InheritedWidget {
  const _ScrollChrome({
    required this.collapsed,
    required this.fabExtended,
    required super.child,
  });

  /// The balance card has scrolled out of view.
  final ValueNotifier<bool> collapsed;
  final ValueNotifier<bool> fabExtended;

  static _ScrollChrome? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ScrollChrome>();

  @override
  bool updateShouldNotify(_ScrollChrome old) => false;
}

class _PhoneChrome extends StatefulWidget {
  const _PhoneChrome({required this.builder});

  final Widget Function(
    ValueNotifier<bool> collapsed,
    ValueNotifier<bool> fabExtended,
  )
  builder;

  @override
  State<_PhoneChrome> createState() => _PhoneChromeState();
}

class _PhoneChromeState extends State<_PhoneChrome> {
  final _collapsed = ValueNotifier(false);
  final _fabExtended = ValueNotifier(true);

  @override
  void dispose() {
    _collapsed.dispose();
    _fabExtended.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ScrollChrome(
    collapsed: _collapsed,
    fabExtended: _fabExtended,
    child: widget.builder(_collapsed, _fabExtended),
  );
}

/// Column titles above the desktop records table. "Wagt" and "Mukdar"
/// sort the list; clicking the active one flips the direction.
class _TableHeader extends ConsumerWidget {
  const _TableHeader({required this.registerId});

  final String registerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final query = ref.watch(recordQueryProvider(registerId));
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: p.textSubtle);

    Widget sortable(RecordSort sort, String label, {bool end = false}) {
      final on = query.sort == sort;
      final arrow = Icon(
        query.ascending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
        size: 13,
        color: on ? p.brand : Colors.transparent,
      );
      return Tooltip(
        message: l.sortBy(label),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => ref
              .read(recordQueryProvider(registerId).notifier)
              .update(
                (q) => on
                    ? q.copyWith(ascending: !q.ascending)
                    : q.copyWith(sort: sort, ascending: false),
              ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: end
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (end) ...[arrow, const SizedBox(width: 4)],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: on ? style?.copyWith(color: p.text) : style,
                  ),
                ),
                if (!end) ...[const SizedBox(width: 4), arrow],
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(flex: 5, child: Text(l.colRecord, style: style)),
          Expanded(flex: 2, child: Text(l.colMember, style: style)),
          SizedBox(width: 64, child: sortable(RecordSort.time, l.colTime)),
          SizedBox(
            width: 150,
            child: sortable(RecordSort.amount, l.colAmount, end: true),
          ),
        ],
      ),
    );
  }
}

/// While filters are on: how many records match and the cash in and out.
class _FilteredTotals extends ConsumerWidget {
  const _FilteredTotals({required this.registerId});

  final String registerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(recordQueryProvider(registerId)).isDefault) {
      return const SizedBox.shrink();
    }
    final totals = ref.watch(recordTotalsProvider(registerId)).value;
    if (totals == null) return const SizedBox.shrink();
    final l = context.l10n;
    final p = context.palette;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: p.textMuted,
      fontWeight: FontWeight.w600,
      fontFeatures: tabularFigures,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 4),
      child: Wrap(
        spacing: 14,
        children: [
          Text(l.dayRecordCount('${totals.count}'), style: style),
          if (totals.moneyIn > 0)
            Text(
              l.totalsIn(Money.signed(totals.moneyIn)),
              style: style?.copyWith(color: p.positive),
            ),
          if (totals.moneyOut > 0)
            Text(
              l.totalsOut(Money.signed(-totals.moneyOut)),
              style: style?.copyWith(color: p.negative),
            ),
        ],
      ),
    );
  }
}
