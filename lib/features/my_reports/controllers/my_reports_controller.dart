import 'package:flutter/material.dart';

import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

/// Controller for citizen personal reports list
class MyReportsController extends ChangeNotifier {
  MyReportsController({required this.userId, required this.reportRepository}) {
    fetchMyReports();
  }

  final String userId;
  final ReportRepository reportRepository;

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

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> fetchMyReports({bool forceRefresh = false}) async {
    if (_reports.isEmpty) {
      _isLoading = true;
    } else {
      _isRefreshing = true;
    }
    notifyListeners();

    try {
      final result = await reportRepository.getMyReports(
        userId,
        forceRefresh: forceRefresh,
        limit: pageSize,
        offset: 0,
      );
      if (_isDisposed) return;
      _reports = result;
      _hasMore = result.length >= pageSize;
    } catch (_) {
      // Handle or swallow if needed
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
      final result = await reportRepository.getMyReports(
        userId,
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
}
