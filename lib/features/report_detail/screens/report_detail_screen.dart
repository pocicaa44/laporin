import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/report_detail_controller.dart';
import '../widgets/comment_tile.dart';
import '../widgets/status_timeline.dart';
import '../widgets/vote_action_bar.dart';

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
    return ChangeNotifierProvider(
      create: (context) => ReportDetailController(
        reportId: reportId,
        reportRepository: context.read<ReportRepository>(),
        commentRepository: context.read<CommentRepository>(),
        initialReport: initialReport,
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
    final controller = context.read<ReportDetailController>();

    final focusScope = FocusScope.of(context);
    final authorDisplayName = (user != null && user.username.trim().isNotEmpty)
        ? '@${user.username.trim().replaceFirst('@', '')}'
        : (user?.fullName ?? 'Warga Laporin');

    controller
        .submitComment(
          authorId: user?.id ?? 'guest',
          authorName: authorDisplayName,
          authorRole: user?.role ?? UserRole.user,
          body: text,
        )
        .then((success) {
          if (success && mounted) {
            _commentController.clear();
            focusScope.unfocus();
          }
        });
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

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyState(
                  title: 'Laporan Tidak Ditemukan',
                  message: 'Laporan ini mungkin sedang diproses, telah dihapus, atau berada di luar batas akses.',
                ),
                const SizedBox(height: 16),
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
              title: Text(report.reportNumber),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: HandlingStatusBadge(status: report.handlingStatus),
                  ),
                ),
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

                        // Completion Proof if completed
                        if (report.handlingStatus == HandlingStatus.completed &&
                            report.completionProofUrl != null) ...[
                          Container(
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
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: _buildPhoto(
                                      report.completionProofUrl!,
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
                            onUpvote: () =>
                                controller.vote(currentUserId, 'up'),
                            onDownvote: () =>
                                controller.vote(currentUserId, 'down'),
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
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
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
    );
  }

  Widget _buildPhotoGallery(List<String> urls) {
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(aspectRatio: 16 / 9, child: _buildPhoto(urls.first)),
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
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: _buildPhoto(urls[index]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${urls.length} foto lampiran (geser untuk melihat)',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildPhoto(String url) {
    final isNetwork =
        url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('blob:') ||
        url.startsWith('data:');
    if (isNetwork) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _brokenPlaceholder(),
      );
    }
    if (!kIsWeb) {
      return Image.file(
        io.File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _brokenPlaceholder(),
      );
    }
    return _brokenPlaceholder();
  }

  Widget _brokenPlaceholder() {
    return Container(
      color: AppColors.primarySoft,
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          size: 36,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
