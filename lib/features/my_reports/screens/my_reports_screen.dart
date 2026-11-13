import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_profile_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/offline_fallback_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../create_report/screens/create_report_screen.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../../navigation/widgets/app_drawer.dart';
import '../../report_detail/screens/report_detail_screen.dart';
import '../controllers/my_reports_controller.dart';

/// Screen displaying user's own reports per DESIGN.md Section 5.6
class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final userId = auth.currentUser?.id ?? '';

    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    if (!auth.isAuthenticated || userId.isEmpty) {
      return Scaffold(
        drawer: isDesktop ? null : const AppDrawer(),
        appBar: AppBar(
          leading: isDesktop ? null : const DrawerMenuButton(),
          automaticallyImplyLeading: !isDesktop,
          title: const Text('Laporan Saya'),
        ),
        body: const EmptyState(
          title: 'Belum Masuk',
          message:
              'Silakan masuk ke akun Anda untuk melihat daftar laporan yang pernah Anda buat.',
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => MyReportsController(
        userId: userId,
        reportRepository: context.read<ReportRepository>(),
      ),
      child: const _MyReportsView(),
    );
  }
}

class _MyReportsView extends StatefulWidget {
  const _MyReportsView();

  @override
  State<_MyReportsView> createState() => _MyReportsViewState();
}

