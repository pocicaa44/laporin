import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
    final isUp = report.currentUserVote == 'up';
    final isDown = report.currentUserVote == 'down';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEnabled ? AppColors.surface : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                activeColor: AppColors.primary,
                isEnabled: isEnabled,
                onTap: isEnabled ? onUpvote : null,
              ),
              Container(width: 1, height: 28, color: AppColors.border),
              _ActionButton(
                icon: isDown
                    ? Icons.thumb_down_alt_rounded
                    : Icons.thumb_down_alt_outlined,
                label: 'Keberatan (${report.downvotesCount})',
                isActive: isDown,
                activeColor: AppColors.danger,
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
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  disabledReason!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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
    final color = !isEnabled
        ? AppColors.textSecondary.withValues(alpha: 0.6)
        : (isActive ? activeColor : AppColors.textPrimary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled && isActive
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEnabled && isActive
                ? activeColor.withValues(alpha: 0.28)
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
