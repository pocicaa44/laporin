import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/app_profile_bar.dart';
import '../../../core/widgets/offline_fallback_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/controllers/auth_controller.dart';
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
          message: 'Silakan masuk ke akun Anda untuk melihat daftar laporan yang pernah Anda buat.',
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MyReportsController>();
    final isOnline = context.isOnline;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final isDesktop = MediaQuery.sizeOf(context).width > 800;

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
                                child: const Center(
                                  child: EmptyState(
                                    title: 'Belum Ada Laporan',
                                    message:
                                        'Anda belum memiliki riwayat laporan fasilitas publik.',
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
                        vertical: isDesktop ? 20 : 12,
                      ),
                      children: [
                        LayoutBuilder(
                          builder: (context, innerConstraints) {
                            final isMultiColumn =
                                isDesktop && innerConstraints.maxWidth >= 700;
                            if (!isMultiColumn) {
                              return Column(
                                children: controller.reports.map((report) {
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
                              children: controller.reports.map((report) {
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

    return Container(
      margin: EdgeInsets.only(bottom: isGridItem ? 0 : 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    report.reportNumber,
                    style: AppTextStyles.label.copyWith(
                      color: primaryColor,
                    ),
                  ),
                  HandlingStatusBadge(
                    status: report.handlingStatus,
                    createdAt: report.createdAt,
                    isDraft: report.isDraft,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitleOf(context),
              ),
              const SizedBox(height: 6),
              Text(
                report.locationAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionOf(context),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PublicationStateBadge(
                    state: report.publicationState,
                    isDraft: report.isDraft,
                  ),
                  Text(
                    report.createdAt.toReportTimeLabel(),
                    style: AppTextStyles.captionOf(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
