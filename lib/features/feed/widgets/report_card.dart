import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.border;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final chipBg =
        isDark ? AppColors.darkSurfaceElevated : AppColors.primarySubtle;
    final chipBorder =
        isDark ? AppColors.darkBorder : const Color(0xFFBFDBFE);
    final chipText =
        isDark ? AppColors.darkTextBody : AppColors.primary;

    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.card, // 16px rounded
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clickable card content (thumbnail, title, category, location)
          InkWell(
            onTap: onTap,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail if photos exist (rounded top per DESIGN.md Section 4.3; capped on desktop)
                if (report.photoUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: isDesktop ? 220 : null,
                          child: isDesktop
                              ? _buildThumbnail(report.photoUrls.first)
                              : AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: _buildThumbnail(report.photoUrls.first),
                                ),
                        ),
                        if (report.photoUrls.length > 1)
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: AppRadius.pill,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.photo_library_outlined,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+${report.photoUrls.length - 1} Foto',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
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
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
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
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: chipBg,
                                    borderRadius: AppRadius.pill,
                                    border: Border.all(
                                      color: chipBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Baru',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: chipText,
                                    ),
                                  ),
                                );
                              }

                              return Text(
                                timeLabel,
                                style: AppTextStyles.captionOf(context),
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
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: AppRadius.pill,
                              border: Border.all(
                                color: chipBorder,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              report.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: chipText,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HandlingStatusBadge(
                                status: report.handlingStatus,
                                createdAt: report.createdAt,
                                isDraft: report.isDraft,
                              ),
                              if (report.isPrivate) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurfaceElevated
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: AppRadius.badge,
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
                                        size: 11,
                                        color: textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Privat',
                                        style: TextStyle(
                                          fontSize: 10,
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
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Title
                      Text(
                        report.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sectionTitleOf(context),
                      ),
                      const SizedBox(height: 8),

                      // Location metadata
                      Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.locationDot,
                            size: 13,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.locationAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.captionOf(context),
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
            ),
          ),

          // Independent interactions row: Upvote, Downvote, Comments
          Builder(
            builder: (context) {
              if (report.isPrivate) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Laporan Privat • Komentar & vote dinonaktifkan',
                        style: AppTextStyles.captionOf(context),
                      ),
                    ],
                  ),
                );
              }

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
                      activeColor:
                          isDark ? AppColors.darkPrimary : AppColors.primary,
                      isEnabled: !isCompleted,
                      onTap: isCompleted ? null : onUpvote,
                    ),
                    const SizedBox(width: 12),
                    _VoteButton(
                      icon: FontAwesomeIcons.thumbsDown,
                      count: report.downvotesCount,
                      isActive: report.currentUserVote == 'down',
                      activeColor:
                          isDark ? AppColors.darkDanger : AppColors.danger,
                      isEnabled: !isCompleted,
                      onTap: isCompleted ? null : onDownvote,
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onTap,
                      mouseCursor: SystemMouseCursors.click,
                      borderRadius: AppRadius.pill,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Opacity(
                          opacity: report.isDiscussionActive ? 1.0 : 0.4,
                          child: Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.comment,
                                size: 14,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${report.commentsCount} komentar',
                                style: AppTextStyles.captionOf(context).copyWith(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final effectiveColor = !isEnabled
        ? inactiveColor.withValues(alpha: 0.5)
        : (isActive ? activeColor : inactiveColor);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        mouseCursor: isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        borderRadius: AppRadius.pill,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isEnabled && isActive
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: AppRadius.pill,
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
