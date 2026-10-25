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

        // Batch enrich comments with latest author profile (avatar_url, full_name)
        try {
          final authorIds = list
              .map((c) => c.authorId)
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();
          if (authorIds.isNotEmpty) {
            final profilesData = await client
                .from('profiles')
                .select('id, username, full_name, avatar_url')
                .inFilter('id', authorIds);
            final profileMap = <String, Map<String, dynamic>>{};
            for (final p in (profilesData as List)) {
              final pid = p['id']?.toString();
              if (pid != null) {
                profileMap[pid] = p as Map<String, dynamic>;
              }
            }
            final currentAuthUser = client.auth.currentUser;
            for (var i = 0; i < list.length; i++) {
              final prof = profileMap[list[i].authorId];
              var av = prof?['avatar_url'] as String?;

              // Fallback jika profiles belum terisi avatar_url tapi ini adalah user yang sedang login dengan Google
              if ((av == null || av.trim().isEmpty) &&
                  currentAuthUser != null &&
                  list[i].authorId == currentAuthUser.id) {
                av =
                    currentAuthUser.userMetadata?['avatar_url'] as String? ??
                    currentAuthUser.userMetadata?['picture'] as String? ??
                    currentAuthUser.userMetadata?['photo_url'] as String?;
              }

              final finalAvatar = (av != null && av.trim().isNotEmpty)
                  ? av
                  : list[i].authorAvatarUrl;

              if (finalAvatar != list[i].authorAvatarUrl) {
                list[i] = list[i].copyWith(authorAvatarUrl: finalAvatar);
              }
            }
          }
        } catch (enrichError) {
          debugPrint('Catatan enrich comments profile: $enrichError');
        }

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
    String? authorAvatarUrl,
    required UserRole authorRole,
    required String body,
    String? parentCommentId,
  }) async {
    final client = _service.client;
    String? resolvedAvatarUrl = authorAvatarUrl;
    if (resolvedAvatarUrl == null || resolvedAvatarUrl.trim().isEmpty) {
      final curUser = client?.auth.currentUser;
      if (curUser != null && curUser.id == authorId) {
        resolvedAvatarUrl =
            curUser.userMetadata?['avatar_url'] as String? ??
            curUser.userMetadata?['picture'] as String? ??
            curUser.userMetadata?['photo_url'] as String?;
      }
    }

    if (client != null) {
      try {
        final commentData = <String, dynamic>{
          'report_id': reportId,
          'author_id': authorId,
          'author_name': authorName,
          if (resolvedAvatarUrl != null && resolvedAvatarUrl.trim().isNotEmpty)
            'author_avatar_url': resolvedAvatarUrl.trim(),
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

        var created = CommentModel.fromJson(
          Map<String, dynamic>.from(response),
        );
        if (created.authorAvatarUrl == null && resolvedAvatarUrl != null) {
          created = created.copyWith(authorAvatarUrl: resolvedAvatarUrl);
        }
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
      authorAvatarUrl: resolvedAvatarUrl,
      authorRole: authorRole,
      body: body.trim(),
      createdAt: DateTime.now(),
      parentCommentId: parentCommentId,
    );
    _memoryFallbackComments.add(newComment);
    return newComment;
  }
}
