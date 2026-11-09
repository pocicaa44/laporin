import 'package:flutter/material.dart';

/// Modern & Rounded design tokens based on DESIGN.md Section 3.1 & 8.1
class AppRadius {
  AppRadius._();

  // Raw scalar double values
  static const double kXs = 4.0;
  static const double kSm = 8.0;
  static const double kMd = 12.0;
  static const double kLg = 16.0;
  static const double kXl = 20.0;
  static const double kXxl = 24.0;
  static const double kPill = 999.0;

  // Radius constants
  static const Radius radiusXs = Radius.circular(kXs);
  static const Radius radiusSm = Radius.circular(kSm);
  static const Radius radiusMd = Radius.circular(kMd);
  static const Radius radiusLg = Radius.circular(kLg);
  static const Radius radiusXl = Radius.circular(kXl);
  static const Radius radiusXxl = Radius.circular(kXxl);
  static const Radius radiusPill = Radius.circular(kPill);

  // BorderRadius scale tokens
  static const BorderRadius borderXs = BorderRadius.all(radiusXs);
  static const BorderRadius borderSm = BorderRadius.all(radiusSm);
  static const BorderRadius borderMd = BorderRadius.all(radiusMd);
  static const BorderRadius borderLg = BorderRadius.all(radiusLg);
  static const BorderRadius borderXl = BorderRadius.all(radiusXl);
  static const BorderRadius borderXxl = BorderRadius.all(radiusXxl);
  static const BorderRadius borderPill = BorderRadius.all(radiusPill);

  /// 4 px - Indikator mikro, handle bar kecil, tooltip
  static const BorderRadius xs = borderXs;

  /// 8 px - Thumbnail foto kecil, inner card, badge kotak rounded
  static const BorderRadius sm = borderSm;

  /// 12 px - Tombol standar, text field input, dropdown
  static const BorderRadius md = borderMd;

  /// 16 px - Kartu laporan, dialog konfirmasi, container uploader media
  static const BorderRadius lg = borderLg;

  /// 20 px - Floating banner, dialog besar
  static const BorderRadius xl = borderXl;

  /// 24 px - Sudut atas Bottom Sheet
  static const BorderRadius xxl = borderXxl;

  /// 999 px - Filter chip, pill badge status, search bar pill
  static const BorderRadius pill = borderPill;

  /// Stadium border untuk tombol & chip pill
  static const OutlinedBorder stadium = StadiumBorder();

  /// Lingkaran sempurna - Avatar pengguna & logo
  static const BoxShape circle = BoxShape.circle;

  // Component-specific semantic radius tokens
  static const BorderRadius button = borderMd; // 12px
  static const BorderRadius card = borderLg; // 16px
  static const BorderRadius input = borderMd; // 12px
  static const BorderRadius badge = borderPill; // 999px (Pill)
  static const BorderRadius chip = borderPill; // 999px (Pill)
  static const BorderRadius dialog = borderXl; // 20px
  static const BorderRadius sheet = BorderRadius.vertical(
    top: radiusXxl,
  ); // 24px top

  // Backward-compatible flat token
  static const BorderRadius flat = BorderRadius.zero;
}
