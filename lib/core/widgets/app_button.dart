import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, destructive, text }

/// Reusable button widget matching DESIGN.md Section 4.1
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
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final Widget? iconWidget;
  final double height;
  final double? width;

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
        borderSide = null;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = AppColors.surface;
        foregroundColor = isEnabled
            ? AppColors.textPrimary
            : AppColors.textSecondary;
        borderSide = const BorderSide(color: AppColors.border);
        break;
      case AppButtonVariant.destructive:
        backgroundColor = isEnabled ? AppColors.danger : AppColors.disabled;
        foregroundColor = Colors.white;
        borderSide = null;
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

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: Material(
        color: backgroundColor,
        borderRadius: borderSide == null ? BorderRadius.circular(12) : null,
        shape: borderSide != null
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: borderSide,
              )
            : null,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: content),
        ),
      ),
    );
  }
}
