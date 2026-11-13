import 'package:flutter/material.dart';

/// Design tokens for colors based on DESIGN.md Section 3.3
class AppColors {
  AppColors._();

  // Brand Primary
  static const Color primary = Color(0xFF2563EB); // Blue 600
  static const Color primaryHover = Color(0xFF1D4ED8); // Blue 700
  static const Color primaryStrong = Color(
    0xFF1D4ED8,
  ); // Alias for primaryHover
  static const Color primaryLight = Color(0xFF3B82F6); // Blue 500
  static const Color primarySoft = Color(0xFFEFF6FF); // Blue 50
  static const Color primarySubtle = Color(0xFFEFF6FF); // Alias for primarySoft
  static const Color accent = Color(0xFF2563EB);

  // Brand Primary (Dark Mode - Strict Primary Accent Rule)
  static const Color darkPrimary = Color(0xFF3B82F6); // Blue 500 (Electric Blue)
  static const Color darkPrimaryHover = Color(0xFF2563EB); // Blue 600
  static const Color darkPrimaryLight = Color(0xFF60A5FA); // Blue 400
  static const Color darkPrimarySoft = Color(0xFF1C2638); // Subtle primary tint for active state
  static const Color darkPrimarySubtle = Color(0xFF1C2638);

  // Secondary (Slate Neutral Palette - Light Mode)
  static const Color secondary = Color(0xFF475569); // Slate 600
  static const Color secondaryHover = Color(0xFF334155); // Slate 700
  static const Color secondaryLight = Color(0xFF64748B); // Slate 500
  static const Color secondarySoft = Color(0xFFF1F5F9); // Slate 100
  static const Color secondarySubtle = Color(0xFFF8FAFC); // Slate 50

  // Secondary (Neutral Charcoal Palette - Dark Mode)
  static const Color darkSecondary = Color(0xFF8E8E93); // Neutral Grey 400
  static const Color darkSecondaryHover = Color(0xFFD1D1D6); // Neutral Grey 300
  static const Color darkSecondaryLight = Color(0xFFE5E5EA); // Neutral Grey 200
  static const Color darkSecondarySoft = Color(0xFF242428); // Elevated Charcoal
  static const Color darkSecondarySubtle = Color(0xFF1A1A1E); // Dark Charcoal Surface

  // Tertiary (Sky Accent Palette - Light Mode)
  static const Color tertiary = Color(0xFF0284C7); // Sky 600
  static const Color tertiaryHover = Color(0xFF0369A1); // Sky 700
  static const Color tertiaryLight = Color(0xFF38BDF8); // Sky 400
  static const Color tertiarySoft = Color(0xFFE0F2FE); // Sky 100
  static const Color tertiarySubtle = Color(0xFFF0F9FF); // Sky 50

  // Tertiary (Sky Accent Palette - Dark Mode)
  static const Color darkTertiary = Color(0xFF38BDF8); // Sky 400
  static const Color darkTertiaryHover = Color(0xFF0284C7); // Sky 600
  static const Color darkTertiaryLight = Color(0xFF7DD3FC); // Sky 300
  static const Color darkTertiarySoft = Color(0xFF0C4A6E); // Sky 900
  static const Color darkTertiarySubtle = Color(0xFF082F49); // Sky 950

  // Status & Semantics (Light Mode)
  static const Color success = Color(0xFF16A34A); // Emerald 600
  static const Color successSubtle = Color(0xFFDCFCE7); // Emerald 100
  static const Color successText = Color(0xFF15803D); // Emerald 700

  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color warningSubtle = Color(0xFFFEF3C7); // Amber 100
  static const Color warningText = Color(0xFFB45309); // Amber 700

  static const Color danger = Color(0xFFDC2626); // Red 600
  static const Color dangerSubtle = Color(0xFFFEE2E2); // Red 100
  static const Color dangerText = Color(0xFFB91C1C); // Red 700

  static const Color info = Color(0xFF0284C7); // Sky 600
  static const Color infoSubtle = Color(0xFFE0F2FE); // Sky 100
  static const Color infoText = Color(0xFF0369A1); // Sky 700

  // Status & Semantics (Dark Mode)
  static const Color darkSuccess = Color(0xFF22C55E); // Emerald 500
  static const Color darkSuccessSubtle = Color(0xFF064E3B); // Emerald 900
  static const Color darkSuccessText = Color(0xFF86EFAC); // Emerald 300

  static const Color darkWarning = Color(0xFFF59E0B); // Amber 500
  static const Color darkWarningSubtle = Color(0xFF78350F); // Amber 900
  static const Color darkWarningText = Color(0xFFFDE68A); // Amber 200

