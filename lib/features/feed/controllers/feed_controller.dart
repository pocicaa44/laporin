import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

/// Controller for managing the public thread feed.
class FeedController extends ChangeNotifier {
  FeedController({required this.reportRepository}) {
    fetchFeed();
  }

  final ReportRepository reportRepository;

  List<ReportModel> _reports = [];
  List<ReportModel> get reports => _reports;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _selectedCategory = 'Semua';
  String get selectedCategory => _selectedCategory;

  String _sortBy = 'newest';
  String get sortBy => _sortBy;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

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

  Future<void> fetchFeed() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await reportRepository.getPublicFeed(
        category: _selectedCategory,
        searchQuery: _searchQuery,
        sortBy: _sortBy,
      );
      if (_isDisposed) return;
      _reports = result;
    } catch (_) {
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
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

  Future<void> vote(String reportId, String userId, String voteType) async {
    try {
      final updated = await reportRepository.voteReport(
        reportId: reportId,
        userId: userId,
        voteType: voteType,
      );

      // If the report reached downvote threshold and became 'held', it must vanish from public feed immediately!
      if (!updated.isPubliclyVisible) {
        _reports.removeWhere((r) => r.id == reportId);
      } else {
        final index = _reports.indexWhere((r) => r.id == reportId);
        if (index != -1) {
          _reports[index] = updated;
        }
      }
      notifyListeners();
    } catch (_) {}
  }
}
