import 'user_profile_model.dart';

/// Model komentar laporan sesuai PRD.md Bagian 7.7
class CommentModel {
  const CommentModel({
    required this.id,
    required this.reportId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.authorRole = UserRole.user,
    required this.body,
    required this.createdAt,
    this.parentCommentId,
  });

  final String id;
  final String reportId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final UserRole authorRole;
  final String body;
  final DateTime createdAt;
  final String? parentCommentId;

  bool get isStaff => authorRole == UserRole.admin;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar_url': authorAvatarUrl,
      'author_role': authorRole.value,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'parent_comment_id': parentCommentId,
    };
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      authorId: json['author_id'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Warga',
      authorAvatarUrl: json['author_avatar_url'] as String?,
      authorRole: UserRole.fromString(json['author_role'] as String?),
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      parentCommentId: json['parent_comment_id'] as String?,
    );
  }
}
