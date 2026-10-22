import 'package:flutter/material.dart';

/// Design tokens for colors based on DESIGN.md Section 3.2
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF596CFF);
  static const Color primaryStrong = Color(0xFF4858E8);
  static const Color primarySoft = Color(0xFFEEF0FF);
  static const Color accent = Color(0xFF8B70FF);

  // Status & Alerts
  static const Color success = Color(0xFF35B978);
  static const Color warning = Color(0xFFF4B740);
  static const Color danger = Color(0xFFF05260);
  static const Color info = Color(0xFF4F9BE8);

  // Neutrals & Surfaces
  static const Color textPrimary = Color(0xFF172746);
  static const Color textSecondary = Color(0xFF6F7F9B);
  static const Color border = Color(0xFFE2E8F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FC);
  static const Color disabled = Color(0xFFB8C2D5);

  // Card shadows based on DESIGN.md 3.5
  static const BoxShadow cardShadow = BoxShadow(
    color: Color.fromRGBO(34, 56, 100, 0.06),
    offset: Offset(0, 4),
    blurRadius: 18,
  );

  static const BoxShadow modalShadow = BoxShadow(
    color: Color.fromRGBO(34, 56, 100, 0.14),
    offset: Offset(0, 12),
    blurRadius: 32,
  );
}