class _MyReportsViewState extends State<_MyReportsView> {
  late final ScrollController _scrollController;
  int? _lastNavChangeCount;
  bool _wasOffline = false;
  String _statusFilter = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final isOnline = context.isOnline;
      if (_wasOffline && isOnline) {
        _wasOffline = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<MyReportsController>().fetchMyReports(
              forceRefresh: true,
            );
          }
        });
      } else if (!isOnline) {
        _wasOffline = true;
      }
    } catch (_) {}

    try {
      final nav = context.watch<NavigationController>();
      if (nav.currentIndex == 1 && _lastNavChangeCount != nav.tabChangeCount) {
        _lastNavChangeCount = nav.tabChangeCount;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<MyReportsController>().fetchMyReports(
              forceRefresh: true,
            );
          }
        });
      } else {
        _lastNavChangeCount = nav.tabChangeCount;
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      context.read<MyReportsController>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _openDetail(ReportModel report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(
          reportId: report.id,
          initialReport: report,
        ),
      ),
    ).then((_) {
      if (mounted) {
        context.read<MyReportsController>().fetchMyReports();
      }
    });
  }

  void _navigateToCreateReport() {
    try {
      final nav = context.read<NavigationController?>();
      if (nav != null) {
        nav.setIndex(2);
        return;
      }
    } catch (_) {}

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateReportScreen(),
      ),
    ).then((_) {
      if (mounted) {
        context.read<MyReportsController>().fetchMyReports(forceRefresh: true);
      }
    });
  }

  List<ReportModel> _filterReports(List<ReportModel> all) {
    switch (_statusFilter) {
      case 'waiting':
        return all
            .where((r) =>
                r.handlingStatus == HandlingStatus.newReport && !r.isDraft)
            .toList();
      case 'inProgress':
        return all
            .where((r) =>
                (r.handlingStatus == HandlingStatus.inProgress ||
                    r.handlingStatus == HandlingStatus.accepted) &&
                !r.isDraft)
            .toList();
      case 'completed':
        return all
            .where((r) => r.handlingStatus == HandlingStatus.completed)
            .toList();
      case 'draft':
        return all.where((r) => r.isDraft).toList();
      case 'all':
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MyReportsController>();
    final isOnline = context.isOnline;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    final filteredReports = _filterReports(controller.reports);

    return Container(
      color: isDark ? AppColors.darkBackground : const Color(0xFFF0F2F5),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : 840),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.symmetric(
              vertical: BorderSide(color: borderColor, width: 1),
            ),
          ),
          child: Scaffold(
            drawer: isDesktop ? null : const AppDrawer(),
            appBar: AppBar(
              leading: isDesktop ? null : const DrawerMenuButton(),
              automaticallyImplyLeading: !isDesktop,
              title: const Text('Laporan Saya'),
              actions: [
                if (isDesktop && isOnline) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Buat Laporan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.button,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 36),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _navigateToCreateReport,
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Segarkan Laporan',
                  onPressed: () => controller.fetchMyReports(),
                ),
                if (isDesktop) const AppProfileBar(),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () => controller.fetchMyReports(),
              child: controller.isLoading && controller.reports.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : controller.reports.isEmpty
                  ? (!isOnline
                        ? OfflineFallbackView(
                            onRetry: () =>
                                controller.fetchMyReports(forceRefresh: true),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const EmptyState(
                                          title: 'Belum Ada Laporan',
                                          message:
                                              'Anda belum memiliki riwayat laporan fasilitas publik. Mulai laporkan masalah di sekitar Anda untuk perbaikan bersama.',
                                        ),
                                        if (isOnline) ...[
                                          const SizedBox(height: 20),
                                          ElevatedButton.icon(
                                            icon: const Icon(
                                              Icons.add_rounded,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'Buat Laporan Baru',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 12,
                                              ),
                                              shape: const RoundedRectangleBorder(
                                                borderRadius: AppRadius.button,
                                              ),
                                            ),
                                            onPressed: _navigateToCreateReport,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ))
                  : ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 24 : 16,
                        vertical: isDesktop ? 20 : 14,
                      ),
                      children: [
                        // 1. Executive Summary Metric KPI Cards
                        _buildMetricCards(controller, isDesktop),
                        const SizedBox(height: 16),

                        // 2. Status Filter Chips
                        _buildFilterChips(controller),
                        const SizedBox(height: 16),

                        // 3. Reports Grid / List
                        if (filteredReports.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 40,
                              horizontal: 20,
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.filter_list_off_rounded,
                                  size: 44,
                                  color: textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tidak ada laporan dengan status ini',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Pilih kategori filter lain atau tampilkan seluruh laporan Anda.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: () =>
                                      setState(() => _statusFilter = 'all'),
                                  child: const Text('Tampilkan Semua'),
                                ),
                              ],
                            ),
                          )
                        else if (isDesktop)
                          LayoutBuilder(
                            builder: (context, innerConstraints) {
                              final isMultiColumn =
                                  innerConstraints.maxWidth >= 700;
                              if (!isMultiColumn) {
                                return Column(
                                  children: filteredReports.map((report) {
                                    return _MyReportItem(
                                      key: ValueKey(report.id),
                                      report: report,
                                      onTap: () => _openDetail(report),
                                    );
                                  }).toList(),
                                );
                              }
                              return Wrap(
                                spacing: 14,
                                runSpacing: 14,
                                children: filteredReports.map((report) {
                                  return SizedBox(
                                    width: (innerConstraints.maxWidth - 14) / 2,
                                    child: _MyReportItem(
                                      key: ValueKey(report.id),
                                      report: report,
                                      isGridItem: true,
                                      onTap: () => _openDetail(report),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          )
                        else
                          Column(
                            children: filteredReports.map((report) {
                              return _MyReportItem(
                                key: ValueKey(report.id),
                                report: report,
                                onTap: () => _openDetail(report),
                              );
                            }).toList(),
                          ),

                        if (controller.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCards(MyReportsController controller, bool isDesktop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final successColor = isDark ? AppColors.darkSuccess : AppColors.success;
    final waitingColor =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    const inProgressColor = Color(0xFFD98205);

    final totalCount = controller.reports.length;
    final waitingCount = controller.reports
        .where((r) =>
            r.handlingStatus == HandlingStatus.newReport && !r.isDraft)
        .length;
    final inProgressCount = controller.reports
        .where((r) =>
            (r.handlingStatus == HandlingStatus.inProgress ||
                r.handlingStatus == HandlingStatus.accepted) &&
            !r.isDraft)
        .length;
    final completedCount = controller.reports
        .where((r) => r.handlingStatus == HandlingStatus.completed)
        .length;

    final cards = [
      _ReportMetricCard(
        title: 'Total Laporan',
        value: '$totalCount',
        color: primaryColor,
        icon: Icons.assignment_outlined,
        isSelected: _statusFilter == 'all',
        onTap: () => setState(() => _statusFilter = 'all'),
      ),
      _ReportMetricCard(
        title: 'Menunggu',
        value: '$waitingCount',
        color: waitingColor,
        icon: Icons.schedule_rounded,
        isSelected: _statusFilter == 'waiting',
        onTap: () => setState(() => _statusFilter = 'waiting'),
      ),
      _ReportMetricCard(
        title: 'Diproses',
        value: '$inProgressCount',
        color: inProgressColor,
        icon: Icons.engineering_outlined,
        isSelected: _statusFilter == 'inProgress',
        onTap: () => setState(() => _statusFilter = 'inProgress'),
      ),
      _ReportMetricCard(
        title: 'Selesai',
        value: '$completedCount',
        color: successColor,
        icon: Icons.check_circle_outline_rounded,
        isSelected: _statusFilter == 'completed',
        onTap: () => setState(() => _statusFilter = 'completed'),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: [
          cards[0],
          const SizedBox(width: 12),
          cards[1],
          const SizedBox(width: 12),
          cards[2],
          const SizedBox(width: 12),
          cards[3],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            cards[0],
            const SizedBox(width: 8),
            cards[1],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            cards[2],
            const SizedBox(width: 8),
            cards[3],
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChips(MyReportsController controller) {
    final totalCount = controller.reports.length;
    final waitingCount = controller.reports
        .where((r) =>
            r.handlingStatus == HandlingStatus.newReport && !r.isDraft)
        .length;
    final inProgressCount = controller.reports
        .where((r) =>
            (r.handlingStatus == HandlingStatus.inProgress ||
                r.handlingStatus == HandlingStatus.accepted) &&
            !r.isDraft)
        .length;
    final completedCount = controller.reports
        .where((r) => r.handlingStatus == HandlingStatus.completed)
        .length;
    final draftCount = controller.reports.where((r) => r.isDraft).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Semua ($totalCount)',
            isSelected: _statusFilter == 'all',
            onTap: () => setState(() => _statusFilter = 'all'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Menunggu ($waitingCount)',
            isSelected: _statusFilter == 'waiting',
            onTap: () => setState(() => _statusFilter = 'waiting'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Diproses ($inProgressCount)',
            isSelected: _statusFilter == 'inProgress',
            onTap: () => setState(() => _statusFilter = 'inProgress'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Selesai ($completedCount)',
            isSelected: _statusFilter == 'completed',
            onTap: () => setState(() => _statusFilter = 'completed'),
          ),
          if (draftCount > 0) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Draft ($draftCount)',
              isSelected: _statusFilter == 'draft',
              onTap: () => setState(() => _statusFilter = 'draft'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final textMuted = AppColors.textMutedOf(context);

    return Expanded(
      child: Material(
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(
            color: isSelected ? color : borderColor,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.card,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? color : textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primaryOf(context);
    final surfaceColor = AppColors.surfaceOf(context);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: primaryColor,
      backgroundColor: surfaceColor,
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? Colors.transparent : borderColor,
        ),
      ),
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

class _MyReportItem extends StatelessWidget {
  const _MyReportItem({
    super.key,
    required this.report,
    required this.onTap,
    this.isGridItem = false,
  });

  final ReportModel report;
  final VoidCallback onTap;
  final bool isGridItem;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.border;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderSubtle =
        isDark ? AppColors.darkBorder : AppColors.borderSubtle;
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.danger;
    final dangerSubtle =
        isDark ? AppColors.darkDangerSubtle : AppColors.dangerSubtle;
    final dangerBorder = isDark
        ? dangerColor.withValues(alpha: 0.3)
        : const Color(0xFFFECACA);

    final hasPhotos = report.photoUrls.isNotEmpty;
    final firstPhoto = hasPhotos ? report.photoUrls.first : null;

    return Container(
      margin: EdgeInsets.only(bottom: isGridItem ? 0 : 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.card,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Report Number & Category (Left) | Status & Publication Badges (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            report.reportNumber,
                            style: AppTextStyles.label.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (report.category.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkPrimarySoft
                                    : AppColors.primarySubtle,
                                borderRadius: AppRadius.pill,
                                border: Border.all(
                                  color: isDark
                                      ? primaryColor.withValues(alpha: 0.3)
                                      : const Color(0xFFBFDBFE),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                report.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HandlingStatusBadge(
                          status: report.handlingStatus,
                          createdAt: report.createdAt,
                          isDraft: report.isDraft,
                        ),
                        const SizedBox(width: 6),
                        PublicationStateBadge(
                          state: report.publicationState,
                          isDraft: report.isDraft,
                          iconOnly: true,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. Content Row: Title, Location + Optional Photo Thumbnail
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTextStyles.sectionTitleOf(context).copyWith(
                              color: textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  report.locationAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      AppTextStyles.captionOf(context).copyWith(
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (hasPhotos && firstPhoto != null) ...[
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: AppRadius.borderSm,
                        child: Stack(
                          children: [
                            AppImage(
                              imageSource: firstPhoto,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              memCacheWidth: 200,
                            ),
                            if (report.photoUrls.length > 1)
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xBF000000),
                                    borderRadius: AppRadius.pill,
                                  ),
                                  child: Text(
                                    '+${report.photoUrls.length - 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                // 3. Warning banner if soft deleted by citizen
                if (report.deletedByUser) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: dangerSubtle,
                      borderRadius: AppRadius.borderSm,
                      border: Border.all(color: dangerBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 14,
                          color: dangerColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Laporan telah Anda hapus. Menunggu proses admin.',
                            style: TextStyle(
                              fontSize: 11,
                              color: dangerColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Divider(height: 1, thickness: 1, color: borderSubtle),
                const SizedBox(height: 10),

                // 4. Footer: Date & Community Engagement + Detail CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          report.createdAt.toReportTimeLabel(),
                          style: AppTextStyles.captionOf(context),
                        ),
                        if (report.isPubliclyVisible) ...[
                          const SizedBox(width: 14),
                          Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 13,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${report.upvotesCount}',
                            style: AppTextStyles.captionOf(context),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 13,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${report.commentsCount}',
                            style: AppTextStyles.captionOf(context),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Detail',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
