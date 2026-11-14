import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/shortcuts.dart';
import '../../../core/offline/offline_providers.dart';
import '../../../l10n/l10n.dart';
import '../../auth/application/auth_controller.dart';
import '../application/registers_providers.dart';
import '../domain/cash_register.dart';
import '../domain/register_query.dart';
import '../../records/application/records_controller.dart';
import '../../records/domain/record_type.dart';
import '../../records/presentation/register_record_tiles.dart';
import 'overview_pane.dart';
import 'register_detail_page.dart';
import 'widgets/register_form_sheet.dart';
import 'widgets/register_widgets.dart';

/// Phone: the list. Wide: list pane on the left, selected register on the
/// right.
class RegistersScreen extends StatelessWidget {
  const RegistersScreen({super.key, this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    if (!isWide(context)) return const _PhoneList();

    final p = context.palette;
    // Not a Scaffold: the detail pane's Scaffold should own snackbars.
    return Material(
      color: p.canvas,
      child: Row(
        children: [
          Container(
            // Narrower next to the icon-only sidebar, so the register keeps
            // room for its table.
            width: MediaQuery.sizeOf(context).width >= 1100 ? 340 : 300,
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(right: BorderSide(color: p.border)),
            ),
            child: _ListPane(selectedId: selectedId),
          ),
          Expanded(
            child: selectedId == null
                ? const OverviewPane()
                : RegisterDetailPage(
                    key: ValueKey(selectedId),
                    registerId: selectedId!,
                    embedded: true,
                  ),
          ),
        ],
      ),
    );
  }
}

Future<void> createRegister(BuildContext context) async {
  final created = await showAdaptiveSheet<CashRegister>(
    context,
    builder: (_) => const RegisterFormSheet(),
  );
  if (created != null && context.mounted) {
    context.go('/registers/${created.id}');
  }
}

bool _isManager(WidgetRef ref) =>
    ref.watch(authControllerProvider).value?.isManager ?? false;

/// Right-click menu (desktop) or long-press sheet (phone) for a register.
void _openRegisterMenu(
  BuildContext context,
  WidgetRef ref,
  CashRegister register,
  Offset? at,
) {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final pin = !register.isPinned;

  Future<void> setPinned() async {
    try {
      await ref
          .read(registerActionsProvider)
          .setPinned(register.id, pinned: pin);
      messenger.showSnackBar(
        SnackBar(content: Text(pin ? l.registerPinned : l.registerUnpinned)),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(l, e))));
    }
  }

  showActionMenu(
    context,
    at: at,
    title: register.name,
    actions: [
      MenuAction(
        icon: LucideIcons.squareArrowOutUpRight,
        label: l.open,
        onSelected: () => context.go('/registers/${register.id}'),
      ),
      if (RecordType.values.any(
        (t) => t.creatable && t.allowedIn(register.status),
      ))
        MenuAction(
          icon: LucideIcons.plus,
          label: l.addRecord,
          onSelected: () => showAddRecord(context, register),
        ),
      MenuAction(
        icon: pin ? LucideIcons.pin : LucideIcons.pinOff,
        label: pin ? l.pin : l.unpin,
        onSelected: setPinned,
      ),
    ],
  );
}

// ─── Phone ────────────────────────────────────────────────────────────────

/// Adds a record without opening a register first: straight to the form
/// when the member can add to just one register, otherwise asks which.
Future<void> _quickAdd(BuildContext context, WidgetRef ref) async {
  final registers = await ref.read(addableRegistersProvider.future);
  if (!context.mounted || registers.isEmpty) return;
  final register = registers.length == 1
      ? registers.single
      : await showAdaptiveSheet<CashRegister>(
          context,
          builder: (context) => _PickRegisterSheet(registers: registers),
        );
  if (register != null && context.mounted) {
    await showAddRecord(context, register);
  }
}

class _PickRegisterSheet extends StatelessWidget {
  const _PickRegisterSheet({required this.registers});

