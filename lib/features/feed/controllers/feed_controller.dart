import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

/// Controller for managing the public thread feed.
class FeedController extends ChangeNotifier {
  FeedController({required this.reportRepository, this.currentUserId}) {
    fetchFeed();
  }

  final ReportRepository reportRepository;
  String? currentUserId;

  List<ReportModel> _reports = [];
  List<ReportModel> get reports => _reports;

  static const int pageSize = 10;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String _selectedCategory = 'Semua';
  String get selectedCategory => _selectedCategory;

  String _sortBy = 'newest';
  String get sortBy => _sortBy;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Set untuk mengunci request in-flight per reportId agar tidak terjadi race condition
  final Set<String> _votingReportIds = <String>{};
  bool isVoting(String reportId) => _votingReportIds.contains(reportId);

  Timer? _searchDebounceTimer;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> fetchFeed([String? userId, bool forceRefresh = true]) async {
    if (userId != null) currentUserId = userId;
    if (_reports.isEmpty) {
      _isLoading = true;
    } else {
      _isRefreshing = true;
    }
    notifyListeners();

    try {
      final result = await reportRepository.getPublicFeed(
        category: _selectedCategory,
        searchQuery: _searchQuery,
        sortBy: _sortBy,
        userId: currentUserId,
        forceRefresh: forceRefresh,
        limit: pageSize,
        offset: 0,
      );
      if (_isDisposed) return;
      _reports = result;
      _hasMore = result.length >= pageSize;
    } catch (_) {
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isRefreshing || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await reportRepository.getPublicFeed(
        category: _selectedCategory,
        searchQuery: _searchQuery,
        sortBy: _sortBy,
        userId: currentUserId,
        forceRefresh: false,
        limit: pageSize,
        offset: _reports.length,
      );
      if (_isDisposed) return;

      if (result.isEmpty) {
        _hasMore = false;
      } else {
        final existingIds = _reports.map((r) => r.id).toSet();
        final newItems = result
            .where((r) => !existingIds.contains(r.id))
            .toList();
        _reports.addAll(newItems);
        _hasMore = result.length >= pageSize;
      }
    } catch (_) {
    } finally {
      if (!_isDisposed) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    fetchFeed();
  }

  void setSortBy(String sort) {
    if (_sortBy == sort) return;
    _sortBy = sort;
    fetchFeed();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      fetchFeed();
    });
  }

  /// Sinkronisasi laporan secara instan dari halaman detail / event eksternal
  void syncReport(ReportModel updatedReport) {
    final idx = _reports.indexWhere((r) => r.id == updatedReport.id);
    if (idx != -1) {
      if (!updatedReport.isPubliclyVisible) {
        _reports.removeAt(idx);
      } else {
        _reports[idx] = updatedReport;
      }
      notifyListeners();
    }
  }

  Future<void> vote(String reportId, String userId, String voteType) async {
    // 1. Pencegahan Race Condition: In-flight request lock per reportId
    if (_votingReportIds.contains(reportId)) {
      return;
    }

    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return;

    final currentReport = _reports[index];

    // Invarian Produk: Laporan harus publik dan non-terminal
    if (!currentReport.isPubliclyVisible || currentReport.isTerminal) {
      return;
    }

    // 2. Optimistic UI Update: Terapkan perubahan seketika tanpa menunggu respon jaringan
    final previousReport = currentReport;
    final optimisticReport = currentReport.calculateOptimisticVote(voteType);

    _votingReportIds.add(reportId);
    _errorMessage = null;

    // Jika downvote mencapai ambang batas dan status menjadi 'held', laporan wajib seketika lenyap dari feed
    if (!optimisticReport.isPubliclyVisible) {
      _reports.removeAt(index);
    } else {
      _reports[index] = optimisticReport;
    }
    notifyListeners();

    // 3. Eksekusi asynchronous request ke backend/repository
    try {
      final updated = await reportRepository.voteReport(
        reportId: reportId,
        userId: userId,
        voteType: voteType,
      );

      if (_isDisposed) return;

      if (!updated.isPubliclyVisible) {
        _reports.removeWhere((r) => r.id == reportId);
      } else {
        final currentIndex = _reports.indexWhere((r) => r.id == reportId);
        if (currentIndex != -1) {
          _reports[currentIndex] = updated;
        }
      }
      notifyListeners();
    } catch (e) {
      if (_isDisposed) return;

      // 4. Rollback State ke kondisi semula jika request gagal
      final currentIndex = _reports.indexWhere((r) => r.id == reportId);
      if (currentIndex != -1) {
        _reports[currentIndex] = previousReport;
      } else if (previousReport.isPubliclyVisible) {
        _reports.insert(index.clamp(0, _reports.length), previousReport);
      }
      _errorMessage = 'Gagal memperbarui vote. Silakan coba kembali.';
      notifyListeners();
    } finally {
      _votingReportIds.remove(reportId);
    }
  }
}
