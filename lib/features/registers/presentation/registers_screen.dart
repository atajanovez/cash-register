import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/offline/offline_providers.dart';
import '../../../l10n/l10n.dart';
import '../../auth/application/auth_controller.dart';
import '../application/registers_providers.dart';
import '../domain/cash_register.dart';
import '../domain/register_query.dart';
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
            width: 340,
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(right: BorderSide(color: p.border)),
            ),
            child: _ListPane(selectedId: selectedId),
          ),
          Expanded(
            child: selectedId == null
                ? EmptyState(
                    icon: LucideIcons.mousePointerClick,
                    title: context.l10n.selectRegister,
                    message: context.l10n.selectRegisterHint,
                  )
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
      MenuAction(
        icon: pin ? LucideIcons.pin : LucideIcons.pinOff,
        label: pin ? l.pin : l.unpin,
        onSelected: setPinned,
      ),
    ],
  );
}

// ─── Phone ────────────────────────────────────────────────────────────────

class _PhoneList extends ConsumerWidget {
  const _PhoneList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isManager = _isManager(ref);
    final registers = ref.watch(registersProvider);
    final query = ref.watch(registerQueryProvider);
    final theme = Theme.of(context);
    final company = ref.watch(authControllerProvider).value?.companyName;

    return Scaffold(
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
              onPressed: () => createRegister(context),
              icon: const Icon(LucideIcons.plus),
              label: Text(context.l10n.newRegister),
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
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  sliver: SliverToBoxAdapter(child: _Summary(registers: list)),
                ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(child: _SearchField()),
              ),
              const SliverToBoxAdapter(child: _FilterChips()),
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
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
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

class _ListPane extends ConsumerWidget {
  const _ListPane({this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(registerQueryProvider);
    final registers = ref.watch(registersProvider);
    final isManager = _isManager(ref);
    final theme = Theme.of(context);
    final p = context.palette;
    final count = registers.value?.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
          child: Row(
            children: [
              Text(
                context.l10n.registersTitle,
                style: theme.textTheme.titleLarge,
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Pill(label: '$count', color: p.textMuted),
              ],
              const Spacer(),
              _SortButton(query: query),
              if (isManager) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: context.l10n.newRegister,
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _SearchField(),
        ),
        const _FilterChips(),
        Divider(color: p.border),
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
    );
  }
}

// ─── Shared parts ─────────────────────────────────────────────────────────

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

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
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.l10n.searchRegisters,
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
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(registerQueryProvider);
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
