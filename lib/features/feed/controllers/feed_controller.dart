import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/indonesia_regions.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

/// Scope for public thread feed: National (all Indonesia) or Provincial.
enum FeedScope { national, provincial }

/// Controller for managing the public thread feed with provincial & national scopes.
class FeedController extends ChangeNotifier {
  FeedController({
    required this.reportRepository,
    this.currentUserId,
    bool autoDetectGps = false,
  }) {
    _initPreferenceAndFeed(autoDetectGps: autoDetectGps);
  }

  final ReportRepository reportRepository;
  String? currentUserId;

  List<ReportModel> _reports = [];
  List<ReportModel> get reports => _reports;

  static const int pageSize = 10;

  FeedScope _scope = FeedScope.national;
  FeedScope get scope => _scope;
  bool get isNational => _scope == FeedScope.national;

  String? _selectedProvinceId;
  String? get selectedProvinceId => _selectedProvinceId;

  String? _selectedProvinceName;
  String? get selectedProvinceName => _selectedProvinceName;

  String? _detectedProvinceId;
  String? get detectedProvinceId => _detectedProvinceId;

  String? _detectedProvinceName;
  String? get detectedProvinceName => _detectedProvinceName;

  bool _isDetectingLocation = false;
  bool get isDetectingLocation => _isDetectingLocation;

  bool get hasDetectedProvince =>
      _detectedProvinceId != null && _detectedProvinceName != null;

  bool get isDetectedProvinceActive =>
      !isNational && _selectedProvinceId == _detectedProvinceId;

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

  final Set<String> _votingReportIds = <String>{};
  bool isVoting(String reportId) => _votingReportIds.contains(reportId);

  bool isReportViewedByAdmin(String reportId) =>
      reportRepository.isReportViewedByAdmin(reportId);

  void markReportAsViewedByAdmin(String reportId) {
    reportRepository.markReportAsViewedByAdmin(reportId);
    notifyListeners();
  }

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

  Future<void> _initPreferenceAndFeed({bool autoDetectGps = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('pref_province_id');
      final savedName = prefs.getString('pref_province_name');
      if (savedId != null && savedName != null) {
        _scope = FeedScope.provincial;
        _selectedProvinceId = savedId;
        _selectedProvinceName = savedName;
      }

      final savedDetectedId = prefs.getString('detected_province_id');
      final savedDetectedName = prefs.getString('detected_province_name');
      if (savedDetectedId != null && savedDetectedName != null) {
        _detectedProvinceId = savedDetectedId;
        _detectedProvinceName = savedDetectedName;
      }
    } catch (_) {}
    fetchFeed();

    if (autoDetectGps) {
      unawaited(autoDetectLocation());
    }
  }

  Future<void> _savePreference(String? id, String? name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (id != null && name != null) {
        await prefs.setString('pref_province_id', id);
        await prefs.setString('pref_province_name', name);
      } else {
        await prefs.remove('pref_province_id');
        await prefs.remove('pref_province_name');
      }
    } catch (_) {}
  }

  Future<void> _saveDetectedLocation(String id, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('detected_province_id', id);
      await prefs.setString('detected_province_name', name);
    } catch (_) {}
  }

  void setNationalScope() {
    if (_scope == FeedScope.national) return;
    _scope = FeedScope.national;
    _selectedProvinceId = null;
    _selectedProvinceName = null;
    _reports = [];
    _hasMore = true;
    _savePreference(null, null);
    fetchFeed();
  }

  void setProvincialScope(String provinceId, String provinceName) {
    if (_scope == FeedScope.provincial && _selectedProvinceId == provinceId) {
      return;
    }
    _scope = FeedScope.provincial;
    _selectedProvinceId = provinceId;
    _selectedProvinceName = provinceName;
    _reports = [];
    _hasMore = true;
    _savePreference(provinceId, provinceName);
    fetchFeed();
  }

  void switchToAll() {
    setNationalScope();
  }

  Future<bool> switchToDetectedProvince() async {
    if (_detectedProvinceId != null && _detectedProvinceName != null) {
      setProvincialScope(_detectedProvinceId!, _detectedProvinceName!);
      return true;
    } else {
      return autoDetectLocation(setAsActiveScope: true);
    }
  }

  @visibleForTesting
  void setDetectedProvinceForTesting(String? id, String? name) {
    _detectedProvinceId = id;
    _detectedProvinceName = name;
    notifyListeners();
  }

  Future<bool> autoDetectLocation({bool setAsActiveScope = false}) async {
    if (_isDetectingLocation) return false;
    _isDetectingLocation = true;
    notifyListeners();

    try {
      final pos = await LocationService.instance.getCurrentLocation();
      final res = await LocationService.instance.getAddressFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      String? provId = res.provinceId;
      String? provName = res.provinceName;

      if ((provId == null || provName == null) &&
          res.areaName.isNotEmpty &&
          res.isValidRegion) {
        final prov = IndonesiaRegions.findByName(res.areaName);
        if (prov != null) {
          provId = prov.id;
          provName = prov.name;
        }
      }

      if (provId != null && provName != null) {
        _detectedProvinceId = provId;
        _detectedProvinceName = provName;
        await _saveDetectedLocation(provId, provName);

        if (setAsActiveScope) {
          setProvincialScope(provId, provName);
        } else {
          notifyListeners();
        }
        return true;
      }
    } catch (_) {
      // Graceful fallback on permission denied, GPS disabled, or test environment
    } finally {
      if (!_isDisposed) {
        _isDetectingLocation = false;
        notifyListeners();
      }
    }
    return false;
  }

  Future<bool> detectAndSetProvinceFromGps() async {
    return autoDetectLocation(setAsActiveScope: true);
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
        provinceId: _scope == FeedScope.provincial ? _selectedProvinceId : null,
        forceRefresh: forceRefresh,
        limit: pageSize,
        offset: 0,
      );
      if (_isDisposed) return;
      _reports = List<ReportModel>.from(result);
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
        provinceId: _scope == FeedScope.provincial ? _selectedProvinceId : null,
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
    if (_votingReportIds.contains(reportId)) return;

    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return;

    final currentReport = _reports[index];
    if (!currentReport.isPubliclyVisible || currentReport.isTerminal) return;

    final previousReport = currentReport;
    final optimisticReport = currentReport.calculateOptimisticVote(voteType);

    _votingReportIds.add(reportId);
    _errorMessage = null;

    if (!optimisticReport.isPubliclyVisible) {
      _reports.removeAt(index);
    } else {
      _reports[index] = optimisticReport;
    }
    notifyListeners();

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
