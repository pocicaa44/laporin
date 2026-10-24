import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../report_detail/screens/report_detail_screen.dart';
import '../controllers/my_reports_controller.dart';

/// Screen displaying user's own reports per DESIGN.md Section 5.6
class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final userId = auth.currentUser?.id ?? '';

    if (!auth.isAuthenticated || userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Laporan Saya')),
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MyReportsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.fetchMyReports(),
          ),
        ],
      ),
      body: controller.isLoading && controller.reports.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : controller.reports.isEmpty
          ? const EmptyState(
              title: 'Belum Ada Laporan',
              message: 'Anda belum memiliki riwayat laporan fasilitas publik.',
            )
          : RefreshIndicator(
              onRefresh: () => controller.fetchMyReports(),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount:
                    controller.reports.length +
                    (controller.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == controller.reports.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }
                  final report = controller.reports[index];
                  return _MyReportItem(
                    report: report,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportDetailScreen(
                            reportId: report.id,
                            initialReport: report,
                          ),
                        ),
                      ).then((_) => controller.fetchMyReports());
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _MyReportItem extends StatelessWidget {
  const _MyReportItem({required this.report, required this.onTap});

  final ReportModel report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                      color: AppColors.primary,
                    ),
                  ),
                  HandlingStatusBadge(status: report.handlingStatus),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 6),
              Text(
                report.locationAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PublicationStateBadge(state: report.publicationState),
                  Text(
                    report.createdAt.toRelativeTime(),
                    style: AppTextStyles.caption,
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
