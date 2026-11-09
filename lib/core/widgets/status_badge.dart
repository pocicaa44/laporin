import 'package:flutter/material.dart';

import '../../data/models/report_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Distinct sharp rectangular badge for handling_status (DESIGN.md Section 4.4)
class HandlingStatusBadge extends StatelessWidget {
  const HandlingStatusBadge({
    super.key,
    required this.status,
    this.createdAt,
    this.isDraft = false,
  });

  final HandlingStatus status;
  final DateTime? createdAt;
  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    if (isDraft) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: AppRadius.badge,
          border: Border.all(color: const Color(0xFFFDE68A), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFFB45309)),
            SizedBox(width: 4),
            Text(
              'Draft',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
              ),
            ),
          ],
        ),
      );
    }

    // Hilangkan badge "Baru" jika laporan berstatus newReport namun sudah lebih dari 1 jam
    if (status == HandlingStatus.newReport && createdAt != null) {
      final now = DateTime.now();
      final effectiveDate = createdAt!.isAfter(now) ? now : createdAt!;
      final diff = now.difference(effectiveDate);
      if (diff.inMinutes >= 60) {
        return const SizedBox.shrink();
      }
    }

    Color bg;
    Color fg;
    Color borderColor;
    IconData icon;
    String label = status.label;

    switch (status) {
      case HandlingStatus.newReport:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        borderColor = const Color(0xFFBFDBFE);
        icon = Icons.fiber_new_rounded;
        break;
      case HandlingStatus.accepted:
        bg = const Color(0xFFF0F9FF);
        fg = const Color(0xFF0284C7);
        borderColor = const Color(0xFFBAE6FD);
        icon = Icons.check_circle_outline_rounded;
        break;
      case HandlingStatus.inProgress:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFB45309);
        borderColor = const Color(0xFFFDE68A);
        icon = Icons.autorenew_rounded;
        break;
      case HandlingStatus.completed:
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF15803D);
        borderColor = const Color(0xFFBBF7D0);
        icon = Icons.task_alt_rounded;
        break;
      case HandlingStatus.rejected:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFB91C1C);
        borderColor = const Color(0xFFFECACA);
        icon = Icons.cancel_outlined;
        break;
      case HandlingStatus.cancelled:
        bg = const Color(0xFFF8FAFC);
        fg = AppColors.textSecondary;
        borderColor = AppColors.border;
        icon = Icons.block_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.badge,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Distinct sharp rectangular badge for publication_state (DESIGN.md Section 4.4)
class PublicationStateBadge extends StatelessWidget {
  const PublicationStateBadge({
    super.key,
    required this.state,
    this.isDraft = false,
    this.iconOnly = false,
  });

  final PublicationState state;
  final bool isDraft;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    if (isDraft) {
      if (iconOnly) {
        return Tooltip(
          message: 'Draft',
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: AppRadius.badge,
              border: Border.all(color: const Color(0xFFFDE68A), width: 1),
            ),
            child: const Center(
              child: Icon(
                Icons.edit_note_rounded,
                size: 14,
                color: Color(0xFFB45309),
              ),
            ),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: AppRadius.badge,
          border: Border.all(color: const Color(0xFFFDE68A), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_rounded, size: 12, color: Color(0xFFB45309)),
            SizedBox(width: 4),
            Text(
              'Draft',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
              ),
            ),
          ],
        ),
      );
    }

    Color bg;
    Color fg;
    Color borderColor;
    IconData icon;
    String label = state.label;

    switch (state) {
      case PublicationState.pendingReview:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFB45309);
        borderColor = const Color(0xFFFDE68A);
        icon = Icons.hourglass_empty_rounded;
        break;
      case PublicationState.published:
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF15803D);
        borderColor = const Color(0xFFBBF7D0);
        icon = Icons.public_rounded;
        break;
      case PublicationState.held:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFB91C1C);
        borderColor = const Color(0xFFFECACA);
        icon = Icons.flag_rounded;
        break;
      case PublicationState.archived:
        bg = const Color(0xFFF8FAFC);
        fg = AppColors.textSecondary;
        borderColor = AppColors.border;
        icon = Icons.archive_outlined;
        break;
    }

    if (iconOnly) {
      return Tooltip(
        message: label,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.badge,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Center(child: Icon(icon, size: 14, color: fg)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.badge,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
