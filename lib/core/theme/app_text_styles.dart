import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography tokens based on DESIGN.md Section 3.4
class AppTextStyles {
  AppTextStyles._();

  // Heading Hierarchy
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textTitle,
    height: 1.25,
    letterSpacing: -0.3,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textTitle,
    height: 1.30,
    letterSpacing: -0.2,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textTitle,
    height: 1.35,
  );

  // Body Text
  static const TextStyle bodyRegular = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    height: 1.50,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textBody,
    height: 1.40,
  );

  // Labels & Captions
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textTitle,
    height: 1.20,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.30,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.40,
  );

  // Backward-compatible aliases for existing screens
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textTitle,
    letterSpacing: -0.5,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textTitle,
    letterSpacing: -0.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textTitle,
  );

  static const TextStyle body = bodyRegular;

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.50,
  );

  // Dynamic Context-Aware TextStyles for Dual Themes (Light & Dark)
  static TextStyle h1Of(BuildContext context) =>
      h1.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle h2Of(BuildContext context) =>
      h2.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle h3Of(BuildContext context) =>
      h3.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle bodyOf(BuildContext context) =>
      bodyRegular.copyWith(color: AppColors.textBodyOf(context));

  static TextStyle bodyMediumOf(BuildContext context) =>
      bodyMedium.copyWith(color: AppColors.textBodyOf(context));

  static TextStyle bodySecondaryOf(BuildContext context) =>
      bodySecondary.copyWith(color: AppColors.textSecondaryOf(context));

  static TextStyle captionOf(BuildContext context) =>
      caption.copyWith(color: AppColors.textMutedOf(context));

  static TextStyle pageTitleOf(BuildContext context) =>
      pageTitle.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle sectionTitleOf(BuildContext context) =>
      sectionTitle.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle labelOf(BuildContext context) =>
      label.copyWith(color: AppColors.textPrimaryOf(context));
}
