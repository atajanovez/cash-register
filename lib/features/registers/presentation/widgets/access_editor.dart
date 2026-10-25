import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../members/application/members_providers.dart';
import '../../../members/domain/member.dart';
import '../../application/registers_providers.dart';
import '../../domain/cash_register.dart';

/// Per-member access: a checkbox for whether they can use the register at
/// all, then view or modify. The manager is left out: they always have full
/// access.
class AccessEditor extends ConsumerWidget {
  const AccessEditor({
    super.key,
    required this.access,
    required this.onChanged,
    this.enabled = true,
  });

  final Map<String, RegisterAccess> access;
  final ValueChanged<Map<String, RegisterAccess>> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).value?.memberId;
    final members = ref.watch(membersProvider);
    final theme = Theme.of(context);

    return AsyncValueView(
      value: members,
      onRetry: () => ref.invalidate(membersProvider),
      data: (list) {
        final others = list.where((m) => m.id != me).toList();
        if (others.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              context.l10n.noTeamMembers,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final member in others)
              _MemberAccessRow(
                member: member,
                access: access[member.id],
                enabled: enabled,
                onChanged: (value) {
                  final next = {...access};
                  if (value == null) {
                    next.remove(member.id);
                  } else {
                    next[member.id] = value;
                  }
                  onChanged(next);
                },
              ),
          ],
        );
      },
    );
  }
}

/// Checkbox row; when ticked, a view / modify switch appears under the name.
class _MemberAccessRow extends StatelessWidget {
  const _MemberAccessRow({
    required this.member,
    required this.access,
    required this.enabled,
    required this.onChanged,
  });

  final Member member;
  final RegisterAccess? access;
  final bool enabled;
  final ValueChanged<RegisterAccess?> onChanged;

  void _toggle() => onChanged(access == null ? RegisterAccess.view : null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final access = this.access;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? _toggle : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: access != null,
                    onChanged: enabled ? (_) => _toggle() : null,
                  ),
                  const SizedBox(width: 4),
                  Avatar(
                    initials: member.initials,
                    size: 36,
                    muted: !member.isActive,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge,
                        ),
                        Text(
                          member.isActive
                              ? '@${member.username}'
                              : l.usernameInactive(member.username),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (access != null)
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 4, bottom: 4),
              child: SegmentedButton<RegisterAccess>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [
                  ButtonSegment(
                    value: RegisterAccess.view,
                    icon: const Icon(LucideIcons.eye, size: 18),
                    label: Text(l.accessView),
                  ),
                  ButtonSegment(
                    value: RegisterAccess.modify,
                    icon: const Icon(LucideIcons.pencil, size: 18),
                    label: Text(l.accessModify),
                  ),
                ],
                selected: {access},
                onSelectionChanged: enabled
                    ? (selection) => onChanged(selection.first)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// Sheet for changing who can see or edit an existing register.
class AccessSheet extends ConsumerStatefulWidget {
  const AccessSheet({super.key, required this.detail});

  final RegisterDetail detail;

  @override
  ConsumerState<AccessSheet> createState() => _AccessSheetState();
}

class _AccessSheetState extends ConsumerState<AccessSheet> {
  late var _access = {
    for (final m in widget.detail.members) m.member.id: m.access,
  };
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(registerActionsProvider)
          .setAccess(widget.detail.register.id, _access);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showErrorSnack(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: context.l10n.accessTitle(widget.detail.register.name),
      subtitle: context.l10n.accessSubtitle,
      primaryLabel: context.l10n.saveAccess,
      busy: _saving,
      onPrimary: _save,
      child: AccessEditor(
        access: _access,
        enabled: !_saving,
        onChanged: (next) => setState(() => _access = next),
      ),
    );
  }
}
