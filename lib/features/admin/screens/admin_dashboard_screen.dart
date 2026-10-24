import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../core/widgets/access_denied_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../navigation/widgets/app_drawer.dart';
import '../../report_detail/screens/report_detail_screen.dart';
import '../../report_detail/widgets/delete_report_dialog.dart';
import '../controllers/admin_report_controller.dart';
import 'admin_resolve_sheet.dart';
import 'admin_status_update_sheet.dart';

/// Admin Dashboard & Moderation portal per PRD.md Section 4.3 & DESIGN.md Section 6
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    // Route guard: hanya akun admin yang berhak mengakses Panel
    if (!auth.isAdmin) {
      return AccessDeniedScreen(
        title: 'Akses Khusus Petugas',
        message: 'Panel Laporan hanya dapat diakses oleh akun dengan peran Petugas / Admin.',
        buttonText: 'Kembali ke Beranda',
        onButtonPressed: () => Navigator.of(context).pop(),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => AdminReportController(
        reportRepository: context.read<ReportRepository>(),
      ),
      child: _AdminDashboardView(isEmbedded: isEmbedded),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView({required this.isEmbedded});

  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminReportController>();

    return Container(
      color: const Color(0xFFF0F2F5),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 840),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border.symmetric(
              vertical: BorderSide(color: AppColors.border, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 24,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Scaffold(
            drawer: const AppDrawer(),
            appBar: AppBar(
              leading: isEmbedded ? const DrawerMenuButton() : null,
              automaticallyImplyLeading: !isEmbedded,
              title: const Text('Panel Laporan'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Segarkan Data',
                  onPressed: () => controller.fetchReports(),
                ),
              ],
            ),
            body: controller.isLoading && controller.reports.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => controller.fetchReports(),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // KPI Metric Cards
                        Row(
                          children: [
                            _MetricCard(
                              title: 'Total Laporan',
                              value: '${controller.totalReports}',
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            _MetricCard(
                              title: 'Diproses',
                              value: '${controller.inProgressCount}',
                              color: const Color(0xFFD98205),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _MetricCard(
                              title: 'Selesai',
                              value: '${controller.completedCount}',
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            _MetricCard(
                              title: 'Perlu Review',
                              value: '${controller.heldCount}',
                              color: AppColors.danger,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterChip(
                                label: 'Semua',
                                isSelected: controller.filter == 'all',
                                onTap: () => controller.setFilter('all'),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Perlu Review (${controller.heldCount})',
                                isSelected: controller.filter == 'held',
                                onTap: () => controller.setFilter('held'),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Baru',
                                isSelected: controller.filter == 'new',
                                onTap: () => controller.setFilter('new'),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Diproses',
                                isSelected: controller.filter == 'in_progress',
                                onTap: () =>
                                    controller.setFilter('in_progress'),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Selesai',
                                isSelected: controller.filter == 'completed',
                                onTap: () => controller.setFilter('completed'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reports List
                        if (controller.reports.isEmpty)
                          const EmptyState(
                            title: 'Tidak Ada Laporan',
                            message:
                                'Tidak ada laporan dalam kategori filter ini.',
                          )
                        else
                          ...controller.reports.map(
                            (report) => _AdminReportCard(
                              report: report,
                              onDelete: () async {
                                final auth = context.read<AuthController>();
                                final adminId = auth.currentUser?.id ?? 'admin';
                                final deleted = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => DeleteReportDialog(
                                    reportNumber: report.reportNumber,
                                    onConfirmDelete: () =>
                                        controller.deleteReport(
                                          reportId: report.id,
                                          adminId: adminId,
                                        ),
                                  ),
                                );
                                if (deleted == true && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Laporan ${report.reportNumber} berhasil dihapus.',
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                              onUpdateStatus: () async {
                                final res =
                                    await showModalBottomSheet<
                                      Map<String, dynamic>
                                    >(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (_) => AdminStatusUpdateSheet(
                                        report: report,
                                      ),
                                    );
                                if (res != null && context.mounted) {
                                  final success = await controller.updateStatus(
                                    reportId: report.id,
                                    newStatus: res['status'] as HandlingStatus,
                                    reason: res['reason'] as String?,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Status laporan berhasil diperbarui.'
                                              : (controller.errorMessage ??
                                                    'Gagal memperbarui status laporan. Coba lagi.'),
                                        ),
                                        backgroundColor: success
                                            ? AppColors.success
                                            : AppColors.danger,
                                      ),
                                    );
                                  }
                                }
                              },
                              onResolve: () async {
                                final res =
                                    await showModalBottomSheet<
                                      Map<String, dynamic>
                                    >(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (_) =>
                                          AdminResolveSheet(report: report),
                                    );
                                if (res != null && context.mounted) {
                                  final success = await controller.updateStatus(
                                    reportId: report.id,
                                    newStatus: HandlingStatus.completed,
                                    reason: res['notes'] as String?,
                                    proofUrl: res['proofUrl'] as String?,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Laporan berhasil diselesaikan dengan bukti foto.'
                                              : (controller.errorMessage ??
                                                    'Gagal menyelesaikan laporan. Coba lagi.'),
                                        ),
                                        backgroundColor: success
                                            ? AppColors.success
                                            : AppColors.danger,
                                      ),
                                    );
                                  }
                                }
                              },
                              onRestorePublication: () async {
                                final success = await controller
                                    .restorePublication(
                                      report.id,
                                      'Laporan telah ditinjau ulang oleh petugas dan dinyatakan valid.',
                                    );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Publikasi laporan berhasil dipulihkan.'
                                            : (controller.errorMessage ??
                                                  'Gagal memulihkan publikasi laporan.'),
                                      ),
                                      backgroundColor: success
                                          ? AppColors.success
                                          : AppColors.danger,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [AppColors.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  const _AdminReportCard({
    required this.report,
    required this.onUpdateStatus,
    required this.onResolve,
    required this.onRestorePublication,
    this.onDelete,
  });

  final ReportModel report;
  final VoidCallback onUpdateStatus;
  final VoidCallback onResolve;
  final VoidCallback onRestorePublication;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isHeld = report.publicationState == PublicationState.held;
    final isFinalized =
        report.handlingStatus == HandlingStatus.completed ||
        report.handlingStatus == HandlingStatus.rejected;
    final controller = context.watch<AdminReportController?>();
    final isViewed = controller?.isReportViewed(report.id) ?? false;
    final timeLabel = report.createdAt.toReportTimeLabel(
      isAdmin: true,
      isViewedByAdmin: isViewed,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHeld ? AppColors.danger : AppColors.border,
          width: isHeld ? 1.5 : 1,
        ),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    report.reportNumber,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (timeLabel == 'Baru')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Baru',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    Text(
                      timeLabel,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                ],
              ),
              Row(
                children: [
                  PublicationStateBadge(state: report.publicationState),
                  const SizedBox(width: 6),
                  HandlingStatusBadge(
                    status: report.handlingStatus,
                    createdAt: report.createdAt,
                    isDraft: report.isDraft,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(report.title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          Text(report.locationAddress, style: AppTextStyles.caption),
          if (report.moderationReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF8E7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Moderasi: ${report.moderationReason}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFD98205)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          if (isFinalized)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Detail'),
                  onPressed: () async {
                    controller?.markReportAsViewed(report.id);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailScreen(
                          reportId: report.id,
                          initialReport: report,
                        ),
                      ),
                    );
                    controller?.fetchReports(forceRefresh: true);
                  },
                ),
                if (onDelete != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Hapus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    onPressed: onDelete,
                  ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Detail'),
                  onPressed: () async {
                    controller?.markReportAsViewed(report.id);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailScreen(
                          reportId: report.id,
                          initialReport: report,
                        ),
                      ),
                    );
                    controller?.fetchReports(forceRefresh: true);
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Ubah Status'),
                  onPressed: onUpdateStatus,
                ),
                if (report.handlingStatus != HandlingStatus.completed)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.task_alt, size: 16),
                    label: const Text('Selesaikan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: onResolve,
                  ),
                if (isHeld)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.public, size: 16),
                    label: const Text('Pulihkan Publikasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: onRestorePublication,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
