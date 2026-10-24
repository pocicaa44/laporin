import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/comment_model.dart';

/// Individual comment tile widget matching DESIGN.md Section 4.5 & 5.11
class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment});

  final CommentModel comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: comment.isStaff ? const Color(0xFFF7F8FF) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: comment.isStaff
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: comment.authorName,
                avatarUrl: comment.authorAvatarUrl,
                radius: 16,
                backgroundColor: comment.isStaff
                    ? AppColors.primary
                    : AppColors.primarySoft,
                foregroundColor: comment.isStaff
                    ? Colors.white
                    : AppColors.primaryStrong,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.authorName,
                            style: AppTextStyles.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (comment.isStaff) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Petugas',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      comment.createdAt.toRelativeTime(),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(comment.body, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
