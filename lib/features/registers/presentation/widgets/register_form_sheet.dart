import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../l10n/l10n.dart';
import '../../application/registers_providers.dart';
import '../../domain/cash_register.dart';
import 'access_editor.dart';

/// Creates a register; pops with the new [CashRegister].
class RegisterFormSheet extends ConsumerStatefulWidget {
  const RegisterFormSheet({super.key});

  @override
  ConsumerState<RegisterFormSheet> createState() => _RegisterFormSheetState();
}

class _RegisterFormSheetState extends ConsumerState<RegisterFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  Map<String, RegisterAccess> _access = const {};
  bool _saving = false;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _nameError = null);
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      final register = await ref
          .read(registerActionsProvider)
          .create(name: _name.text.trim(), access: _access);
      if (mounted) Navigator.pop(context, register);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _nameError = describeFieldErrors(context.l10n, e)['name'];
      });
      if (_nameError == null) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: context.l10n.newRegister,
      primaryLabel: context.l10n.createRegister,
      busy: _saving,
      onPrimary: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              enabled: !_saving,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                labelText: context.l10n.name,
                hintText: context.l10n.registerNameHint,
                prefixIcon: const Icon(LucideIcons.wallet),
                errorText: _nameError,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? context.l10n.enterName
                  : null,
            ),
            const SizedBox(height: 24),
            SectionTitle(context.l10n.teamAccess),
            const SizedBox(height: 4),
            AccessEditor(
              access: _access,
              enabled: !_saving,
              onChanged: (next) => setState(() => _access = next),
            ),
          ],
        ),
      ),
    );
  }
}
