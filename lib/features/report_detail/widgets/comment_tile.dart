import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/comment_model.dart';

/// Item balasan komentar beserta info author yang dibalas
class CommentReplyItem {
  const CommentReplyItem({required this.comment, this.replyToAuthorName});

  final CommentModel comment;
  final String? replyToAuthorName;
}

/// Struktur data untuk mengelompokkan komentar utama dan balasannya
class CommentThreadItem {
  const CommentThreadItem({required this.root, required this.replies});

  final CommentModel root;
  final List<CommentReplyItem> replies;

  /// Membangun thread terstruktur dari daftar komentar datar (flat comments)
  static List<CommentThreadItem> buildThreads(List<CommentModel> comments) {
    if (comments.isEmpty) return const [];

    final commentMap = <String, CommentModel>{
      for (final c in comments) c.id: c,
    };

    final repliesByRootId = <String, List<CommentReplyItem>>{};
    final rootComments = <CommentModel>[];

    for (final c in comments) {
      if (c.parentCommentId == null ||
          !commentMap.containsKey(c.parentCommentId)) {
        rootComments.add(c);
      } else {
        // Cari komentar yang dibalas secara langsung untuk menampilkan "To @author"
        final parentComment = commentMap[c.parentCommentId];
        final replyToAuthor = parentComment?.authorName;

        // Telusuri root ancestor dari balasan ini
        var curr = c;
        final visited = <String>{curr.id};
        while (curr.parentCommentId != null &&
            commentMap.containsKey(curr.parentCommentId)) {
          final parent = commentMap[curr.parentCommentId]!;
          if (visited.contains(parent.id)) break;
          visited.add(parent.id);
          curr = parent;
        }

        final rootId = curr.id;
        repliesByRootId
            .putIfAbsent(rootId, () => [])
            .add(
              CommentReplyItem(comment: c, replyToAuthorName: replyToAuthor),
            );
      }
    }

    return rootComments.map((root) {
      final replies = repliesByRootId[root.id] ?? const [];
      return CommentThreadItem(root: root, replies: replies);
    }).toList();
  }

  /// Menemukan ID root dari sebuah komentar (baik root maupun balasan)
  static String findRootId(
    CommentModel comment,
    List<CommentModel> allComments,
  ) {
    final commentMap = <String, CommentModel>{
      for (final c in allComments) c.id: c,
    };
    var curr = comment;
    final visited = <String>{curr.id};
    while (curr.parentCommentId != null &&
        commentMap.containsKey(curr.parentCommentId)) {
      final parent = commentMap[curr.parentCommentId]!;
      if (visited.contains(parent.id)) break;
      visited.add(parent.id);
      curr = parent;
    }
    return curr.id;
  }
}

/// Individual comment tile widget matching DESIGN.md Section 4.5 & 5.11
/// and updated with modern threaded design (avatar, author, To @target, · Pencipta, timestamp & Balas).
class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    this.isCreator = false,
    this.replyToAuthor,
    this.onReply,
    this.isReply = false,
  });

  final CommentModel comment;
  final bool isCreator;
  final String? replyToAuthor;
  final VoidCallback? onReply;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header: Avatar + Author + To @target + · Pencipta + Petugas Badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UserAvatar(
              name: comment.authorName,
              username: comment.authorName,
              avatarUrl: comment.authorAvatarUrl,
              radius: isReply ? 15 : 17,
              backgroundColor: comment.isStaff
                  ? AppColors.primary
                  : AppColors.primarySoft,
              foregroundColor: comment.isStaff
                  ? Colors.white
                  : AppColors.primaryStrong,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    comment.authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  if (replyToAuthor != null &&
                      replyToAuthor!.trim().isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: FaIcon(
                        FontAwesomeIcons.caretRight,
                        size: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      replyToAuthor!.trim().startsWith('@')
                          ? replyToAuthor!.trim()
                          : '@${replyToAuthor!.trim()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                  if (!isReply && isCreator) ...[
                    const Text(
                      ' · ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const Text(
                      'Pencipta',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                  if (!isReply && comment.isStaff) ...[
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
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 2. Body Text (flush sejajar kiri sesuai screenshot design)
        Text(
          comment.body,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 6),

        // 3. Footer: Timestamp ringkas & tombol Balas
        Row(
          children: [
            Text(
              comment.createdAt.toShortRelativeTime(),
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            if (onReply != null) ...[
              const SizedBox(width: 14),
              InkWell(
                onTap: onReply,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Balas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Widget untuk merender satu thread komentar:
/// - Komentar utama (root)
/// - Daftar balasan (indented 36px) jika expanded
/// - Tombol "—— Lihat X balasan v" jika collapsed
/// - Tombol "—— Sembunyikan ^" jika expanded
class CommentThreadTile extends StatelessWidget {
  const CommentThreadTile({
    super.key,
    required this.thread,
    required this.reportAuthorId,
    required this.onReply,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  final CommentThreadItem thread;
  final String reportAuthorId;
  final void Function(CommentModel commentToReply) onReply;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Komentar Utama (Root)
        CommentTile(
          comment: thread.root,
          isCreator: thread.root.authorId == reportAuthorId,
          onReply: () => onReply(thread.root),
          isReply: false,
        ),

        // 2. Daftar Balasan jika expanded
        if (isExpanded && thread.replies.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < thread.replies.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  CommentTile(
                    comment: thread.replies[i].comment,
                    isCreator:
                        thread.replies[i].comment.authorId == reportAuthorId,
                    replyToAuthor: thread.replies[i].replyToAuthorName,
                    onReply: () => onReply(thread.replies[i].comment),
                    isReply: true,
                  ),
                ],
                const SizedBox(height: 10),
                // Tombol "—— Sembunyikan ^"
                InkWell(
                  onTap: onToggleExpanded,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 1.5,
                          color: const Color(0xFFD1D5DB),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Sembunyikan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 18,
                          color: Color(0xFF4B5563),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 3. Tombol "—— Lihat X balasan v" jika collapsed
        if (!isExpanded && thread.replies.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: InkWell(
              onTap: onToggleExpanded,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 1.5,
                      color: const Color(0xFFD1D5DB),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lihat ${thread.replies.length} balasan',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF4B5563),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
