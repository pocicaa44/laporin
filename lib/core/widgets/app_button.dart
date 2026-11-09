import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, destructive, text }

/// Reusable modern button widget matching DESIGN.md Section 4.1 (12px rounded or pill)
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.iconWidget,
    this.height = 48,
    this.width,
    this.borderRadius,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final Widget? iconWidget;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = isEnabled ? AppColors.primary : AppColors.disabled;
        foregroundColor = Colors.white;
        borderSide = BorderSide(
          color: isEnabled ? AppColors.primary : AppColors.disabled,
          width: 1,
        );
        break;
      case AppButtonVariant.secondary:
        backgroundColor = AppColors.surface;
        foregroundColor = isEnabled
            ? AppColors.textPrimary
            : AppColors.textSecondary;
        borderSide = const BorderSide(color: AppColors.border, width: 1);
        break;
      case AppButtonVariant.destructive:
        backgroundColor = isEnabled ? AppColors.danger : AppColors.disabled;
        foregroundColor = Colors.white;
        borderSide = BorderSide(
          color: isEnabled ? AppColors.danger : AppColors.disabled,
          width: 1,
        );
        break;
      case AppButtonVariant.text:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled ? AppColors.primary : AppColors.disabled;
        borderSide = null;
        break;
    }

    final content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconWidget != null) ...[
                iconWidget!,
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(icon, size: 18, color: foregroundColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: AppTextStyles.button.copyWith(color: foregroundColor),
              ),
            ],
          );

    final effectiveRadius = borderRadius ?? AppRadius.button;

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: effectiveRadius,
          side: borderSide ?? BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          child: Center(child: content),
        ),
      ),
    );
  }
}
