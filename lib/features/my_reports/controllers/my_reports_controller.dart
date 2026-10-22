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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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

  Future<void> fetchMyReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await reportRepository.getMyReports(userId);
      if (_isDisposed) return;
      _reports = result;
    } catch (_) {
      // Handle or swallow if needed
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
