import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../data/models/report_model.dart';

/// Action bar for upvoting, downvoting, and community engagement
class VoteActionBar extends StatelessWidget {
  const VoteActionBar({
    super.key,
    required this.report,
    required this.onUpvote,
    required this.onDownvote,
    this.isEnabled = true,
    this.disabledReason,
  });

  final ReportModel report;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;
  final bool isEnabled;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUp = report.currentUserVote == 'up';
    final isDown = report.currentUserVote == 'down';

    final surfaceColor = isEnabled ? AppColors.surfaceOf(context) : AppColors.backgroundOf(context);
    final borderColor = AppColors.borderSubtleOf(context);
    final dividerColor = AppColors.borderOf(context);
    final primaryColor = AppColors.primaryOf(context);
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.danger;
    final textSecondary = AppColors.textSecondaryOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionButton(
                icon: isUp
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_up_alt_outlined,
                label: 'Dukung (${report.upvotesCount})',
                isActive: isUp,
                activeColor: primaryColor,
                isEnabled: isEnabled,
                onTap: isEnabled ? onUpvote : null,
              ),
              Container(width: 1, height: 28, color: dividerColor),
              _ActionButton(
                icon: isDown
                    ? Icons.thumb_down_alt_rounded
                    : Icons.thumb_down_alt_outlined,
                label: 'Keberatan (${report.downvotesCount})',
                isActive: isDown,
                activeColor: dangerColor,
                isEnabled: isEnabled,
                onTap: isEnabled ? onDownvote : null,
              ),
            ],
          ),
          if (!isEnabled && disabledReason != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  disabledReason!,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    this.isEnabled = true,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    final color = !isEnabled
        ? textSecondary.withValues(alpha: 0.6)
        : (isActive ? activeColor : textPrimary);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pill,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled && isActive
              ? activeColor.withValues(alpha: isDark ? 0.2 : 0.1)
              : Colors.transparent,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isEnabled && isActive
                ? activeColor.withValues(alpha: isDark ? 0.35 : 0.28)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
