import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/boundary_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../report_detail/screens/report_detail_screen.dart';
import '../controllers/feed_controller.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/report_card.dart';

/// Main public community feed matching DESIGN.md Section 5.3
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FeedController>();
    final auth = context.watch<AuthController>();
    final currentUserId = auth.currentUser?.id ?? 'guest-usr';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
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
            onPressed: () => controller.fetchFeed(),
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
            child: controller.isLoading
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
                      padding: const EdgeInsets.only(bottom: 24, top: 4),
                      itemCount: controller.reports.length,
                      itemBuilder: (context, index) {
                        final report = controller.reports[index];
                        return ReportCard(
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
                            ).then((_) => controller.fetchFeed());
                          },
                          onUpvote: () =>
                              controller.vote(report.id, currentUserId, 'up'),
                          onDownvote: () =>
                              controller.vote(report.id, currentUserId, 'down'),
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
