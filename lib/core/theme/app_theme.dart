import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Semantic colours used across the app. Widgets read them with
/// `context.palette` instead of hard-coding hex values, so light and dark
/// stay in step.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.sidebar,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textMuted,
    required this.textSubtle,
    required this.brand,
    required this.brandSoft,
    required this.onBrand,
    required this.positive,
    required this.positiveSoft,
    required this.negative,
    required this.negativeSoft,
    required this.warning,
    required this.warningSoft,
    required this.heroStart,
    required this.heroEnd,
  });

  /// Page background behind cards.
  final Color canvas;
  final Color surface;

  /// Hover, selected rows, quiet fills.
  final Color surfaceMuted;
  final Color sidebar;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textMuted;
  final Color textSubtle;
  final Color brand;
  final Color brandSoft;
  final Color onBrand;

  /// Money in.
  final Color positive;
  final Color positiveSoft;

  /// Money out, errors.
  final Color negative;
  final Color negativeSoft;

  /// Open obligations, checked registers.
  final Color warning;
  final Color warningSoft;

  /// Balance card gradient.
  final Color heroStart;
  final Color heroEnd;

  static const light = AppPalette(
    canvas: Color(0xFFF6F7F9),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F3F6),
    sidebar: Color(0xFFFBFBFC),
    border: Color(0xFFE4E7EC),
    borderStrong: Color(0xFFD0D5DD),
    text: Color(0xFF101828),
    textMuted: Color(0xFF475467),
    textSubtle: Color(0xFF667085),
    brand: Color(0xFF0F766E),
    brandSoft: Color(0xFFE6F4F2),
    onBrand: Color(0xFFFFFFFF),
    positive: Color(0xFF067647),
    positiveSoft: Color(0xFFECFDF3),
    negative: Color(0xFFB42318),
    negativeSoft: Color(0xFFFEF3F2),
    warning: Color(0xFFB54708),
    warningSoft: Color(0xFFFFFAEB),
    heroStart: Color(0xFF13857C),
    heroEnd: Color(0xFF0B5550),
  );

  static const dark = AppPalette(
    canvas: Color(0xFF0C0E12),
    surface: Color(0xFF15181D),
    surfaceMuted: Color(0xFF1E2229),
    sidebar: Color(0xFF111317),
    border: Color(0xFF262B33),
    borderStrong: Color(0xFF353B46),
    text: Color(0xFFF2F4F7),
    textMuted: Color(0xFFB0B7C3),
    textSubtle: Color(0xFF8A93A2),
    brand: Color(0xFF14B8A6),
    brandSoft: Color(0xFF0E2B29),
    onBrand: Color(0xFF0C0E12),
    positive: Color(0xFF47CD89),
    positiveSoft: Color(0xFF0E2A1D),
    negative: Color(0xFFF97066),
    negativeSoft: Color(0xFF2E1513),
    warning: Color(0xFFFDB022),
    warningSoft: Color(0xFF2E2210),
    heroStart: Color(0xFF0F766E),
    heroEnd: Color(0xFF09403C),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      canvas: c(canvas, other.canvas),
      surface: c(surface, other.surface),
      surfaceMuted: c(surfaceMuted, other.surfaceMuted),
      sidebar: c(sidebar, other.sidebar),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      text: c(text, other.text),
      textMuted: c(textMuted, other.textMuted),
      textSubtle: c(textSubtle, other.textSubtle),
      brand: c(brand, other.brand),
      brandSoft: c(brandSoft, other.brandSoft),
      onBrand: c(onBrand, other.onBrand),
      positive: c(positive, other.positive),
      positiveSoft: c(positiveSoft, other.positiveSoft),
      negative: c(negative, other.negative),
      negativeSoft: c(negativeSoft, other.negativeSoft),
      warning: c(warning, other.warning),
      warningSoft: c(warningSoft, other.warningSoft),
      heroStart: c(heroStart, other.heroStart),
      heroEnd: c(heroEnd, other.heroEnd),
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// Amounts line up in columns.
const tabularFigures = [FontFeature.tabularFigures()];

/// Mouse-and-keyboard platforms get denser controls than touch screens.
bool get isDesktopPlatform => switch (defaultTargetPlatform) {
  TargetPlatform.macOS ||
  TargetPlatform.windows ||
  TargetPlatform.linux => true,
  _ => false,
};

abstract final class AppTheme {
  static const fontFamily = 'Inter';
  static const radius = 10.0;

  static ThemeData light({bool? desktop}) =>
      _build(AppPalette.light, Brightness.light, desktop ?? isDesktopPlatform);

  static ThemeData dark({bool? desktop}) =>
      _build(AppPalette.dark, Brightness.dark, desktop ?? isDesktopPlatform);

  static TextTheme _text(AppPalette p) {
    TextStyle s(double size, FontWeight weight, {double? track, double? h}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: track ?? 0,
          height: h,
          color: p.text,
        );
    return TextTheme(
      displaySmall: s(32, FontWeight.w700, track: -0.8, h: 1.15),
      headlineLarge: s(30, FontWeight.w700, track: -0.7, h: 1.2),
      headlineMedium: s(26, FontWeight.w700, track: -0.5, h: 1.2),
      headlineSmall: s(22, FontWeight.w700, track: -0.4, h: 1.25),
      titleLarge: s(18, FontWeight.w600, track: -0.2, h: 1.3),
      titleMedium: s(15, FontWeight.w600, track: -0.1, h: 1.35),
      titleSmall: s(14, FontWeight.w600, h: 1.4),
      bodyLarge: s(15, FontWeight.w400, h: 1.45),
      bodyMedium: s(14, FontWeight.w400, h: 1.45),
      bodySmall: s(12.5, FontWeight.w400, h: 1.4).copyWith(color: p.textMuted),
      labelLarge: s(14, FontWeight.w600),
      labelMedium: s(12.5, FontWeight.w500),
      labelSmall: s(11.5, FontWeight.w600, track: 0.2),
    );
  }

  static ThemeData _build(AppPalette p, Brightness brightness, bool desktop) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.brand,
      onPrimary: p.onBrand,
      primaryContainer: p.brandSoft,
      onPrimaryContainer: p.brand,
      secondary: p.text,
      onSecondary: p.surface,
      secondaryContainer: p.surfaceMuted,
      onSecondaryContainer: p.text,
      tertiary: p.positive,
      onTertiary: p.surface,
      error: p.negative,
      onError: brightness == Brightness.light ? Colors.white : p.canvas,
      errorContainer: p.negativeSoft,
      onErrorContainer: p.negative,
      surface: p.surface,
      onSurface: p.text,
      onSurfaceVariant: p.textMuted,
      surfaceContainerLowest: p.canvas,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceMuted,
      surfaceContainerHighest: p.surfaceMuted,
      outline: p.borderStrong,
      outlineVariant: p.border,
      inverseSurface: p.text,
      onInverseSurface: p.surface,
      inversePrimary: p.brandSoft,
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: Colors.transparent,
    );
    final text = _text(p);
    final controlHeight = desktop ? 40.0 : 48.0;
    final buttonText = TextStyle(
      fontFamily: fontFamily,
      fontSize: desktop ? 14 : 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: width),
        );
    final menuShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: p.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: p.canvas,
      canvasColor: p.surface,
      dividerColor: p.border,
      visualDensity: desktop ? VisualDensity.compact : VisualDensity.standard,
      materialTapTargetSize: desktop
          ? MaterialTapTargetSize.shrinkWrap
          : MaterialTapTargetSize.padded,
      splashFactory: desktop
          ? NoSplash.splashFactory
          : InkSparkle.splashFactory,
      hoverColor: p.surfaceMuted,
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.canvas,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        titleTextStyle: text.titleLarge?.copyWith(fontSize: 19),
        iconTheme: IconThemeData(color: p.text, size: 22),
        actionsIconTheme: IconThemeData(color: p.textMuted, size: 20),
      ),
      iconTheme: IconThemeData(color: p.textMuted, size: 20),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        isDense: desktop,
        // Faint enough that an example value never reads as typed input.
        hintStyle: text.bodyMedium?.copyWith(color: p.textSubtle),
        labelStyle: text.bodyMedium?.copyWith(color: p.textMuted),
        floatingLabelStyle: text.bodyMedium?.copyWith(
          color: p.brand,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: p.negative),
        prefixIconColor: p.textSubtle,
        suffixIconColor: p.textSubtle,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: desktop ? 12 : 14,
        ),
        border: border(p.borderStrong),
        enabledBorder: border(p.borderStrong),
        disabledBorder: border(p.border),
        focusedBorder: border(p.brand, 1.5),
        errorBorder: border(p.negative),
        focusedErrorBorder: border(p.negative, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(64, controlHeight),
          // Exact heights: compact density would shrink these by 8 px.
          visualDensity: VisualDensity.standard,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: shape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(64, controlHeight),
          visualDensity: VisualDensity.standard,
          shape: shape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(64, controlHeight),
          visualDensity: VisualDensity.standard,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          foregroundColor: p.text,
          backgroundColor: p.surface,
          shape: shape,
          side: BorderSide(color: p.borderStrong),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(48, desktop ? 36 : 44),
          visualDensity: VisualDensity.standard,
          foregroundColor: p.brand,
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.textMuted,
          shape: shape,
          minimumSize: Size.square(desktop ? 36 : 44),
          visualDensity: VisualDensity.standard,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.brand,
        foregroundColor: p.onBrand,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle: buttonText,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.border),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.brandSoft,
        disabledColor: p.surfaceMuted,
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? p.brand.withValues(alpha: .35)
                : p.border,
          ),
        ),
        labelStyle: text.labelMedium?.copyWith(color: p.text),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: p.brand),
        checkmarkColor: p.brand,
        iconTheme: IconThemeData(color: p.textMuted, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, controlHeight - 4)),
          side: WidgetStatePropertyAll(BorderSide(color: p.borderStrong)),
          shape: WidgetStatePropertyAll(shape),
          textStyle: WidgetStatePropertyAll(
            text.labelLarge?.copyWith(fontSize: 13.5),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.brandSoft : p.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.brand : p.textMuted,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.brand : p.textMuted,
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: .18),
        shape: menuShape,
        menuPadding: const EdgeInsets.symmetric(vertical: 6),
        textStyle: text.bodyMedium,
        labelTextStyle: WidgetStatePropertyAll(text.bodyMedium),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(8),
          shadowColor: WidgetStatePropertyAll(
            Colors.black.withValues(alpha: .18),
          ),
          shape: WidgetStatePropertyAll(menuShape),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 6),
          ),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: MenuItemButton.styleFrom(
          textStyle: text.bodyMedium,
          iconColor: p.textMuted,
          iconSize: 18,
          minimumSize: const Size(180, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.textMuted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        dragHandleColor: p.borderStrong,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.text,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.surface),
        actionTextColor: p.brandSoft,
        shape: shape,
        width: desktop ? 420 : null,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.text,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: text.bodySmall?.copyWith(color: p.surface),
        waitDuration: const Duration(milliseconds: 400),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textMuted,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodySmall,
        shape: shape,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: p.borderStrong, width: 1.5),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.brand,
        linearTrackColor: p.surfaceMuted,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(3),
        thumbColor: WidgetStatePropertyAll(p.borderStrong),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: p.brandSoft,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? p.brand
                : p.textSubtle,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall!.copyWith(
            fontSize: 12,
            letterSpacing: 0,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? p.text
                : p.textSubtle,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, space: 1, thickness: 1),
    );
  }
}
