import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/offline/offline_providers.dart';
import '../../../l10n/l10n.dart';
import '../../records/application/records_controller.dart';
import '../../records/domain/cash_record.dart';
import '../../records/domain/record_type.dart';
import '../../records/presentation/add_record_sheet.dart';
import '../../records/presentation/record_details_sheet.dart';
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
      return Scaffold(
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
                        onPressed: () => _addRecord(context, register),
                      ),
                  ],
                ),
              ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !embedded,
        title: Text(register?.name ?? ''),
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
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _addRecord(context, register),
              icon: const Icon(LucideIcons.plus),
              label: Text(context.l10n.addRecord),
            )
          : null,
      body: body,
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
    return [
      ToolbarIconButton(
        icon: LucideIcons.refreshCw,
        tooltip: l.refresh,
        onPressed: commands.refresh,
      ),
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

Future<void> _addRecord(
  BuildContext context,
  CashRegister register, {
  RecordType? type,
  CashRecord? parent,
}) async {
  final saved = await showAdaptiveSheet<bool>(
    context,
    builder: (_) =>
        AddRecordSheet(register: register, type: type, parent: parent),
  );
  if (saved == true && context.mounted) {
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

  bool _onScroll(ScrollNotification n) {
    // Load the next page a little before the end is reached.
    if (n.metrics.extentAfter < 600) {
      ref.read(recordsControllerProvider(_id).notifier).loadMore();
    }
    return false;
  }

  Future<void> _refresh() => ref.read(syncControllerProvider).refresh();

  void _openRecord(CashRecord record) async {
    final register = widget.detail.register;
    final settleType = record.type.settledBy;
    final canSettle =
        (widget.perms?.canAddRecords ?? false) &&
        settleType != null &&
        record.remaining > 0 &&
        settleType.allowedIn(register.status);

    final settle = await showAdaptiveSheet<bool>(
      context,
      builder: (_) => RecordDetailsSheet(record: record, canSettle: canSettle),
    );
    if (settle == true && mounted) {
      await _addRecord(context, register, type: settleType, parent: record);
    }
  }

  @override
  Widget build(BuildContext context) {
    final register = widget.detail.register;
    final records = ref.watch(recordsControllerProvider(_id));
    final wide = isWide(context);
    final perms = widget.perms;

    return RefreshIndicator(
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
                  const SizedBox(height: 24),
                  _RecordsToolbar(registerId: _id),
                  if (wide) const _TableHeader(),
                ],
              ),
              top: wide ? 0 : 8,
            ),
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

    // One card per day.
    final days = <List<CashRecord>>[];
    for (final record in page.items) {
      if (days.isEmpty ||
          !Dates.sameDay(days.last.first.createdAt, record.createdAt)) {
        days.add([record]);
      } else {
        days.last.add(record);
      }
    }
    return [
      SliverList.builder(
        itemCount: days.length,
        itemBuilder: (context, i) {
          final day = days[i];
          return _pad(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DayHeader(day.first.createdAt, records: day),
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
              ],
            ),
          );
        },
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

  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    ),
    onPressed: onPressed,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ],
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
  Timer? _debounce;

  RecordQueryNotifier get _query =>
      ref.read(recordQueryProvider(widget.registerId).notifier);

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
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
      onChanged: _onSearch,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.l10n.searchRecords,
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
                  setState(() {});
                },
              ),
      ),
    );
    final filters = [
      _TypeFilter(
        selected: query.type,
        onChanged: (type) => _query.update((q) => q.copyWith(type: () => type)),
      ),
      FilterChip(
        avatar: Icon(
          LucideIcons.circleDashed,
          size: 15,
          color: query.onlyUnsettled ? context.palette.brand : null,
        ),
        label: Text(context.l10n.unsettledOnly),
        selected: query.onlyUnsettled,
        onSelected: (v) => _query.update((q) => q.copyWith(onlyUnsettled: v)),
      ),
    ];

    final title = Text(
      context.l10n.records,
      style: Theme.of(context).textTheme.titleLarge,
    );

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
    if (!wide) return stacked;
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 760
          ? stacked
          : Row(
              children: [
                title,
                const SizedBox(width: 20),
                for (final f in filters) ...[f, const SizedBox(width: 8)],
                const Spacer(),
                SizedBox(width: 300, child: searchField),
              ],
            ),
    );
  }
}

/// Column titles above the desktop records table.
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: context.palette.textSubtle);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(flex: 5, child: Text(l.colRecord, style: style)),
          Expanded(flex: 2, child: Text(l.colMember, style: style)),
          SizedBox(width: 64, child: Text(l.colTime, style: style)),
          SizedBox(
            width: 150,
            child: Text(l.colAmount, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _TypeFilter extends StatelessWidget {
  const _TypeFilter({required this.selected, required this.onChanged});

  final RecordType? selected;
  final ValueChanged<RecordType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      menuChildren: [
        MenuItemButton(
          onPressed: () => onChanged(null),
          leadingIcon: const Icon(LucideIcons.layers),
          child: Text(context.l10n.allTypes),
        ),
        for (final type in RecordType.values)
          MenuItemButton(
            onPressed: () => onChanged(type),
            leadingIcon: Icon(type.icon, color: recordTypeTint(context, type)),
            child: Text(type.label(context.l10n)),
          ),
      ],
      builder: (context, controller, _) => FilterChip(
        avatar: Icon(
          selected?.icon ?? LucideIcons.listFilter,
          size: 15,
          color: selected != null ? p.brand : null,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected?.label(context.l10n) ?? context.l10n.allTypes),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronDown, size: 14),
          ],
        ),
        selected: selected != null,
        onSelected: (_) =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
