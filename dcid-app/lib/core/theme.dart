import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand design tokens — Smart Industrial palette
// ─────────────────────────────────────────────────────────────────────────────

/// Primary accent — Electric Cyan/Teal (dark mode buttons, AI glows, chips).
const Color kCyan = Color(0xFF0EA5E9);

/// Primary accent — Industrial Cobalt Blue (light mode active states).
const Color kCobalt = Color(0xFF2563EB);

/// Cyan focus glow at ~30% opacity.
const Color kCyanGlow = Color(0x4D0EA5E9);

/// Cobalt focus glow at ~25% opacity.
const Color kCobaltGlow = Color(0x402563EB);

/// Dark mode: Deep Slate background.
const Color kDarkBg = Color(0xFF0F172A);

/// Dark mode: card/container surface.
const Color kDarkCard = Color(0xFF1E293B);

/// Dark mode: subtle card border.
const Color kDarkBorder = Color(0xFF334155);

/// Light mode: soft slate background.
const Color kLightBg = Color(0xFFF3F4F6);

// ─────────────────────────────────────────────────────────────────────────────
// Text themes — Plus Jakarta Sans → Inter fallback (both from Google Fonts)
// ─────────────────────────────────────────────────────────────────────────────

TextTheme _buildTextTheme(ColorScheme scheme) {
  // Plus Jakarta Sans for display/headings; Inter for body.
  return GoogleFonts.plusJakartaSansTextTheme(
    ThemeData(brightness: scheme.brightness).textTheme,
  ).copyWith(
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: scheme.onSurface,
    ),
    displayMedium: GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    bodyLarge: GoogleFonts.inter(fontSize: 15, height: 1.5),
    bodyMedium: GoogleFonts.inter(fontSize: 14, height: 1.5),
    bodySmall: GoogleFonts.inter(fontSize: 12, height: 1.4),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Light theme — Soft Slate + Cobalt Blue accent
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Cached ThemeData instances for high-performance builds
// ─────────────────────────────────────────────────────────────────────────────

ThemeData? _cachedLightTheme;
ThemeData? _cachedDarkTheme;

ThemeData buildAppTheme() {
  return _cachedLightTheme ??= _buildAppThemeInternal();
}

ThemeData buildDarkAppTheme() {
  return _cachedDarkTheme ??= _buildDarkAppThemeInternal();
}

ThemeData _buildAppThemeInternal() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kCobalt,
    brightness: Brightness.light,
  ).copyWith(
    surface: Colors.white,
    surfaceContainerLowest: const Color(0xFFF1F5F9),
    surfaceContainerLow: const Color(0xFFE2E8F0),
    surfaceContainer: const Color(0xFFCBD5E1),
    surfaceContainerHigh: const Color(0xFF94A3B8),
    primary: kCobalt,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFDBEAFE),
    onPrimaryContainer: const Color(0xFF1E3A8A),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kLightBg,
    textTheme: _buildTextTheme(scheme),
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    fontFamilyFallback: [
      GoogleFonts.inter().fontFamily!,
      'Segoe UI',
      'Arial',
      'sans-serif',
    ],
    visualDensity: VisualDensity.adaptivePlatformDensity,
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shadowColor: Color(0x1A0F172A),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        backgroundColor: kCobalt,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kCobalt : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? kCobalt.withValues(alpha: 0.35)
            : null,
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: kCobalt.withValues(alpha: 0.12),
      selectedIconTheme: const IconThemeData(color: kCobalt),
      selectedLabelTextStyle: const TextStyle(
        color: kCobalt,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: kCobalt.withValues(alpha: 0.12),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? const IconThemeData(color: kCobalt)
            : const IconThemeData(color: Color(0xFF64748B)),
      ),
    ),
  );
}

ThemeData _buildDarkAppThemeInternal() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kCyan,
    brightness: Brightness.dark,
  ).copyWith(
    surface: kDarkBg,
    surfaceContainerLowest: const Color(0xFF0A0F1E),
    surfaceContainerLow: kDarkCard,
    surfaceContainer: const Color(0xFF253047),
    surfaceContainerHigh: const Color(0xFF2D3B52),
    surfaceContainerHighest: kDarkBorder,
    outlineVariant: kDarkBorder,
    primary: kCyan,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFF0C3547),
    onPrimaryContainer: const Color(0xFFBAE6FD),
    secondary: const Color(0xFF38BDF8),
    onSecondary: const Color(0xFF003348),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kDarkBg,
    textTheme: _buildTextTheme(scheme),
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    fontFamilyFallback: [
      GoogleFonts.inter().fontFamily!,
      'Segoe UI',
      'Arial',
      'sans-serif',
    ],
    visualDensity: VisualDensity.adaptivePlatformDensity,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: kDarkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kDarkBorder, width: 1),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        backgroundColor: kCyan,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: kDarkCard,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kCyan : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? kCyan.withValues(alpha: 0.35)
            : null,
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: kDarkCard,
      indicatorColor: kCyan.withValues(alpha: 0.15),
      selectedIconTheme: const IconThemeData(color: kCyan),
      selectedLabelTextStyle: const TextStyle(
        color: kCyan,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kDarkCard,
      indicatorColor: kCyan.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? const IconThemeData(color: kCyan)
            : IconThemeData(color: Colors.white.withValues(alpha: 0.5)),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience: return the correct accent for the current brightness.
// ─────────────────────────────────────────────────────────────────────────────

/// Returns [kCyan] in dark mode, [kCobalt] in light mode.
Color accentFor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark ? kCyan : kCobalt;
}

/// Returns the appropriate glow color for the current brightness.
Color accentGlowFor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? kCyanGlow
      : kCobaltGlow;
}
