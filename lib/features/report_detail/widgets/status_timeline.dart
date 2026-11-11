import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/report_model.dart';

/// Visual timeline of report handling status per DESIGN.md Section 4.5 & 5.6
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primaryOf(context);
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final borderSubtle = AppColors.borderSubtleOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.danger;
    final dangerSubtle = isDark ? AppColors.darkDangerSubtle : AppColors.dangerSubtle;
    final dangerBorder = isDark ? dangerColor.withValues(alpha: 0.3) : const Color(0xFFFECACA);
    final successColor = isDark ? AppColors.darkSuccess : AppColors.success;
    final successSubtle = isDark ? AppColors.darkSuccessSubtle : AppColors.successSubtle;
    final successBorder = isDark ? successColor.withValues(alpha: 0.3) : const Color(0xFFBBF7D0);

    if (report.handlingStatus == HandlingStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dangerSubtle,
          borderRadius: AppRadius.borderSm,
          border: Border.all(color: dangerBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: dangerColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Laporan Ditolak',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: dangerColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.rejectionReason ??
                  'Laporan belum memenuhi kriteria kelayakan publik.',
              style: AppTextStyles.bodyOf(context),
            ),
          ],
        ),
      );
    }

    final steps = [
      {'title': 'Baru', 'status': HandlingStatus.newReport},
      {'title': 'Diterima', 'status': HandlingStatus.accepted},
      {'title': 'Diproses', 'status': HandlingStatus.inProgress},
      {'title': 'Selesai', 'status': HandlingStatus.completed},
    ];

    final int currentStepIndex = switch (report.handlingStatus) {
      HandlingStatus.accepted => 1,
      HandlingStatus.inProgress => 2,
      HandlingStatus.completed => 3,
      _ => 0,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progres Penanganan', style: AppTextStyles.sectionTitleOf(context)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length, (index) {
              final isPassed = index <= currentStepIndex;
              final isCurrent = index == currentStepIndex;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index == 0
                                ? Colors.transparent
                                : (isPassed
                                      ? primaryColor
                                      : borderSubtle),
                          ),
                        ),
                        // Circular status node per DESIGN.md Section 5.4
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isPassed
                                ? primaryColor
                                : surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isPassed
                                  ? primaryColor
                                  : borderColor,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: isPassed
                                ? const Icon(
                                    Icons.check,
                                    size: 15,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isPassed
                                          ? Colors.white
                                          : textSecondary,
                                    ),
                                  ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index == steps.length - 1
                                ? Colors.transparent
                                : (index < currentStepIndex
                                      ? primaryColor
                                      : borderSubtle),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index]['title'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isPassed
                            ? textPrimary
                            : textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          if (report.handlingStatus == HandlingStatus.completed &&
              report.completionNotes != null &&
              report.completionNotes!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: successSubtle,
                borderRadius: AppRadius.button,
                border: Border.all(color: successBorder, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: successColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Penyelesaian: ${report.completionNotes!}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
