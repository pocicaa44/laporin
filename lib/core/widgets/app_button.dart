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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final disabledColor = isDark ? AppColors.darkDisabled : AppColors.disabled;
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.danger;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textPrimaryColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = isEnabled ? primaryColor : disabledColor;
        foregroundColor = Colors.white;
        borderSide = BorderSide(
          color: isEnabled ? primaryColor : disabledColor,
          width: 1,
        );
        break;
      case AppButtonVariant.secondary:
        backgroundColor = surfaceColor;
        foregroundColor = isEnabled
            ? textPrimaryColor
            : textSecondaryColor;
        borderSide = BorderSide(color: borderColor, width: 1);
        break;
      case AppButtonVariant.destructive:
        backgroundColor = isEnabled ? dangerColor : disabledColor;
        foregroundColor = Colors.white;
        borderSide = BorderSide(
          color: isEnabled ? dangerColor : disabledColor,
          width: 1,
        );
        break;
      case AppButtonVariant.text:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled ? primaryColor : disabledColor;
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
