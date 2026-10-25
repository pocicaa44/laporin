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
  int get deletedByUserCount =>
      _allReports.where((r) => r.deletedByUser && !r.deletedByAdmin).length;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final Set<String> _processingReportIds = <String>{};
  bool isProcessing(String reportId) => _processingReportIds.contains(reportId);

  bool isReportViewed(String reportId) =>
      reportRepository.isReportViewedByAdmin(reportId);

  void markReportAsViewed(String reportId) {
    reportRepository.markReportAsViewedByAdmin(reportId);
    notifyListeners();
  }

  Future<void> fetchReports({bool forceRefresh = false}) async {
    if (_allReports.isEmpty || forceRefresh) {
      _isLoading = true;
    }
    notifyListeners();

    try {
      final list = await reportRepository.getAdminReports(
        filterStatus: _filter == 'all' ? null : _filter,
        forceRefresh: forceRefresh,
      );
      if (_isDisposed) return;
      _allReports = list;
      _errorMessage = null;
    } catch (e) {
      if (_isDisposed) return;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await reportRepository.updateHandlingStatus(
        reportId: reportId,
        newStatus: newStatus,
        reason: reason,
        completionProofUrl: proofUrl,
        completionProofType: proofUrl != null ? 'completion_photo' : null,
      );
      final idx = _allReports.indexWhere((r) => r.id == reportId);
      if (idx != -1) {
        _allReports[idx] = updated;
      }
      await fetchReports(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('AdminReportController updateStatus error: $_errorMessage');
      return false;
    } finally {
      _processingReportIds.remove(reportId);
      notifyListeners();
    }
  }

  Future<bool> restorePublication(String reportId, String reason) async {
    if (_processingReportIds.contains(reportId)) return false;
    _processingReportIds.add(reportId);
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await reportRepository.updatePublicationState(
        reportId: reportId,
        newState: PublicationState.published,
        reason: reason,
      );
      final idx = _allReports.indexWhere((r) => r.id == reportId);
      if (idx != -1) {
        _allReports[idx] = updated;
      }
      await fetchReports(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint(
        'AdminReportController restorePublication error: $_errorMessage',
      );
      return false;
    } finally {
      _processingReportIds.remove(reportId);
      notifyListeners();
    }
  }

  Future<bool> deleteReport({
    required String reportId,
    required String adminId,
  }) async {
    if (_processingReportIds.contains(reportId)) return false;
    _processingReportIds.add(reportId);
    _errorMessage = null;
    notifyListeners();

    try {
      await reportRepository.softDeleteReport(
        reportId: reportId,
        currentUserId: adminId,
        isCallerAdmin: true,
      );
      _allReports.removeWhere((r) => r.id == reportId);
      await fetchReports(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('AdminReportController deleteReport error: $_errorMessage');
      return false;
    } finally {
      _processingReportIds.remove(reportId);
      notifyListeners();
    }
  }
}
