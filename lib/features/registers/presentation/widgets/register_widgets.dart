import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/format/money.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../../../l10n/l10n.dart';
import '../../../sync/sync_widgets.dart';
import '../../domain/cash_register.dart';

extension RegisterStatusUi on RegisterStatus {
  IconData get icon => switch (this) {
    RegisterStatus.open => LucideIcons.lockOpen,
    RegisterStatus.checked => LucideIcons.clipboardCheck,
    RegisterStatus.closed => LucideIcons.lock,
  };

  Color color(BuildContext context) {
    final p = context.palette;
    return switch (this) {
      RegisterStatus.open => p.positive,
      RegisterStatus.checked => p.warning,
      RegisterStatus.closed => p.textSubtle,
    };
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final RegisterStatus status;

  @override
  Widget build(BuildContext context) => Pill(
    label: status.label(context.l10n),
    icon: status.icon,
    color: status.color(context),
  );
}

/// One register in a list. [dense] rows are for the desktop side pane;
/// the taller ones are touch targets on phones.
class RegisterTile extends StatefulWidget {
  const RegisterTile({
    super.key,
    required this.register,
    required this.onTap,
    this.selected = false,
    this.dense = false,
    this.onMenu,
  });

  final CashRegister register;
  final VoidCallback onTap;
  final bool selected;
  final bool dense;

  /// Right-click (with the pointer position) or long press (null position).
  final void Function(Offset? at)? onMenu;

  @override
  State<RegisterTile> createState() => _RegisterTileState();
}

class _RegisterTileState extends State<RegisterTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final r = widget.register;
    final status = r.status;
    final diff = r.difference;
    final menu = widget.onMenu;

    final background = widget.selected
        ? p.brandSoft
        : _hover
        ? p.surfaceMuted
        : Colors.transparent;

    final subtitle = [
      status.label(context.l10n),
      if (diff != 0) context.l10n.realShort(Money.format(r.realAmount)),
    ].join(' · ');

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(widget.dense ? 10 : 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.dense ? 10 : 0),
          onTap: widget.onTap,
          onSecondaryTapUp: menu == null
              ? null
              : (details) => menu(details.globalPosition),
          onLongPress: menu == null ? null : () => menu(null),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.dense ? 12 : 16,
              vertical: widget.dense ? 10 : 14,
            ),
            child: Row(
              children: [
                _StatusMark(status: status, size: widget.dense ? 34 : 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: widget.dense ? 14 : 15,
                                color: widget.selected ? p.brand : p.text,
                              ),
                            ),
                          ),
                          if (r.isPending) ...[
                            const SizedBox(width: 6),
                            const PendingMark(label: false),
                          ],
                          if (r.isPinned) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: context.l10n.pinned,
                              child: Icon(
                                LucideIcons.pin,
                                size: 13,
                                color: p.textSubtle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  Money.format(r.currentAmount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: widget.dense ? 14 : 15,
                    fontFeatures: tabularFigures,
                    color: status == RegisterStatus.closed
                        ? p.textMuted
                        : p.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({required this.status, required this.size});

  final RegisterStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = status.color(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(size * .28),
        border: Border.all(color: p.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(LucideIcons.wallet, size: size * .46, color: p.textMuted),
          Positioned(
            right: size * .14,
            bottom: size * .14,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: p.surface, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blue brand card for the headline money figure, like a bank balance.
class MoneyHeroCard extends StatelessWidget {
  const MoneyHeroCard({
    super.key,
    required this.label,
    required this.amount,
    this.badge,
    this.footer = const [],
  });

  final String label;
  final int amount;
  final Widget? badge;

  /// Secondary figures shown in a row under the amount.
  final List<HeroFigure> footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    const onHero = Colors.white;
    final muted = Colors.white.withValues(alpha: .72);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.heroStart, p.heroEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: p.heroEnd.withValues(alpha: .22),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Money.format(amount),
              style: theme.textTheme.displaySmall?.copyWith(
                color: onHero,
                fontFeatures: tabularFigures,
              ),
            ),
          ),
          if (footer.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < footer.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: _HeroFigureBox(footer[i])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroFigureBox extends StatelessWidget {
  const _HeroFigureBox(this.figure);

  final HeroFigure figure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            figure.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: .72),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              figure.value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: figure.color ?? Colors.white,
                fontFeatures: tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
    return figure.help == null
        ? box
        : Tooltip(message: figure.help!, child: box);
  }
}

class HeroFigure {
  const HeroFigure(this.label, this.value, {this.color, this.help});

  final String label;
  final String value;
  final Color? color;
  final String? help;
}

/// Light green / red that stay readable on the blue hero card.
Color heroAmountColor(int sign) => sign > 0
    ? const Color(0xFFA6F4C5)
    : sign < 0
    ? const Color(0xFFFECDCA)
    : Colors.white;

/// Cash on hand, real amount and outstanding at the top of a register: a
/// brand card on phones, three figure tiles on wide screens.
class BalanceHeader extends StatelessWidget {
  const BalanceHeader({super.key, required this.register});

  final CashRegister register;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final diff = register.difference;
    final outstanding = diff == 0 ? l.none : Money.signed(diff);

    if (isWide(context)) {
      return Row(
        children: [
          Expanded(
            child: StatTile(
              icon: LucideIcons.banknote,
              label: l.cashOnHand,
              value: Money.format(register.currentAmount),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatTile(
              icon: LucideIcons.scale,
              label: l.realAmount,
              value: Money.format(register.realAmount),
              help: l.realAmountHelp,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatTile(
              icon: LucideIcons.hourglass,
              label: l.outstanding,
              value: outstanding,
              valueColor: diff == 0 ? null : amountColor(context, diff.sign),
              help: l.outstandingHelp,
            ),
          ),
        ],
      );
    }

    return MoneyHeroCard(
      label: l.cashOnHand,
      amount: register.currentAmount,
      footer: [
        HeroFigure(
          l.realAmount,
          Money.format(register.realAmount),
          help: l.realAmountHelp,
        ),
        HeroFigure(
          l.outstanding,
          outstanding,
          color: heroAmountColor(diff.sign),
          help: l.outstandingHelp,
        ),
      ],
    );
  }
}
