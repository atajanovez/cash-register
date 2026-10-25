import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/dates.dart';
import '../../core/offline/offline_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../core/widgets/common.dart';
import '../../l10n/l10n.dart';
import '../auth/application/auth_controller.dart';
import '../members/domain/member.dart';

/// Settings-style page: profile, company, appearance, log out.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final sync = ref.read(syncControllerProvider);
    final unsent = sync.unsentCount;
    final ok = await confirm(
      context,
      title: context.l10n.logOutTitle,
      message: unsent > 0
          ? context.l10n.logOutUnsent('$unsent')
          : context.l10n.logOutMessage,
      confirmLabel: context.l10n.logOut,
      destructive: true,
    );
    if (!ok) return;
    // Local data stays on a shared device otherwise.
    await sync.wipe();
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    if (session == null) return const SizedBox.shrink();
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = context.palette;
    final wide = isWide(context);
    final initials = Member(
      id: session.memberId,
      fullName: session.fullName,
      username: session.username,
      isActive: true,
    ).initials;

    final content = ListView(
      padding: EdgeInsets.fromLTRB(
        wide ? 28 : 16,
        wide ? 0 : 4,
        wide ? 28 : 16,
        32,
      ),
      children: [
        Align(
          alignment: wide ? Alignment.topLeft : Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Avatar(initials: initials, size: 56),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.displayName,
                                style: theme.textTheme.titleLarge,
                              ),
                              Text(
                                '@${session.username}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: p.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Pill(
                          label: session.isManager
                              ? l.roleManager
                              : l.roleMember,
                          icon: session.isManager
                              ? LucideIcons.shieldCheck
                              : LucideIcons.userRound,
                          color: session.isManager ? p.brand : p.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                _Section(l.company),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: LucideIcons.building2,
                        label: l.company,
                        value: session.companyName,
                      ),
                      if (session.expiresAt != null) ...[
                        const Divider(indent: 52),
                        _InfoRow(
                          icon: LucideIcons.clock,
                          label: l.sessionValidUntil,
                          value: Dates.date(session.expiresAt!),
                        ),
                      ],
                    ],
                  ),
                ),
                _Section(l.theme),
                const _ThemePicker(),
                const SizedBox(height: 28),
                Align(
                  alignment: wide ? Alignment.centerLeft : Alignment.center,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.negative,
                      side: BorderSide(color: p.negative.withValues(alpha: .4)),
                      minimumSize: wide ? null : const Size.fromHeight(48),
                    ),
                    onPressed: () => _logout(context, ref),
                    icon: const Icon(LucideIcons.logOut, size: 18),
                    label: Text(l.logOut),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (wide) {
      return Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(title: l.accountTitle),
            Expanded(child: content),
          ],
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Text(
                l.accountTitle,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
    child: SectionTitle(title),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: p.textSubtle),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: p.textMuted),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Three preview tiles: follow the device, light, dark.
class _ThemePicker extends ConsumerWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final mode = ref.watch(themeModeProvider);
    final options = [
      (ThemeMode.system, LucideIcons.sunMoon, l.themeSystem),
      (ThemeMode.light, LucideIcons.sun, l.themeLight),
      (ThemeMode.dark, LucideIcons.moon, l.themeDark),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _ThemeOption(
                  mode: options[i].$1,
                  icon: options[i].$2,
                  label: options[i].$3,
                  selected: mode == options[i].$1,
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).set(options[i].$1),
                ),
              ),
            ],
          ],
        ),
        if (mode == ThemeMode.system) ...[
          const SizedBox(height: 8),
          Text(l.themeSystemHint, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? p.brand : p.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                AspectRatio(aspectRatio: 2, child: _Preview(mode: mode)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 15,
                      color: selected ? p.brand : p.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: selected ? p.brand : p.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Miniature of the app in a theme; "system" shows both halves.
class _Preview extends StatelessWidget {
  const _Preview({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    // Drawn at a fixed size and scaled to the tile, so it never overflows.
    Widget mini(AppPalette c) => FittedBox(
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      child: Container(
        width: 120,
        height: 60,
        color: c.canvas,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 16,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c.heroStart, c.heroEnd]),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            for (var i = 0; i < 2; i++) ...[
              const SizedBox(height: 4),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: c.border, width: .5),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: switch (mode) {
        ThemeMode.light => mini(AppPalette.light),
        ThemeMode.dark => mini(AppPalette.dark),
        ThemeMode.system => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: mini(AppPalette.light)),
            Expanded(child: mini(AppPalette.dark)),
          ],
        ),
      },
    );
  }
}
