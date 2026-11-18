import 'package:flutter/foundation.dart';

import '../../../data/models/report_statistics_model.dart';
import '../../../data/repositories/report_repository.dart';

/// Mode filter statistik: Per Bulan atau Per Hari (laporan masuk per tanggal)
enum StatisticsFilterMode {
  monthly, // Per Bulan
  daily,   // Per Hari
}

/// Controller for managing admin statistics, monthly and daily historical analytics
class AdminStatisticsController extends ChangeNotifier {
  AdminStatisticsController({required ReportRepository reportRepository})
    : _repository = reportRepository;

  final ReportRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  StatisticsFilterMode _filterMode = StatisticsFilterMode.monthly;

  // Filter Bulanan
  String? _selectedPeriod; // null = Semua Bulan (Keseluruhan)
  List<MonthlyReportStats> _monthlyStats = [];
  ReportStatisticsSummary? _summary;

  // Filter Harian (Laporan Masuk per Tanggal)
  List<DailyReportStats> _dailyStats = [];
  String? _selectedDate; // null = Semua Tanggal dalam rentang aktif
  String _selectedDailyRange = 'all'; // 'all', '7_days', '14_days', '30_days', 'this_month', atau 'YYYY-MM'

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StatisticsFilterMode get filterMode => _filterMode;

  String? get selectedPeriod => _selectedPeriod;
  List<MonthlyReportStats> get monthlyStats => _monthlyStats;
  ReportStatisticsSummary? get summary => _summary;

  String? get selectedDate => _selectedDate;
  String get selectedDailyRange => _selectedDailyRange;
  List<DailyReportStats> get dailyStats => _dailyStats;

  /// Daftar periode bulan yang tersedia (format 'YYYY-MM') terurut menurun
  List<String> get availablePeriods =>
      _monthlyStats.map((m) => m.periodYearMonth).toList();

  /// Daftar tanggal yang tersedia (format 'YYYY-MM-DD')
  List<String> get availableDates =>
      _dailyStats.map((d) => d.dateString).toList();

  DailyReportStats? get selectedDailyStat {
    if (_selectedDate == null) return null;
    try {
      return _dailyStats.firstWhere((d) => d.dateString == _selectedDate);
    } catch (_) {
      return null;
    }
  }

  MonthlyReportStats? get selectedMonthlyStat {
    if (_selectedPeriod == null) return null;
    try {
      return _monthlyStats.firstWhere((m) => m.periodYearMonth == _selectedPeriod);
    } catch (_) {
      return null;
    }
  }

  // Metrik terhitung (menyesuaikan mode bulanan atau harian)
  int get totalReports {
    if (_filterMode == StatisticsFilterMode.daily) {
      if (_selectedDate != null) {
        return selectedDailyStat?.totalReports ?? 0;
      }
      return _dailyStats.fold<int>(0, (sum, d) => sum + d.totalReports);
    }
    return _summary?.totalReports ?? 0;
  }

  int get completedReports {
    if (_filterMode == StatisticsFilterMode.daily) {
      if (_selectedDate != null) {
        return selectedDailyStat?.completedReports ?? 0;
      }
      return _dailyStats.fold<int>(0, (sum, d) => sum + d.completedReports);
    }
    return _summary?.completedReports ?? 0;
  }

  int get inProgressReports {
    if (_filterMode == StatisticsFilterMode.daily) {
      if (_selectedDate != null) {
        return selectedDailyStat?.inProgressReports ?? 0;
      }
      return _dailyStats.fold<int>(0, (sum, d) => sum + d.inProgressReports);
    }
    return _summary?.inProgressReports ?? 0;
  }

  int get newReports {
    if (_filterMode == StatisticsFilterMode.daily) {
      if (_selectedDate != null) {
        return selectedDailyStat?.newReports ?? 0;
      }
      return _dailyStats.fold<int>(0, (sum, d) => sum + d.newReports);
    }
    return _summary?.newReports ?? 0;
  }

  int get rejectedReports {
    if (_filterMode == StatisticsFilterMode.daily) {
      if (_selectedDate != null) {
        return selectedDailyStat?.rejectedReports ?? 0;
      }
      return _dailyStats.fold<int>(0, (sum, d) => sum + d.rejectedReports);
    }
    return _summary?.rejectedReports ?? 0;
  }

  int get deletedReports {
    if (_filterMode == StatisticsFilterMode.daily) {
      if (_selectedDate != null) {
        return selectedDailyStat?.deletedReports ?? 0;
      }
      return _dailyStats.fold<int>(0, (sum, d) => sum + d.deletedReports);
    }
    return _summary?.deletedReports ?? 0;
  }

  double get completionRate {
    final total = totalReports;
    if (total == 0) return 0.0;
    return completedReports / total;
  }

  Map<String, int> get categoryDistribution {
    if (_filterMode == StatisticsFilterMode.daily) {
      if (_selectedDate != null) {
        return selectedDailyStat?.categoryCounts ?? {};
      }
      final dist = <String, int>{};
      for (final d in _dailyStats) {
        d.categoryCounts.forEach((cat, cnt) {
          dist[cat] = (dist[cat] ?? 0) + cnt;
        });
      }
      return dist;
    }
    return _summary?.categoryDistribution ?? {};
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
      await _fetchDailyStatsInternal(forceRefresh: forceRefresh);
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

  /// Mengubah mode tampilan filter antara Per Bulan dan Per Hari
  Future<void> setFilterMode(StatisticsFilterMode mode) async {
    if (_filterMode == mode) return;
    _filterMode = mode;
    _selectedDate = null;

    if (_filterMode == StatisticsFilterMode.daily && _dailyStats.isEmpty) {
      _isLoading = true;
      notifyListeners();
      try {
        await _fetchDailyStatsInternal();
      } catch (e) {
        _errorMessage = 'Gagal memuat data harian: $e';
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  /// Memfilter rentang harian (misal 'all', '7_days', '14_days', '30_days', 'this_month')
  Future<void> selectDailyRange(String range) async {
    if (_selectedDailyRange == range) return;
    _selectedDailyRange = range;
    _selectedDate = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _fetchDailyStatsInternal();
    } catch (e) {
      _errorMessage = 'Gagal memfilter rentang harian: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memfilter ke tanggal spesifik (format 'YYYY-MM-DD') atau null untuk reset
  void selectDate(String? dateString) {
    if (_selectedDate == dateString) {
      _selectedDate = null; // Toggle reset jika tanggal yang sama ditekan
    } else {
      _selectedDate = dateString;
    }
    notifyListeners();
  }

  Future<void> _fetchDailyStatsInternal({bool forceRefresh = false}) async {
    DateTime? start;
    DateTime? end;
    String? periodYm;

    final now = DateTime.now();
    switch (_selectedDailyRange) {
      case '7_days':
        start = now.subtract(const Duration(days: 6));
        end = now;
        break;
      case '14_days':
        start = now.subtract(const Duration(days: 13));
        end = now;
        break;
      case '30_days':
        start = now.subtract(const Duration(days: 29));
        end = now;
        break;
      case 'this_month':
        periodYm =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
        break;
      default:
        // Cek jika format 'YYYY-MM'
        if (_selectedDailyRange.contains('-') &&
            _selectedDailyRange.length == 7) {
          periodYm = _selectedDailyRange;
        }
        break;
    }

    _dailyStats = await _repository.getDailyStatistics(
      startDate: start,
      endDate: end,
      periodYearMonth: periodYm,
      forceRefresh: forceRefresh,
    );
  }
}

