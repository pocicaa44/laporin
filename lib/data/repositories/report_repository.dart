import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../../core/services/boundary_service.dart';
import '../models/report_model.dart';
import '../services/supabase_service.dart';

/// Repository for reports with strict enforcement of business invariants
/// (Dual state machine, public visibility, downvote thresholds, terminal archive window).
class ReportRepository {
  ReportRepository({SupabaseService? supabaseService})
    : _service = supabaseService ?? SupabaseService.instance;

  final SupabaseService _service;

  // In-memory reports store (starts empty; populated from Supabase or created reports)
  final List<ReportModel> _reports = [];
  // In-memory votes per report and user: reportId -> { userId: voteType }
  final Map<String, Map<String, String>> _reportUserVotes = {};
  bool _hasFetchedFromSupabase = false;

  Future<void> _fetchFromSupabaseIfAvailable() async {
    if (_hasFetchedFromSupabase) return;
    final client = _service.client;
    if (client != null) {
      try {
        // Query reports with author profiles relation to fetch author username and avatar
        final response = await client
            .from('reports')
            .select('*, profiles(username, full_name, avatar_url)');
        final rawList = response as List;

        // Deserializing report records offloaded to background isolate
        final list = await _parseReportsInIsolate(rawList);

        // Jika user aktif terautentikasi, sinkronkan status vote aktif dari tabel votes
        final currentUserId = client.auth.currentUser?.id;
        if (currentUserId != null && list.isNotEmpty) {
          try {
            final userVotes = await client
                .from('votes')
                .select('report_id, vote_type')
                .eq('user_id', currentUserId);
            final voteMap = <String, String>{};
            for (final v in (userVotes as List)) {
              final rId = v['report_id']?.toString();
              final vType = v['vote_type']?.toString();
              if (rId != null && vType != null) {
                voteMap[rId] = vType;
              }
            }
            for (var i = 0; i < list.length; i++) {
              if (voteMap.containsKey(list[i].id)) {
                list[i] = list[i].copyWith(
                  currentUserVote: voteMap[list[i].id],
                );
              }
            }
          } catch (_) {}
        }

        _reports.clear();
        _reports.addAll(list);
        _hasFetchedFromSupabase = true;
      } catch (_) {
        try {
          final fallbackResponse = await client.from('reports').select();
          final rawList = fallbackResponse as List;
          final list = await _parseReportsInIsolate(rawList);
          _reports.clear();
          _reports.addAll(list);
          _hasFetchedFromSupabase = true;
        } catch (_) {
          // Table does not exist in Supabase yet, keep _reports empty
        }
      }
    }
  }

