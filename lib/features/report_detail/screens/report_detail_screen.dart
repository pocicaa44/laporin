import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../admin/screens/admin_resolve_sheet.dart';
import '../../admin/screens/admin_status_update_sheet.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../edit_report/screens/edit_report_screen.dart';
import '../controllers/report_detail_controller.dart';
import '../widgets/comment_tile.dart';
import '../widgets/delete_report_dialog.dart';
import '../widgets/status_timeline.dart';
import '../widgets/vote_action_bar.dart';
import '../widgets/photo_viewer_dialog.dart';

/// Screen for report details and comment discussion thread per DESIGN.md Section 5.4
class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({
    super.key,
    required this.reportId,
    this.initialReport,
  });

  final String reportId;
  final ReportModel? initialReport;

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthController>().currentUser?.id;

    return ChangeNotifierProvider(
      create: (context) => ReportDetailController(
        reportId: reportId,
        reportRepository: context.read<ReportRepository>(),
        commentRepository: context.read<CommentRepository>(),
        initialReport: initialReport,
        currentUserId: currentUserId,
      ),
      child: const _ReportDetailView(),
    );
  }
}

class _ReportDetailView extends StatefulWidget {
  const _ReportDetailView();

  @override
  State<_ReportDetailView> createState() => _ReportDetailViewState();
}

