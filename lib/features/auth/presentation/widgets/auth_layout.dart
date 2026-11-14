import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/format/money.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../l10n/l10n.dart';
import '../../../settings/server_widgets.dart';

/// Shared frame for login and signup.
///
/// - Wide (desktop, landscape tablet): form on the left, brand panel on the
///   right.
/// - Narrow (phone): logo, title and form stacked in one scrollable column.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  static const wideBreakpoint = 900.0;

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= wideBreakpoint;
          final form = _FormColumn(
            title: title,
            subtitle: subtitle,
            wide: wide,
            child: child,
          );
          if (!wide) return SafeArea(child: form);

          return Row(
            children: [
              Expanded(flex: 6, child: SafeArea(child: form)),
              const Expanded(
                flex: 5,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: _BrandPanel(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FormColumn extends StatelessWidget {
  const _FormColumn({
    required this.title,
    required this.subtitle,
    required this.wide,
    required this.child,
  });

  final String title;
  final String subtitle;
  final bool wide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final roomy = MediaQuery.sizeOf(context).height >= 560;
    return Center(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(24, wide ? 40 : 24, 24, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Skipped on short screens (phone landscape) so the form
              // starts higher.
              if (roomy) ...[
                Row(
                  children: [
                    const AppLogo(size: 40),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.appName,
                          style: theme.textTheme.titleLarge,
                        ),
                        const AdylHasapWordmark(size: 13),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: wide ? 48 : 36),
              ],
              Text(title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(color: p.textMuted),
              ),
              const SizedBox(height: 28),
              child,
              const SizedBox(height: 16),
              const ServerLink(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = Colors.white.withValues(alpha: .75);
    // Drop the sample card on short windows so the panel never overflows.
    final roomy = MediaQuery.sizeOf(context).height >= 720;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppPalette.light.heroStart, AppPalette.light.heroEnd],
          ),
        ),
        child: Stack(
          children: [
            // Large faint receipt as texture.
            Positioned(
              right: -60,
              top: -40,
              child: Opacity(
                opacity: .08,
                child: CustomPaint(
                  size: const Size.square(360),
                  painter: LogoPainter(
                    tile: false,
                    start: Colors.white,
                    end: Colors.white,
                  ),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(44),
                    // Wordmark at the top, the pitch at the bottom.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AdylHasapWordmark(size: 20, onBrand: true),
                        const SizedBox(height: 32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (roomy) ...[
                              const _SampleCard(),
                              const SizedBox(height: 40),
                            ],
                            Text(
                              context.l10n.brandHeadline,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.l10n.brandBody,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _Feature(
                              icon: LucideIcons.monitorSmartphone,
                              text: context.l10n.featureDevices,
                            ),
                            _Feature(
                              icon: LucideIcons.shieldCheck,
                              text: context.l10n.featureRoles,
                            ),
                            _Feature(
                              icon: LucideIcons.receiptText,
                              text: context.l10n.featureAudit,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small preview of what the app shows: a register's balance.
class _SampleCard extends StatelessWidget {
  const _SampleCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final muted = Colors.white.withValues(alpha: .7);
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.wallet, size: 16, color: muted),
              const SizedBox(width: 8),
              Text(l.cashOnHand, style: TextStyle(color: muted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Money.format(1254000),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontFeatures: tabularFigures,
            ),
          ),
          const SizedBox(height: 16),
          _sampleRow(LucideIcons.arrowDownLeft, l.typeIncome, '+2 500,00'),
          const SizedBox(height: 8),
          _sampleRow(LucideIcons.arrowUpRight, l.typeExpense, '−340,00'),
        ],
      ),
    );
  }

  Widget _sampleRow(IconData icon, String label, String amount) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      Text(
        amount,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFeatures: tabularFigures,
        ),
      ),
    ],
  );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .88),
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
