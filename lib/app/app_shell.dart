import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/app_logo.dart';
import '../core/widgets/common.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/sync/sync_widgets.dart';
import '../l10n/l10n.dart';

typedef _Destination = ({IconData icon, String label});

/// Bottom navigation on phones; a sidebar on wide screens (full with labels
/// from [_fullSidebarWidth], icons only below that).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _fullSidebarWidth = 1100.0;

  static List<_Destination> _destinations(AppLocalizations l) => [
    (icon: LucideIcons.wallet, label: l.navRegisters),
    (icon: LucideIcons.users, label: l.navMembers),
    (icon: LucideIcons.circleUser, label: l.navAccount),
  ];

  /// Snackbars shown from a page appear inside that page's Scaffold (not the
  /// shell's), so its floating action button moves up instead of being
  /// covered.
  Widget get _content => ScaffoldMessenger(child: shell);

  void _go(int index) =>
      // Tapping the current tab again returns to its first page.
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final destinations = _destinations(context.l10n);

    if (!isWide(context)) {
      return Scaffold(
        body: Column(
          children: [
            const SyncBanner(),
            Expanded(child: _content),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: p.border)),
          ),
          child: NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _go,
            destinations: [
              for (final d in destinations)
                NavigationDestination(icon: Icon(d.icon), label: d.label),
            ],
          ),
        ),
      );
    }

    final full = MediaQuery.sizeOf(context).width >= _fullSidebarWidth;
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            full: full,
            destinations: destinations,
            selected: shell.currentIndex,
            onSelect: _go,
          ),
          VerticalDivider(width: 1, color: p.border),
          Expanded(child: _content),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.full,
    required this.destinations,
    required this.selected,
    required this.onSelect,
  });

  final bool full;
  final List<_Destination> destinations;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).value;

    return Container(
      width: full ? 248 : 76,
      color: p.sidebar,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                full ? 20 : 0,
                20,
                full ? 16 : 0,
                20,
              ),
              child: Row(
                mainAxisAlignment: full
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  const AppLogo(size: 34),
                  if (full) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.appName,
                            style: theme.textTheme.titleMedium,
                          ),
                          if (session != null)
                            Text(
                              session.companyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            for (var i = 0; i < destinations.length; i++)
              _NavItem(
                destination: destinations[i],
                selected: i == selected,
                full: full,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: full ? 12 : 0),
              child: full
                  ? const SyncIndicator()
                  : const Center(child: SyncIndicator(compact: true)),
            ),
            if (session != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  full ? 12 : 0,
                  8,
                  full ? 12 : 0,
                  16,
                ),
                child: _UserCard(
                  full: full,
                  name: session.fullName,
                  role: session.isManager
                      ? context.l10n.roleManager
                      : context.l10n.roleMember,
                  initials: _initials(session.fullName),
                  // The account page is the last destination.
                  onTap: () => onSelect(destinations.length - 1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    return parts.take(2).map((s) => s[0].toUpperCase()).join();
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.full,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final bool full;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.text : p.textMuted;
    final item = Padding(
      padding: EdgeInsets.symmetric(horizontal: full ? 12 : 14, vertical: 2),
      child: Material(
        color: selected ? p.surfaceMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: full
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                if (full) const SizedBox(width: 12),
                Icon(
                  destination.icon,
                  size: 19,
                  color: selected ? p.brand : p.textSubtle,
                ),
                if (full) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      destination.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    final semantic = Semantics(
      selected: selected,
      button: true,
      label: full ? null : destination.label,
      child: item,
    );
    return full
        ? semantic
        : Tooltip(message: destination.label, child: semantic);
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.full,
    required this.name,
    required this.role,
    required this.initials,
    required this.onTap,
  });

  final bool full;
  final String name;
  final String role;
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    final avatar = Avatar(initials: initials, size: 34);
    if (!full) {
      return Center(
        child: Tooltip(
          message: name,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: avatar,
          ),
        ),
      );
    }
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: p.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(role, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronsUpDown, size: 16, color: p.textSubtle),
            ],
          ),
        ),
      ),
    );
  }
}
