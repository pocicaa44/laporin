import 'package:flutter/foundation.dart';

import '../../../data/models/report_statistics_model.dart';
import '../../../data/repositories/report_repository.dart';

/// Controller for managing admin statistics and monthly historical analytics
class AdminStatisticsController extends ChangeNotifier {
  AdminStatisticsController({required ReportRepository reportRepository})
    : _repository = reportRepository;

  final ReportRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedPeriod; // null = Semua Bulan (Keseluruhan)
  List<MonthlyReportStats> _monthlyStats = [];
  ReportStatisticsSummary? _summary;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedPeriod => _selectedPeriod;
  List<MonthlyReportStats> get monthlyStats => _monthlyStats;
  ReportStatisticsSummary? get summary => _summary;

  /// Daftar periode bulan yang tersedia (format 'YYYY-MM') terurut menurun
  List<String> get availablePeriods =>
      _monthlyStats.map((m) => m.periodYearMonth).toList();

  int get totalReports => _summary?.totalReports ?? 0;
  int get completedReports => _summary?.completedReports ?? 0;
  int get inProgressReports => _summary?.inProgressReports ?? 0;
  int get newReports => _summary?.newReports ?? 0;
  int get rejectedReports => _summary?.rejectedReports ?? 0;
  int get deletedReports => _summary?.deletedReports ?? 0;
  double get completionRate => _summary?.completionRate ?? 0.0;
  Map<String, int> get categoryDistribution =>
      _summary?.categoryDistribution ?? {};

  MonthlyReportStats? get selectedMonthlyStat {
    if (_selectedPeriod == null) return null;
    try {
      return _monthlyStats.firstWhere((m) => m.periodYearMonth == _selectedPeriod);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchStatistics({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _monthlyStats = await _repository.getMonthlyStatistics(
        forceRefresh: forceRefresh,
      );
      _summary = await _repository.getStatisticsSummary(
        selectedPeriod: _selectedPeriod,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      _errorMessage = 'Gagal memuat data statistik: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectPeriod(String? period) async {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    _isLoading = true;
    notifyListeners();

    try {
      _summary = await _repository.getStatisticsSummary(
        selectedPeriod: _selectedPeriod,
      );
    } catch (e) {
      _errorMessage = 'Gagal memfilter periode: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

