import 'package:flutter/material.dart';

import '../../../core/config/indonesia_regions.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

/// Controller for Admin & Moderator workflows
class AdminReportController extends ChangeNotifier {
  AdminReportController({required this.reportRepository}) {
    fetchReports();
  }

  final ReportRepository reportRepository;

  List<ReportModel> _allReports = [];

  String? _selectedProvinceId;
  String? get selectedProvinceId => _selectedProvinceId;

  String? _selectedProvinceName;
  String? get selectedProvinceName => _selectedProvinceName;

  List<ReportModel> get _scopedReports {
    if (_selectedProvinceId == null ||
        _selectedProvinceId!.isEmpty ||
        _selectedProvinceId == 'all') {
      return _allReports;
    }
    return _allReports.where((r) {
      if (r.provinceId == _selectedProvinceId) return true;
      if (r.areaId.contains(_selectedProvinceId!)) return true;
      final prov = IndonesiaRegions.findById(_selectedProvinceId!);
      if (prov != null) {
        if (r.areaId.toLowerCase().contains(prov.name.toLowerCase())) return true;
        if (r.areaId.toLowerCase().contains(prov.code.toLowerCase())) return true;
        if (r.areaName.toLowerCase().contains(prov.name.toLowerCase())) return true;
      }
      return false;
    }).toList();
  }

  List<ReportModel> get reports {
    final list = _scopedReports;
    switch (_filter) {
      case 'deleted_by_user':
        return list.where((r) => r.deletedByUser).toList();
      case 'new':
        return list
            .where((r) => r.handlingStatus == HandlingStatus.newReport)
            .toList();
      case 'accepted':
        return list
            .where((r) => r.handlingStatus == HandlingStatus.accepted)
            .toList();
      case 'in_progress':
        return list
            .where((r) => r.handlingStatus == HandlingStatus.inProgress)
            .toList();
      case 'completed':
        return list
            .where((r) => r.handlingStatus == HandlingStatus.completed)
            .toList();
      case 'rejected':
        return list
            .where((r) => r.handlingStatus == HandlingStatus.rejected)
            .toList();
      default:
        return list;
    }
  }

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

  String _filter =
      'all'; // 'all', 'new', 'accepted', 'in_progress', 'completed', 'rejected'
  String get filter => _filter;

  int get totalReports => _scopedReports.length;
  int get newCount => _scopedReports
      .where((r) => r.handlingStatus == HandlingStatus.newReport)
      .length;
  int get acceptedCount => _scopedReports
      .where((r) => r.handlingStatus == HandlingStatus.accepted)
      .length;
  int get inProgressCount => _scopedReports
      .where((r) => r.handlingStatus == HandlingStatus.inProgress)
      .length;
  int get completedCount => _scopedReports
      .where((r) => r.handlingStatus == HandlingStatus.completed)
      .length;
  int get rejectedCount => _scopedReports
      .where((r) => r.handlingStatus == HandlingStatus.rejected)
      .length;
  int get heldCount => _scopedReports
      .where((r) => r.publicationState == PublicationState.held)
      .length;
  int get deletedByUserCount =>
      _scopedReports.where((r) => r.deletedByUser && !r.deletedByAdmin).length;

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
        provinceId: _selectedProvinceId,
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
    if (_filter != newFilter) {
      _filter = newFilter;
      notifyListeners();
    }
  }

  void setProvinceFilter(String? provinceId, [String? provinceName]) {
    if (_selectedProvinceId != provinceId) {
      _selectedProvinceId = provinceId;
      _selectedProvinceName = provinceName ??
          (provinceId != null
              ? IndonesiaRegions.findById(provinceId)?.name
              : null);
      notifyListeners();
      fetchReports(forceRefresh: true);
    }
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
