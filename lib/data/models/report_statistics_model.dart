import 'package:intl/intl.dart';

/// Model representing monthly aggregated report statistics
class MonthlyReportStats {
  const MonthlyReportStats({
    required this.periodYearMonth,
    required this.year,
    required this.month,
    required this.periodDate,
    required this.totalReports,
    this.completedReports = 0,
    this.rejectedReports = 0,
    this.inProgressReports = 0,
    this.newReports = 0,
    this.deletedReports = 0,
    this.categoryCounts = const {},
  });

  /// Format 'YYYY-MM', misal: '2026-11'
  final String periodYearMonth;
  final int year;
  final int month;
  final DateTime periodDate;
  final int totalReports;
  final int completedReports;
  final int rejectedReports;
  final int inProgressReports;
  final int newReports;
  final int deletedReports;
  final Map<String, int> categoryCounts;

  /// Nama bulan panjang dalam Bahasa Indonesia, misal: 'November 2026'
  String get monthName {
    try {
      return DateFormat('MMMM yyyy', 'id_ID').format(periodDate);
    } catch (_) {
      const monthNames = [
        '',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      if (month >= 1 && month <= 12) {
        return '${monthNames[month]} $year';
      }
      return periodYearMonth;
    }
  }

  /// Nama bulan pendek, misal: 'Nov 26'
  String get shortMonthLabel {
    const shortNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final shortYear = (year % 100).toString().padLeft(2, '0');
    if (month >= 1 && month <= 12) {
      return '${shortNames[month]} \'$shortYear';
    }
    return periodYearMonth;
  }

  double get completionRate =>
      totalReports > 0 ? (completedReports / totalReports) : 0.0;

  factory MonthlyReportStats.fromJson(
    Map<String, dynamic> json, {
    Map<String, int>? categories,
  }) {
    final ym = json['period_year_month']?.toString() ?? '';
    final parsedDate = DateTime.tryParse(
          json['period_date']?.toString() ?? '',
        ) ??
        DateTime.now();
    final y = (json['year'] as num?)?.toInt() ?? parsedDate.year;
    final m = (json['month'] as num?)?.toInt() ?? parsedDate.month;

    return MonthlyReportStats(
      periodYearMonth: ym,
      year: y,
      month: m,
      periodDate: parsedDate,
      totalReports: (json['total_reports'] as num?)?.toInt() ?? 0,
      completedReports: (json['completed_reports'] as num?)?.toInt() ?? 0,
      rejectedReports: (json['rejected_reports'] as num?)?.toInt() ?? 0,
      inProgressReports: (json['in_progress_reports'] as num?)?.toInt() ?? 0,
      newReports: (json['new_reports'] as num?)?.toInt() ?? 0,
      deletedReports: (json['deleted_reports'] as num?)?.toInt() ?? 0,
      categoryCounts: categories ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'period_year_month': periodYearMonth,
    'year': year,
    'month': month,
    'period_date': periodDate.toIso8601String(),
    'total_reports': totalReports,
    'completed_reports': completedReports,
    'rejected_reports': rejectedReports,
    'in_progress_reports': inProgressReports,
    'new_reports': newReports,
    'deleted_reports': deletedReports,
    'category_counts': categoryCounts,
  };

  MonthlyReportStats copyWith({
    String? periodYearMonth,
    int? year,
    int? month,
    DateTime? periodDate,
    int? totalReports,
    int? completedReports,
    int? rejectedReports,
    int? inProgressReports,
    int? newReports,
    int? deletedReports,
    Map<String, int>? categoryCounts,
  }) {
    return MonthlyReportStats(
      periodYearMonth: periodYearMonth ?? this.periodYearMonth,
      year: year ?? this.year,
      month: month ?? this.month,
      periodDate: periodDate ?? this.periodDate,
      totalReports: totalReports ?? this.totalReports,
      completedReports: completedReports ?? this.completedReports,
      rejectedReports: rejectedReports ?? this.rejectedReports,
      inProgressReports: inProgressReports ?? this.inProgressReports,
      newReports: newReports ?? this.newReports,
      deletedReports: deletedReports ?? this.deletedReports,
      categoryCounts: categoryCounts ?? this.categoryCounts,
    );
  }
}

/// Model encapsulating overall statistics summary across all time or a selected period
class ReportStatisticsSummary {
  const ReportStatisticsSummary({
    required this.totalReports,
    required this.completedReports,
    required this.inProgressReports,
    required this.rejectedReports,
    required this.newReports,
    required this.deletedReports,
    required this.categoryDistribution,
    required this.monthlyTrend,
    this.selectedPeriod,
  });

  final int totalReports;
  final int completedReports;
  final int inProgressReports;
  final int rejectedReports;
  final int newReports;
  final int deletedReports;
  final Map<String, int> categoryDistribution;
  final List<MonthlyReportStats> monthlyTrend;
  final String? selectedPeriod;

  double get completionRate =>
      totalReports > 0 ? (completedReports / totalReports) : 0.0;
}

