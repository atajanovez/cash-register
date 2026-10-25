import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/old_money_dialog.dart';
import '../../../core/widgets/sheet_scaffold.dart';
import '../../../l10n/l10n.dart';
import '../../registers/application/registers_providers.dart';
import '../../registers/domain/cash_register.dart';
import '../application/records_controller.dart';
import '../data/records_repository.dart';
import '../domain/cash_record.dart';
import '../domain/record_type.dart';
import 'record_tile.dart';

/// Two steps: pick a type (only those the register's state allows), then
/// fill in what that type needs. Pops with `true` once the record is saved.
///
/// Settlements must name the record they settle (`parent_record_id`): the
/// borrow, loan or accrued income being paid off.
class AddRecordSheet extends ConsumerStatefulWidget {
  const AddRecordSheet({
    super.key,
    required this.register,
    this.type,
    this.parent,
  });

  final CashRegister register;

  /// Skip the type step (e.g. settling from a record's details).
  final RecordType? type;
  final CashRecord? parent;

  @override
  ConsumerState<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends ConsumerState<AddRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  late RecordType? _type = widget.type;
  late CashRecord? _parent = widget.parent;
  String? _destinationId;
  DateTime? _deadline;

  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  CashRegister get _register => widget.register;

  @override
  void initState() {
    super.initState();
    if (_parent != null) _amount.text = Money.toInput(_parent!.remaining);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _pickType(RecordType type) {
    setState(() {
      _type = type;
      _parent = null;
      _destinationId = null;
      _amount.clear();
      _deadline = type.needsDeadline
          ? DateUtils.addDaysToDate(DateUtils.dateOnly(DateTime.now()), 7)
          : null;
      _error = null;
      _fieldErrors = const {};
    });
  }

  void _pickParent(CashRecord record) => setState(() {
    _parent = record;
    _amount.text = Money.toInput(record.remaining);
    _fieldErrors = {..._fieldErrors}..remove('parent_record_id');
  });

  String? _validateAmount(String? value) {
    final l = context.l10n;
    final amount = Money.parse(value ?? '');
    if (amount == null || amount <= 0) return l.enterAmount;
    final type = _type!;
    if (type.needsFunds && amount > _register.currentAmount) {
      return l.onlyCash(Money.format(_register.currentAmount));
    }
    if (type.isSettlement && _parent != null && amount > _parent!.remaining) {
      return l.onlyLeftToSettle(Money.format(_parent!.remaining));
    }
    return null;
  }

  /// For people who still count in old manats; fills in the new amount.
  Future<void> _convertOldMoney() async {
    final minor = await showOldMoneyConverter(context);
    if (minor == null || !mounted) return;
    setState(() => _amount.text = Money.toInput(minor));
  }

  Future<void> _pickDeadline() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? today,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365 * 10)),
      helpText: context.l10n.dueDate,
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _fieldErrors = const {};
    });
    final type = _type!;
    final formOk = _formKey.currentState!.validate();
    if (type.needsParent && _parent == null) {
      setState(
        () =>
            _fieldErrors = {'parent_record_id': context.l10n.chooseObligation},
      );
      return;
    }
    if (!formOk) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final draft = RecordDraft(
      type: type,
      amount: Money.parse(_amount.text)!,
      note: _note.text,
      // End of the chosen day, so "due today" is not already overdue.
      deadline: _deadline?.add(const Duration(hours: 23, minutes: 59)),
      parentRecordId: _parent?.id,
      destinationRegisterId: _destinationId,
    );

    setState(() => _saving = true);
    try {
      await ref.read(recordsRepositoryProvider).create(_register.id, draft);
      ref
          .read(registerActionsProvider)
          .refreshAfterRecord(_register.id, otherRegisterId: _destinationId);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      final l = context.l10n;
      setState(() {
        _saving = false;
        _fieldErrors = describeFieldErrors(l, e);
        _error = describeError(l, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = _type;
    if (type == null) {
      return _TypePicker(register: _register, onPick: _pickType);
    }
    final l = context.l10n;

    return SheetScaffold(
      title: type.label(l),
      subtitle: type.hint(l),
      leading: widget.type == null
          ? IconButton(
              tooltip: l.changeType,
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: _saving ? null : () => setState(() => _type = null),
            )
          : null,
      primaryLabel: l.saveRecord,
      busy: _saving,
      onPrimary: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (type.isSettlement) ...[
              _ParentPicker(
                registerId: _register.id,
                openingType: type.settles!,
                selected: _parent,
                locked: widget.parent != null,
                enabled: !_saving,
                errorText: _fieldErrors['parent_record_id'],
                onPick: _pickParent,
              ),
              const SizedBox(height: 16),
            ],
            if (type.needsDestination) ...[
              _DestinationPicker(
                current: _register,
                selectedId: _destinationId,
                enabled: !_saving,
                errorText: _fieldErrors['destination_cash_register_id'],
                onChanged: (id) => setState(() => _destinationId = id),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _amount,
              enabled: !_saving && (!type.isSettlement || _parent != null),
              autofocus: !type.isSettlement && !type.needsDestination,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [AmountInputFormatter()],
              textInputAction: TextInputAction.next,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontFeatures: tabularFigures),
              decoration: InputDecoration(
                labelText: l.amount,
                hintText: '0,00',
                suffixText: Money.currency,
                prefixIcon: const Icon(LucideIcons.banknote),
                helperText: type.needsFunds
                    ? l.availableCash(Money.format(_register.currentAmount))
                    : null,
                errorText: _fieldErrors['amount'],
              ),
              validator: _validateAmount,
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: _saving || (type.isSettlement && _parent == null)
                    ? null
                    : _convertOldMoney,
                icon: const Icon(LucideIcons.coins, size: 18),
                label: Text(l.oldMoneyButton),
              ),
            ),
            if (type.needsDeadline) ...[
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _saving ? null : _pickDeadline,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l.dueDate,
                    prefixIcon: const Icon(LucideIcons.calendar),
                    suffixIcon: const Icon(LucideIcons.calendarDays),
                    errorText: _fieldErrors['deadline'],
                  ),
                  child: Text(
                    _deadline == null ? l.chooseDate : Dates.date(_deadline!),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              minLines: 1,
              maxLength: 500,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: InputDecoration(
                labelText: l.noteLabel,
                hintText: l.noteHint,
                prefixIcon: const Icon(LucideIcons.stickyNote),
                counterText: '',
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? l.errNoteRequired : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              ErrorBanner(message: _error!),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypePicker extends StatelessWidget {
  const _TypePicker({required this.register, required this.onPick});

  final CashRegister register;
  final ValueChanged<RecordType> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final allowed = RecordType.values
        .where((t) => t.creatable && t.allowedIn(register.status))
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, isWide(context) ? 24 : 0, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(l.addARecord, style: theme.textTheme.titleLarge),
            ),
            if (register.status != RegisterStatus.open)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Text(
                  register.status == RegisterStatus.checked
                      ? l.typesWhenChecked
                      : l.typesWhenClosed,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final group in RecordGroup.values)
              if (allowed.any((t) => t.group == group)) ...[
                // A lone type already says what the group is.
                if (allowed.where((t) => t.group == group).length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                    child: SectionTitle(group.label(l)),
                  )
                else
                  const SizedBox(height: 16),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (i, type)
                          in allowed
                              .where((t) => t.group == group)
                              .indexed) ...[
                        if (i > 0) const Divider(indent: 68),
                        ListTile(
                          shape: const RoundedRectangleBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          leading: RecordTypeIcon(type: type),
                          title: Text(
                            type.label(l),
                            style: theme.textTheme.titleSmall,
                          ),
                          subtitle: Text(type.hint(l)),
                          trailing: Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: context.palette.textSubtle,
                          ),
                          onTap: () => onPick(type),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _DestinationPicker extends ConsumerWidget {
  const _DestinationPicker({
    required this.current,
    required this.selectedId,
    required this.enabled,
    required this.onChanged,
    this.errorText,
  });

  final CashRegister current;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final registers = ref.watch(allRegistersProvider);
    // A closed register cannot receive transfers.
    final options = (registers.value ?? const <CashRegister>[])
        .where((r) => r.id != current.id && r.status != RegisterStatus.closed)
        .toList();

    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l.toRegister,
        prefixIcon: const Icon(LucideIcons.arrowRight),
        errorText: errorText,
        helperText: registers.isLoading
            ? l.loadingRegisters
            : options.isEmpty
            ? l.noTransferTargets
            : null,
      ),
      items: [
        for (final r in options)
          DropdownMenuItem(
            value: r.id,
            child: Text(
              '${r.name} · ${Money.format(r.currentAmount)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: enabled ? onChanged : null,
      validator: (v) => v == null ? l.chooseDestination : null,
    );
  }
}

/// The open borrow / loan / accrued income being settled, as tappable cards
/// so the cashier sees note, what is left and the due date before choosing.
class _ParentPicker extends ConsumerWidget {
  const _ParentPicker({
    required this.registerId,
    required this.openingType,
    required this.selected,
    required this.locked,
    required this.enabled,
    required this.onPick,
    this.errorText,
  });

  final String registerId;
  final RecordType openingType;
  final CashRecord? selected;

  /// Opened from the record's own details: show only that one.
  final bool locked;
  final bool enabled;
  final ValueChanged<CashRecord> onPick;
  final String? errorText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);

    final List<CashRecord> options;
    Widget? status;
    if (locked && selected != null) {
      options = [selected!];
    } else {
      final openings = ref.watch(
        unsettledOpeningsProvider((registerId: registerId, type: openingType)),
      );
      options = openings.value ?? const [];
      if (openings.isLoading) {
        status = const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      } else if (openings.hasError) {
        status = Text(describeError(l, openings.error!));
      } else if (options.isEmpty) {
        status = Text(
          l.nothingToSettle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.whichObligation),
        const SizedBox(height: 8),
        ?status,
        for (final record in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ObligationCard(
              record: record,
              selected: record.id == selected?.id,
              onTap: enabled && !locked ? () => onPick(record) : null,
            ),
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _ObligationCard extends StatelessWidget {
  const _ObligationCard({
    required this.record,
    required this.selected,
    required this.onTap,
  });

  final CashRecord record;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = context.palette;
    final overdue = record.isOverdue();

    return Material(
      color: selected ? p.brandSoft : p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? p.brand : p.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                selected ? LucideIcons.circleDot : LucideIcons.circle,
                color: selected ? p.brand : p.borderStrong,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.note.isNotEmpty
                          ? record.note
                          : record.type.label(l),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        Dates.date(record.createdAt),
                        if (record.creator != null) record.creator!.displayName,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (record.deadline != null)
                      Text(
                        l.dueOn(Dates.date(record.deadline!)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: overdue
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                          fontWeight: overdue ? FontWeight.w600 : null,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Money.format(record.remaining),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                  if (record.remaining != record.amount)
                    Text(
                      Money.format(record.amount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
