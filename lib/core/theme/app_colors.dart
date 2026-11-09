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

  // Status & Semantics
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

  // Neutrals, Text & Surfaces
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
}
