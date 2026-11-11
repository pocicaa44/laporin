import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/offline_fallback_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../core/widgets/access_denied_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../../navigation/widgets/app_drawer.dart';
import '../../report_detail/screens/report_detail_screen.dart';
import '../../report_detail/widgets/delete_report_dialog.dart';
import '../controllers/admin_report_controller.dart';
import '../widgets/admin_province_filter_dropdown.dart';
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

class _AdminDashboardView extends StatefulWidget {
  const _AdminDashboardView({required this.isEmbedded});

  final bool isEmbedded;

  @override
  State<_AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<_AdminDashboardView> {
  int? _lastNavChangeCount;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isEmbedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AdminReportController>().fetchReports(
            forceRefresh: true,
          );
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final isOnline = context.isOnline;
      if (_wasOffline && isOnline) {
        _wasOffline = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<AdminReportController>().fetchReports(
              forceRefresh: true,
            );
          }
        });
      } else if (!isOnline) {
        _wasOffline = true;
      }
    } catch (_) {}

    if (widget.isEmbedded) {
      try {
        final nav = context.watch<NavigationController>();
        if (nav.currentIndex == 1 &&
            _lastNavChangeCount != nav.tabChangeCount) {
          _lastNavChangeCount = nav.tabChangeCount;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<AdminReportController>().fetchReports(
                forceRefresh: true,
              );
            }
          });
        } else {
          _lastNavChangeCount = nav.tabChangeCount;
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminReportController>();
    final isOnline = context.isOnline;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      color: isDark ? AppColors.darkBackground : const Color(0xFFF0F2F5),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 840),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.symmetric(
              vertical: BorderSide(color: borderColor, width: 1),
            ),
          ),
          child: Scaffold(
            drawer: const AppDrawer(),
            appBar: AppBar(
              leading: widget.isEmbedded ? const DrawerMenuButton() : null,
              automaticallyImplyLeading: !widget.isEmbedded,
              title: const Text('Panel Laporan'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Segarkan Data',
                  onPressed: () => controller.fetchReports(forceRefresh: true),
                ),
              ],
            ),
            body: controller.isLoading && controller.reports.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => controller.fetchReports(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Dropdown Filter Wilayah Provinsi (Task 3)
                        AdminProvinceFilterDropdown(controller: controller),
                        const SizedBox(height: 12),

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
                              title: 'Baru',
                              value: '${controller.newCount}',
                              color: const Color(0xFF2563EB),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _MetricCard(
                              title: 'Diproses',
                              value: '${controller.inProgressCount}',
                              color: const Color(0xFFD98205),
                            ),
                            const SizedBox(width: 8),
                            _MetricCard(
                              title: 'Selesai',
                              value: '${controller.completedCount}',
                              color: AppColors.success,
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
                                label: 'Baru (${controller.newCount})',
                                isSelected: controller.filter == 'new',
                                onTap: () => controller.setFilter('new'),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Diterima (${controller.acceptedCount})',
                                isSelected: controller.filter == 'accepted',
                                onTap: () => controller.setFilter('accepted'),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label:
                                    'Diproses (${controller.inProgressCount})',
                                isSelected: controller.filter == 'in_progress',
                                onTap: () =>
                                    controller.setFilter('in_progress'),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Selesai (${controller.completedCount})',
                                isSelected: controller.filter == 'completed',
                                onTap: () => controller.setFilter('completed'),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Ditolak (${controller.rejectedCount})',
                                isSelected: controller.filter == 'rejected',
                                onTap: () => controller.setFilter('rejected'),
                              ),
                              if (controller.deletedByUserCount > 0) ...[
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label:
                                      'Dihapus Pelapor (${controller.deletedByUserCount})',
                                  isSelected:
                                      controller.filter == 'deleted_by_user',
                                  onTap: () =>
                                      controller.setFilter('deleted_by_user'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reports List
                        if (controller.reports.isEmpty)
                          (!isOnline
                              ? OfflineFallbackView(
                                  onRetry: () => controller.fetchReports(
                                    forceRefresh: true,
                                  ),
                                )
                              : const EmptyState(
                                  title: 'Tidak Ada Laporan',
                                  message: 'Tidak ada laporan dalam kategori filter ini.',
                                ))
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
                                    isOtherPartyDeleted: report.deletedByUser,
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
                                        borderRadius: AppRadius.sheet,
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
                                        borderRadius: AppRadius.sheet,
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
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final textMuted = AppColors.textMutedOf(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: AppRadius.card,
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.1,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primaryOf(context);
    final surfaceColor = AppColors.surfaceOf(context);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: primaryColor,
      backgroundColor: surfaceColor,
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? Colors.transparent : borderColor,
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final borderSubtle = AppColors.borderSubtleOf(context);
    final primaryColor = AppColors.primaryOf(context);
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.danger;
    final dangerSubtle = isDark ? AppColors.darkDangerSubtle : const Color(0xFFFEE2E2);
    final dangerBorder = isDark ? dangerColor.withValues(alpha: 0.3) : const Color(0xFFFCA5A5);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final successColor = isDark ? AppColors.darkSuccess : AppColors.success;

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

    final showStatusBadge =
        report.isDraft ||
        report.handlingStatus != HandlingStatus.newReport ||
        DateTime.now().difference(report.createdAt).inMinutes < 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: isHeld ? dangerColor : borderColor,
          width: isHeld ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Report Number & Time (Left) | Status & Publication Badges (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      report.reportNumber,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
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
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: AppRadius.pill,
                        ),
                        child: Text(
                          'Baru',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showStatusBadge) ...[
                    HandlingStatusBadge(
                      status: report.handlingStatus,
                      createdAt: report.createdAt,
                      isDraft: report.isDraft,
                    ),
                    const SizedBox(width: 6),
                  ],
                  PublicationStateBadge(
                    state: report.publicationState,
                    isDraft: report.isDraft,
                    iconOnly: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 2. Title
          Text(
            report.title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // 3. Location Address
          Text(
            report.locationAddress,
            style: TextStyle(
              fontSize: 12.5,
              color: textSecondary,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // 4. Moderation Reason if any
          if (report.moderationReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkWarningSubtle : const Color(0xFFFEF8E7),
                borderRadius: AppRadius.borderSm,
                border: Border.all(
                  color: isDark ? AppColors.darkWarning.withValues(alpha: 0.3) : const Color(0xFFFDD888),
                ),
              ),
              child: Text(
                'Moderasi: ${report.moderationReason}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkWarningText : const Color(0xFFD98205),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (report.deletedByUser) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: dangerSubtle,
                borderRadius: AppRadius.borderSm,
                border: Border.all(color: dangerBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 14,
                    color: dangerColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Laporan telah dihapus oleh pelapor. Menunggu konfirmasi admin untuk hapus permanen.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: dangerColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // 5. Divider
          Divider(height: 1, thickness: 1, color: borderSubtle),
          const SizedBox(height: 12),

          // 6. Action Buttons
          if (isFinalized)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDetailButton(context, controller, primaryColor),
                if (onDelete != null && !report.deletedByAdmin)
                  _buildDeleteButton(
                    dangerColor: dangerColor,
                    dangerBorder: dangerBorder,
                    disabledColor: textSecondary,
                    isDeletedByUser: report.deletedByUser,
                    canDelete: report.canAdminDelete,
                  ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDetailButton(context, controller, primaryColor),
                _buildUpdateStatusButton(primaryColor),
                if (report.handlingStatus != HandlingStatus.completed)
                  _buildResolveButton(successColor),
                if (isHeld) _buildRestorePublicationButton(primaryColor),
                if (onDelete != null && !report.deletedByAdmin)
                  _buildDeleteButton(
                    dangerColor: dangerColor,
                    dangerBorder: dangerBorder,
                    disabledColor: textSecondary,
                    isDeletedByUser: report.deletedByUser,
                    canDelete: report.canAdminDelete,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailButton(
    BuildContext context,
    AdminReportController? controller,
    Color primaryColor,
  ) {
    return OutlinedButton.icon(
      icon: Icon(
        Icons.visibility_outlined,
        size: 15,
        color: primaryColor,
      ),
      label: const Text('Detail'),
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: Color(0xFF9CA3AF), width: 1),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        minimumSize: const Size(0, 34),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      onPressed: () async {
        controller?.markReportAsViewed(report.id);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ReportDetailScreen(reportId: report.id, initialReport: report),
          ),
        );
        controller?.fetchReports(forceRefresh: true);
      },
    );
  }

  Widget _buildUpdateStatusButton(Color primaryColor) {
    return OutlinedButton.icon(
      icon: Icon(Icons.tune_rounded, size: 15, color: primaryColor),
      label: const Text('Ubah Status'),
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: Color(0xFF9CA3AF), width: 1),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        minimumSize: const Size(0, 34),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      onPressed: onUpdateStatus,
    );
  }

  Widget _buildResolveButton(Color successColor) {
    return ElevatedButton.icon(
      icon: const Icon(
        Icons.check_circle_outline_rounded,
        size: 15,
        color: Colors.white,
      ),
      label: const Text('Selesaikan'),
      style: ElevatedButton.styleFrom(
        backgroundColor: successColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        minimumSize: const Size(0, 34),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      onPressed: onResolve,
    );
  }

  Widget _buildDeleteButton({
    required Color dangerColor,
    required Color dangerBorder,
    required Color disabledColor,
    bool isDeletedByUser = false,
    bool canDelete = true,
  }) {
    final tooltip = canDelete
        ? (isDeletedByUser ? 'Hapus Permanen Laporan' : 'Hapus Laporan')
        : (report.cannotAdminDeleteReason ??
            'Laporan belum dihapus oleh pelapor');

    return Tooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        icon: Icon(
          isDeletedByUser
              ? Icons.delete_forever_rounded
              : Icons.delete_outline_rounded,
          size: 15,
          color: canDelete ? dangerColor : disabledColor,
        ),
        label: Text(isDeletedByUser ? 'Hapus Permanen' : 'Hapus'),
        style: OutlinedButton.styleFrom(
          foregroundColor: canDelete ? dangerColor : disabledColor,
          side: BorderSide(
            color: canDelete ? dangerBorder : const Color(0xFFD1D5DB),
            width: 1,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          minimumSize: const Size(0, 34),
          textStyle:
              const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        onPressed: canDelete ? onDelete : null,
      ),
    );
  }

  Widget _buildRestorePublicationButton(Color primaryColor) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.public_rounded, size: 15, color: Colors.white),
      label: const Text('Pulihkan Publikasi'),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        minimumSize: const Size(0, 34),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      onPressed: onRestorePublication,
    );
  }
}
