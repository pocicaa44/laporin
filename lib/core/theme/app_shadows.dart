import 'package:flutter/material.dart';

/// Flat design tokens: Zero drop shadows across the entire application.
/// Visual separation and spatial depth are achieved purely through
/// crisp hairline borders (1px) and subtle surface contrast (Flat UI Design).
class AppShadows {
  AppShadows._();

  /// Flat UI: No drop shadow
  static const List<BoxShadow> none = [];

  /// Flat UI: Card tanpa drop shadow
  static const List<BoxShadow> card = [];

  /// Flat UI: Komponen floating tanpa drop shadow
  static const List<BoxShadow> floating = [];

  /// Flat UI: Modal dan dialog tanpa drop shadow
  static const List<BoxShadow> modal = [];

  /// Flat UI: Tombol primary tanpa glow shadow
  static const List<BoxShadow> primaryGlow = [];
}
