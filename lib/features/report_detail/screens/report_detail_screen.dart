import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../../data/repositories/report_repository.dart';
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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

    controller
        .submitComment(
          authorId: user.id,
          authorName: authorDisplayName,
          authorAvatarUrl: user.avatarUrl,
          authorRole: user.role,
          body: text,
        )
        .then((success) {
          if (!mounted) return;
          if (success) {
            _commentController.clear();
            focusScope.unfocus();
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

  void _showDeleteDialog(ReportModel currentReport, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteReportDialog(
        reportNumber: currentReport.reportNumber,
        onConfirmDelete: () =>
            context.read<ReportDetailController>().softDeleteReport(userId),
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportDetailController>();
    final auth = context.watch<AuthController>();
    final report = controller.report;
    final currentUserId = auth.currentUser?.id ?? 'guest';

    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (report == null || report.isDeleted) {
      final isDeleted = report?.isDeleted == true;
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
                      ? 'Laporan ini telah dihapus oleh pemiliknya dan tidak lagi aktif.'
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

    final isOwner = auth.currentUser?.id == report.authorId;

    return PopScope<ReportModel>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(controller.report);
      },
      child: Container(
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
                      child: HandlingStatusBadge(status: report.handlingStatus),
                    ),
                  ),
                  if (isOwner && !report.isDeleted) ...[
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      tooltip: 'Opsi Laporan',
                      onSelected: (val) {
                        if (val == 'edit') {
                          _openEditScreen(report);
                        } else if (val == 'delete') {
                          _showDeleteDialog(report, currentUserId);
                        }
                      },
                      itemBuilder: (ctx) => [
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
                                Text('Edit Laporan'),
                              ],
                            ),
                          ),
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
                              Text(
                                'Hapus Laporan',
                                style: TextStyle(color: AppColors.danger),
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
                        padding: const EdgeInsets.all(16),
                        children: [
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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

                          // Completion Proof if completed
                          if (report.handlingStatus ==
                                  HandlingStatus.completed &&
                              report.completionProofUrl != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F8F0),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.success.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        color: AppColors.success,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Bukti Penyelesaian Pekerjaan',
                                        style: AppTextStyles.sectionTitle,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
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
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Upvote & Downvote actions (Only if report is active public)
                          if (report.isPubliclyVisible && !report.isTerminal)
                            VoteActionBar(
                              report: report,
                              onUpvote: () => _handleVote('up'),
                              onDownvote: () => _handleVote('down'),
                            ),
                          const SizedBox(height: 24),

                          // Comments header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tanggapan & Diskusi (${controller.comments.length})',
                                style: AppTextStyles.sectionTitle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Comments list
                          if (controller.comments.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'Belum ada komentar. Jadilah yang pertama menanggapi.',
                                  style: AppTextStyles.caption,
                                ),
                              ),
                            )
                          else
                            ...controller.comments.map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: CommentTile(comment: c),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Comment Composer (Disabled if terminal or non-public per PRD invariant 5.4)
                  if (report.isPubliclyVisible && !report.isTerminal)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendComment(),
                                decoration: InputDecoration(
                                  hintText: 'Tulis komentar atau tanggapan...',
                                  hintStyle: AppTextStyles.caption,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
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
                                      child: CircularProgressIndicator(
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
                    ),
                ],
              ),
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