  final List<CashRegister> registers;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(
            context.l10n.pickRegister,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, r) in registers.indexed) ...[
                if (i > 0) const Divider(indent: 68),
                RegisterTile(
                  register: r,
                  onTap: () => Navigator.pop(context, r),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Overdue and soon-due obligations across registers; opens the list.
class _DueBanner extends ConsumerWidget {
  const _DueBanner();

  void _open(BuildContext context, DueObligations due) {
    final router = GoRouter.of(context);
    showAdaptiveSheet<void>(
      context,
      builder: (sheet) => SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                context.l10n.dueTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, e) in [
                    ...due.overdue,
                    ...due.soon,
                  ].indexed) ...[
                    if (i > 0) const Divider(indent: 62),
                    DueObligationTile(
                      entry: e,
                      onTap: () {
                        Navigator.pop(sheet);
                        router.go('/registers/${e.register.id}');
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(dueObligationsProvider).value;
    if (due == null || due.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final p = context.palette;
    final overdue = due.overdue.isNotEmpty;
    final color = overdue ? p.negative : p.warning;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: overdue ? p.negativeSoft : p.warningSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: .25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context, due),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  overdue ? LucideIcons.triangleAlert : LucideIcons.clock,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    [
                      if (overdue) l.overdueCount('${due.overdue.length}'),
                      if (due.soon.isNotEmpty)
                        l.dueSoonCount('${due.soon.length}'),
                    ].join(' · '),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 18, color: p.textSubtle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneList extends ConsumerWidget {
  const _PhoneList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isManager = _isManager(ref);
    final registers = ref.watch(registersProvider);
    final query = ref.watch(registerQueryProvider);
    final theme = Theme.of(context);
    final company = ref.watch(authControllerProvider).value?.companyName;
    final canQuickAdd =
        ref.watch(addableRegistersProvider).value?.isNotEmpty ?? false;
    // Tablets: the same column as the register page, centred.
    final width = MediaQuery.sizeOf(context).width;
    final side = width > 792 ? (width - 760) / 2 : 16.0;

    return Scaffold(
      // Managers create registers here; members add records, the thing
      // they do most, without opening a register first.
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
              onPressed: () => createRegister(context),
              icon: const Icon(LucideIcons.plus),
              label: Text(context.l10n.newRegister),
            )
          : canQuickAdd
          ? FloatingActionButton.extended(
              onPressed: () => _quickAdd(context, ref),
              icon: const Icon(LucideIcons.plus),
              label: Text(context.l10n.addRecord),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(syncControllerProvider).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side + 4, 12, side - 8, 4),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.registersTitle,
                              style: theme.textTheme.headlineMedium,
                            ),
                            if (company != null)
                              Text(company, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      _SortButton(query: query, outlined: false),
                    ],
                  ),
                ),
              ),
              if (registers.value case final list? when list.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 12, side, 4),
                  sliver: SliverToBoxAdapter(child: _Summary(registers: list)),
                ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: side),
                sliver: const SliverToBoxAdapter(child: _DueBanner()),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side, 12, side, 0),
                sliver: const SliverToBoxAdapter(child: _SearchField()),
              ),
              SliverToBoxAdapter(child: _FilterChips(side: side)),
              ...switch (registers) {
                AsyncValue(:final value?, hasValue: true) => [
                  if (value.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _Empty(
                        query: query,
                        isManager: isManager,
                        inSliver: true,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(side, 4, side, 104),
                      sliver: SliverToBoxAdapter(
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (var i = 0; i < value.length; i++) ...[
                                if (i > 0) const Divider(indent: 68),
                                RegisterTile(
                                  register: value[i],
                                  onTap: () =>
                                      context.go('/registers/${value[i].id}'),
                                  onMenu: isManager
                                      ? (at) => _openRegisterMenu(
                                          context,
                                          ref,
                                          value[i],
                                          at,
                                        )
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
                AsyncError(:final error) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorState(
                      message: errorMessage(context, error),
                      onRetry: () => ref.invalidate(registersProvider),
                    ),
                  ),
                ],
                _ => [
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.registers});

  final List<CashRegister> registers;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final total = registers.fold(0, (sum, r) => sum + r.currentAmount);
    final outstanding = registers.fold(0, (sum, r) => sum + r.difference);
    return MoneyHeroCard(
      label: l.totalCash,
      amount: total,
      footer: [
        HeroFigure(l.registersTitle, '${registers.length}'),
        HeroFigure(
          l.outstanding,
          outstanding == 0 ? l.none : Money.signed(outstanding),
          color: heroAmountColor(outstanding.sign),
          help: l.outstandingHelp,
        ),
      ],
    );
  }
}

// ─── Desktop ──────────────────────────────────────────────────────────────

class _ListPane extends ConsumerStatefulWidget {
  const _ListPane({this.selectedId});

  final String? selectedId;

  @override
  ConsumerState<_ListPane> createState() => _ListPaneState();
}

class _ListPaneState extends ConsumerState<_ListPane> {
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  /// ↑/↓: open the previous or next register in the list.
  void _move(int by) {
    final list = ref.read(registersProvider).value;
    if (list == null || list.isEmpty) return;
    final at = list.indexWhere((r) => r.id == widget.selectedId);
    final next = at < 0 ? 0 : (at + by).clamp(0, list.length - 1);
    if (next != at) context.go('/registers/${list[next].id}');
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = widget.selectedId;
    final query = ref.watch(registerQueryProvider);
    final registers = ref.watch(registersProvider);
    final isManager = _isManager(ref);
    final theme = Theme.of(context);
    final p = context.palette;
    final count = registers.value?.length;
    void search() => _searchFocus.requestFocus();

    return KeyboardShortcuts(
      textField: _searchFocus,
      bindings: {
        cmd(LogicalKeyboardKey.keyK): search,
        cmd(LogicalKeyboardKey.keyF): search,
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
        if (isManager)
          cmd(LogicalKeyboardKey.keyN, shift: true): () =>
              createRegister(context),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          context.l10n.registersTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      // The narrow pane has no room; the summary card
                      // shows the count too.
                      if (count != null &&
                          MediaQuery.sizeOf(context).width >= 1100) ...[
                        const SizedBox(width: 8),
                        Pill(label: '$count', color: p.textMuted),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _FilterButton(query: query),
                const SizedBox(width: 8),
                _SortButton(query: query),
                if (isManager) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message:
                        '${context.l10n.newRegister} '
                        '(${shortcutLabel('N', shift: true)})',
                    child: SizedBox.square(
                      dimension: 40,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                        onPressed: () => createRegister(context),
                        child: const Icon(LucideIcons.plus, size: 18),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (registers.value case final list? when list.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _Summary(registers: list),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _SearchField(
              focusNode: _searchFocus,
              hint: '${context.l10n.searchRegisters} (${shortcutLabel('K')})',
            ),
          ),
          Divider(height: 1, color: p.border),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(syncControllerProvider).refresh(),
              child: AsyncValueView(
                value: registers,
                onRetry: () => ref.invalidate(registersProvider),
                data: (list) => list.isEmpty
                    ? _Empty(query: query, isManager: isManager)
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 2),
                        itemBuilder: (context, i) => RegisterTile(
                          dense: true,
                          register: list[i],
                          selected: list[i].id == selectedId,
                          onTap: () => context.go('/registers/${list[i].id}'),
                          onMenu: isManager
                              ? (at) =>
                                    _openRegisterMenu(context, ref, list[i], at)
                              : null,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared parts ─────────────────────────────────────────────────────────

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField({this.focusNode, this.hint});

  final FocusNode? focusNode;
  final String? hint;

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final _search = TextEditingController(
    text: ref.read(registerQueryProvider).search,
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _set(String value) => ref
      .read(registerQueryProvider.notifier)
      .update((q) => q.copyWith(search: value));

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _set(value));
    setState(() {}); // Toggle the clear button.
  }

  void _clear() {
    _search.clear();
    _debounce?.cancel();
    _set('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _search,
      focusNode: widget.focusNode,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint ?? context.l10n.searchRegisters,
        prefixIcon: const Icon(LucideIcons.search, size: 18),
        isDense: true,
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.l10n.clear,
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: _clear,
              ),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({this.side = 16});

  final double side;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(registerQueryProvider);
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: side, vertical: 10),
        children: [
          for (final filter in RegisterFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(filter.label(context.l10n)),
                selected: query.filter == filter,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => ref
                    .read(registerQueryProvider.notifier)
                    .update((q) => q.copyWith(filter: filter)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty({
    required this.query,
    required this.isManager,
    this.inSliver = false,
  });

  final RegisterQuery query;
  final bool isManager;

  /// Inside a sliver list the outer scroll view already scrolls.
  final bool inSliver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered =
        query.search.isNotEmpty || query.filter != RegisterFilter.all;
    final sync = ref.watch(syncStatusProvider);
    final content = !sync.hasData
        // Never downloaded on this device: "no registers" would be wrong.
        ? EmptyState(
            icon: sync.isOffline
                ? LucideIcons.cloudOff
                : LucideIcons.cloudDownload,
            title: context.l10n.noDataOffline,
            message: context.l10n.noDataOfflineHint,
          )
        : filtered
        ? EmptyState(
            icon: LucideIcons.searchX,
            title: context.l10n.noMatchingRegisters,
            message: context.l10n.tryAnotherSearch,
          )
        : EmptyState(
            icon: LucideIcons.wallet,
            title: context.l10n.noRegisters,
            message: isManager
                ? context.l10n.noRegistersManager
                : context.l10n.noRegistersMember,
            action: isManager
                ? FilledButton.icon(
                    onPressed: () => createRegister(context),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: Text(context.l10n.newRegister),
                  )
                : null,
          );
    if (inSliver) return content;
    // Scrollable so pull-to-refresh still works on an empty list.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 0,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Desktop: the status filter as a menu, so a narrow pane never clips it.
class _FilterButton extends ConsumerWidget {
  const _FilterButton({required this.query});

  final RegisterQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final active = query.filter != RegisterFilter.all;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      menuChildren: [
        for (final filter in RegisterFilter.values)
          MenuItemButton(
            leadingIcon: Icon(
              LucideIcons.check,
              size: 16,
              color: query.filter == filter ? p.brand : Colors.transparent,
            ),
            onPressed: () => ref
                .read(registerQueryProvider.notifier)
                .update((q) => q.copyWith(filter: filter)),
            child: Text(filter.label(l)),
          ),
      ],
      builder: (context, controller, _) => ToolbarIconButton(
        icon: LucideIcons.listFilter,
        tooltip: active ? query.filter.label(l) : l.statusFilter,
        active: active,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _SortButton extends ConsumerWidget {
  const _SortButton({required this.query, this.outlined = true});

  final RegisterQuery query;
  final bool outlined;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    void set(RegisterQuery Function(RegisterQuery) change) =>
        ref.read(registerQueryProvider.notifier).update(change);

    Widget check(bool on) => Icon(
      LucideIcons.check,
      size: 16,
      color: on ? p.brand : Colors.transparent,
    );

    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      menuChildren: [
        for (final sort in RegisterSort.values)
          MenuItemButton(
            leadingIcon: check(query.sort == sort),
            onPressed: () => set((q) => q.copyWith(sort: sort)),
            child: Text(sort.label(context.l10n)),
          ),
        const Divider(),
        MenuItemButton(
          leadingIcon: check(query.descending),
          onPressed: () => set((q) => q.copyWith(descending: true)),
          child: Text(context.l10n.sortDescending),
        ),
        MenuItemButton(
          leadingIcon: check(!query.descending),
          onPressed: () => set((q) => q.copyWith(descending: false)),
          child: Text(context.l10n.sortAscending),
        ),
      ],
      builder: (context, controller, _) {
        void toggle() =>
            controller.isOpen ? controller.close() : controller.open();
        return outlined
            ? ToolbarIconButton(
                icon: LucideIcons.arrowUpDown,
                tooltip: context.l10n.sort,
                onPressed: toggle,
              )
            : IconButton(
                tooltip: context.l10n.sort,
                icon: const Icon(LucideIcons.arrowUpDown),
                onPressed: toggle,
              );
      },
    );
  }
}
