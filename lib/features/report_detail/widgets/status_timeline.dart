import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/report_model.dart';

/// Visual timeline of report handling status per DESIGN.md Section 4.5 & 5.6
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    if (report.handlingStatus == HandlingStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cancel, color: AppColors.danger, size: 20),
                SizedBox(width: 8),
                Text(
                  'Laporan Ditolak',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.rejectionReason ??
                  'Laporan belum memenuhi kriteria kelayakan publik.',
              style: AppTextStyles.body,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progres Penanganan', style: AppTextStyles.sectionTitle),
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
                            height: 3,
                            color: index == 0
                                ? Colors.transparent
                                : (isPassed
                                      ? AppColors.primary
                                      : AppColors.border),
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPassed
                                ? AppColors.primary
                                : AppColors.surface,
                            border: Border.all(
                              color: isPassed
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: isPassed
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 3,
                            color: index == steps.length - 1
                                ? Colors.transparent
                                : (index < currentStepIndex
                                      ? AppColors.primary
                                      : AppColors.border),
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
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
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
                color: const Color(0xFFE8F8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Penyelesaian: ${report.completionNotes!}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
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