  static const Color darkDanger = Color(0xFFEF4444); // Red 500
  static const Color darkDangerSubtle = Color(0xFF7F1D1D); // Red 900
  static const Color darkDangerText = Color(0xFFFCA5A5); // Red 300

  static const Color darkInfo = Color(0xFF38BDF8); // Sky 400
  static const Color darkInfoSubtle = Color(0xFF0C4A6E); // Sky 900
  static const Color darkInfoText = Color(0xFFBAE6FD); // Sky 200

  // Neutrals, Text & Surfaces (Light Mode)
  static const Color textPrimary = Color(
    0xFF0F172A,
  ); // Slate 900 (Headings, titles)
  static const Color textTitle = Color(0xFF0F172A); // Slate 900
  static const Color textBody = Color(0xFF334155); // Slate 700 (Body, comments)
  static const Color textSecondary = Color(
    0xFF64748B,
  ); // Slate 500 (Captions, timestamps)
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color border = Color(
    0xFFE2E8F0,
  ); // Slate 200 (Input borders, cards)
  static const Color borderSubtle = Color(
    0xFFF1F5F9,
  ); // Slate 100 (Dividers, internal lines)
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color background = Color(
    0xFFF8FAFC,
  ); // Slate 50 (Scaffold canvas)
  static const Color disabled = Color(0xFF94A3B8); // Slate 400

  // Neutrals, Text & Surfaces (Dark Mode - Neutral Charcoal & Deep Black)
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Pure White (14.2:1 contrast)
  static const Color darkTextTitle = Color(0xFFFFFFFF);
  static const Color darkTextBody = Color(0xFFD1D1D6); // Neutral Grey 300 (9.5:1 contrast)
  static const Color darkTextSecondary = Color(0xFF8E8E93); // Neutral Grey 400 (4.9:1 contrast)
  static const Color darkTextMuted = Color(0xFF8E8E93);
  static const Color darkBorder = Color(0xFF2E2E34); // Neutral Hairline 1px
  static const Color darkBorderSubtle = Color(0xFF222226); // Deep Charcoal
  static const Color darkSurface = Color(0xFF1A1A1E); // Dark Charcoal Surface
  static const Color darkSurfaceElevated = Color(0xFF242428); // Elevated Charcoal (Modals, Popovers)
  static const Color darkSurfaceRecessed = Color(0xFF141416); // Recessed Charcoal (Input fills, search)
  static const Color darkBackground = Color(0xFF0E0E10); // Deep Charcoal Black Canvas
  static const Color darkDisabled = Color(0xFF48484A); // Neutral Muted Grey

  // Flat UI Design Tokens: Zero drop shadow
  static const BoxShadow cardShadow = BoxShadow(
    color: Colors.transparent,
    blurRadius: 0,
    offset: Offset.zero,
  );

  static const BoxShadow modalShadow = BoxShadow(
    color: Colors.transparent,
    blurRadius: 0,
    offset: Offset.zero,
  );

  // Dynamic Theme Context Helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? darkBackground : background;

  static Color surfaceElevatedOf(BuildContext context) =>
      isDark(context) ? darkSurfaceElevated : const Color(0xFFF8FAFC);

  static Color surfaceRecessedOf(BuildContext context) =>
      isDark(context) ? darkSurfaceRecessed : const Color(0xFFF8FAFC);

  static Color borderOf(BuildContext context) =>
      isDark(context) ? darkBorder : border;

  static Color borderSubtleOf(BuildContext context) =>
      isDark(context) ? darkBorderSubtle : borderSubtle;

  static Color primaryOf(BuildContext context) =>
      isDark(context) ? darkPrimary : primary;

  static Color secondaryOf(BuildContext context) =>
      isDark(context) ? darkSecondary : secondary;

  static Color tertiaryOf(BuildContext context) =>
      isDark(context) ? darkTertiary : tertiary;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color textBodyOf(BuildContext context) =>
      isDark(context) ? darkTextBody : textBody;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color textMutedOf(BuildContext context) =>
      isDark(context) ? darkTextMuted : textMuted;

  static Color successOf(BuildContext context) =>
      isDark(context) ? darkSuccess : success;

  static Color warningOf(BuildContext context) =>
      isDark(context) ? darkWarning : warning;

  static Color dangerOf(BuildContext context) =>
      isDark(context) ? darkDanger : danger;

  static Color infoOf(BuildContext context) =>
      isDark(context) ? darkInfo : info;

  static Color disabledOf(BuildContext context) =>
      isDark(context) ? darkDisabled : disabled;
}

/// Extension on [BuildContext] for ergonomic theme access
extension ThemeContextExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}
