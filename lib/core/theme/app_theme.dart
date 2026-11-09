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
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.danger,
        brightness: Brightness.light,
      ),

      // App Bar: Clean surface, 0 elevation, 1px bottom border
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
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
}
