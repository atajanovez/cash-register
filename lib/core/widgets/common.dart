import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Width at which screens switch from stacked (phone) to side-by-side.
const wideBreakpoint = 900.0;

bool isWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= wideBreakpoint;

/// Green for money in, red for money out, muted for no cash effect.
Color amountColor(BuildContext context, int sign) {
  final p = context.palette;
  return sign > 0
      ? p.positive
      : sign < 0
      ? p.negative
      : p.textMuted;
}

String errorMessage(BuildContext context, Object error) =>
    describeError(context.l10n, error);

void showErrorSnack(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(errorMessage(context, error))));
}

void showInfoSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Loading spinner, error with retry, or [data].
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncValue(:final value?, hasValue: true) => data(value),
      AsyncError(:final error) => ErrorState(
        message: errorMessage(context, error),
        onRetry: onRetry,
      ),
      _ => const Center(
        child: SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    };
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: LucideIcons.cloudOff,
      title: context.l10n.couldNotLoad,
      message: message,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(context.l10n.retry),
            ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 24, color: p.textMuted),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: p.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded label, e.g. a status or role. Wraps to a second line
/// rather than cutting off longer text.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.background,
  });

  final String label;
  final Color color;
  final IconData? icon;

  /// Defaults to a light tint of [color].
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: dark ? .16 : .10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.muted = false,
  });

  final String initials;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: muted ? p.surfaceMuted : p.brandSoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          color: muted ? p.textSubtle : p.brand,
        ),
      ),
    );
  }
}

/// Bottom sheet on phones, dialog on wide screens. Content scrolls and stays
/// above the keyboard.
Future<T?> showAdaptiveSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double maxWidth = 500,
}) {
  if (isWide(context)) {
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 720),
          child: builder(context),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    // Cover the bottom navigation bar instead of opening behind it.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: builder(context),
    ),
  );
}

/// Yes/no question. [destructive] colors the confirm button red.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final p = context.palette;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Text(message),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? p.negative : null,
            foregroundColor: destructive ? Colors.white : null,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(
              color: context.palette.textMuted,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// One entry in [showActionMenu].
class MenuAction {
  const MenuAction({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
  final bool destructive;
}

/// Context actions for an item. With a mouse ([at] is the pointer position)
/// a compact menu opens right at the cursor; on touch a bottom sheet lists
/// the actions with large rows, as phones do.
Future<void> showActionMenu(
  BuildContext context, {
  required List<MenuAction> actions,
  String? title,
  Offset? at,
}) async {
  final p = context.palette;
  if (at != null) {
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    // The menu is placed in the navigator's overlay, which may not start at
    // the window's top-left (e.g. next to the sidebar).
    final local = overlay.globalToLocal(at);
    final chosen = await showMenu<MenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        local & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        for (final a in actions)
          PopupMenuItem(
            value: a,
            height: 40,
            child: Row(
              children: [
                Icon(
                  a.icon,
                  size: 18,
                  color: a.destructive ? p.negative : p.textMuted,
                ),
                const SizedBox(width: 12),
                Text(
                  a.label,
                  style: TextStyle(color: a.destructive ? p.negative : null),
                ),
              ],
            ),
          ),
      ],
    );
    chosen?.onSelected();
    return;
  }

  final chosen = await showModalBottomSheet<MenuAction>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            for (final a in actions)
              ListTile(
                leading: Icon(
                  a.icon,
                  color: a.destructive ? p.negative : p.textMuted,
                ),
                title: Text(
                  a.label,
                  style: TextStyle(color: a.destructive ? p.negative : null),
                ),
                onTap: () => Navigator.pop(context, a),
              ),
          ],
        ),
      ),
    ),
  );
  chosen?.onSelected();
}

/// Title row at the top of a desktop page: title (and optional subtitle or
/// badge) on the left, actions on the right, as in desktop finance apps.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.actions = const [],
    this.leading,
    this.padding = const EdgeInsets.fromLTRB(28, 22, 24, 18),
  });

  final String title;
  final String? subtitle;
  final Widget? badge;
  final List<Widget> actions;
  final Widget? leading;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[const SizedBox(width: 10), badge!],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.palette.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            actions[i],
          ],
        ],
      ),
    );
  }
}

/// Figure with a small label above it, e.g. a balance.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.help,
    this.icon,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final String? help;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final tile = Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: p.textSubtle),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: p.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (help != null) ...[
                const SizedBox(width: 4),
                Icon(LucideIcons.info, size: 13, color: p.textSubtle),
              ],
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: valueColor ?? p.text,
                fontFeatures: tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
    return help == null ? tile : Tooltip(message: help!, child: tile);
  }
}

/// A page's main action in the app bar. Wide screens use this instead of a
/// floating button, which would sit over the content far from everything else.
class AppBarPrimaryAction extends StatelessWidget {
  const AppBarPrimaryAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// E.g. the keyboard shortcut.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Square outlined icon button with a tooltip, for toolbars.
class ToolbarIconButton extends StatelessWidget {
  const ToolbarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Tinted, for a filter that is on.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Same height as the themed text buttons beside it.
    final height = Theme.of(
      context,
    ).outlinedButtonTheme.style?.minimumSize?.resolve(const {})?.height;
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: height ?? 40,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            foregroundColor: active ? p.brand : p.textMuted,
            backgroundColor: active ? p.brandSoft : null,
            side: active
                ? BorderSide(color: p.brand.withValues(alpha: .4))
                : null,
          ),
          onPressed: onPressed,
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}
