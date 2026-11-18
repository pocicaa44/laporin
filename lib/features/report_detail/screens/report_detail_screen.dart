import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_profile_bar.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/offline_fallback_view.dart';
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
import 'report_map_viewer_screen.dart';
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
  bool _wasOffline = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final isOnline = context.isOnline;
      if (_wasOffline && isOnline) {
        _wasOffline = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<ReportDetailController>().loadData();
          }
        });
      } else if (!isOnline) {
        _wasOffline = true;
      }
    } catch (_) {}
  }

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
    AppToast.dismiss();
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

  Future<void> _handleDeleteComment(CommentModel comment) async {
    if (!context.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hapus komentar tidak dapat dilakukan saat offline.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Komentar?'),
        content: const Text('Apakah Anda yakin ingin menghapus komentar ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final controller = context.read<ReportDetailController>();
    final auth = context.read<AuthController>();
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    final success = await controller.deleteComment(
      commentId: comment.id,
      userId: userId,
      isCallerAdmin: auth.isAdmin,
    );

    if (!mounted) return;
    if (success) {
      if (_replyingToComment?.id == comment.id) {
        setState(() {
          _replyingToComment = null;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komentar berhasil dihapus'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Gagal menghapus komentar'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  String _formatCommentCount(int count) {
    try {
      return NumberFormat('#,###', 'id_ID').format(count).replaceAll(',', '.');
    } catch (_) {
      return count.toString();
    }
  }

  void _sendComment() {
    if (!context.isOnline) return;
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
            AppToast.show(
              context,
              message: 'komentar diposting',
              duration: const Duration(seconds: 3),
            );
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
    if (!currentReport.canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentReport.cannotEditReason ??
                'Laporan dengan status ini tidak dapat diedit.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (!context.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Edit laporan tidak dapat dilakukan saat offline.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
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
    if (!context.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Dukungan atau tanggapan tidak dapat diberikan saat offline.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
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
    if (!context.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hapus laporan tidak dapat dilakukan saat offline.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
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
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
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
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
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
    final isOnline = context.isOnline;
    final auth = context.watch<AuthController>();
    final report = controller.report;
    final currentUserId = auth.currentUser?.id ?? 'guest';

    if (report == null && !isOnline && !controller.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: OfflineFallbackView(onRetry: () => controller.loadData()),
      );
    }

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primaryOf(context);
    final surfaceColor = AppColors.surfaceOf(context);
    final bgColor = AppColors.backgroundOf(context);
    final borderColor = AppColors.borderOf(context);
    final borderSubtle = AppColors.borderSubtleOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final textBody = AppColors.textBodyOf(context);
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.danger;
    final dangerSubtle = isDark ? AppColors.darkDangerSubtle : AppColors.dangerSubtle;
    final dangerBorder = isDark ? dangerColor.withValues(alpha: 0.3) : const Color(0xFFFECACA);
    final warningSubtle = isDark ? AppColors.darkWarningSubtle : const Color(0xFFFFFBEB);
    final warningBorder = isDark ? (AppColors.darkWarning.withValues(alpha: 0.3)) : const Color(0xFFFDE68A);
    final warningText = isDark ? AppColors.darkWarningText : const Color(0xFFB45309);
    final successColor = isDark ? AppColors.darkSuccess : AppColors.success;
    final successSubtle = isDark ? AppColors.darkSuccessSubtle : AppColors.successSubtle;
    final successBorder = isDark ? successColor.withValues(alpha: 0.3) : const Color(0xFFBBF7D0);
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    return Container(
      color: isDark ? AppColors.darkBackground : const Color(0xFFF0F2F5),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1280 : 720),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.symmetric(
              vertical: BorderSide(color: borderColor, width: 1),
            ),
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
                      PopupMenuItem(
                        value: 'update_status',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              size: 20,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text('Ubah Status'),
                          ],
                        ),
                      ),
                      if (report.handlingStatus != HandlingStatus.completed)
                        PopupMenuItem(
                          value: 'resolve',
                          child: Row(
                            children: [
                              Icon(
                                Icons.task_alt,
                                size: 20,
                                color: successColor,
                              ),
                              const SizedBox(width: 8),
                              const Text('Selesaikan Laporan'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                if (isAdmin && !report.deletedByAdmin) ...[
                  Tooltip(
                    message: report.canAdminDelete
                        ? (report.deletedByUser
                            ? 'Hapus Permanen Laporan'
                            : 'Hapus Laporan')
                        : (report.cannotAdminDeleteReason ??
                            'Laporan belum dihapus oleh pelapor'),
                    child: IconButton(
                      icon: Icon(
                        report.deletedByUser
                            ? Icons.delete_forever_rounded
                            : Icons.delete_outline_rounded,
                        color: report.canAdminDelete
                            ? dangerColor
                            : textSecondary,
                      ),
                      onPressed: report.canAdminDelete
                          ? () => _showDeleteDialog(
                              report,
                              currentUserId,
                              isAdmin: true,
                            )
                          : null,
                    ),
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
                        PopupMenuItem(
                          value: 'publish_draft',
                          child: Row(
                            children: [
                              Icon(
                                Icons.public_rounded,
                                size: 20,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(child: Text('Publikasikan Laporan')),
                            ],
                          ),
                        ),
                      // Opsi Edit Laporan (Task 1: Disabled jika selesai atau ditolak)
                      if (!report.isDeleted &&
                          report.handlingStatus != HandlingStatus.cancelled)
                        PopupMenuItem<String>(
                          value: report.canEdit ? 'edit' : 'edit_disabled',
                          enabled: report.canEdit,
                          child: Tooltip(
                            message: report.cannotEditReason ?? 'Edit Laporan',
                            child: Row(
                              children: [
                                Icon(
                                  report.canEdit
                                      ? Icons.edit_outlined
                                      : Icons.edit_off_outlined,
                                  size: 20,
                                  color: report.canEdit
                                      ? primaryColor
                                      : textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Edit Laporan',
                                        style: TextStyle(
                                          color: report.canEdit
                                              ? null
                                              : textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (!report.canEdit &&
                                          report.cannotEditReason != null)
                                        Text(
                                          report.cannotEditReason!,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Opsi Toggle Diskusi untuk Pemilik Laporan (bisa dinonaktifkan/diaktifkan)
                      if (!report.isPrivate &&
                          report.handlingStatus != HandlingStatus.rejected)
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
                                    ? textSecondary
                                    : primaryColor,
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
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: dangerColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hapus Laporan',
                                  style: TextStyle(color: dangerColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ] else
                  const SizedBox(width: 12),
                if (isDesktop) const AppProfileBar(),
              ],
            ),
            body: isDesktop
                ? (report.isPrivate
                    ? Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: RefreshIndicator(
                            onRefresh: () => controller.loadData(),
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                              children: _buildReportDetailItems(
                                report: report,
                                controller: controller,
                                auth: auth,
                                isDark: isDark,
                                primaryColor: primaryColor,
                                surfaceColor: surfaceColor,
                                borderColor: borderColor,
                                borderSubtle: borderSubtle,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                textBody: textBody,
                                dangerColor: dangerColor,
                                dangerSubtle: dangerSubtle,
                                dangerBorder: dangerBorder,
                                warningSubtle: warningSubtle,
                                warningBorder: warningBorder,
                                warningText: warningText,
                                successColor: successColor,
                                successSubtle: successSubtle,
                                successBorder: successBorder,
                                isOwner: isOwner,
                                isAdmin: isAdmin,
                                isFinalized: isFinalized,
                                currentUserId: currentUserId,
                                isOnline: isOnline,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. BAGIAN KIRI: Detail Laporan, Progress, dan Vote (flex: 6)
                          Expanded(
                            flex: 6,
                            child: RefreshIndicator(
                              onRefresh: () => controller.loadData(),
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(24, 20, 20, 32),
                                children: _buildReportDetailItems(
                                  report: report,
                                  controller: controller,
                                  auth: auth,
                                  isDark: isDark,
                                  primaryColor: primaryColor,
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                  borderSubtle: borderSubtle,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  textBody: textBody,
                                  dangerColor: dangerColor,
                                  dangerSubtle: dangerSubtle,
                                  dangerBorder: dangerBorder,
                                  warningSubtle: warningSubtle,
                                  warningBorder: warningBorder,
                                  warningText: warningText,
                                  successColor: successColor,
                                  successSubtle: successSubtle,
                                  successBorder: successBorder,
                                  isOwner: isOwner,
                                  isAdmin: isAdmin,
                                  isFinalized: isFinalized,
                                  currentUserId: currentUserId,
                                  isOnline: isOnline,
                                ),
                              ),
                            ),
                          ),

                          // Garis pemisah vertikal antar kolom
                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: borderColor,
                          ),

                          // 2. BAGIAN KANAN: Section Diskusi dan Komentar (flex: 5)
                          Expanded(
                            flex: 5,
                            child: Container(
                              color: surfaceColor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Header Diskusi
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(20, 18, 20, 14),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.chat_bubble_outline_rounded,
                                              size: 18,
                                              color: primaryColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Diskusi & Komentar (${_formatCommentCount(controller.comments.length)})',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (controller.isLoadingComments &&
                                            controller.comments.isNotEmpty)
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                primaryColor,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: borderSubtle,
                                  ),

                                  // Area Komentar Scrollable
                                  Expanded(
                                    child: _buildDesktopCommentsContent(
                                      controller: controller,
                                      report: report,
                                      auth: auth,
                                      isDark: isDark,
                                      primaryColor: primaryColor,
                                      textPrimary: textPrimary,
                                      textSecondary: textSecondary,
                                      borderSubtle: borderSubtle,
                                    ),
                                  ),

                                  // Composer Komentar di bagian bawah panel kanan
                                  _buildCommentComposer(
                                    report: report,
                                    controller: controller,
                                    isDark: isDark,
                                    primaryColor: primaryColor,
                                    surfaceColor: surfaceColor,
                                    borderColor: borderColor,
                                    textSecondary: textSecondary,
                                    isOnline: isOnline,
                                    currentUserId: currentUserId,
                                    isOwner: isOwner,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ))
                : Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => controller.loadData(),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            children: [
                              ..._buildReportDetailItems(
                                report: report,
                                controller: controller,
                                auth: auth,
                                isDark: isDark,
                                primaryColor: primaryColor,
                                surfaceColor: surfaceColor,
                                borderColor: borderColor,
                                borderSubtle: borderSubtle,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                textBody: textBody,
                                dangerColor: dangerColor,
                                dangerSubtle: dangerSubtle,
                                dangerBorder: dangerBorder,
                                warningSubtle: warningSubtle,
                                warningBorder: warningBorder,
                                warningText: warningText,
                                successColor: successColor,
                                successSubtle: successSubtle,
                                successBorder: successBorder,
                                isOwner: isOwner,
                                isAdmin: isAdmin,
                                isFinalized: isFinalized,
                                currentUserId: currentUserId,
                                isOnline: isOnline,
                              ),
                              if (!report.isPrivate) ...[
                                const SizedBox(height: 24),

                                // Comments header: Komentar & Diskusi
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Komentar & Diskusi (${_formatCommentCount(controller.comments.length)})',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    if (controller.isLoadingComments &&
                                        controller.comments.isNotEmpty)
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            primaryColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                _buildMobileCommentsContent(
                                  controller: controller,
                                  report: report,
                                  auth: auth,
                                  isDark: isDark,
                                  primaryColor: primaryColor,
                                  textSecondary: textSecondary,
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                  borderSubtle: borderSubtle,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Comment Composer di bagian bawah layar mobile (hanya jika bukan laporan privat)
                      if (!report.isPrivate)
                        _buildCommentComposer(
                          report: report,
                          controller: controller,
                          isDark: isDark,
                          primaryColor: primaryColor,
                          surfaceColor: surfaceColor,
                          borderColor: borderColor,
                          textSecondary: textSecondary,
                          isOnline: isOnline,
                          currentUserId: currentUserId,
                          isOwner: isOwner,
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Membangun seluruh item detail laporan, progress, dan vote (digunakan di kiri pada desktop, dan di atas pada mobile)
  List<Widget> _buildReportDetailItems({
    required ReportModel report,
    required ReportDetailController controller,
    required AuthController auth,
    required bool isDark,
    required Color primaryColor,
    required Color surfaceColor,
    required Color borderColor,
    required Color borderSubtle,
    required Color textPrimary,
    required Color textSecondary,
    required Color textBody,
    required Color dangerColor,
    required Color dangerSubtle,
    required Color dangerBorder,
    required Color warningSubtle,
    required Color warningBorder,
    required Color warningText,
    required Color successColor,
    required Color successSubtle,
    required Color successBorder,
    required bool isOwner,
    required bool isAdmin,
    required bool isFinalized,
    required String currentUserId,
    required bool isOnline,
  }) {
    return [
      // 1. Draft banner jika laporan masih dalam status draft
      if (report.isDraft) ...[
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: warningSubtle,
            borderRadius: AppRadius.borderSm,
            border: Border.all(
              color: warningBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: warningText,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Draft Laporan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: warningText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Laporan ini masih disimpan sebagai draft dan belum dapat dilihat publik atau ditangani petugas.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF78350F),
                  height: 1.35,
                ),
              ),
              if (isOwner) ...[
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(38),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.button,
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
                  onPressed: () => _handlePublishDraft(report),
                ),
              ],
            ],
          ),
        ),
      ],

      // 2. Banner pemberitahuan jika laporan sudah dihapus oleh pelapor
      if (isAdmin && report.deletedByUser) ...[
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dangerSubtle,
            borderRadius: AppRadius.borderSm,
            border: Border.all(
              color: dangerBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    color: dangerColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Laporan Telah Dihapus Oleh Pelapor',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: dangerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Pelapor telah menghapus laporan ini dari akunnya. Tekan tombol di bawah untuk menghapus permanen dari database dan membersihkan media di server.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF991B1B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(38),
                  backgroundColor: dangerColor,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.button,
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

      // 3. Author Header & Category
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: AppRadius.card,
          border: Border.all(color: borderColor),
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
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${report.authorName} • ${report.createdAt.toDisplayDateTime()}',
                    style: AppTextStyles.captionOf(context),
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
                color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySubtle,
                borderRadius: AppRadius.pill,
                border: Border.all(
                  color: isDark ? primaryColor.withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                  width: 1,
                ),
              ),
              child: Text(
                report.category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
            if (report.isPrivate) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : const Color(0xFFF1F5F9),
                  borderRadius: AppRadius.pill,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFCBD5E1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Privat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),

      // 4. Title
      Text(report.title, style: AppTextStyles.pageTitleOf(context)),
      const SizedBox(height: 8),

      // 5. Location row
      InkWell(
        borderRadius: AppRadius.borderSm,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportMapViewerScreen(report: report),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: primaryColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.locationAddress,
                  style: AppTextStyles.captionOf(context).copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.open_in_new,
                size: 14,
                color: primaryColor,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),

      // 6. Photo gallery
      if (report.photoUrls.isNotEmpty) ...[
        _buildPhotoGallery(report.photoUrls),
        const SizedBox(height: 16),
      ],

      // 7. Description
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: AppRadius.card,
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deskripsi Masalah',
              style: AppTextStyles.sectionTitleOf(context),
            ),
            const SizedBox(height: 8),
            Text(
              report.description,
              style: AppTextStyles.bodyOf(context).copyWith(
                color: textBody,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // 8. Status Timeline (Progress)
      StatusTimeline(report: report),
      const SizedBox(height: 16),

      // 9. Admin Status Action Card
      if (isAdmin) ...[
        if (isFinalized)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8FAFC),
              borderRadius: AppRadius.card,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Laporan ini telah ${report.handlingStatus.label.toLowerCase()} dan statusnya tidak dapat diubah lagi.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: dangerColor,
                  ),
                  label: const Text('Hapus'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dangerColor,
                    side: BorderSide(
                      color: dangerBorder,
                      width: 1,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.button,
                    ),
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
              color: warningSubtle,
              borderRadius: AppRadius.card,
              border: Border.all(
                color: warningBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 18,
                      color: warningText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Aksi Penanganan Petugas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: warningText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.edit_note_rounded,
                          size: 17,
                          color: primaryColor,
                        ),
                        label: const Text('Ubah Status'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(
                            color: isDark ? primaryColor.withValues(alpha: 0.5) : const Color(0xFF9CA3AF),
                            width: 1,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.button,
                          ),
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
                        onPressed: () => _openAdminStatusSheet(report),
                      ),
                    ),
                    if (report.handlingStatus != HandlingStatus.completed) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                          label: const Text('Selesaikan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: successColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.button,
                            ),
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
                          onPressed: () => _openAdminResolveSheet(report),
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

      // 10. Completion Proof & Resolution Notes if completed (Progress)
      if (report.handlingStatus == HandlingStatus.completed &&
          (report.completionProofUrl != null ||
              (report.completionNotes != null &&
                  report.completionNotes!.trim().isNotEmpty))) ...[
        Container(
          key: const Key('completion_resolution_card'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: successSubtle,
            borderRadius: AppRadius.card,
            border: Border.all(
              color: successBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Penyelesaian Pekerjaan',
                      style: AppTextStyles.sectionTitleOf(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: successColor,
                      borderRadius: AppRadius.pill,
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
                  report.completionNotes!.trim().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                    borderRadius: AppRadius.button,
                    border: Border.all(
                      color: successBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.assignment_turned_in_outlined,
                            size: 16,
                            color: successColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Catatan Penyelesaian:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
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
                        style: AppTextStyles.bodyOf(context).copyWith(
                          fontSize: 13,
                          color: textPrimary,
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
                Text(
                  'Foto Bukti Pekerjaan:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
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
                    borderRadius: AppRadius.input,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                borderRadius: AppRadius.pill,
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

      // Banner jika Laporan Bersifat Privat
      if (report.isPrivate) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceElevated
                : const Color(0xFFF8FAFC),
            borderRadius: AppRadius.card,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimarySoft
                      : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 18,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan Privat',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Laporan ini bersifat privat. Hanya Anda dan petugas berwenang yang dapat melihat. Fitur komentar dan penilaian suara (vote) dinonaktifkan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],

      // 11. Upvote & Downvote actions (Vote) - dinonaktifkan / dihilangkan jika laporan privat
      if (!report.isPrivate && report.isPubliclyVisible && !report.isTerminal) ...[
        VoteActionBar(
          report: report,
          isEnabled: isOnline && report.isVotingActive,
          disabledReason: !isOnline
              ? 'Tidak tersedia dalam mode offline'
              : (report.handlingStatus == HandlingStatus.completed
                  ? 'Penilaian suara ditutup (Laporan Selesai)'
                  : null),
          onUpvote: () => _handleVote('up'),
          onDownvote: () => _handleVote('down'),
        ),
      ],
    ];
  }

  /// Membangun daftar komentar scrollable untuk panel kanan desktop
  Widget _buildDesktopCommentsContent({
    required ReportDetailController controller,
    required ReportModel report,
    required AuthController auth,
    required bool isDark,
    required Color primaryColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderSubtle,
  }) {
    if (controller.isLoadingComments && controller.comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft)
                    .withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Memuat komentar & diskusi...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (controller.comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.forum_outlined,
                size: 44,
                color: textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Belum Ada Diskusi',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Jadilah yang pertama menyampaikan tanggapan atau masukan pada laporan ini.',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final threads = CommentThreadItem.buildThreads(controller.comments);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      itemCount: threads.length,
      separatorBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(
          color: borderSubtle,
          height: 1,
          thickness: 1,
        ),
      ),
      itemBuilder: (context, index) {
        final thread = threads[index];
        return CommentThreadTile(
          thread: thread,
          reportAuthorId: report.authorId,
          isExpanded: _expandedThreadIds.contains(thread.root.id),
          onToggleExpanded: () {
            setState(() {
              if (_expandedThreadIds.contains(thread.root.id)) {
                _expandedThreadIds.remove(thread.root.id);
              } else {
                _expandedThreadIds.add(thread.root.id);
              }
            });
          },
          onReply: _startReply,
          currentUserId: auth.currentUser?.id,
          onDelete: _handleDeleteComment,
        );
      },
    );
  }

  /// Membangun kontainer komentar untuk tata letak mobile
  Widget _buildMobileCommentsContent({
    required ReportDetailController controller,
    required ReportModel report,
    required AuthController auth,
    required bool isDark,
    required Color primaryColor,
    required Color textSecondary,
    required Color surfaceColor,
    required Color borderColor,
    required Color borderSubtle,
  }) {
    if (controller.isLoadingComments && controller.comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft)
                      .withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Memuat komentar & diskusi...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Belum ada komentar. Jadilah yang pertama menanggapi.',
            style: AppTextStyles.captionOf(context),
          ),
        ),
      );
    }

    final threads = CommentThreadItem.buildThreads(controller.comments);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < threads.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: Divider(
                  color: borderSubtle,
                  height: 1,
                  thickness: 1,
                ),
              ),
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
              currentUserId: auth.currentUser?.id,
              onDelete: _handleDeleteComment,
            ),
          ],
        ],
      ),
    );
  }

  /// Komponen composer komentar atau banner saat diskusi ditutup
  Widget _buildCommentComposer({
    required ReportModel report,
    required ReportDetailController controller,
    required bool isDark,
    required Color primaryColor,
    required Color surfaceColor,
    required Color borderColor,
    required Color textSecondary,
    required bool isOnline,
    required String currentUserId,
    required bool isOwner,
  }) {
    if (!report.isPubliclyVisible || report.isTerminal) {
      return const SizedBox.shrink();
    }

    if (!report.canAddComment) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF9FAFB),
          border: Border(
            top: BorderSide(color: borderColor),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.handlingStatus == HandlingStatus.completed
                      ? (isOwner
                            ? 'Diskusi dinonaktifkan (Laporan Selesai). Anda dapat mengaktifkannya kembali melalui menu opsi di atas.'
                            : 'Diskusi telah dinonaktifkan karena laporan telah selesai.')
                      : 'Diskusi telah dinonaktifkan oleh pemilik laporan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(color: borderColor),
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
                color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF3F4F6),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Membalas ',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
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
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
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
                      borderRadius: AppRadius.borderSm,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: borderColor,
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
                      enabled: isOnline,
                      textInputAction: TextInputAction.send,
                      onSubmitted: isOnline
                          ? (_) => _sendComment()
                          : null,
                      decoration: InputDecoration(
                        hintText: !isOnline
                            ? 'Komentar dinonaktifkan saat offline'
                            : (_replyingToComment != null
                                  ? 'Tulis balasan untuk ${_replyingToComment!.authorName.trim().startsWith('@') ? _replyingToComment!.authorName.trim() : '@${_replyingToComment!.authorName.trim()}'}...'
                                  : 'Tulis komentar atau tanggapan...'),
                        hintStyle: AppTextStyles.captionOf(context),
                        contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.input,
                          borderSide: BorderSide(
                            color: borderColor,
                          ),
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                              borderRadius: AppRadius.input,
                              borderSide: BorderSide(
                                color: borderColor,
                              ),
                            ),
                        focusedBorder:
                            OutlineInputBorder(
                              borderRadius: AppRadius.input,
                              borderSide: BorderSide(
                                color: primaryColor,
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
                        : Icon(
                            Icons.send_rounded,
                            color: isOnline
                                ? primaryColor
                                : (isDark ? AppColors.darkDisabled : AppColors.disabled),
                          ),
                    onPressed:
                        (isOnline &&
                            !controller.isSendingComment)
                        ? _sendComment
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery(List<String> urls) {
    if (urls.length == 1) {
      return GestureDetector(
        onTap: () => _openPhotoViewer(urls, 0),
        child: ClipRRect(
          borderRadius: AppRadius.card,
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
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    borderRadius: AppRadius.pill,
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
                  borderRadius: AppRadius.input,
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
