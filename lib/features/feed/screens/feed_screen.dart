import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/boundary_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/report_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../navigation/widgets/app_drawer.dart';
import '../../report_detail/screens/report_detail_screen.dart';
import '../controllers/feed_controller.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/report_card.dart';

/// Main public community feed matching DESIGN.md Section 5.3
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
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
            _scrollController.position.maxScrollExtent - 250) {
      context.read<FeedController>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleVote(BuildContext context, ReportModel report, String voteType) {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (!auth.isAuthenticated || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan masuk terlebih dahulu untuk memberikan dukungan atau tanggapan.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }
    context.read<FeedController>().vote(report.id, user.id, voteType);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FeedController>();
    final auth = context.watch<AuthController>();
    final currentUserId = auth.currentUser?.id;

    if (auth.currentUser?.id != null &&
        controller.currentUserId != auth.currentUser?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchFeed(auth.currentUser!.id, false);
      });
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const DrawerMenuButton(),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 16, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    BoundaryService.provinceName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryStrong,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Laporan',
            onPressed: () => controller.fetchFeed(currentUserId),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Sort bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari laporan atau lokasi...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (val) => controller.setSearchQuery(val),
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.sort_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  tooltip: 'Urutkan',
                  initialValue: controller.sortBy,
                  onSelected: (val) => controller.setSortBy(val),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'newest',
                      child: Text('Terbaru'),
                    ),
                    const PopupMenuItem(
                      value: 'popular',
                      child: Text('Terpopuler'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Categories Filter
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: CategoryFilterBar(
              selectedCategory: controller.selectedCategory,
              onCategorySelected: (cat) => controller.setCategory(cat),
            ),
          ),

          // List or Loading / Empty States
          Expanded(
            child: controller.isLoading && controller.reports.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : controller.reports.isEmpty
                ? EmptyState(
                    title: 'Belum Ada Laporan',
                    message:
                        controller.selectedCategory == 'Semua' &&
                            (controller.searchQuery.isEmpty)
                        ? 'Saat ini belum ada data laporan fasilitas publik yang terdaftar di database.'
                        : 'Belum ada laporan publik yang cocok dengan kriteria filter ini.',
                    actionLabel:
                        controller.selectedCategory != 'Semua' ||
                            controller.searchQuery.isNotEmpty
                        ? 'Reset Filter'
                        : null,
                    onAction: () {
                      controller.setCategory('Semua');
                      controller.setSearchQuery('');
                    },
                  )
                : RefreshIndicator(
                    onRefresh: () => controller.fetchFeed(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 24, top: 4),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          );
                        }
                        final report = controller.reports[index];
                        return ReportCard(
                          report: report,
                          onTap: () async {
                            final auth = context.read<AuthController>();
                            if (auth.isAdmin) {
                              controller.markReportAsViewedByAdmin(report.id);
                            }
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportDetailScreen(
                                  reportId: report.id,
                                  initialReport: report,
                                ),
                              ),
                            );
                            if (auth.isAdmin) {
                              controller.markReportAsViewedByAdmin(report.id);
                            }
                            if (result is ReportModel) {
                              controller.syncReport(result);
                            } else if (result == true) {
                              controller.fetchFeed(currentUserId, false);
                            } else {
                              final cached = controller.reportRepository
                                  .getCachedReport(
                                    report.id,
                                    userId: currentUserId,
                                  );
                              if (cached != null) {
                                controller.syncReport(cached);
                              }
                            }
                          },
                          onUpvote: () => _handleVote(context, report, 'up'),
                          onDownvote: () =>
                              _handleVote(context, report, 'down'),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
