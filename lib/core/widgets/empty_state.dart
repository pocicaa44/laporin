import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Reusable empty state widget matching DESIGN.md Section 4.5 & 11
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.faIcon = FontAwesomeIcons.boxOpen,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData? icon;
  final FaIconData? faIcon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft;
    final iconColor =
        isDark ? AppColors.darkPrimaryLight : AppColors.primary;
    final messageColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: faIcon != null
                  ? FaIcon(faIcon, size: 40, color: iconColor)
                  : Icon(
                      icon ?? Icons.inbox_outlined,
                      size: 40,
                      color: iconColor,
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitleOf(context).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(color: messageColor),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 180,
                child: AppButton(
                  text: actionLabel!,
                  onPressed: onAction,
                  height: 44,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
