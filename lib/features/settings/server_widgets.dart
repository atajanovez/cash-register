import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/config/app_config.dart';
import '../../core/config/server_settings.dart';
import '../../core/network/api_exception.dart';
import '../../core/offline/offline_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/button_spinner.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/password_field.dart';
import '../../core/widgets/sheet_scaffold.dart';
import '../../l10n/l10n.dart';
import '../auth/application/auth_controller.dart';

Future<void> showServerSettings(BuildContext context) =>
    showAdaptiveSheet<void>(context, builder: (_) => const _ServerSheet());

class _ServerSheet extends ConsumerStatefulWidget {
  const _ServerSheet();

  @override
  ConsumerState<_ServerSheet> createState() => _ServerSheetState();
}

class _ServerSheetState extends ConsumerState<_ServerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _api;
  late final TextEditingController _sync;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(serverSettingsProvider);
    _api = TextEditingController(text: ServerSettings.display(settings.apiUrl));
    _sync = TextEditingController(
      text: ServerSettings.display(settings.syncUrl),
    );
  }

  @override
  void dispose() {
    _api.dispose();
    _sync.dispose();
    super.dispose();
  }

  String? _validate(String? value) =>
      ServerSettings.normalize(value ?? '') == null
      ? context.l10n.serverInvalidUrl
      : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l = context.l10n;
    final settings = ref.read(serverSettingsProvider.notifier);
    final apiUrl = ServerSettings.normalize(_api.text)!;
    final syncUrl = ServerSettings.normalize(_sync.text)!;
    final signedIn = ref.read(authControllerProvider).value != null;
    final apiChanged =
        (apiUrl.isEmpty ? AppConfig.baseUrl : apiUrl) !=
        ref.read(serverSettingsProvider).apiUrl;

    // A token from one server is not valid on another, and the cached data
    // belongs to the old one: log in again on the new server.
    if (signedIn && apiChanged) {
      final sync = ref.read(syncControllerProvider);
      final auth = ref.read(authControllerProvider.notifier);
      final unsent = sync.unsentCount;
      final ok = await confirm(
        context,
        title: l.serverChangeTitle,
        message: unsent > 0
            ? l.serverChangeUnsent('$unsent')
            : l.serverChangeMessage,
        confirmLabel: l.serverChangeConfirm,
        destructive: true,
      );
      if (!ok || !mounted) return;
      Navigator.pop(context);
      await sync.wipe();
      await auth.logout();
      await settings.save(apiUrl: apiUrl, syncUrl: syncUrl);
      return;
    }

    await settings.save(apiUrl: apiUrl, syncUrl: syncUrl);
    if (!mounted) return;
    showInfoSnack(context, l.serverSaved);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SheetScaffold(
      title: l.serverTitle,
      subtitle: l.serverSubtitle,
      primaryLabel: l.serverSave,
      onPrimary: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _api,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l.serverApiUrl,
                hintText: l.serverUrlHint,
                helperText: l.serverApiUrlHelp,
                helperMaxLines: 3,
                prefixIcon: const Icon(LucideIcons.server),
              ),
              validator: _validate,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    _api.text = ServerSettings.display(AppConfig.baseUrl),
                child: Text(l.serverUseDefault),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _sync,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: l.serverSyncUrl,
                hintText: l.serverUrlHint,
                helperText: l.serverSyncUrlHelp,
                helperMaxLines: 3,
                prefixIcon: const Icon(LucideIcons.refreshCcwDot),
              ),
              validator: _validate,
            ),
          ],
        ),
      ),
    );
  }
}

/// Under the login and signup forms: which server the app talks to.
class ServerLink extends ConsumerWidget {
  const ServerLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final api = ref.watch(serverSettingsProvider.select((s) => s.apiUrl));
    final host = Uri.tryParse(api)?.authority ?? api;
    return Center(
      child: TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: p.textMuted),
        onPressed: () => showServerSettings(context),
        icon: const Icon(LucideIcons.server, size: 16),
        label: Text('${context.l10n.serverTitle}: $host'),
      ),
    );
  }
}

/// Profile card: both addresses, an edit button and the sync button.
class ServerCard extends ConsumerWidget {
  const ServerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(serverSettingsProvider);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UrlRow(
            icon: LucideIcons.server,
            label: l.serverApiUrl,
            value: ServerSettings.display(settings.apiUrl),
          ),
          const Divider(indent: 52),
          _UrlRow(
            icon: LucideIcons.refreshCcwDot,
            label: l.serverSyncUrl,
            value: settings.hasSyncUrl
                ? ServerSettings.display(settings.syncUrl)
                : l.serverNotSet,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => showServerSettings(context),
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: Text(l.serverEdit),
                ),
                if (showSyncServers(ref)) const SyncServersButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UrlRow extends StatelessWidget {
  const _UrlRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: p.textSubtle),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(value, style: theme.textTheme.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The server allows the sync button to managers only.
bool showSyncServers(WidgetRef ref) =>
    ref.watch(serverSettingsProvider).hasSyncUrl &&
    (ref.watch(authControllerProvider).value?.isManager ?? false);

/// Makes the local server exchange data with the cloud, then reloads.
class SyncServersButton extends ConsumerStatefulWidget {
  const SyncServersButton({super.key, this.expanded = false});

  /// Full width, for sheets.
  final bool expanded;

  @override
  ConsumerState<SyncServersButton> createState() => _SyncServersButtonState();
}

class _SyncServersButtonState extends ConsumerState<SyncServersButton> {
  bool _running = false;

  Future<void> _run() async {
    final controller = ref.read(syncControllerProvider);
    setState(() => _running = true);
    try {
      try {
        await controller.syncServers();
      } on ApiException catch (e) {
        if (e.code != 'sync_login_required' || !mounted) rethrow;
        final loggedIn = await showDialog<bool>(
          context: context,
          builder: (_) => const _SyncLoginDialog(),
        );
        if (loggedIn != true) return;
        await controller.syncServers();
      }
      if (mounted) showInfoSnack(context, context.l10n.serverSyncDone);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Tooltip(
      message: l.serverSyncHint,
      child: OutlinedButton.icon(
        style: widget.expanded
            ? OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46))
            : null,
        onPressed: _running ? null : _run,
        icon: _running
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(LucideIcons.refreshCcwDot, size: 16),
        label: Text(_running ? l.serverSyncRunning : l.serverSyncNow),
      ),
    );
  }
}

/// Asks for the password once; the sync server issues its own token.
class _SyncLoginDialog extends ConsumerStatefulWidget {
  const _SyncLoginDialog();

  @override
  ConsumerState<_SyncLoginDialog> createState() => _SyncLoginDialogState();
}

class _SyncLoginDialogState extends ConsumerState<_SyncLoginDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(syncControllerProvider).loginToSyncServer(_password.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(context.l10n, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = ref.watch(authControllerProvider).value;
    final server = ServerSettings.display(
      ref.watch(serverSettingsProvider).syncUrl,
    );
    return AlertDialog(
      title: Text(l.syncLoginTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.syncLoginMessage(server, session?.username ?? '')),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              autofocus: true,
              enabled: !_busy,
              errorText: _error,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        OutlinedButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy ? const ButtonSpinner() : Text(l.syncLoginButton),
        ),
      ],
    );
  }
}
