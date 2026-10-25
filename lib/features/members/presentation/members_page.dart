import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/offline/offline_providers.dart';
import '../../../core/widgets/password_field.dart';
import '../../../core/widgets/sheet_scaffold.dart';
import '../../../l10n/l10n.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/validators.dart';
import '../application/members_providers.dart';
import '../domain/member.dart';

class MembersPage extends ConsumerWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final isManager = session?.isManager ?? false;
    final members = ref.watch(membersProvider);
    final wide = isWide(context);
    final theme = Theme.of(context);

    void addMember() =>
        showAdaptiveSheet<Member>(
          context,
          builder: (_) => const _AddMemberSheet(),
        ).then((m) {
          if (m != null && context.mounted) {
            showInfoSnack(context, context.l10n.memberAdded(m.displayName));
          }
        });

    final count = members.value?.length;
    final list = AsyncValueView(
      value: members,
      onRetry: () => ref.invalidate(membersProvider),
      data: (list) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          wide ? 28 : 16,
          wide ? 0 : 4,
          wide ? 28 : 16,
          104,
        ),
        children: [
          Align(
            alignment: wide ? Alignment.topLeft : Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isManager && list.length <= 1) ...[
                    _Hint(context.l10n.membersHint),
                    const SizedBox(height: 12),
                  ],
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, member) in list.indexed) ...[
                          if (i > 0) const Divider(indent: 68),
                          _MemberTile(
                            member: member,
                            isMe: member.id == session?.memberId,
                            isManagerMe:
                                member.id == session?.memberId && isManager,
                            onTap: isManager && member.id != session?.memberId
                                ? () => _openMember(context, member)
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (wide) {
      return Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: context.l10n.membersTitle,
              badge: count == null
                  ? null
                  : Pill(label: '$count', color: context.palette.textMuted),
              subtitle: context.l10n.membersSubtitle,
              actions: [
                if (isManager)
                  AppBarPrimaryAction(
                    icon: LucideIcons.userPlus,
                    label: context.l10n.addMember,
                    onPressed: addMember,
                  ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(syncControllerProvider).refresh(),
                child: list,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
              onPressed: addMember,
              icon: const Icon(LucideIcons.userPlus),
              label: Text(context.l10n.addMember),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.membersTitle,
                    style: theme.textTheme.headlineMedium,
                  ),
                  Text(
                    context.l10n.membersSubtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(syncControllerProvider).refresh(),
                child: list,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openMember(BuildContext context, Member member) async {
  final done = await showAdaptiveSheet<String>(
    context,
    builder: (_) => _MemberActionsSheet(member: member),
  );
  if (done != null && context.mounted) showInfoSnack(context, done);
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.brandSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.brand.withValues(alpha: .2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.lightbulb, size: 18, color: p.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isMe,
    required this.isManagerMe,
    this.onTap,
  });

  final Member member;
  final bool isMe;
  final bool isManagerMe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final muted = p.textSubtle;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: const RoundedRectangleBorder(),
      leading: Avatar(initials: member.initials, muted: !member.isActive),
      title: Text(
        member.displayName,
        style: TextStyle(color: member.isActive ? null : muted),
      ),
      subtitle: Text('@${member.username}'),
      onTap: onTap,
      trailing: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (isManagerMe)
            Pill(label: context.l10n.roleManager, color: p.brand),
          if (isMe) Pill(label: context.l10n.you, color: muted),
          if (!member.isActive)
            Pill(label: context.l10n.inactive, color: muted),
          if (onTap != null)
            Icon(LucideIcons.chevronRight, size: 18, color: muted),
        ],
      ),
    );
  }
}

class _AddMemberSheet extends ConsumerStatefulWidget {
  const _AddMemberSheet();

  @override
  ConsumerState<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _fieldErrors = const {});
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      final member = await ref
          .read(memberActionsProvider)
          .create(
            fullName: _fullName.text.trim(),
            username: _username.text.trim(),
            password: _password.text,
          );
      if (mounted) Navigator.pop(context, member);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _fieldErrors = describeFieldErrors(context.l10n, e);
      });
      if (e.fields.isEmpty) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: context.l10n.addMember,
      subtitle: context.l10n.addMemberSubtitle,
      primaryLabel: context.l10n.addMember,
      busy: _saving,
      onPrimary: _save,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _fullName,
              enabled: !_saving,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.fullName,
                prefixIcon: const Icon(LucideIcons.idCard),
                errorText: _fieldErrors['full_name'],
              ),
              validator: Validators.required(context.l10n.enterFullName),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _username,
              enabled: !_saving,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.username,
                prefixIcon: const Icon(LucideIcons.userRound),
                errorText: _fieldErrors['username'],
              ),
              validator: Validators.username(context.l10n),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              enabled: !_saving,
              autofillHints: const [AutofillHints.newPassword],
              helperText: context.l10n.passwordHelper(
                '${Validators.passwordMin}',
              ),
              errorText: _fieldErrors['password'],
              validator: Validators.newPassword(context.l10n),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberActionsSheet extends ConsumerStatefulWidget {
  const _MemberActionsSheet({required this.member});

  final Member member;

  @override
  ConsumerState<_MemberActionsSheet> createState() =>
      _MemberActionsSheetState();
}

class _MemberActionsSheetState extends ConsumerState<_MemberActionsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _busy = false;

  Member get _member => widget.member;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _toggleActive() async {
    final l = context.l10n;
    final activate = !_member.isActive;
    if (!activate) {
      final ok = await confirm(
        context,
        title: l.deactivateTitle(_member.displayName),
        message: l.deactivateMessage,
        confirmLabel: l.deactivate,
        destructive: true,
      );
      if (!ok) return;
    }
    await _run(
      () => ref.read(memberActionsProvider).setActive(_member.id, activate),
      done: activate
          ? l.memberActivated(_member.displayName)
          : l.memberDeactivated(_member.displayName),
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await _run(
      () => ref
          .read(memberActionsProvider)
          .resetPassword(_member.id, _password.text),
      done: context.l10n.passwordChanged(_member.displayName),
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String done,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) Navigator.pop(context, done);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetScaffold(
      title: _member.displayName,
      subtitle: '@${_member.username}',
      primaryLabel: context.l10n.changePassword,
      busy: _busy,
      onPrimary: _resetPassword,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(context.l10n.newPassword),
            const SizedBox(height: 10),
            PasswordField(
              controller: _password,
              enabled: !_busy,
              label: context.l10n.newPassword,
              autofillHints: const [AutofillHints.newPassword],
              helperText: context.l10n.newPasswordHelper,
              validator: Validators.newPassword(context.l10n),
              onSubmitted: (_) => _resetPassword(),
            ),
            const SizedBox(height: 24),
            SectionTitle(context.l10n.access),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.active),
              subtitle: Text(
                _member.isActive
                    ? context.l10n.activeOn
                    : context.l10n.activeOff,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              value: _member.isActive,
              onChanged: _busy ? null : (_) => _toggleActive(),
            ),
          ],
        ),
      ),
    );
  }
}
