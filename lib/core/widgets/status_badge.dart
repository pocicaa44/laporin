import 'package:flutter/material.dart';

import '../../data/models/report_model.dart';
import '../theme/app_colors.dart';

/// Distinct badge for handling_status (Diterima, Diproses, Selesai, Ditolak, Dibatalkan)
class HandlingStatusBadge extends StatelessWidget {
  const HandlingStatusBadge({super.key, required this.status});

  final HandlingStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label = status.label;

    switch (status) {
      case HandlingStatus.newReport:
        bg = AppColors.primarySoft;
        fg = AppColors.primaryStrong;
        icon = Icons.fiber_new_rounded;
        break;
      case HandlingStatus.accepted:
        bg = const Color(0xFFE8F4FD);
        fg = AppColors.info;
        icon = Icons.check_circle_outline_rounded;
        break;
      case HandlingStatus.inProgress:
        bg = const Color(0xFFFEF8E7);
        fg = const Color(0xFFD98205);
        icon = Icons.autorenew_rounded;
        break;
      case HandlingStatus.completed:
        bg = const Color(0xFFE8F8F0);
        fg = AppColors.success;
        icon = Icons.task_alt_rounded;
        break;
      case HandlingStatus.rejected:
        bg = const Color(0xFFFDECEE);
        fg = AppColors.danger;
        icon = Icons.cancel_outlined;
        break;
      case HandlingStatus.cancelled:
        bg = const Color(0xFFF1F3F9);
        fg = AppColors.textSecondary;
        icon = Icons.block_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
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

/// Distinct badge for publication_state (Menunggu Review, Dipublikasikan, Ditahan, Diarsipkan)
class PublicationStateBadge extends StatelessWidget {
  const PublicationStateBadge({super.key, required this.state});

  final PublicationState state;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label = state.label;

    switch (state) {
      case PublicationState.pendingReview:
        bg = const Color(0xFFFEF8E7);
        fg = const Color(0xFFD98205);
        icon = Icons.hourglass_empty_rounded;
        break;
      case PublicationState.published:
        bg = const Color(0xFFE8F8F0);
        fg = AppColors.success;
        icon = Icons.public_rounded;
        break;
      case PublicationState.held:
        bg = const Color(0xFFFDECEE);
        fg = AppColors.danger;
        icon = Icons.flag_rounded;
        break;
      case PublicationState.archived:
        bg = const Color(0xFFF1F3F9);
        fg = AppColors.textSecondary;
        icon = Icons.archive_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
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