class _ReportDetailViewState extends State<_ReportDetailView> {
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  CommentModel? _replyingToComment;
  final Set<String> _expandedThreadIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthController>();
        if (auth.isAdmin) {
          final detailController = context.read<ReportDetailController>();
          context.read<ReportRepository>().markReportAsViewedByAdmin(
            detailController.reportId,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _startReply(CommentModel targetComment) {
    setState(() {
      _replyingToComment = targetComment;
      final rootId = CommentThreadItem.findRootId(
        targetComment,
        context.read<ReportDetailController>().comments,
      );
      _expandedThreadIds.add(rootId);
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
    });
  }

  String _formatCommentCount(int count) {
    try {
      return NumberFormat('#,###', 'id_ID').format(count).replaceAll(',', '.');
    } catch (_) {
      return count.toString();
    }
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (!auth.isAuthenticated || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan masuk terlebih dahulu untuk mengirim komentar.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final controller = context.read<ReportDetailController>();
    final focusScope = FocusScope.of(context);
    final authorDisplayName = (user.username.trim().isNotEmpty)
        ? '@${user.username.trim().replaceFirst('@', '')}'
        : user.fullName;

    final authorAvatar =
        (user.avatarUrl != null && user.avatarUrl!.trim().isNotEmpty)
        ? user.avatarUrl
        : context.read<AuthController>().currentUser?.avatarUrl;

    final targetReply = _replyingToComment;

    controller
        .submitComment(
          authorId: user.id,
          authorName: authorDisplayName,
          authorAvatarUrl: authorAvatar,
          authorRole: user.role,
          body: text,
          parentCommentId: targetReply?.id,
        )
        .then((success) {
          if (!mounted) return;
          if (success) {
            _commentController.clear();
            focusScope.unfocus();
            setState(() {
              if (targetReply != null) {
                final rootId = CommentThreadItem.findRootId(
                  targetReply,
                  controller.comments,
                );
                _expandedThreadIds.add(rootId);
              }
              _replyingToComment = null;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  controller.errorMessage ??
                      'Gagal mengirim komentar. Silakan coba kembali.',
                ),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        });
  }

  void _openEditScreen(ReportModel currentReport) async {
    final updated = await Navigator.push<ReportModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditReportScreen(report: currentReport),
      ),
    );

    if (updated != null && mounted) {
      context.read<ReportDetailController>().setReport(updated);
    }
  }

  void _handleVote(String voteType) {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (!auth.isAuthenticated || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan masuk terlebih dahulu untuk memberikan dukungan atau tanggapan.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }
    context.read<ReportDetailController>().vote(user.id, voteType);
  }

  void _openPhotoViewer(List<String> urls, int initialIndex, {String? title}) {
    PhotoViewerDialog.show(
      context: context,
      photoUrls: urls,
      initialIndex: initialIndex,
      title: title,
    );
  }

  void _showDeleteDialog(
    ReportModel currentReport,
    String userId, {
    bool isAdmin = false,
  }) async {
    final isOtherPartyDeleted = isAdmin
        ? currentReport.deletedByUser
        : currentReport.deletedByAdmin;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteReportDialog(
        reportNumber: currentReport.reportNumber,
        isOtherPartyDeleted: isOtherPartyDeleted,
        onConfirmDelete: () => context
            .read<ReportDetailController>()
            .softDeleteReport(userId, isCallerAdmin: isAdmin),
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dihapus.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  void _handleToggleDiscussion(String userId) async {
    final controller = context.read<ReportDetailController>();
    final currentReport = controller.report;
    if (currentReport == null) return;

    final wasActive = currentReport.isDiscussionActive;
    final success = await controller.toggleDiscussion(userId: userId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasActive
                ? 'Diskusi telah dinonaktifkan. Pengguna lain tidak dapat menambah komentar.'
                : 'Diskusi berhasil diaktifkan kembali.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Gagal memperbarui status diskusi.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _handlePublishDraft(ReportModel currentReport) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publikasikan Laporan?'),
        content: const Text(
          'Laporan akan dipublikasikan ke publik dan diteruskan ke petugas untuk penanganan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publikasikan'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final controller = context.read<ReportDetailController>();
    final success = await controller.publishDraft();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dipublikasikan!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Gagal mempublikasikan laporan.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _openAdminStatusSheet(ReportModel currentReport) async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AdminStatusUpdateSheet(report: currentReport),
    );

    if (res != null && mounted) {
      try {
        final repo = context.read<ReportRepository>();
        final updated = await repo.updateHandlingStatus(
          reportId: currentReport.id,
          newStatus: res['status'] as HandlingStatus,
          reason: res['reason'] as String?,
        );
        if (mounted) {
          context.read<ReportDetailController>().setReport(updated);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status laporan berhasil diperbarui.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal memperbarui status: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _openAdminResolveSheet(ReportModel currentReport) async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AdminResolveSheet(report: currentReport),
    );

    if (res != null && mounted) {
      try {
        final repo = context.read<ReportRepository>();
        final updated = await repo.updateHandlingStatus(
          reportId: currentReport.id,
          newStatus: HandlingStatus.completed,
          reason: res['notes'] as String?,
          completionProofUrl: res['proofUrl'] as String?,
          completionProofType: 'completion_photo',
        );
        if (mounted) {
          context.read<ReportDetailController>().setReport(updated);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Laporan berhasil diselesaikan dengan bukti foto.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menyelesaikan laporan: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportDetailController>();
    final auth = context.watch<AuthController>();
    final report = controller.report;
    final currentUserId = auth.currentUser?.id ?? 'guest';

    // 1. Tampilkan loading spin saat proses pengambilan data dan data laporan belum ada
    if (controller.isLoading && report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Memuat detail laporan...',
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
        ),
      );
    }

    final isAdmin = auth.isAdmin;
    final isOwner = report?.authorId == currentUserId;
    final isDeletedForViewer =
        (isOwner && report?.deletedByUser == true) ||
        (isAdmin && report?.deletedByAdmin == true) ||
        (!isOwner && !isAdmin && report?.isDeleted == true);

    if (report == null || isDeletedForViewer) {
      final isDeleted =
          report != null &&
          (report.deletedByUser || report.deletedByAdmin || report.isDeleted);
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyState(
                  title: isDeleted
                      ? 'Laporan Telah Dihapus'
                      : 'Laporan Tidak Ditemukan',
                  message: isDeleted
                      ? 'Laporan ini telah dihapus dan tidak lagi aktif.'
                      : 'Laporan ini mungkin sedang diproses, telah dihapus, atau berada di luar batas akses.',
                ),
                const SizedBox(height: 16),
                if (isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Kembali'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => controller.loadData(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Muat Ulang'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final isFinalized =
        report.handlingStatus == HandlingStatus.completed ||
        report.handlingStatus == HandlingStatus.rejected;

    return Container(
      color: const Color(0xFFF0F2F5),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
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
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Kembali',
                onPressed: () => Navigator.of(context).pop(controller.report),
              ),
              title: Text(report.reportNumber),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: HandlingStatusBadge(
                      status: report.handlingStatus,
                      createdAt: report.createdAt,
                      isDraft: report.isDraft,
                    ),
                  ),
                ),
                if (isAdmin && !isFinalized) ...[
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: 'Kelola Status (Admin)',
                    onSelected: (val) {
                      if (val == 'update_status') {
                        _openAdminStatusSheet(report);
                      } else if (val == 'resolve') {
                        _openAdminResolveSheet(report);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'update_status',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text('Ubah Status'),
                          ],
                        ),
                      ),
                      if (report.handlingStatus != HandlingStatus.completed)
                        const PopupMenuItem(
                          value: 'resolve',
                          child: Row(
                            children: [
                              Icon(
                                Icons.task_alt,
                                size: 20,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 8),
                              Text('Selesaikan Laporan'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                if (isAdmin &&
                    !report.deletedByAdmin &&
                    report.canAdminDelete) ...[
                  IconButton(
                    icon: Icon(
                      report.deletedByUser
                          ? Icons.delete_forever_rounded
                          : Icons.delete_outline_rounded,
                      color: AppColors.danger,
                    ),
                    tooltip: report.deletedByUser
                        ? 'Hapus Permanen Laporan'
                        : 'Hapus Laporan',
                    onPressed: () =>
                        _showDeleteDialog(report, currentUserId, isAdmin: true),
                  ),
                ],
                if (isOwner && !report.deletedByUser) ...[
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    tooltip: 'Opsi Laporan',
                    onSelected: (val) {
                      if (val == 'edit') {
                        _openEditScreen(report);
                      } else if (val == 'publish_draft') {
                        _handlePublishDraft(report);
                      } else if (val == 'delete') {
                        _showDeleteDialog(report, currentUserId);
                      } else if (val == 'toggle_discussion') {
                        _handleToggleDiscussion(currentUserId);
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (report.isDraft)
                        const PopupMenuItem(
                          value: 'publish_draft',
                          child: Row(
                            children: [
                              Icon(
                                Icons.public_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Expanded(child: Text('Publikasikan Laporan')),
                            ],
                          ),
                        ),
                      if (!report.isTerminal)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Expanded(child: Text('Edit Laporan')),
                            ],
                          ),
                        ),
                      // Opsi Toggle Diskusi untuk Pemilik Laporan (bisa dinonaktifkan/diaktifkan)
                      if (report.handlingStatus != HandlingStatus.rejected)
                        PopupMenuItem(
                          value: 'toggle_discussion',
                          child: Row(
                            children: [
                              Icon(
                                report.isDiscussionActive
                                    ? Icons.comments_disabled_outlined
                                    : Icons.comment_outlined,
                                size: 20,
                                color: report.isDiscussionActive
                                    ? AppColors.textSecondary
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  report.isDiscussionActive
                                      ? 'Nonaktifkan Diskusi'
                                      : 'Aktifkan Diskusi',
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Skema Hapus Laporan: Hanya tampil jika status baru/pending, ditolak, atau selesai
                      if (report.canAuthorDelete)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: AppColors.danger,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hapus Laporan',
                                  style: TextStyle(color: AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ] else
                  const SizedBox(width: 12),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => controller.loadData(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Draft banner jika laporan masih dalam status draft
                        if (report.isDraft) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF8E7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFDD888),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.edit_note_rounded,
                                      color: Color(0xFFD98205),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Draft Laporan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Laporan ini masih disimpan sebagai draft dan belum dapat dilihat publik atau ditangani petugas.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF78350F),
                                    height: 1.35,
                                  ),
                                ),
                                if (isOwner) ...[
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(38),
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(
                                      Icons.public_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Publikasikan Sekarang',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () =>
                                        _handlePublishDraft(report),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // Banner pemberitahuan jika laporan sudah dihapus oleh pelapor
                        if (isAdmin && report.deletedByUser) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.person_off_outlined,
                                      color: AppColors.danger,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Laporan Telah Dihapus Oleh Pelapor',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Pelapor telah menghapus laporan ini dari akunnya. Tekan tombol di bawah untuk menghapus permanen dari database dan membersihkan media di server.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF991B1B),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(38),
                                    backgroundColor: AppColors.danger,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(
                                    Icons.delete_forever_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Hapus Permanen Laporan',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () => _showDeleteDialog(
                                    report,
                                    currentUserId,
                                    isAdmin: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Author Header & Category
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              UserAvatar(
                                name: report.authorName,
                                username: report.authorUsername,
                                avatarUrl: report.authorAvatarUrl,
                                radius: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report.displayAuthorUsername,
                                      style: AppTextStyles.label.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${report.authorName} • ${report.createdAt.toDisplayDateTime()}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  report.category,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryStrong,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(report.title, style: AppTextStyles.pageTitle),
                        const SizedBox(height: 8),

                        // Location row
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                report.locationAddress,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Photo gallery
                        if (report.photoUrls.isNotEmpty) ...[
                          _buildPhotoGallery(report.photoUrls),
                          const SizedBox(height: 16),
                        ],

                        // Description
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deskripsi Masalah',
                                style: AppTextStyles.sectionTitle,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                report.description,
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Status Timeline
                        StatusTimeline(report: report),
                        const SizedBox(height: 16),

                        // Admin Status Action Card
                        if (isAdmin) ...[
                          if (isFinalized)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Laporan ini telah ${report.handlingStatus.label.toLowerCase()} dan statusnya tidak dapat diubah lagi.',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: AppColors.danger,
                                    ),
                                    label: const Text('Hapus'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                      side: const BorderSide(
                                        color: Color(0xFFFCA5A5),
                                        width: 1,
                                      ),
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 0,
                                      ),
                                      minimumSize: const Size(0, 34),
                                      textStyle: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: () => _showDeleteDialog(
                                      report,
                                      currentUserId,
                                      isAdmin: true,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF8E7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFDD835),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings,
                                        size: 18,
                                        color: Color(0xFFD98205),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Aksi Penanganan Petugas',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFFD98205),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(
                                            Icons.edit_note_rounded,
                                            size: 17,
                                            color: AppColors.primary,
                                          ),
                                          label: const Text('Ubah Status'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: const BorderSide(
                                              color: Color(0xFF9CA3AF),
                                              width: 1,
                                            ),
                                            shape: const StadiumBorder(),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 0,
                                            ),
                                            minimumSize: const Size(0, 38),
                                            textStyle: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          onPressed: () =>
                                              _openAdminStatusSheet(report),
                                        ),
                                      ),
                                      if (report.handlingStatus !=
                                          HandlingStatus.completed) ...[
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            icon: const Icon(
                                              Icons
                                                  .check_circle_outline_rounded,
                                              size: 17,
                                              color: Colors.white,
                                            ),
                                            label: const Text('Selesaikan'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF10B981,
                                              ),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: const StadiumBorder(),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 0,
                                                  ),
                                              minimumSize: const Size(0, 38),
                                              textStyle: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            onPressed: () =>
                                                _openAdminResolveSheet(report),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],

                        // Completion Proof & Resolution Notes if completed
                        if (report.handlingStatus == HandlingStatus.completed &&
                            (report.completionProofUrl != null ||
                                (report.completionNotes != null &&
                                    report.completionNotes!
                                        .trim()
                                        .isNotEmpty))) ...[
                          Container(
                            key: const Key('completion_resolution_card'),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8F0),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      color: AppColors.success,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Penyelesaian Pekerjaan',
                                      style: AppTextStyles.sectionTitle,
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Selesai',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Catatan Penyelesaian Petugas
                                if (report.completionNotes != null &&
                                    report.completionNotes!
                                        .trim()
                                        .isNotEmpty) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.success.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons
                                                  .assignment_turned_in_outlined,
                                              size: 16,
                                              color: AppColors.success,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Catatan Penyelesaian:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          report.completionNotes!,
                                          key: const Key(
                                            'report_completion_notes_text',
                                          ),
                                          style: AppTextStyles.body.copyWith(
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (report.completionProofUrl != null)
                                    const SizedBox(height: 12),
                                ],

                                // Foto Bukti Pekerjaan Selesai
                                if (report.completionProofUrl != null) ...[
                                  const Text(
                                    'Foto Bukti Pekerjaan:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => _openPhotoViewer(
                                      [report.completionProofUrl!],
                                      0,
                                      title: 'Bukti Penyelesaian',
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            _buildPhoto(
                                              report.completionProofUrl!,
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.zoom_in_rounded,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Perbesar',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Upvote & Downvote actions (Only if report is active public)
                        if (report.isPubliclyVisible && !report.isTerminal)
                          VoteActionBar(
                            report: report,
                            isEnabled: report.isVotingActive,
                            disabledReason:
                                report.handlingStatus ==
                                    HandlingStatus.completed
                                ? 'Penilaian suara ditutup (Laporan Selesai)'
                                : null,
                            onUpvote: () => _handleVote('up'),
                            onDownvote: () => _handleVote('down'),
                          ),
                        const SizedBox(height: 24),

                        // Comments header: Komentar & Diskusi (2.586)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Komentar & Diskusi (${_formatCommentCount(controller.comments.length)})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (controller.isLoadingComments &&
                                controller.comments.isNotEmpty)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Comments list
                        Builder(
                          builder: (context) {
                            if (controller.isLoadingComments &&
                                controller.comments.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 36,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySoft
                                              .withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.8,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.primary,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Memuat komentar & diskusi...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (controller.comments.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'Belum ada komentar. Jadilah yang pertama menanggapi.',
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                              );
                            }

                            final threads = CommentThreadItem.buildThreads(
                              controller.comments,
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < threads.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 18),
                                  CommentThreadTile(
                                    thread: threads[i],
                                    reportAuthorId: report.authorId,
                                    isExpanded: _expandedThreadIds.contains(
                                      threads[i].root.id,
                                    ),
                                    onToggleExpanded: () {
                                      setState(() {
                                        if (_expandedThreadIds.contains(
                                          threads[i].root.id,
                                        )) {
                                          _expandedThreadIds.remove(
                                            threads[i].root.id,
                                          );
                                        } else {
                                          _expandedThreadIds.add(
                                            threads[i].root.id,
                                          );
                                        }
                                      });
                                    },
                                    onReply: _startReply,
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Comment Composer atau Banner Diskusi Ditutup
                if (report.isPubliclyVisible && !report.isTerminal)
                  report.canAddComment
                      ? Container(
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            border: Border(
                              top: BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Reply Header Banner (Membalas @username)
                                if (_replyingToComment != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    color: const Color(0xFFF3F4F6),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.reply_rounded,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: 'Membalas ',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF4B5563),
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      _replyingToComment!
                                                          .authorName
                                                          .trim()
                                                          .startsWith('@')
                                                      ? _replyingToComment!
                                                            .authorName
                                                            .trim()
                                                      : '@${_replyingToComment!.authorName.trim()}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: _cancelReply,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 16,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppColors.border,
                                  ),
                                ],

                                // Input Row
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _commentController,
                                          focusNode: _commentFocusNode,
                                          textInputAction: TextInputAction.send,
                                          onSubmitted: (_) => _sendComment(),
                                          decoration: InputDecoration(
                                            hintText: _replyingToComment != null
                                                ? 'Tulis balasan untuk ${_replyingToComment!.authorName.trim().startsWith('@') ? _replyingToComment!.authorName.trim() : '@${_replyingToComment!.authorName.trim()}'}...'
                                                : 'Tulis komentar atau tanggapan...',
                                            hintStyle: AppTextStyles.caption,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              borderSide: const BorderSide(
                                                color: AppColors.border,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              borderSide: const BorderSide(
                                                color: AppColors.border,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              borderSide: const BorderSide(
                                                color: AppColors.primary,
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: controller.isSendingComment
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.send_rounded,
                                                color: AppColors.primary,
                                              ),
                                        onPressed: controller.isSendingComment
                                            ? null
                                            : _sendComment,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            border: Border(
                              top: BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    report.handlingStatus ==
                                            HandlingStatus.completed
                                        ? (isOwner
                                              ? 'Diskusi dinonaktifkan (Laporan Selesai). Anda dapat mengaktifkannya kembali melalui menu opsi di atas.'
                                              : 'Diskusi telah dinonaktifkan karena laporan telah selesai.')
                                        : 'Diskusi telah dinonaktifkan oleh pemilik laporan.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGallery(List<String> urls) {
    if (urls.length == 1) {
      return GestureDetector(
        onTap: () => _openPhotoViewer(urls, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              AspectRatio(aspectRatio: 16 / 9, child: _buildPhoto(urls.first)),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Ketuk untuk perbesar',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openPhotoViewer(urls, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildPhoto(urls[index]),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.zoom_in_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${urls.length} foto lampiran (ketuk untuk perbesar & geser)',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildPhoto(String url) {
    return AppImage(
      imageSource: url,
      fit: BoxFit.cover,
      memCacheWidth: 1200,
      memCacheHeight: 675,
    );
  }
}
