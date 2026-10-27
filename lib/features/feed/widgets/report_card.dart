import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/controllers/auth_controller.dart';

/// Reusable report card widget matching DESIGN.md Section 4.3
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
    required this.onUpvote,
    required this.onDownvote,
  });

  final ReportModel report;
  final VoidCallback onTap;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clickable card content (thumbnail, title, category, location)
          InkWell(
            onTap: onTap,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail if photos exist (safe web-rendering)
                if (report.photoUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _buildThumbnail(report.photoUrls.first),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author Row: UserAvatar + Username + Time
                      Row(
                        children: [
                          UserAvatar(
                            name: report.authorName,
                            username: report.authorUsername,
                            avatarUrl: report.authorAvatarUrl,
                            radius: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.displayAuthorUsername,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (report.authorName.isNotEmpty &&
                                    report.authorName != 'Warga Laporin' &&
                                    report.authorUsername != null &&
                                    report.authorName.toLowerCase() !=
                                        report.authorUsername!.toLowerCase())
                                  Text(
                                    report.authorName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final auth = context.watch<AuthController?>();
                              final isAdmin = auth?.isAdmin ?? false;
                              final repo = context.watch<ReportRepository?>();
                              final isViewed =
                                  repo?.isReportViewedByAdmin(report.id) ??
                                  false;
                              final timeLabel = report.createdAt
                                  .toReportTimeLabel(
                                    isAdmin: isAdmin,
                                    isViewedByAdmin: isViewed,
                                  );

                              if (timeLabel == 'Baru') {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
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
                                );
                              }

                              return Text(
                                timeLabel,
                                style: AppTextStyles.caption,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Category & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              report.category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryStrong,
                              ),
                            ),
                          ),
                          HandlingStatusBadge(
                            status: report.handlingStatus,
                            createdAt: report.createdAt,
                            isDraft: report.isDraft,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Title
                      Text(
                        report.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 8),

                      // Location metadata
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.locationDot,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.locationAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1),
          ),

          // Independent interactions row: Upvote, Downvote, Comments
          Builder(
            builder: (context) {
              final isCompleted =
                  report.handlingStatus == HandlingStatus.completed;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _VoteButton(
                      icon: FontAwesomeIcons.thumbsUp,
                      count: report.upvotesCount,
                      isActive: report.currentUserVote == 'up',
                      activeColor: AppColors.primary,
                      isEnabled: !isCompleted,
                      onTap: isCompleted ? null : onUpvote,
                    ),
                    const SizedBox(width: 12),
                    _VoteButton(
                      icon: FontAwesomeIcons.thumbsDown,
                      count: report.downvotesCount,
                      isActive: report.currentUserVote == 'down',
                      activeColor: AppColors.danger,
                      isEnabled: !isCompleted,
                      onTap: isCompleted ? null : onDownvote,
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onTap,
                      mouseCursor: SystemMouseCursors.click,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Opacity(
                          opacity: report.isDiscussionActive ? 1.0 : 0.4,
                          child: Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.comment,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${report.commentsCount} komentar',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String url) {
    return AppImage(
      imageSource: url,
      fit: BoxFit.cover,
      memCacheWidth: 800,
      memCacheHeight: 450,
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    this.isEnabled = true,
  });

  final FaIconData icon;
  final int count;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = !isEnabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (isActive ? activeColor : AppColors.textSecondary);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        mouseCursor: isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isEnabled && isActive
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEnabled && isActive
                  ? activeColor.withValues(alpha: 0.28)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, size: 14, color: effectiveColor),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isEnabled && isActive
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
