import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// The Kassa mark: a white receipt on an Adyl Hasap teal tile. Drawn as
/// vector so it is crisp at every size; the launcher icons are rendered from
/// the same painter.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.tile = true});

  final double size;

  /// Without the tile only the receipt is drawn, for dark or brand
  /// backgrounds.
  final bool tile;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.logoLabel,
    image: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: LogoPainter(
        tile: tile,
        start: AppPalette.light.heroStart,
        end: AppPalette.light.heroEnd,
      ),
    ),
  );
}

class LogoPainter extends CustomPainter {
  const LogoPainter({
    this.tile = true,
    this.cornerRadius = 0.26,
    this.inset = 0,
    this.receiptScale = 1,
    required this.start,
    required this.end,
  });

  final bool tile;

  /// Tile corner radius as a fraction of its side; 0 for a full square.
  final double cornerRadius;

  /// Empty margin around the tile, as a fraction of the canvas (macOS icons
  /// leave room around the artwork).
  final double inset;

  /// Receipt size relative to the default; Android's adaptive icons need it
  /// smaller to fit the safe zone.
  final double receiptScale;
  final Color start;
  final Color end;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * (1 - inset * 2);
    final origin = Offset((size.width - side) / 2, (size.height - side) / 2);
    final box = origin & Size.square(side);

    if (tile) {
      final rrect = RRect.fromRectAndRadius(
        box,
        Radius.circular(side * cornerRadius),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [start, end],
          ).createShader(box),
      );
    }

    // Receipt in a 100×100 grid, centred.
    final u = side / 100 * receiptScale;
    final c = box.center;
    Offset at(double x, double y) =>
        Offset(c.dx + (x - 50) * u, c.dy + (y - 50) * u);

    const left = 29.0, right = 71.0, top = 20.0, bottom = 80.0;
    const teeth = 5;
    const toothDepth = 5.0;
    final path = Path()
      ..moveTo(at(left, top + 6).dx, at(left, top + 6).dy)
      ..arcToPoint(at(left + 6, top), radius: Radius.circular(6 * u))
      ..lineTo(at(right - 6, top).dx, at(right - 6, top).dy)
      ..arcToPoint(at(right, top + 6), radius: Radius.circular(6 * u))
      ..lineTo(at(right, bottom).dx, at(right, bottom).dy);
    const step = (right - left) / teeth;
    for (var i = teeth; i > 0; i--) {
      final x = left + step * i;
      final mid = at(x - step / 2, bottom - toothDepth);
      final end = at(x - step, bottom);
      path
        ..lineTo(mid.dx, mid.dy)
        ..lineTo(end.dx, end.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = Colors.white);

    // Printed lines: two items and a bold total.
    final ink = Paint()
      ..color = tile ? end : start
      ..strokeCap = StrokeCap.round;
    void line(double x1, double x2, double y, double weight) =>
        canvas.drawLine(at(x1, y), at(x2, y), ink..strokeWidth = weight * u);
    line(37, 63, 34, 4.2);
    line(37, 55, 44, 4.2);
    line(37, 63, 60, 6.5);
  }

  @override
  bool shouldRepaint(LogoPainter old) =>
      old.tile != tile ||
      old.cornerRadius != cornerRadius ||
      old.inset != inset ||
      old.receiptScale != receiptScale ||
      old.start != start ||
      old.end != end;
}

/// "Adyl Hasap", the family of apps Kassa belongs to, lettered like its logo:
/// bold Inter with "Hasap" in the brand teal.
class AdylHasapWordmark extends StatelessWidget {
  const AdylHasapWordmark({super.key, this.size = 15, this.onBrand = false});

  final double size;

  /// White lettering for the brand panel.
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text.rich(
      TextSpan(
        text: 'Adyl ',
        children: [
          TextSpan(
            text: 'Hasap',
            style: TextStyle(
              color: onBrand ? Colors.white.withValues(alpha: .75) : p.brand,
            ),
          ),
        ],
      ),
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: size,
        height: 1.2,
        letterSpacing: -.2,
        color: onBrand ? Colors.white : p.text,
      ),
    );
  }
}
