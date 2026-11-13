import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// Central ThemeData implementation matching DESIGN.md Section 8.2
/// (Modern, Rounded, Friendly & Professional Civic-Tech)
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const borderSide = BorderSide(color: AppColors.border, width: 1.0);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        tertiary: AppColors.tertiary,
        onTertiary: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),

      // Text Theme: Light mode text hierarchy
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.display,
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        headlineSmall: AppTextStyles.h3,
        titleLarge: AppTextStyles.pageTitle,
        titleMedium: AppTextStyles.sectionTitle,
        bodyLarge: AppTextStyles.bodyRegular,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.label,
        labelSmall: AppTextStyles.caption,
      ),

      // Navigation Bar Themes
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
      ),

      // App Bar: Clean surface, 0 elevation, 1px bottom border
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.pageTitle,
      ),

      // Card Theme: Sudut membulat 16px, background putih bersih, hairline border (Flat UI)
      cardTheme: CardThemeData(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: borderSide,
        ),
        margin: EdgeInsets.zero,
        color: AppColors.surface,
      ),

      // Elevated & Filled Button Theme: Sudut membulat 12px
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Outlined Button Theme: Sudut membulat 12px, border 1px solid
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          side: borderSide,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppTextStyles.button.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          foregroundColor: AppColors.primary,
        ),
      ),

      // Floating Action Button Theme: Squircle membulat 16px, Flat UI (0 elevation)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      // Input Decoration Theme: Sudut membulat 12px, hairline border, fokus ring 1.5px
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.bodySecondary,
        labelStyle: AppTextStyles.label,
      ),

      // Dialog & Modal Theme: Sudut membulat 20px, border 1px
      dialogTheme: const DialogThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.dialog,
          side: borderSide,
        ),
        backgroundColor: AppColors.surface,
      ),

      // Bottom Sheet Theme: Sudut atas membulat 24px
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        backgroundColor: AppColors.surface,
      ),

      // Divider Theme: 1 px hairline border
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ==========================================
  // MODE GELAP (DARK THEME - Neutral Charcoal & Deep Black)
  // ==========================================
  static ThemeData get darkTheme {
    const darkBorderSide = BorderSide(color: AppColors.darkBorder, width: 1.0);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: Colors.white,
        secondary: AppColors.darkSecondary,
        onSecondary: Colors.white,
        tertiary: AppColors.darkTertiary,
        onTertiary: Colors.white,
        error: AppColors.darkDanger,
        onError: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkSurfaceElevated,
        surfaceContainer: AppColors.darkSurface,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorderSubtle,
      ),

      // Text Theme: Dark mode text hierarchy with WCAG AA compliance
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(color: AppColors.darkTextPrimary),
        headlineLarge: AppTextStyles.h1.copyWith(color: AppColors.darkTextPrimary),
        headlineMedium: AppTextStyles.h2.copyWith(color: AppColors.darkTextPrimary),
        headlineSmall: AppTextStyles.h3.copyWith(color: AppColors.darkTextPrimary),
        titleLarge: AppTextStyles.pageTitle.copyWith(color: AppColors.darkTextPrimary),
        titleMedium: AppTextStyles.sectionTitle.copyWith(color: AppColors.darkTextPrimary),
        bodyLarge: AppTextStyles.bodyRegular.copyWith(color: AppColors.darkTextBody),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkTextBody),
        bodySmall: AppTextStyles.caption.copyWith(color: AppColors.darkTextMuted),
        labelLarge: AppTextStyles.label.copyWith(color: AppColors.darkTextPrimary),
        labelSmall: AppTextStyles.caption.copyWith(color: AppColors.darkTextMuted),
      ),

      // Navigation Bar Themes (Dark Mode)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.darkPrimary,
        unselectedLabelColor: AppColors.darkTextSecondary,
        indicatorColor: AppColors.darkPrimary,
      ),

      // App Bar: Dark Charcoal (#1A1A1E) surface, 0 elevation, 1px bottom border (#2E2E34)
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: AppTextStyles.pageTitle.copyWith(
          color: AppColors.darkTextPrimary,
        ),
      ),

      // Card Theme: Sudut membulat 16px, background Dark Charcoal (#1A1A1E), hairline border (#2E2E34)
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: darkBorderSide,
        ),
        margin: EdgeInsets.zero,
        color: AppColors.darkSurface,
      ),

      // Elevated & Filled Button Theme: Sudut membulat 12px, warna aksen primary
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Outlined Button Theme: Sudut membulat 12px, latar Dark Charcoal, border netral 1px solid
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          side: darkBorderSide,
          foregroundColor: AppColors.darkTextPrimary,
          backgroundColor: AppColors.darkSurface,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppTextStyles.button.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          foregroundColor: AppColors.darkPrimary,
        ),
      ),

      // Floating Action Button Theme: Squircle membulat 16px, Flat UI
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: Colors.white,
      ),

      // Input Decoration Theme: Latar Recessed Charcoal (#141416), sudut membulat 12px, border netral (#2E2E34)
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceRecessed,
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: darkBorderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: darkBorderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.darkDanger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.darkDanger, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        labelStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Dialog & Modal Theme: Latar Dark Charcoal (#1A1A1E), sudut membulat 20px, border netral (#2E2E34)
      dialogTheme: const DialogThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.dialog,
          side: darkBorderSide,
        ),
        backgroundColor: AppColors.darkSurface,
      ),

      // Bottom Sheet Theme: Sudut atas membulat 24px, latar Dark Charcoal (#1A1A1E)
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        backgroundColor: AppColors.darkSurface,
      ),

      // Divider Theme: 1 px hairline border netral (#2E2E34)
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