  /// Deserializes JSON report maps into ReportModel objects on a dedicated Isolate.
  static Future<List<ReportModel>> _parseReportsInIsolate(
    List<dynamic> rawList,
  ) async {
    if (kIsWeb || rawList.isEmpty) {
      return rawList
          .map((item) => ReportModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return await Isolate.run<List<ReportModel>>(() {
      return rawList
          .map((item) => ReportModel.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  /// Mengambil laporan publik yang memenuhi syarat visibilitas:
  /// publication_state == 'published' AND handling_status NOT IN ('rejected', 'cancelled')
  Future<List<ReportModel>> getPublicFeed({
    String? category,
    String? searchQuery,
    String? sortBy, // 'newest', 'popular'
    String? userId,
  }) async {
    await _fetchFromSupabaseIfAvailable();

    if (_reports.isEmpty) return const [];

    final effectiveUserId = userId ?? _service.client?.auth.currentUser?.id;
    final List<ReportModel> reportsSnapshot;
    if (effectiveUserId != null && _reportUserVotes.isNotEmpty) {
      reportsSnapshot = _reports.map((r) {
        final hasVote =
            _reportUserVotes[r.id]?.containsKey(effectiveUserId) ?? false;
        if (hasVote) {
          final userVote = _reportUserVotes[r.id]![effectiveUserId];
          return r.copyWith(
            currentUserVote: userVote,
            clearCurrentUserVote: userVote == null,
          );
        } else if (_reportUserVotes.containsKey(r.id)) {
          // Laporan memiliki vote dari user lain, maka untuk user ini adalah null
          return r.copyWith(clearCurrentUserVote: true);
        }
        return r;
      }).toList();
    } else {
      reportsSnapshot = List<ReportModel>.from(_reports);
    }

    if (kIsWeb || reportsSnapshot.length < 25) {
      return _filterAndSortFeed(
        reports: reportsSnapshot,
        category: category,
        searchQuery: searchQuery,
        sortBy: sortBy,
      );
    }

    // Heavy string searching, category filtering, and sorting offloaded to background isolate
    return await Isolate.run<List<ReportModel>>(() {
      return _filterAndSortFeed(
        reports: reportsSnapshot,
        category: category,
        searchQuery: searchQuery,
        sortBy: sortBy,
      );
    });
  }

  static List<ReportModel> _filterAndSortFeed({
    required List<ReportModel> reports,
    String? category,
    String? searchQuery,
    String? sortBy,
  }) {
    var list = reports.where((r) => r.isPubliclyVisible).toList();

    if (category != null && category.isNotEmpty && category != 'Semua') {
      final cat = category.toLowerCase();
      list = list.where((r) => r.category.toLowerCase() == cat).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list
          .where(
            (r) =>
                r.title.toLowerCase().contains(q) ||
                r.description.toLowerCase().contains(q) ||
                r.locationAddress.toLowerCase().contains(q) ||
                r.category.toLowerCase().contains(q),
          )
          .toList();
    }

    if (sortBy == 'popular') {
      list.sort(
        (a, b) => (b.upvotesCount - b.downvotesCount).compareTo(
          a.upvotesCount - a.downvotesCount,
        ),
      );
    } else {
      // Default newest
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return list;
  }

  /// Mengambil laporan milik pengguna tertentu
  Future<List<ReportModel>> getMyReports(String userId) async {
    await _fetchFromSupabaseIfAvailable();
    final reportsSnapshot = List<ReportModel>.from(_reports);

    if (kIsWeb || reportsSnapshot.length < 25) {
      final list = reportsSnapshot.where((r) => r.authorId == userId).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }

    return await Isolate.run<List<ReportModel>>(() {
      final list = reportsSnapshot.where((r) => r.authorId == userId).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Mengambil semua laporan untuk portal Admin (termasuk yang 'held', 'pending_review', 'rejected')
  Future<List<ReportModel>> getAdminReports({String? filterStatus}) async {
    await _fetchFromSupabaseIfAvailable();
    final reportsSnapshot = List<ReportModel>.from(_reports);

    if (kIsWeb || reportsSnapshot.length < 25) {
      return _filterAdminReports(reportsSnapshot, filterStatus);
    }

    return await Isolate.run<List<ReportModel>>(() {
      return _filterAdminReports(reportsSnapshot, filterStatus);
    });
  }

  static List<ReportModel> _filterAdminReports(
    List<ReportModel> reports,
    String? filterStatus,
  ) {
    var list = List<ReportModel>.from(reports);

    if (filterStatus == 'held') {
      list = list
          .where((r) => r.publicationState == PublicationState.held)
          .toList();
    } else if (filterStatus == 'new') {
      list = list
          .where((r) => r.handlingStatus == HandlingStatus.newReport)
          .toList();
    } else if (filterStatus == 'in_progress') {
      list = list
          .where(
            (r) =>
                r.handlingStatus == HandlingStatus.inProgress ||
                r.handlingStatus == HandlingStatus.accepted,
          )
          .toList();
    } else if (filterStatus == 'completed') {
      list = list
          .where((r) => r.handlingStatus == HandlingStatus.completed)
          .toList();
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Mendapatkan detail satu laporan berdasarkan ID
  Future<ReportModel?> getReportById(String id) async {
    // 1. Cek cache in-memory terlebih dahulu
    try {
      return _reports.firstWhere((r) => r.id == id);
    } catch (_) {}

    // 2. Muat data dari Supabase jika belum pernah dimuat
    await _fetchFromSupabaseIfAvailable();
    try {
      return _reports.firstWhere((r) => r.id == id);
    } catch (_) {}

    // 3. Query spesifik ID ke Supabase jika tetap tidak ditemukan di list
    final client = _service.client;
    if (client != null) {
      try {
        final response = await client
            .from('reports')
            .select('*, profiles(username, full_name, avatar_url)')
            .eq('id', id)
            .maybeSingle();
        if (response != null) {
          var fetched = ReportModel.fromJson(response);
          final currentUserId = client.auth.currentUser?.id;
          if (currentUserId != null) {
            try {
              final userVote = await client
                  .from('votes')
                  .select('vote_type')
                  .eq('report_id', id)
                  .eq('user_id', currentUserId)
                  .maybeSingle();
              if (userVote != null) {
                fetched = fetched.copyWith(
                  currentUserVote: userVote['vote_type'] as String?,
                );
              }
            } catch (_) {}
          }
          _reports.add(fetched);
          return fetched;
        }
      } catch (_) {
        try {
          final response = await client
              .from('reports')
              .select()
              .eq('id', id)
              .maybeSingle();
          if (response != null) {
            final fetched = ReportModel.fromJson(response);
            _reports.add(fetched);
            return fetched;
          }
        } catch (_) {}
      }
    }

    return null;
  }

  /// Membuat laporan baru dan menyimpannya ke Supabase
  Future<ReportModel> createReport({
    required String authorId,
    required String authorName,
    String? authorUsername,
    String? authorAvatarUrl,
    required String title,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    required String locationAddress,
    String? areaName,
    List<String> photoUrls = const [],
  }) async {
    // Validasi aturan bisnis: lokasi wajib di dalam batas Provinsi Jawa Tengah
    if (!BoundaryService.instance.isInsideCentralJava(latitude, longitude)) {
      throw Exception(BoundaryService.outsideAreaErrorMessage);
    }

    final now = DateTime.now();
    final newReport = ReportModel(
      id: 'rep-${DateTime.now().millisecondsSinceEpoch}',
      reportNumber:
          'LPR-${now.year}-${(_reports.length + 1).toString().padLeft(4, '0')}',
      authorId: authorId,
      authorName: authorName,
      authorUsername: authorUsername,
      authorAvatarUrl: authorAvatarUrl,
      areaId: 'area-jateng',
      areaName: areaName ?? BoundaryService.defaultAreaName,
      title: title.trim(),
      description: description.trim(),
      category: category,
      latitude: latitude,
      longitude: longitude,
      locationAddress: locationAddress,
      handlingStatus: HandlingStatus.newReport,
      publicationState: PublicationState.published,
      createdAt: now,
      updatedAt: now,
      photoUrls: photoUrls,
    );

    final client = _service.client;
    if (client != null && client.auth.currentUser != null) {
      try {
        await client.from('reports').insert(newReport.toJson());
      } catch (e) {
        try {
          final fallbackMap = newReport.toJson();
          fallbackMap.remove('author_username');
          fallbackMap.remove('author_avatar_url');
          await client.from('reports').insert(fallbackMap);
        } catch (_) {
          throw Exception('Gagal menyimpan laporan ke server: $e');
        }
      }
    }

    _reports.insert(0, newReport);
    return newReport;
  }

  /// Vote / Unvote dengan evaluasi ambang batas downvote secara atomik
  Future<ReportModel> voteReport({
    required String reportId,
    required String userId,
    required String voteType, // 'up' or 'down'
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) throw Exception('Laporan tidak ditemukan');

    final current = _reports[index];

    // Invarian: Vote tidak boleh dilakukan pada laporan non-publik atau terminal
    if (!current.isPubliclyVisible || current.isTerminal) {
      throw Exception('Laporan tidak dapat menerima interaksi vote.');
    }

    final userVotesForReport = _reportUserVotes.putIfAbsent(reportId, () => {});
    final existingUserVote = userVotesForReport[userId];

    int up = current.upvotesCount;
    int down = current.downvotesCount;
    String? newVote;

    if (existingUserVote == voteType) {
      // Toggle off / batalkan vote
      userVotesForReport.remove(userId);
      newVote = null;
      if (voteType == 'up') up = up > 0 ? up - 1 : 0;
      if (voteType == 'down') down = down > 0 ? down - 1 : 0;
    } else if (existingUserVote != null) {
      // Switch vote
      userVotesForReport[userId] = voteType;
      newVote = voteType;
      if (existingUserVote == 'up') up = up > 0 ? up - 1 : 0;
      if (existingUserVote == 'down') down = down > 0 ? down - 1 : 0;
      if (voteType == 'up') up++;
      if (voteType == 'down') down++;
    } else {
      // Vote baru
      userVotesForReport[userId] = voteType;
      newVote = voteType;
      if (voteType == 'up') up++;
      if (voteType == 'down') down++;
    }

    // Evaluasi ambang batas downvote
    PublicationState newPubState = current.publicationState;
    String? moderationReason = current.moderationReason;

    final totalVotes = up + down;
    final downPercentage = totalVotes > 0 ? (down / totalVotes) * 100 : 0.0;

    if (totalVotes >= 10 && down >= 6 && downPercentage >= 70.0) {
      newPubState = PublicationState.held;
      moderationReason =
          'Ambang batas downvote tercapai (${downPercentage.toStringAsFixed(1)}%). Ditahan untuk review moderasi.';
    }

    final updated = current.copyWith(
      upvotesCount: up,
      downvotesCount: down,
      currentUserVote: newVote,
      clearCurrentUserVote: newVote == null,
      publicationState: newPubState,
      moderationReason: moderationReason,
      updatedAt: DateTime.now(),
    );

    // Sinkronisasi dengan Supabase jika client aktif
    final client = _service.client;
    final currentAuthUser = client?.auth.currentUser;
    if (client != null && currentAuthUser != null) {
      final effectiveUserId = userId.isNotEmpty ? userId : currentAuthUser.id;

      try {
        // Coba panggil RPC atomik vote_report terlebih dahulu jika tersedia di database
        await client.rpc(
          'vote_report',
          params: {'p_report_id': reportId, 'p_vote_type': voteType},
        );
      } catch (_) {
        // Fallback: Query tabel votes dan update reports secara langsung
        try {
          if (updated.currentUserVote == null) {
            // Batalkan vote
            await client
                .from('votes')
                .delete()
                .eq('report_id', reportId)
                .eq('user_id', effectiveUserId);
          } else {
            // Simpan / update vote
            await client.from('votes').upsert({
              'report_id': reportId,
              'user_id': effectiveUserId,
              'vote_type': updated.currentUserVote,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            });
          }

          // Sinkronisasi agregat count & status ke tabel reports
          await client
              .from('reports')
              .update({
                'upvotes_count': updated.upvotesCount,
                'downvotes_count': updated.downvotesCount,
                'publication_state': updated.publicationState.value,
                'moderation_reason': updated.moderationReason,
                'updated_at': updated.updatedAt.toUtc().toIso8601String(),
              })
              .eq('id', reportId);
        } catch (dbError) {
          debugPrint('Catatan sinkronisasi vote Supabase: $dbError');
        }
      }
    }

    _reports[index] = updated;
    return updated;
  }

  /// Update status penanganan oleh Admin (dengan validasi bisnis)
  Future<ReportModel> updateHandlingStatus({
    required String reportId,
    required HandlingStatus newStatus,
    String? reason,
    String? completionProofUrl,
    String? completionProofType,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) throw Exception('Laporan tidak ditemukan');

    final current = _reports[index];
    final now = DateTime.now();

    // Invarian: Completed wajib memiliki bukti penyelesaian
    if (newStatus == HandlingStatus.completed &&
        (completionProofUrl == null || completionProofUrl.isEmpty)) {
      throw Exception(
        'Status Selesai wajib menyertakan foto/video bukti penyelesaian.',
      );
    }

    // Invarian: Rejected wajib memiliki alasan
    if (newStatus == HandlingStatus.rejected &&
        (reason == null || reason.trim().isEmpty)) {
      throw Exception('Penolakan laporan wajib menyertakan alasan penolakan.');
    }

    // Invarian: Cancelled wajib memiliki alasan
    if (newStatus == HandlingStatus.cancelled &&
        (reason == null || reason.trim().isEmpty)) {
      throw Exception('Pembatalan laporan wajib menyertakan alasan.');
    }

    DateTime? terminalAt = current.terminalAt;
    DateTime? archiveAfter = current.archiveAfter;

    // Jika terminal (rejected / cancelled), tetapkan timer 24 jam untuk pengarsipan
    if (newStatus == HandlingStatus.rejected ||
        newStatus == HandlingStatus.cancelled) {
      terminalAt = now;
      archiveAfter = now.add(const Duration(hours: 24));
    }

    final updated = current.copyWith(
      handlingStatus: newStatus,
      rejectionReason: newStatus == HandlingStatus.rejected
          ? reason
          : current.rejectionReason,
      moderationReason: newStatus == HandlingStatus.cancelled
          ? reason
          : current.moderationReason,
      completionProofUrl: completionProofUrl ?? current.completionProofUrl,
      completionProofType: completionProofType ?? current.completionProofType,
      terminalAt: terminalAt,
      archiveAfter: archiveAfter,
      updatedAt: now,
    );

    _reports[index] = updated;
    return updated;
  }

  /// Moderasi publikasi oleh Admin (Publish ulang dari 'held', atau tahan)
  Future<ReportModel> updatePublicationState({
    required String reportId,
    required PublicationState newState,
    required String reason,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) throw Exception('Laporan tidak ditemukan');

    final current = _reports[index];
    final now = DateTime.now();

    final updated = current.copyWith(
      publicationState: newState,
      moderationReason: reason,
      publishedAt: newState == PublicationState.published
          ? now
          : current.publishedAt,
      updatedAt: now,
    );

    _reports[index] = updated;
    return updated;
  }
}
