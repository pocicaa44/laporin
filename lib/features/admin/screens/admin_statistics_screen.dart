import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/app_profile_bar.dart';
import '../../../core/widgets/offline_fallback_view.dart';
import '../../../data/repositories/report_repository.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../../navigation/widgets/app_drawer.dart';
import '../controllers/admin_statistics_controller.dart';

/// Halaman Statistik Admin menampilkan analitik laporan, grafik tren bulanan,
/// filter per-bulan, dan mempertahankan data historis meskipun laporan dihapus.
class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AdminStatisticsController(
        reportRepository: context.read<ReportRepository>(),
      )..fetchStatistics(),
      child: _AdminStatisticsView(isEmbedded: isEmbedded),
    );
  }
}

class _AdminStatisticsView extends StatefulWidget {
  const _AdminStatisticsView({required this.isEmbedded});

  final bool isEmbedded;

  @override
  State<_AdminStatisticsView> createState() => _AdminStatisticsViewState();
}

class _AdminStatisticsViewState extends State<_AdminStatisticsView> {
  int? _lastNavChangeCount;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isEmbedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AdminStatisticsController>().fetchStatistics(
            forceRefresh: true,
          );
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final isOnline = context.isOnline;
      if (_wasOffline && isOnline) {
        _wasOffline = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<AdminStatisticsController>().fetchStatistics(
              forceRefresh: true,
            );
          }
        });
      } else if (!isOnline) {
        _wasOffline = true;
      }
    } catch (_) {}

    if (widget.isEmbedded) {
      try {
        final nav = context.watch<NavigationController>();
        if (nav.currentIndex == 3 &&
            _lastNavChangeCount != nav.tabChangeCount) {
          _lastNavChangeCount = nav.tabChangeCount;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<AdminStatisticsController>().fetchStatistics(
                forceRefresh: true,
              );
            }
          });
        } else {
          _lastNavChangeCount = nav.tabChangeCount;
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminStatisticsController>();
    final isOnline = context.isOnline;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final isDataEmpty = controller.filterMode == StatisticsFilterMode.monthly
        ? controller.monthlyStats.isEmpty
        : controller.dailyStats.isEmpty;

    return Container(
      color: isDark ? AppColors.darkBackground : const Color(0xFFF0F2F5),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1280 : 840),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.symmetric(
              vertical: BorderSide(color: borderColor, width: 1),
            ),
          ),
          child: Scaffold(
            drawer: isDesktop ? null : const AppDrawer(),
            appBar: AppBar(
              leading: (widget.isEmbedded && !isDesktop) ? const DrawerMenuButton() : null,
              automaticallyImplyLeading: !widget.isEmbedded && !isDesktop,
              title: const Text('Statistik Laporan'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Segarkan Statistik',
                  onPressed: () => controller.fetchStatistics(forceRefresh: true),
                ),
                if (isDesktop) const AppProfileBar(),
              ],
            ),
            body: controller.isLoading && controller.monthlyStats.isEmpty && controller.dailyStats.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => controller.fetchStatistics(forceRefresh: true),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 24 : 16,
                        vertical: isDesktop ? 20 : 16,
                      ),
                      children: [
                        // 1. Header & Filter Periode Bulan / Hari (Responsif)
                        _buildFilterHeader(context, controller, isDesktop),
                        const SizedBox(height: 16),

                        // 2. Kartu Rangkuman Metrik KPI (Responsif)
                        _buildMetricCards(context, controller, isDesktop),
                        const SizedBox(height: 20),

                        // 3. Konten Utama Grafik (Responsif Desktop: 2 Kolom, Mobile: 1 Kolom)
                        if (isDataEmpty)
                          (!isOnline
                              ? OfflineFallbackView(
                                  onRetry: () => controller.fetchStatistics(
                                    forceRefresh: true,
                                  ),
                                )
                              : const EmptyState(
                                  title: 'Belum Ada Data Statistik',
                                  message:
                                      'Data statistik laporan warga belum tersedia pada sistem.',
                                ))
                        else ...[
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Kolom Kiri: Grafik Batang Tren (Bulanan / Harian per Tanggal)
                                Expanded(
                                  flex: 6,
                                  child: controller.filterMode == StatisticsFilterMode.monthly
                                      ? _buildMonthlyTrendCard(context, controller)
                                      : _buildDailyTrendCard(context, controller),
                                ),
                                const SizedBox(width: 16),
                                // Kolom Kanan: Distribusi Kategori & Status
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    children: [
                                      _buildStatusDistributionCard(
                                        context,
                                        controller,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildCategoryDistributionCard(
                                        context,
                                        controller,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            // Tampilan Mobile: Vertikal
                            controller.filterMode == StatisticsFilterMode.monthly
                                ? _buildMonthlyTrendCard(context, controller)
                                : _buildDailyTrendCard(context, controller),
                            const SizedBox(height: 16),
                            _buildStatusDistributionCard(context, controller),
                            const SizedBox(height: 16),
                            _buildCategoryDistributionCard(
                              context,
                              controller,
                            ),
                          ],
                          const SizedBox(height: 20),

                          // 4. Daftar Rincian Histori (Bulanan / Harian)
                          controller.filterMode == StatisticsFilterMode.monthly
                              ? _buildHistoricalMonthlyList(
                                  context,
                                  controller,
                                  isDesktop,
                                )
                              : _buildHistoricalDailyList(
                                  context,
                                  controller,
                                  isDesktop,
                                ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// 1. Header Info & Dropdown Filter Berdasarkan Bulan atau Hari (per tanggal)
  Widget _buildFilterHeader(
    BuildContext context,
    AdminStatisticsController controller,
    bool isDesktop,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final primaryColor = AppColors.primaryOf(context);

    final selectedLabel = controller.selectedPeriod == null
        ? 'Semua Bulan (Keseluruhan)'
        : (controller.selectedMonthlyStat?.monthName ?? controller.selectedPeriod!);

    final monthlyFilterWidget = Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 260 : double.infinity),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.button,
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: controller.selectedPeriod,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.calendar_month_rounded, size: 18, color: primaryColor),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          dropdownColor: surfaceColor,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'Semua Bulan (Keseluruhan)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...controller.monthlyStats.map((stat) {
              return DropdownMenuItem<String?>(
                value: stat.periodYearMonth,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stat.monthName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${stat.totalReports}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: (period) => controller.selectPeriod(period),
        ),
      ),
    );

    final dailyFilterWidget = Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 260 : double.infinity),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.button,
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedDailyRange,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.today_rounded, size: 18, color: primaryColor),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          dropdownColor: surfaceColor,
          items: [
            const DropdownMenuItem<String>(
              value: 'all',
              child: Text(
                'Semua Tanggal Terekam',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const DropdownMenuItem<String>(
              value: '7_days',
              child: Text(
                '7 Hari Terakhir',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const DropdownMenuItem<String>(
              value: '14_days',
              child: Text(
                '14 Hari Terakhir',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const DropdownMenuItem<String>(
              value: '30_days',
              child: Text(
                '30 Hari Terakhir',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const DropdownMenuItem<String>(
              value: 'this_month',
              child: Text(
                'Bulan Ini',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...controller.monthlyStats.map((stat) {
              return DropdownMenuItem<String>(
                value: stat.periodYearMonth,
                child: Text(
                  '${stat.monthName} (Per Tanggal)',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (range) {
            if (range != null) {
              controller.selectDailyRange(range);
            }
          },
        ),
      ),
    );

    final activeFilterDropdown = controller.filterMode == StatisticsFilterMode.monthly
        ? monthlyFilterWidget
        : dailyFilterWidget;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Histori & Analitik Laporan',
                  style: AppTextStyles.sectionTitleOf(context),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.filterMode == StatisticsFilterMode.monthly
                      ? 'Periode: $selectedLabel • Data historis tetap terekam meski laporan dihapus.'
                      : (controller.selectedDate != null
                          ? 'Filter Tanggal: ${controller.selectedDailyStat?.formattedDate ?? controller.selectedDate} • Data historis terekam.'
                          : 'Laporan Masuk per Tanggal (${controller.dailyStats.length} Tanggal Terekam) • Ketuk batang untuk filter.'),
                  style: TextStyle(fontSize: 12.5, color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildModeToggle(context, controller),
          const SizedBox(width: 12),
          activeFilterDropdown,
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Histori & Analitik Laporan',
                  style: AppTextStyles.sectionTitleOf(context),
                ),
              ),
              _buildModeToggle(context, controller),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            controller.filterMode == StatisticsFilterMode.monthly
                ? 'Data historis tetap terekam meski laporan dihapus.'
                : (controller.selectedDate != null
                    ? 'Filter Tanggal: ${controller.selectedDailyStat?.formattedDate ?? controller.selectedDate}'
                    : 'Laporan masuk per tanggal (${controller.dailyStats.length} tanggal terekam)'),
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: activeFilterDropdown),
        ],
      );
    }
  }

  /// Tombol toggle mode filter antara Per Bulan dan Per Hari
  Widget _buildModeToggle(
    BuildContext context,
    AdminStatisticsController controller,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primaryOf(context);
    final borderColor = AppColors.borderOf(context);
    final surfaceColor = AppColors.surfaceOf(context);
    final textMuted = AppColors.textMutedOf(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
        borderRadius: AppRadius.pill,
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            context: context,
            label: 'Per Bulan',
            isSelected: controller.filterMode == StatisticsFilterMode.monthly,
            onTap: () => controller.setFilterMode(StatisticsFilterMode.monthly),
            primaryColor: primaryColor,
            surfaceColor: surfaceColor,
            textMuted: textMuted,
          ),
          _buildModeButton(
            context: context,
            label: 'Per Hari',
            isSelected: controller.filterMode == StatisticsFilterMode.daily,
            onTap: () => controller.setFilterMode(StatisticsFilterMode.daily),
            primaryColor: primaryColor,
            surfaceColor: surfaceColor,
            textMuted: textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color surfaceColor,
    required Color textMuted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pill,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: AppRadius.pill,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  /// 2. Kartu Rangkuman Metrik KPI
  Widget _buildMetricCards(
    BuildContext context,
    AdminStatisticsController controller,
    bool isDesktop,
  ) {
    final successColor = AppColors.successOf(context);
    final warningColor = AppColors.warningOf(context);
    final dangerColor = AppColors.dangerOf(context);
    final primaryColor = AppColors.primaryOf(context);
    final textMuted = AppColors.textMutedOf(context);

    final cards = [
      _MetricCardItem(
        title: 'Total Laporan',
        value: controller.totalReports.toString(),
        icon: Icons.assignment_outlined,
        color: primaryColor,
        subtitle: controller.filterMode == StatisticsFilterMode.daily &&
                controller.selectedDate != null
            ? 'Laporan pada ${controller.selectedDailyStat?.shortDateLabel ?? ""}'
            : (controller.filterMode == StatisticsFilterMode.daily
                ? 'Total periode harian'
                : 'Termasuk riwayat terhapus'),
      ),
      _MetricCardItem(
        title: 'Selesai',
        value: controller.completedReports.toString(),
        icon: Icons.check_circle_outline_rounded,
        color: successColor,
        subtitle: '${(controller.completionRate * 100).toStringAsFixed(0)}% terselesaikan',
      ),
      _MetricCardItem(
        title: 'Diproses / Baru',
        value: (controller.inProgressReports + controller.newReports).toString(),
        icon: Icons.hourglass_top_rounded,
        color: warningColor,
        subtitle: '${controller.newReports} baru, ${controller.inProgressReports} diproses',
      ),
      _MetricCardItem(
        title: 'Ditolak',
        value: controller.rejectedReports.toString(),
        icon: Icons.cancel_outlined,
        color: dangerColor,
        subtitle: 'Laporan tidak valid',
      ),
      _MetricCardItem(
        title: 'Dihapus',
        value: controller.deletedReports.toString(),
        icon: Icons.delete_outline_rounded,
        color: textMuted,
        subtitle: 'Histori tetap valid',
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cards.map((c) {
            return SizedBox(
              width: (constraints.maxWidth - 8) / 2,
              child: c,
            );
          }).toList(),
        );
      },
    );
  }

  /// 3. Grafik Batang Tren Bulanan (Interactive Bar Chart)
  Widget _buildMonthlyTrendCard(
    BuildContext context,
    AdminStatisticsController controller,
  ) {
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final primaryColor = AppColors.primaryOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = AppColors.textMutedOf(context);

    final stats = controller.monthlyStats;
    final maxCount = stats.fold<int>(1, (prev, e) => math.max(prev, e.totalReports));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.chartSimple, size: 16, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Grafik Tren Laporan Bulanan',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Ketuk batang untuk filter',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tampilan Batang Grafik Interaktif
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: stats.reversed.map((stat) {
                final isSelected = controller.selectedPeriod == stat.periodYearMonth;
                final heightFactor = stat.totalReports / maxCount;
                final barHeight = math.max(14.0, heightFactor * 130);

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      if (controller.selectedPeriod == stat.periodYearMonth) {
                        controller.selectPeriod(null); // Reset ke semua
                      } else {
                        controller.selectPeriod(stat.periodYearMonth);
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Label Jumlah di atas batang
                          Text(
                            '${stat.totalReports}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? primaryColor
                                  : (isDark ? Colors.white70 : AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Batang Grafik
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: barHeight,
                            width: 28,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark
                                      ? primaryColor.withValues(alpha: 0.45)
                                      : primaryColor.withValues(alpha: 0.25)),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(5),
                              ),
                              border: Border.all(
                                color: isSelected ? primaryColor : borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Label Bulan Singkat
                          Text(
                            stat.shortMonthLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? primaryColor : textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Data mencakup seluruh histori laporan terbuat',
                  style: TextStyle(fontSize: 11, color: textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (controller.selectedPeriod != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => controller.selectPeriod(null),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Reset Filter Bulan', style: TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 3b. Grafik Laporan Masuk per Tanggal (Interactive Daily Bar Chart)
  Widget _buildDailyTrendCard(
    BuildContext context,
    AdminStatisticsController controller,
  ) {
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final primaryColor = AppColors.primaryOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = AppColors.textMutedOf(context);

    final stats = controller.dailyStats;
    final maxCount =
        stats.fold<int>(1, (prev, e) => math.max(prev, e.totalReports));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.chartSimple,
                  size: 16, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Grafik Laporan Masuk per Tanggal',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Ketuk batang tanggal untuk filter',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (stats.isEmpty)
            Container(
              height: 140,
              alignment: Alignment.center,
              child: Text(
                'Tidak ada laporan masuk pada rentang tanggal ini.',
                style: TextStyle(fontSize: 12.5, color: textMuted),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: stats.map((stat) {
                      final isSelected =
                          controller.selectedDate == stat.dateString;
                      final heightFactor = stat.totalReports / maxCount;
                      final barHeight = math.max(14.0, heightFactor * 130);

                      return InkWell(
                        onTap: () => controller.selectDate(stat.dateString),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Label Jumlah di atas batang
                              Text(
                                '${stat.totalReports}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark
                                          ? Colors.white70
                                          : AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Batang Grafik
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: barHeight,
                                width: 28,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark
                                          ? primaryColor.withValues(alpha: 0.45)
                                          : primaryColor
                                              .withValues(alpha: 0.25)),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(5),
                                  ),
                                  border: Border.all(
                                    color:
                                        isSelected ? primaryColor : borderColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Label Tanggal Singkat
                              Text(
                                stat.shortDateLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected ? primaryColor : textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  controller.selectedDate != null
                      ? 'Menampilkan tanggal: ${controller.selectedDailyStat?.formattedDate ?? controller.selectedDate}'
                      : 'Data mencakup seluruh laporan masuk per tanggal',
                  style: TextStyle(fontSize: 11, color: textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (controller.selectedDate != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => controller.selectDate(null),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Reset Filter Tanggal',
                      style: TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 4. Distribusi Status Penanganan
  Widget _buildStatusDistributionCard(
    BuildContext context,
    AdminStatisticsController controller,
  ) {
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = math.max(1, controller.totalReports);

    final completed = controller.completedReports;
    final inProgress = controller.inProgressReports;
    final newRep = controller.newReports;
    final rejected = controller.rejectedReports;
    final deleted = controller.deletedReports;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Penanganan Laporan',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Multi-segment progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (completed > 0)
                    Expanded(
                      flex: completed,
                      child: Container(color: const Color(0xFF10B981)),
                    ),
                  if (inProgress > 0)
                    Expanded(
                      flex: inProgress,
                      child: Container(color: const Color(0xFFF59E0B)),
                    ),
                  if (newRep > 0)
                    Expanded(
                      flex: newRep,
                      child: Container(color: const Color(0xFF3B82F6)),
                    ),
                  if (rejected > 0)
                    Expanded(
                      flex: rejected,
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                  if (deleted > 0)
                    Expanded(
                      flex: deleted,
                      child: Container(color: const Color(0xFF6B7280)),
                    ),
                  if (controller.totalReports == 0)
                    Expanded(child: Container(color: borderColor)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildStatusLegendRow('Selesai', completed, total, const Color(0xFF10B981)),
          const SizedBox(height: 6),
          _buildStatusLegendRow('Dalam Proses', inProgress, total, const Color(0xFFF59E0B)),
          const SizedBox(height: 6),
          _buildStatusLegendRow('Baru', newRep, total, const Color(0xFF3B82F6)),
          const SizedBox(height: 6),
          _buildStatusLegendRow('Ditolak', rejected, total, const Color(0xFFEF4444)),
          if (deleted > 0) ...[
            const SizedBox(height: 6),
            _buildStatusLegendRow('Laporan Terhapus', deleted, total, const Color(0xFF6B7280)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusLegendRow(String label, int count, int total, Color color) {
    final pct = total > 0 ? ((count / total) * 100).toStringAsFixed(0) : '0';
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          '$count ($pct%)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// 5. Distribusi Kategori Laporan (Horizontal Bar Breakdown)
  Widget _buildCategoryDistributionCard(
    BuildContext context,
    AdminStatisticsController controller,
  ) {
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final primaryColor = AppColors.primaryOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = controller.categoryDistribution;
    final total = math.max(1, controller.totalReports);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.tag, size: 14, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Distribusi Kategori Laporan',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (categories.isEmpty)
            const Text(
              'Belum ada data kategori untuk periode ini.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          else
            ...categories.entries.map((entry) {
              final pct = (entry.value / total);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.value} (${(pct * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: borderColor,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  /// 6. Rincian Histori Bulanan
  Widget _buildHistoricalMonthlyList(
    BuildContext context,
    AdminStatisticsController controller,
    bool isDesktop,
  ) {
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primaryOf(context);
    final textMuted = AppColors.textMutedOf(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.calendarCheck, size: 16, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rincian Histori Bulanan',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.monthlyStats.length} Bulan Terekam',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...controller.monthlyStats.map((stat) {
            final isSelected = controller.selectedPeriod == stat.periodYearMonth;

            return InkWell(
              onTap: () => controller.selectPeriod(
                isSelected ? null : stat.periodYearMonth,
              ),
              borderRadius: AppRadius.button,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.08)
                      : (isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB)),
                  borderRadius: AppRadius.button,
                  border: Border.all(
                    color: isSelected ? primaryColor : borderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.calendar_today_outlined,
                      size: 16,
                      color: isSelected ? primaryColor : textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.monthName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? primaryColor
                                  : (isDark ? Colors.white : AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Selesai: ${stat.completedReports} • Diproses: ${stat.inProgressReports} • Ditolak: ${stat.rejectedReports}${stat.deletedReports > 0 ? " • Dihapus: ${stat.deletedReports}" : ""}',
                            style: TextStyle(fontSize: 11.5, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : borderColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${stat.totalReports} Laporan',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 4b. Rincian Histori Harian (Laporan Masuk per Tanggal)
  Widget _buildHistoricalDailyList(
    BuildContext context,
    AdminStatisticsController controller,
    bool isDesktop,
  ) {
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primaryOf(context);
    final textMuted = AppColors.textMutedOf(context);

    // Tampilkan urutan tanggal menurun (terbaru di atas) untuk daftar rincian
    final reversedStats = controller.dailyStats.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.calendarCheck,
                  size: 16, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rincian Laporan Masuk per Tanggal',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.dailyStats.length} Tanggal Terekam',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (reversedStats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Belum ada laporan masuk pada rentang tanggal ini.',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            )
          else
            ...reversedStats.map((stat) {
              final isSelected = controller.selectedDate == stat.dateString;

              return InkWell(
                onTap: () => controller.selectDate(stat.dateString),
                borderRadius: AppRadius.button,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.08)
                        : (isDark
                            ? AppColors.darkBackground
                            : const Color(0xFFF9FAFB)),
                    borderRadius: AppRadius.button,
                    border: Border.all(
                      color: isSelected ? primaryColor : borderColor,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.today_outlined,
                        size: 16,
                        color: isSelected ? primaryColor : textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat.formattedDate,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? primaryColor
                                    : (isDark
                                        ? Colors.white
                                        : AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Selesai: ${stat.completedReports} • Diproses: ${stat.inProgressReports} • Ditolak: ${stat.rejectedReports}${stat.deletedReports > 0 ? " • Dihapus: ${stat.deletedReports}" : ""}',
                              style: TextStyle(
                                  fontSize: 11.5, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : borderColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${stat.totalReports} Laporan',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white
                                    : AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MetricCardItem extends StatelessWidget {
  const _MetricCardItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final textMuted = AppColors.textMutedOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
