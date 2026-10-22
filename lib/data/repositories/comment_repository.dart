import '../models/comment_model.dart';
import '../models/user_profile_model.dart';

/// Repository for handling comments on reports
class CommentRepository {
  CommentRepository();

  final List<CommentModel> _comments = [];

  Future<List<CommentModel>> getComments(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _comments.where((c) => c.reportId == reportId).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<CommentModel> addComment({
    required String reportId,
    required String authorId,
    required String authorName,
    required UserRole authorRole,
    required String body,
    String? parentCommentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final newComment = CommentModel(
      id: 'com-${DateTime.now().millisecondsSinceEpoch}',
      reportId: reportId,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      body: body.trim(),
      createdAt: DateTime.now(),
      parentCommentId: parentCommentId,
    );

    _comments.add(newComment);
    return newComment;
  }
}
