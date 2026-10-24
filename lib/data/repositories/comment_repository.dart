import 'package:flutter/foundation.dart';

import '../models/comment_model.dart';
import '../models/user_profile_model.dart';
import '../services/supabase_service.dart';

/// Repository for handling comments on reports with Supabase integration
/// and in-memory fallback for offline/test environments.
class CommentRepository {
  CommentRepository({SupabaseService? supabaseService})
    : _service = supabaseService ?? SupabaseService.instance;

  final SupabaseService _service;
  final List<CommentModel> _memoryFallbackComments = [];

  Future<List<CommentModel>> getComments(String reportId) async {
    final client = _service.client;
    if (client != null) {
      try {
        final response = await client
            .from('comments')
            .select()
            .eq('report_id', reportId)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: true);

        final list = (response as List)
            .map(
              (json) => CommentModel.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();
        return list;
      } catch (e) {
        debugPrint('Error getComments Supabase: $e');
      }
    }

    // In-memory fallback (offline / tests)
    await Future.delayed(const Duration(milliseconds: 50));
    final list = _memoryFallbackComments
        .where((c) => c.reportId == reportId)
        .toList();
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
    final client = _service.client;
    if (client != null) {
      try {
        final commentData = <String, dynamic>{
          'report_id': reportId,
          'author_id': authorId,
          'author_name': authorName,
          'author_role': authorRole.value,
          'body': body.trim(),
        };
        if (parentCommentId != null) {
          commentData['parent_comment_id'] = parentCommentId;
        }

        final response = await client
            .from('comments')
            .insert(commentData)
            .select()
            .single();

        final created = CommentModel.fromJson(
          Map<String, dynamic>.from(response),
        );
        _memoryFallbackComments.add(created);
        return created;
      } catch (e) {
        debugPrint('Error addComment Supabase: $e');
        rethrow;
      }
    }

    // Fallback in-memory jika client null (offline / tests)
    await Future.delayed(const Duration(milliseconds: 50));
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

    _memoryFallbackComments.add(newComment);
    return newComment;
  }
}
