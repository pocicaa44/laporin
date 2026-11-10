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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
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
      shape: const StadiumBorder(),
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

    final showStatusBadge =
        report.isDraft ||
        report.handlingStatus != HandlingStatus.newReport ||
        DateTime.now().difference(report.createdAt).inMinutes < 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: isHeld ? AppColors.danger : AppColors.border,
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
                          borderRadius: AppRadius.pill,
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
                      Flexible(
                        child: Text(
                          timeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
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
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // 3. Location Address
          Text(
            report.locationAddress,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
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
                color: const Color(0xFFFEF8E7),
                borderRadius: AppRadius.borderSm,
                border: Border.all(color: const Color(0xFFFDD888)),
              ),
              child: Text(
                'Moderasi: ${report.moderationReason}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFD98205),
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
                color: const Color(0xFFFEE2E2),
                borderRadius: AppRadius.borderSm,
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 14,
                    color: AppColors.danger,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Laporan telah dihapus oleh pelapor. Menunggu konfirmasi admin untuk hapus permanen.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.danger,
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
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),

          // 6. Action Buttons
          if (isFinalized)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDetailButton(context, controller),
                if (onDelete != null && !report.deletedByAdmin)
                  _buildDeleteButton(
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
                _buildDetailButton(context, controller),
                _buildUpdateStatusButton(),
                if (report.handlingStatus != HandlingStatus.completed)
                  _buildResolveButton(),
                if (isHeld) _buildRestorePublicationButton(),
                if (onDelete != null && !report.deletedByAdmin)
                  _buildDeleteButton(
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
  ) {
    return OutlinedButton.icon(
      icon: const Icon(
        Icons.visibility_outlined,
        size: 15,
        color: AppColors.primary,
      ),
      label: const Text('Detail'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
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

  Widget _buildUpdateStatusButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.tune_rounded, size: 15, color: AppColors.primary),
      label: const Text('Ubah Status'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: Color(0xFF9CA3AF), width: 1),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        minimumSize: const Size(0, 34),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      onPressed: onUpdateStatus,
    );
  }

  Widget _buildResolveButton() {
    return ElevatedButton.icon(
      icon: const Icon(
        Icons.check_circle_outline_rounded,
        size: 15,
        color: Colors.white,
      ),
      label: const Text('Selesaikan'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
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
          color: canDelete ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
        ),
        label: Text(isDeletedByUser ? 'Hapus Permanen' : 'Hapus'),
        style: OutlinedButton.styleFrom(
          foregroundColor: canDelete
              ? const Color(0xFFEF4444)
              : const Color(0xFF9CA3AF),
          side: BorderSide(
            color:
                canDelete ? const Color(0xFFFCA5A5) : const Color(0xFFD1D5DB),
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

  Widget _buildRestorePublicationButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.public_rounded, size: 15, color: Colors.white),
      label: const Text('Pulihkan Publikasi'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
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
