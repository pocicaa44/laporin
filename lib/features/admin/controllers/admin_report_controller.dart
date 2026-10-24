import 'package:flutter/material.dart';

import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

/// Controller for Admin & Moderator workflows
class AdminReportController extends ChangeNotifier {
  AdminReportController({required this.reportRepository}) {
    fetchReports();
  }

  final ReportRepository reportRepository;

  List<ReportModel> _allReports = [];
  List<ReportModel> get reports => _allReports;

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

  String _filter = 'all'; // 'all', 'held', 'new', 'in_progress', 'completed'
  String get filter => _filter;

  int get totalReports => _allReports.length;
  int get heldCount => _allReports
      .where((r) => r.publicationState == PublicationState.held)
      .length;
  int get inProgressCount => _allReports
      .where(
        (r) =>
            r.handlingStatus == HandlingStatus.inProgress ||
            r.handlingStatus == HandlingStatus.accepted,
      )
      .length;
  int get completedCount => _allReports
      .where((r) => r.handlingStatus == HandlingStatus.completed)
      .length;

  final Set<String> _processingReportIds = <String>{};
  bool isProcessing(String reportId) => _processingReportIds.contains(reportId);

  Future<void> fetchReports() async {
    if (_allReports.isEmpty) {
      _isLoading = true;
    }
    notifyListeners();

    try {
      final list = await reportRepository.getAdminReports(
        filterStatus: _filter == 'all' ? null : _filter,
      );
      if (_isDisposed) return;
      _allReports = list;
    } catch (_) {
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void setFilter(String newFilter) {
    _filter = newFilter;
    fetchReports();
  }

  Future<bool> updateStatus({
    required String reportId,
    required HandlingStatus newStatus,
    String? reason,
    String? proofUrl,
  }) async {
    if (_processingReportIds.contains(reportId)) return false;
    _processingReportIds.add(reportId);
    notifyListeners();

    try {
      await reportRepository.updateHandlingStatus(
        reportId: reportId,
        newStatus: newStatus,
        reason: reason,
        completionProofUrl: proofUrl,
        completionProofType: proofUrl != null ? 'completion_photo' : null,
      );
      await fetchReports();
      return true;
    } catch (_) {
      return false;
    } finally {
      _processingReportIds.remove(reportId);
      notifyListeners();
    }
  }

  Future<bool> restorePublication(String reportId, String reason) async {
    if (_processingReportIds.contains(reportId)) return false;
    _processingReportIds.add(reportId);
    notifyListeners();

    try {
      await reportRepository.updatePublicationState(
        reportId: reportId,
        newState: PublicationState.published,
        reason: reason,
      );
      await fetchReports();
      return true;
    } catch (_) {
      return false;
    } finally {
      _processingReportIds.remove(reportId);
      notifyListeners();
    }
  }
}
