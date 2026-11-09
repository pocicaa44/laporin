import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../../core/services/boundary_service.dart';
import '../../core/services/media_service.dart';
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
  final Set<String> _loadedVoteUserIds = {};
  bool _hasFetchedFromSupabase = false;

  // In-memory record of reports whose details have been opened by an admin
  final Set<String> _viewedByAdminReportIds = {};

  /// Cek apakah laporan telah dibuka detailnya oleh admin
  bool isReportViewedByAdmin(String reportId) =>
      _viewedByAdminReportIds.contains(reportId);

  /// Tandai laporan telah dibuka detailnya oleh admin (sehingga label 'Baru' hilang)
  void markReportAsViewedByAdmin(String reportId) {
    _viewedByAdminReportIds.add(reportId);
  }

  Future<void> _fetchFromSupabaseIfAvailable({
    bool force = false,
    String? userId,
  }) async {
    final client = _service.client;
    final effectiveUserId = userId ?? client?.auth.currentUser?.id;

    if (_hasFetchedFromSupabase && !force) {
      if (effectiveUserId != null &&
          !_loadedVoteUserIds.contains(effectiveUserId) &&
          client != null &&
          _reports.isNotEmpty) {
        await _fetchUserVotes(client, effectiveUserId);
      }
      return;
    }

    if (client != null) {
      try {
        final response = await client.from('reports').select();
        final rawList = response as List;

        // Deserializing report records offloaded to background isolate
        final list = await _parseReportsInIsolate(rawList);

        // Batch enrich reports with latest author profile (avatar, username, full_name)
        try {
          final authorIds = list
              .map((r) => r.authorId)
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
              String? av = prof?['avatar_url'] as String?;
              final un = prof?['username'] as String?;
              final fn = prof?['full_name'] as String?;

              // Fallback jika profiles belum terisi avatar_url tapi ini adalah user yang sedang login
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

              list[i] = list[i].copyWith(
                authorAvatarUrl: finalAvatar,
                authorUsername: un ?? list[i].authorUsername,
                authorName: (fn != null && fn.isNotEmpty)
                    ? fn
                    : list[i].authorName,
              );
            }
          }
        } catch (_) {}

        // Batch enrich reports with actual comment counts from public.comments to self-heal
        try {
          final reportIds = list
              .map((r) => r.id)
              .where((id) => id.isNotEmpty)
              .toList();
          if (reportIds.isNotEmpty) {
            final commentsData = await client
                .from('comments')
                .select('report_id')
                .inFilter('report_id', reportIds)
                .isFilter('deleted_at', null);
            final countsMap = <String, int>{};
            for (final c in (commentsData as List)) {
              final rId = c['report_id']?.toString();
              if (rId != null) {
                countsMap[rId] = (countsMap[rId] ?? 0) + 1;
              }
            }
            for (var i = 0; i < list.length; i++) {
              final actualCount = countsMap[list[i].id] ?? 0;
              list[i] = list[i].copyWith(commentsCount: actualCount);
            }
          }
        } catch (_) {}

        _reports.clear();
        _reports.addAll(list);
        _hasFetchedFromSupabase = true;

        if (effectiveUserId != null) {
          await _fetchUserVotes(client, effectiveUserId);
        }
      } catch (_) {
        // Table does not exist in Supabase yet or network error, keep _reports
      }
    }
  }

  Future<void> _fetchUserVotes(dynamic client, String userId) async {
    try {
      final userVotes = await client
          .from('votes')
          .select('report_id, vote_type')
          .eq('user_id', userId);
      final voteMap = <String, String>{};
      for (final v in (userVotes as List)) {
        final rId = v['report_id']?.toString();
        final vType = v['vote_type']?.toString();
        if (rId != null && vType != null) {
          voteMap[rId] = vType;
          _reportUserVotes.putIfAbsent(rId, () => {})[userId] = vType;
        }
      }
      for (var i = 0; i < _reports.length; i++) {
        final rId = _reports[i].id;
        final v = voteMap[rId];
        _reports[i] = _reports[i].copyWith(
          currentUserVote: v,
          clearCurrentUserVote: v == null,
        );
      }
      _loadedVoteUserIds.add(userId);
    } catch (_) {}
  }

  /// Mengambil laporan dari memori cache lokal jika tersedia
  ReportModel? getCachedReport(String id, {String? userId}) {
    try {
      final cached = _reports.firstWhere((r) => r.id == id);
      final effectiveUserId = userId ?? _service.client?.auth.currentUser?.id;
      if (effectiveUserId != null && _reportUserVotes.containsKey(id)) {
        final vote = _reportUserVotes[id]?[effectiveUserId];
        return cached.copyWith(
          currentUserVote: vote,
          clearCurrentUserVote: vote == null,
        );
      }
      return cached;
    } catch (_) {
      return null;
    }
  }

  /// Memperbarui laporan di memori cache lokal
  void updateReport(ReportModel updatedReport) {
    final idx = _reports.indexWhere((r) => r.id == updatedReport.id);
    if (idx != -1) {
      _reports[idx] = updatedReport;
    } else {
      _reports.insert(0, updatedReport);
    }
    final client = _service.client;
    final currentUserId = client?.auth.currentUser?.id;
    if (currentUserId != null && updatedReport.currentUserVote != null) {
      _reportUserVotes.putIfAbsent(updatedReport.id, () => {})[currentUserId] =
          updatedReport.currentUserVote!;
    }
  }

  /// Memperbarui jumlah komentar laporan di memori cache lokal
  void updateReportCommentsCount(String reportId, int count) {
    final idx = _reports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      _reports[idx] = _reports[idx].copyWith(commentsCount: count);
    }
  }

  /// Invalidate cache Supabase
  void invalidateCache() {
    _hasFetchedFromSupabase = false;
    _loadedVoteUserIds.clear();
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
    String? provinceId,
    bool forceRefresh = false,
    int? limit,
    int? offset,
  }) async {
    await _fetchFromSupabaseIfAvailable(force: forceRefresh, userId: userId);

    if (_reports.isEmpty) return const [];

    final effectiveUserId = userId ?? _service.client?.auth.currentUser?.id;
    final List<ReportModel> reportsSnapshot;
    if (effectiveUserId != null) {
      reportsSnapshot = _reports.map((r) {
        final cachedUserVote = _reportUserVotes[r.id]?[effectiveUserId];
        final vote = _loadedVoteUserIds.contains(effectiveUserId)
            ? cachedUserVote
            : (cachedUserVote ?? r.currentUserVote);
        return r.copyWith(
          currentUserVote: vote,
          clearCurrentUserVote: vote == null,
        );
      }).toList();
    } else {
      reportsSnapshot = _reports.map((r) {
        return r.copyWith(currentUserVote: null, clearCurrentUserVote: true);
      }).toList();
    }

    List<ReportModel> filtered;
    if (kIsWeb || reportsSnapshot.length < 25) {
      filtered = _filterAndSortFeed(
        reports: reportsSnapshot,
        category: category,
        searchQuery: searchQuery,
        sortBy: sortBy,
        provinceId: provinceId,
      );
    } else {
      // Heavy string searching, category filtering, and sorting offloaded to background isolate
      filtered = await Isolate.run<List<ReportModel>>(() {
        return _filterAndSortFeed(
          reports: reportsSnapshot,
          category: category,
          searchQuery: searchQuery,
          sortBy: sortBy,
          provinceId: provinceId,
        );
      });
    }

    // Apply pagination window if requested
    if (limit != null && limit > 0) {
      final start = offset ?? 0;
      if (start >= filtered.length) return const [];
      final end = (start + limit < filtered.length)
          ? start + limit
          : filtered.length;
      return filtered.sublist(start, end);
    }

    return filtered;
  }

  /// Mengambil feed nasional dari Supabase RPC get_national_feed
  Future<List<ReportModel>> fetchNationalFeed({
    DateTime? cursorCreatedAt,
    int limit = 20,
    String? category,
    String? status,
    String? userId,
  }) async {
    final client = _service.client;
    if (client != null) {
      try {
        final params = <String, dynamic>{
          'p_limit': limit,
          if (cursorCreatedAt != null)
            'p_cursor_created_at': cursorCreatedAt.toUtc().toIso8601String(),
          if (category != null && category.isNotEmpty && category != 'Semua')
            'p_category': category,
          if (status != null && status.isNotEmpty) 'p_status': status,
        };
        final res = await client.rpc('get_national_feed', params: params);
        if (res is List) {
          return await _parseReportsInIsolate(res);
        }
      } catch (_) {}
    }
    return getPublicFeed(category: category, limit: limit, userId: userId);
  }

  /// Mengambil feed provinsi tertentu dari Supabase RPC get_provincial_feed
  Future<List<ReportModel>> fetchProvincialFeed({
    required String provinceId,
    DateTime? cursorCreatedAt,
    int limit = 20,
    String? category,
    String? status,
    String? userId,
  }) async {
    final client = _service.client;
    if (client != null) {
      try {
        final params = <String, dynamic>{
          'p_province_id': provinceId,
          'p_limit': limit,
          if (cursorCreatedAt != null)
            'p_cursor_created_at': cursorCreatedAt.toUtc().toIso8601String(),
          if (category != null && category.isNotEmpty && category != 'Semua')
            'p_category': category,
          if (status != null && status.isNotEmpty) 'p_status': status,
        };
        final res = await client.rpc('get_provincial_feed', params: params);
        if (res is List) {
          return await _parseReportsInIsolate(res);
        }
      } catch (_) {}
    }
    return getPublicFeed(
      category: category,
      provinceId: provinceId,
      limit: limit,
      userId: userId,
    );
  }

  /// Mengambil laporan dalam bounding box viewport peta (ST_MakeEnvelope)
  Future<List<ReportModel>> fetchReportsInViewport({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    int limit = 100,
  }) async {
    final client = _service.client;
    if (client != null) {
      try {
        final params = <String, dynamic>{
          'p_min_lat': minLat,
          'p_min_lng': minLng,
          'p_max_lat': maxLat,
          'p_max_lng': maxLng,
          'p_limit': limit,
        };
        final res = await client.rpc('get_reports_in_viewport', params: params);
        if (res is List) {
          return await _parseReportsInIsolate(res);
        }
      } catch (_) {}
    }
    return _reports
        .where(
          (r) =>
              r.isPubliclyVisible &&
              r.latitude >= minLat &&
              r.latitude <= maxLat &&
              r.longitude >= minLng &&
              r.longitude <= maxLng,
        )
        .take(limit)
        .toList();
  }

  static List<ReportModel> _filterAndSortFeed({
    required List<ReportModel> reports,
    String? category,
    String? searchQuery,
    String? sortBy,
    String? provinceId,
  }) {
    var list = reports.where((r) => r.isPubliclyVisible).toList();

    if (provinceId != null &&
        provinceId.isNotEmpty &&
        provinceId != 'all' &&
        provinceId != 'national') {
      list = list.where((r) {
        if (r.provinceId == provinceId) return true;
        if (r.areaId.contains(provinceId)) return true;
        return false;
      }).toList();
    }

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

  /// Mengambil laporan milik pengguna tertentu (hanya yang aktif / belum di-soft-delete)
  Future<List<ReportModel>> getMyReports(
    String userId, {
    bool forceRefresh = false,
    bool includeDeleted = false,
    int? limit,
    int? offset,
  }) async {
    await _fetchFromSupabaseIfAvailable(force: forceRefresh);
    final reportsSnapshot = List<ReportModel>.from(_reports);

    List<ReportModel> list;
    if (kIsWeb || reportsSnapshot.length < 25) {
      var filtered = reportsSnapshot
          .where((r) => r.authorId == userId)
          .toList();
      if (!includeDeleted) {
        filtered = filtered.where((r) => !r.deletedByUser).toList();
      }
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      list = filtered;
    } else {
      list = await Isolate.run<List<ReportModel>>(() {
        var filtered = reportsSnapshot
            .where((r) => r.authorId == userId)
            .toList();
        if (!includeDeleted) {
          filtered = filtered.where((r) => !r.deletedByUser).toList();
        }
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return filtered;
      });
    }

    // Apply pagination window if requested
    if (limit != null && limit > 0) {
      final start = offset ?? 0;
      if (start >= list.length) return const [];
      final end = (start + limit < list.length) ? start + limit : list.length;
      return list.sublist(start, end);
    }

    return list;
  }

  /// Mengambil semua laporan untuk portal Admin (termasuk yang 'held', 'pending_review', 'rejected')
  Future<List<ReportModel>> getAdminReports({
    String? filterStatus,
    bool forceRefresh = false,
  }) async {
    await _fetchFromSupabaseIfAvailable(force: forceRefresh);
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
    var list = reports.where((r) => !r.deletedByAdmin && !r.isDraft).toList();

    if (filterStatus == 'deleted_by_user') {
      list = list.where((r) => r.deletedByUser).toList();
    } else if (filterStatus == 'held') {
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
  Future<ReportModel?> getReportById(String id, {String? userId}) async {
    final client = _service.client;
    final effectiveUserId = userId ?? client?.auth.currentUser?.id;

    if (client != null) {
      try {
        final response = await client
            .from('reports')
            .select()
            .eq('id', id)
            .maybeSingle();
        if (response != null) {
          var fetched = ReportModel.fromJson(response);

          // Enrich with latest author profile (avatar, username, full_name)
          if (fetched.authorId.isNotEmpty) {
            try {
              final prof = await client
                  .from('profiles')
                  .select('username, full_name, avatar_url')
                  .eq('id', fetched.authorId)
                  .maybeSingle();
              if (prof != null) {
                String? av = prof['avatar_url'] as String?;
                final un = prof['username'] as String?;
                final fn = prof['full_name'] as String?;

                if ((av == null || av.trim().isEmpty) &&
                    effectiveUserId != null &&
                    fetched.authorId == effectiveUserId) {
                  final cur = client.auth.currentUser;
                  av =
                      cur?.userMetadata?['avatar_url'] as String? ??
                      cur?.userMetadata?['picture'] as String? ??
                      cur?.userMetadata?['photo_url'] as String?;
                }

                final finalAvatar = (av != null && av.trim().isNotEmpty)
                    ? av
                    : fetched.authorAvatarUrl;

                fetched = fetched.copyWith(
                  authorAvatarUrl: finalAvatar,
                  authorUsername: un ?? fetched.authorUsername,
                  authorName: (fn != null && fn.isNotEmpty)
                      ? fn
                      : fetched.authorName,
                );
              }
            } catch (_) {}
          }

          if (effectiveUserId != null) {
            try {
              final userVote = await client
                  .from('votes')
                  .select('vote_type')
                  .eq('report_id', id)
                  .eq('user_id', effectiveUserId)
                  .maybeSingle();
              final vType = userVote?['vote_type'] as String?;
              fetched = fetched.copyWith(
                currentUserVote: vType,
                clearCurrentUserVote: vType == null,
              );
              if (vType != null) {
                _reportUserVotes.putIfAbsent(id, () => {})[effectiveUserId] =
                    vType;
              } else {
                _reportUserVotes[id]?.remove(effectiveUserId);
              }
            } catch (_) {
              final cachedVote = _reportUserVotes[id]?[effectiveUserId];
              if (cachedVote != null) {
                fetched = fetched.copyWith(currentUserVote: cachedVote);
              }
            }
          }

          // Enrich with accurate comments_count from public.comments
          try {
            final commentsCountResp = await client
                .from('comments')
                .select('id')
                .eq('report_id', id)
                .isFilter('deleted_at', null);
            fetched = fetched.copyWith(
              commentsCount: (commentsCountResp as List).length,
            );
          } catch (_) {}

          updateReport(fetched);
          return fetched;
        }
      } catch (_) {}
    }

    // In-memory fallback
    try {
      final cached = _reports.firstWhere((r) => r.id == id);
      if (effectiveUserId != null && _reportUserVotes.containsKey(id)) {
        final cachedVote = _reportUserVotes[id]?[effectiveUserId];
        return cached.copyWith(
          currentUserVote: cachedVote,
          clearCurrentUserVote: cachedVote == null,
        );
      }
      return cached;
    } catch (_) {
      return null;
    }
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
    String? provinceId,
    List<String> photoUrls = const [],
    bool isCallerAdmin = false,
    bool isDraft = false,
  }) async {
    // Invarian PRD: Admin tidak dapat membuat laporan baru
    if (isCallerAdmin) {
      throw Exception('Petugas / Admin tidak diizinkan membuat laporan baru.');
    }

    final client = _service.client;
    if (client != null && client.auth.currentUser != null) {
      final metaRole = client.auth.currentUser!.userMetadata?['role']
          ?.toString();
      if (metaRole == 'admin') {
        throw Exception(
          'Petugas / Admin tidak diizinkan membuat laporan baru.',
        );
      }
    }

    // Validasi aturan bisnis: lokasi wajib di dalam batas wilayah Indonesia
    if (!BoundaryService.instance.isInsideIndonesia(latitude, longitude)) {
      throw Exception(BoundaryService.outsideIndonesiaErrorMessage);
    }

    final now = DateTime.now();

    // Pastikan nomor laporan unik dan sinkron dengan sequence laporan terakhir di server
    int nextNumber = _reports.length + 1;
    if (client != null) {
      try {
        final res = await client
            .from('reports')
            .select('report_number')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (res != null && res['report_number'] != null) {
          final str = res['report_number'].toString();
          final parts = str.split('-');
          if (parts.length >= 3) {
            final lastNum = int.tryParse(parts.last);
            if (lastNum != null && lastNum >= nextNumber) {
              nextNumber = lastNum + 1;
            }
          }
        }
      } catch (_) {}
    }

    while (_reports.any(
      (r) =>
          r.reportNumber ==
          'LPR-${now.year}-${nextNumber.toString().padLeft(4, '0')}',
    )) {
      nextNumber++;
    }

    String? resolvedAuthorAvatar = authorAvatarUrl;
    if (resolvedAuthorAvatar == null || resolvedAuthorAvatar.trim().isEmpty) {
      final curUser = client?.auth.currentUser;
      if (curUser != null && curUser.id == authorId) {
        resolvedAuthorAvatar =
            curUser.userMetadata?['avatar_url'] as String? ??
            curUser.userMetadata?['picture'] as String? ??
            curUser.userMetadata?['photo_url'] as String?;
      }
    }

    var newReport = ReportModel(
      id: 'rep-${DateTime.now().millisecondsSinceEpoch}',
      reportNumber: 'LPR-${now.year}-${nextNumber.toString().padLeft(4, '0')}',
      authorId: authorId,
      authorName: authorName,
      authorUsername: authorUsername,
      authorAvatarUrl: resolvedAuthorAvatar,
      areaId: provinceId != null ? 'area-$provinceId' : 'area-jateng',
      areaName: areaName ?? BoundaryService.defaultAreaName,
      provinceId: provinceId,
      title: title.trim(),
      description: description.trim(),
      category: category,
      latitude: latitude,
      longitude: longitude,
      locationAddress: locationAddress,
      handlingStatus: HandlingStatus.newReport,
      publicationState: isDraft
          ? PublicationState.pendingReview
          : PublicationState.published,
      publishedAt: isDraft ? null : now,
      isDraft: isDraft,
      createdAt: now,
      updatedAt: now,
      photoUrls: photoUrls,
    );

    if (client != null && client.auth.currentUser != null) {
      bool inserted = false;
      int attempts = 0;
      while (!inserted && attempts < 3) {
        attempts++;
        try {
          final insertData = newReport.toJson()
            ..removeWhere((key, value) => value == null);
          await client.from('reports').insert(insertData);
          inserted = true;
        } catch (e) {
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('reports_report_number_key') ||
              errorStr.contains('duplicate key')) {
            nextNumber++;
            newReport = newReport.copyWith(
              reportNumber:
                  'LPR-${now.year}-${nextNumber.toString().padLeft(4, '0')}',
            );
          } else {
            throw Exception('Gagal menyimpan laporan ke server: $e');
          }
        }
      }
    }

    _reports.insert(0, newReport);
    return newReport;
  }

  /// Mempublikasikan laporan yang sebelumnya disimpan sebagai draft
  Future<ReportModel> publishDraft(String reportId) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) throw Exception('Laporan tidak ditemukan');

    final current = _reports[index];
    if (!current.isDraft) {
      throw Exception('Laporan ini bukan draft.');
    }

    final now = DateTime.now();
    final updated = current.copyWith(
      isDraft: false,
      publicationState: PublicationState.published,
      publishedAt: now,
      updatedAt: now,
    );

    final client = _service.client;
    if (client != null) {
      try {
        await client
            .from('reports')
            .update({
              'is_draft': false,
              'publication_state': PublicationState.published.value,
              'published_at': now.toUtc().toIso8601String(),
              'updated_at': now.toUtc().toIso8601String(),
            })
            .eq('id', reportId);
      } catch (e) {
        throw Exception('Gagal mempublikasikan draft: $e');
      }
    }

    _reports[index] = updated;
    return updated;
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

    // Invarian: Vote hanya aktif jika isVotingActive (bukan completed, rejected, cancelled, atau deleted)
    if (!current.isVotingActive) {
      throw Exception('Laporan tidak dapat menerima interaksi vote.');
    }

    final userVotesForReport = _reportUserVotes.putIfAbsent(reportId, () => {});
    final existingUserVote =
        userVotesForReport[userId] ??
        (userVotesForReport.isEmpty ? current.currentUserVote : null);

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

    var updated = current.copyWith(
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
        // Panggil RPC atomik vote_report di database dan ambil hasil authoritative dari server
        final rpcResult = await client.rpc(
          'vote_report',
          params: {'p_report_id': reportId, 'p_vote_type': voteType},
        );

        dynamic data = rpcResult;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }

        if (data is Map) {
          final serverVote = data['current_user_vote'] as String?;
          final serverUp =
              (data['upvotes_count'] as num?)?.toInt() ?? updated.upvotesCount;
          final serverDown =
              (data['downvotes_count'] as num?)?.toInt() ??
              updated.downvotesCount;
          final pubStateStr = data['publication_state'] as String?;
          final serverPubState = pubStateStr != null
              ? PublicationState.fromString(pubStateStr)
              : updated.publicationState;
          final serverModReason =
              data['moderation_reason'] as String? ?? updated.moderationReason;

          if (serverVote != null) {
            userVotesForReport[effectiveUserId] = serverVote;
          } else {
            userVotesForReport.remove(effectiveUserId);
          }

          updated = updated.copyWith(
            upvotesCount: serverUp,
            downvotesCount: serverDown,
            currentUserVote: serverVote,
            clearCurrentUserVote: serverVote == null,
            publicationState: serverPubState,
            moderationReason: serverModReason,
          );
        }
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
    var index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) {
      final fetched = await getReportById(reportId);
      if (fetched != null) {
        index = _reports.indexWhere((r) => r.id == reportId);
      }
    }
    if (index == -1) throw Exception('Laporan tidak ditemukan');

    final current = _reports[index];
    final now = DateTime.now();

    // Invarian: Laporan yang sudah selesai atau ditolak tidak dapat diubah statusnya lagi
    if (current.handlingStatus == HandlingStatus.completed ||
        current.handlingStatus == HandlingStatus.rejected) {
      throw Exception(
        'Laporan yang sudah selesai atau ditolak tidak dapat diubah statusnya lagi.',
      );
    }

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

    final autoDisableDiscussion =
        newStatus == HandlingStatus.completed ||
        newStatus == HandlingStatus.rejected;
    final newDiscussionActive = autoDisableDiscussion
        ? false
        : current.isDiscussionActive;

    final updated = current.copyWith(
      handlingStatus: newStatus,
      isDiscussionActive: newDiscussionActive,
      rejectionReason: newStatus == HandlingStatus.rejected
          ? reason
          : current.rejectionReason,
      moderationReason: newStatus == HandlingStatus.cancelled
          ? reason
          : current.moderationReason,
      completionNotes: newStatus == HandlingStatus.completed
          ? (reason ?? current.completionNotes)
          : current.completionNotes,
      completionProofUrl: completionProofUrl ?? current.completionProofUrl,
      completionProofType: completionProofType ?? current.completionProofType,
      terminalAt: terminalAt,
      archiveAfter: archiveAfter,
      updatedAt: now,
    );

    final client = _service.client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client
            .from('reports')
            .update({
              'handling_status': updated.handlingStatus.value,
              'is_discussion_active': updated.isDiscussionActive,
              'rejection_reason': updated.rejectionReason,
              'moderation_reason': updated.moderationReason,
              'completion_notes': updated.completionNotes,
              'completion_proof_url': updated.completionProofUrl,
              'completion_proof_type': updated.completionProofType,
              'terminal_at': updated.terminalAt?.toUtc().toIso8601String(),
              'archive_after': updated.archiveAfter?.toUtc().toIso8601String(),
              'updated_at': updated.updatedAt.toUtc().toIso8601String(),
            })
            .eq('id', reportId)
            .select();
        if ((res as List).isEmpty) {
          throw Exception(
            'Pembaruan status ditolak oleh server (periksa izin akses admin Anda).',
          );
        }
      } catch (dbError) {
        debugPrint('Catatan update handling status di Supabase: $dbError');
        rethrow;
      }
    }

    _reports[index] = updated;
    return updated;
  }

  /// Moderasi publikasi oleh Admin (Publish ulang dari 'held', atau tahan)
  Future<ReportModel> updatePublicationState({
    required String reportId,
    required PublicationState newState,
    required String reason,
  }) async {
    var index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) {
      final fetched = await getReportById(reportId);
      if (fetched != null) {
        index = _reports.indexWhere((r) => r.id == reportId);
      }
    }
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

    final client = _service.client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client
            .from('reports')
            .update({
              'publication_state': updated.publicationState.value,
              'moderation_reason': updated.moderationReason,
              'published_at': updated.publishedAt?.toUtc().toIso8601String(),
              'updated_at': updated.updatedAt.toUtc().toIso8601String(),
            })
            .eq('id', reportId)
            .select();
        if ((res as List).isEmpty) {
          throw Exception('Pembaruan publikasi ditolak oleh server.');
        }
      } catch (dbError) {
        debugPrint('Catatan update publication state di Supabase: $dbError');
        rethrow;
      }
    }

    _reports[index] = updated;
    return updated;
  }

  /// Mengedit detail laporan oleh pemiliknya (PRD FR-03 & Aturan CRUD).
  /// Hanya field yang diizinkan yang dapat diperbarui (judul, deskripsi, kategori, lokasi, foto).
  Future<ReportModel> updateReportDetails({
    required String reportId,
    required String currentUserId,
    required String title,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    required String locationAddress,
    String? areaName,
    required List<String> photoUrls,
  }) async {
    var index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) {
      final fetched = await getReportById(reportId);
      if (fetched != null) {
        index = _reports.indexWhere((r) => r.id == reportId);
      }
    }
    if (index == -1) throw Exception('Laporan tidak ditemukan');

    final current = _reports[index];

    // Otorisasi: Hanya pemilik yang berhak mengedit
    if (current.authorId != currentUserId) {
      throw Exception('Anda tidak memiliki izin untuk mengedit laporan ini.');
    }

    // Integritas: Laporan yang sudah di-soft-delete tidak boleh diedit
    if (current.isDeleted) {
      throw Exception('Laporan yang sudah dihapus tidak dapat diedit.');
    }

    // Integritas: Laporan yang berstatus terminal tidak boleh diedit
    if (current.isTerminal) {
      throw Exception(
        'Laporan dengan status final/terminal tidak dapat diedit.',
      );
    }

    // Validasi aturan bisnis: Lokasi wajib berada di wilayah Indonesia
    if (!BoundaryService.instance.isInsideIndonesia(latitude, longitude)) {
      throw Exception(BoundaryService.outsideIndonesiaErrorMessage);
    }

    final now = DateTime.now();
    final updated = current.copyWith(
      title: title.trim(),
      description: description.trim(),
      category: category,
      latitude: latitude,
      longitude: longitude,
      locationAddress: locationAddress,
      areaName: areaName ?? current.areaName,
      photoUrls: photoUrls,
      updatedAt: now,
    );

    final client = _service.client;
    if (client != null && client.auth.currentUser != null) {
      try {
        await client
            .from('reports')
            .update({
              'title': updated.title,
              'description': updated.description,
              'category': updated.category,
              'latitude': updated.latitude,
              'longitude': updated.longitude,
              'location_address': updated.locationAddress,
              'area_name': updated.areaName,
              'photo_urls': updated.photoUrls,
              'updated_at': updated.updatedAt.toUtc().toIso8601String(),
            })
            .eq('id', reportId)
            .eq('author_id', currentUserId);
      } catch (e) {
        throw Exception('Gagal menyimpan perubahan ke server: $e');
      }
    }

    _reports[index] = updated;
    return updated;
  }

  /// Menghapus laporan per-pihak (Soft Delete) atau permanen (Hard Delete) jika kedua belah pihak sudah menghapus.
  /// Syarat menghapus permanen: Admin DAN User (Pelapor) harus sudah menghapus laporannya.
  /// Jika kedua belah pihak sudah menghapus, seluruh media lampiran dibersihkan dari Storage
  /// dan record laporan dihapus secara fisik dari database.
  Future<ReportModel> softDeleteReport({
    required String reportId,
    required String currentUserId,
    bool isCallerAdmin = false,
  }) async {
    var index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) {
      final fetched = await getReportById(reportId);
      if (fetched != null) {
        index = _reports.indexWhere((r) => r.id == reportId);
      }
    }
    if (index == -1) throw Exception('Laporan tidak ditemukan');

    final current = _reports[index];

    // Otorisasi: Pemilik atau Admin yang berhak menghapus
    if (!isCallerAdmin && current.authorId != currentUserId) {
      throw Exception('Anda tidak memiliki izin untuk menghapus laporan ini.');
    }

    // Validasi aturan penghapusan:
    // Selain laporan yang dihapus oleh user, yang sudah selesai atau ditolak,
    // dan laporan yang batal, baik admin ataupun user TIDAK BISA menghapus laporan.
    if (!isCallerAdmin) {
      if (current.deletedByUser) {
        throw Exception('Laporan ini sudah dihapus oleh Anda sebelumnya.');
      }
      if (!current.canAuthorDelete) {
        throw Exception(
          'Hanya laporan yang baru dipublikasikan, sudah selesai, ditolak, atau dibatalkan yang dapat dihapus oleh pelapor.',
        );
      }
    } else {
      if (current.deletedByAdmin) {
        throw Exception('Laporan ini sudah dihapus oleh admin sebelumnya.');
      }
      if (!current.canAdminDelete) {
        throw Exception(
          'Admin hanya dapat menghapus laporan yang baru dipublikasikan, sudah dihapus oleh pelapor, atau berstatus selesai, ditolak, dan dibatalkan.',
        );
      }
    }

    final now = DateTime.now();
    final bool newDeletedByUser = isCallerAdmin ? current.deletedByUser : true;
    final DateTime? newDeletedByUserAt = isCallerAdmin
        ? current.deletedByUserAt
        : now;
    final bool newDeletedByAdmin = isCallerAdmin
        ? true
        : current.deletedByAdmin;
    final DateTime? newDeletedByAdminAt = isCallerAdmin
        ? now
        : current.deletedByAdminAt;

    // Evaluasi syarat penghapusan permanen: DUAL PARTY (User AND Admin)
    final bool willPermanentlyDelete = newDeletedByUser && newDeletedByAdmin;

    final client = _service.client;

    if (willPermanentlyDelete) {
      // 1. Bersihkan semua file media (lampiran foto & bukti penanganan) dari Supabase Storage
      try {
        await MediaService.instance.deleteReportMedia(
          photoUrls: current.photoUrls,
          completionProofUrl: current.completionProofUrl,
        );
      } catch (mediaError) {
        debugPrint(
          'Catatan pembersihan media storage saat hard delete: $mediaError',
        );
      }

      // 2. Hapus secara fisik dari database Supabase
      if (client != null && client.auth.currentUser != null) {
        try {
          try {
            await client.rpc(
              'execute_dual_party_deletion',
              params: {'p_report_id': reportId, 'p_is_admin': isCallerAdmin},
            );
          } catch (rpcError) {
            debugPrint(
              'Catatan RPC execute_dual_party_deletion: $rpcError, fallback ke DELETE query',
            );
            await client.from('reports').delete().eq('id', reportId);
          }
        } catch (dbError) {
          throw Exception(
            'Gagal menghapus laporan secara permanen di server: $dbError',
          );
        }
      }

      // 3. Hapus dari memori lokal repository
      _reports.removeAt(index);
      _reportUserVotes.remove(reportId);

      return current.copyWith(
        deletedByUser: true,
        deletedByUserAt: newDeletedByUserAt,
        deletedByAdmin: true,
        deletedByAdminAt: newDeletedByAdminAt,
        deletedAt: current.deletedAt ?? now,
        updatedAt: now,
      );
    } else {
      // Baru salah satu pihak yang menghapus: lakukan soft-delete untuk pihak terkait
      final deleteReason = isCallerAdmin
          ? 'Dihapus oleh petugas / admin'
          : 'Dihapus oleh pelapor';

      final finalHandlingStatus =
          (current.handlingStatus == HandlingStatus.completed ||
              current.handlingStatus == HandlingStatus.rejected)
          ? current.handlingStatus
          : HandlingStatus.cancelled;

      final updated = current.copyWith(
        deletedByUser: newDeletedByUser,
        deletedByUserAt: newDeletedByUserAt,
        deletedByAdmin: newDeletedByAdmin,
        deletedByAdminAt: newDeletedByAdminAt,
        deletedAt: current.deletedAt ?? now,
        handlingStatus: finalHandlingStatus,
        terminalAt: current.terminalAt ?? now,
        archiveAfter: now.add(const Duration(hours: 24)),
        moderationReason: deleteReason,
        updatedAt: now,
      );

      if (client != null && client.auth.currentUser != null) {
        try {
          try {
            await client.rpc(
              'execute_dual_party_deletion',
              params: {'p_report_id': reportId, 'p_is_admin': isCallerAdmin},
            );
          } catch (rpcError) {
            debugPrint(
              'Catatan RPC execute_dual_party_deletion: $rpcError, fallback ke UPDATE',
            );
            var query = client
                .from('reports')
                .update({
                  'deleted_by_user': newDeletedByUser,
                  'deleted_by_user_at': newDeletedByUserAt
                      ?.toUtc()
                      .toIso8601String(),
                  'deleted_by_admin': newDeletedByAdmin,
                  'deleted_by_admin_at': newDeletedByAdminAt
                      ?.toUtc()
                      .toIso8601String(),
                  'deleted_at': updated.deletedAt?.toUtc().toIso8601String(),
                  'handling_status': finalHandlingStatus.value,
                  'moderation_reason': deleteReason,
                  'terminal_at': updated.terminalAt?.toUtc().toIso8601String(),
                  'archive_after': now
                      .add(const Duration(hours: 24))
                      .toUtc()
                      .toIso8601String(),
                  'updated_at': now.toUtc().toIso8601String(),
                })
                .eq('id', reportId);

            if (!isCallerAdmin) {
              query = query.eq('author_id', currentUserId);
            }

            await query;
          }
        } catch (e) {
          throw Exception('Gagal memproses penghapusan laporan di server: $e');
        }
      }

      _reports[index] = updated;
      return updated;
    }
  }

  /// Toggle status diskusi oleh pemilik laporan atau admin
  Future<ReportModel> toggleDiscussionActive({
    required String reportId,
    required String currentUserId,
    required bool isDiscussionActive,
    bool isCallerAdmin = false,
  }) async {
    var index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) {
      final fetched = await getReportById(reportId);
      if (fetched != null) {
        index = _reports.indexWhere((r) => r.id == reportId);
      }
    }
    if (index == -1) throw Exception('Laporan tidak ditemukan');

    final current = _reports[index];

    // Otorisasi: Hanya pemilik atau admin yang berhak mengubah status diskusi
    if (!isCallerAdmin && current.authorId != currentUserId) {
      throw Exception(
        'Anda tidak memiliki izin untuk mengubah status diskusi laporan ini.',
      );
    }

    if (current.isDeleted) {
      throw Exception(
        'Laporan ini telah dihapus dan diskusinya tidak dapat diubah.',
      );
    }

    if (current.handlingStatus == HandlingStatus.rejected) {
      throw Exception('Laporan yang ditolak tidak dapat mengaktifkan diskusi.');
    }

    final now = DateTime.now();
    final updated = current.copyWith(
      isDiscussionActive: isDiscussionActive,
      updatedAt: now,
    );

    _reports[index] = updated;

    final client = _service.client;
    if (client != null && client.auth.currentUser != null) {
      try {
        var query = client
            .from('reports')
            .update({
              'is_discussion_active': isDiscussionActive,
              'updated_at': now.toUtc().toIso8601String(),
            })
            .eq('id', reportId);

        if (!isCallerAdmin) {
          query = query.eq('author_id', currentUserId);
        }

        await query;
      } catch (e) {
        debugPrint('Warning: gagal menyimpan toggle diskusi ke Supabase: $e');
      }
    }

    return updated;
  }
}
