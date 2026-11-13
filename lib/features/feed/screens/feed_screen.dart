import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_profile_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/offline_fallback_view.dart';
import '../../../data/models/report_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../../navigation/widgets/app_drawer.dart';
import '../../report_detail/screens/report_detail_screen.dart';
import '../controllers/feed_controller.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/report_card.dart';
import 'feed_map_screen.dart';

/// Main public community feed matching DESIGN.md Section 5.3
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
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
            final auth = context.read<AuthController>();
            context.read<FeedController>().fetchFeed(
              auth.currentUser?.id,
              true,
            );
          }
        });
      } else if (!isOnline) {
        _wasOffline = true;
      }
    } catch (_) {}

    try {
      final nav = context.watch<NavigationController>();
      if (nav.currentIndex == 0 && _lastNavChangeCount != nav.tabChangeCount) {
        _lastNavChangeCount = nav.tabChangeCount;
        if (_scrollController.hasClients && _scrollController.offset > 0) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final auth = context.read<AuthController>();
            context.read<FeedController>().fetchFeed(
              auth.currentUser?.id,
              true,
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
    if (!context.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Dukungan atau tanggapan tidak dapat diberikan saat offline.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
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
    final isOnline = context.isOnline;
    final auth = context.watch<AuthController>();
    final currentUserId = auth.currentUser?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    if (auth.currentUser?.id != null &&
        controller.currentUserId != auth.currentUser?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchFeed(auth.currentUser!.id, false);
      });
    }

    return Scaffold(
      drawer: isDesktop ? null : const AppDrawer(),
      appBar: AppBar(
        leading: isDesktop ? null : const DrawerMenuButton(),
        automaticallyImplyLeading: !isDesktop,
        titleSpacing: isDesktop ? 16 : 0,
        title: Text(
          'Laporin',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Peta Sebaran Laporan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FeedMapScreen(
                    initialReports: controller.reports,
                    initialUserLocation: controller.userLocation ??
                        LocationService.instance.lastKnownLatLng,
                    initialProvinceId: controller.selectedProvinceId,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Laporan',
            onPressed: () => controller.fetchFeed(currentUserId),
          ),
          if (isDesktop) const AppProfileBar(),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 760 : double.infinity,
          ),
          child: Column(
            children: [
              // Search & Sort bar
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final borderColor =
                  isDark ? AppColors.darkBorder : AppColors.border;
              final primaryColor =
                  isDark ? AppColors.darkPrimary : AppColors.primary;
              final surfaceColor =
                  isDark ? AppColors.darkSurface : AppColors.surface;
              final elevatedColor = isDark
                  ? AppColors.darkSurfaceRecessed
                  : AppColors.surface;
              final textColor =
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
              final hintColor = isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cari laporan atau lokasi...',
                          hintStyle:
                              TextStyle(color: hintColor, fontSize: 14),
                          fillColor: elevatedColor,
                          filled: true,
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: hintColor,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.pill,
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadius.pill,
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadius.pill,
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (val) => controller.setSearchQuery(val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PopupMenuButton<String>(
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.input,
                      ),
                      color: surfaceColor,
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: AppRadius.input,
                          border: Border.all(color: borderColor),
                        ),
                        child: Icon(
                          Icons.sort_rounded,
                          size: 20,
                          color: textColor,
                        ),
                      ),
                      tooltip: 'Urutkan',
                      initialValue: controller.sortBy,
                      onSelected: (val) => controller.setSortBy(val),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'newest',
                          child: Text(
                            'Terbaru',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'popular',
                          child: Text(
                            'Terpopuler',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Scope Menu: "Semua" vs "{Provinsi Terdeteksi}"
          _buildScopeSelectorMenu(context, controller),

          // Categories Filter
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: CategoryFilterBar(
              selectedCategory: controller.selectedCategory,
              onCategorySelected: (cat) => controller.setCategory(cat),
            ),
          ),

          // Linear progress bar saat background refresh sedang berjalan
          if (controller.isRefreshing)
            const LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

          // List or Loading / Empty States
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.fetchFeed(),
              child: controller.isLoading && controller.reports.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : controller.reports.isEmpty
                  ? (!isOnline
                        ? OfflineFallbackView(
                            onRetry: () =>
                                controller.fetchFeed(currentUserId, true),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) =>
                                SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Center(
                                      child: EmptyState(
                                        title: 'Belum Ada Laporan',
                                        message:
                                            controller.selectedCategory ==
                                                    'Semua' &&
                                                (controller.searchQuery.isEmpty)
                                            ? 'Saat ini belum ada data laporan fasilitas publik yang terdaftar di database.'
                                            : 'Belum ada laporan publik yang cocok dengan kriteria filter ini.',
                                        actionLabel:
                                            controller.selectedCategory !=
                                                    'Semua' ||
                                                controller
                                                    .searchQuery
                                                    .isNotEmpty
                                            ? 'Reset Filter'
                                            : null,
                                        onAction: () {
                                          controller.setCategory('Semua');
                                          controller.setSearchQuery('');
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                          ))
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
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
    ),
  ),
);
  }

  Widget _buildScopeSelectorMenu(
    BuildContext context,
    FeedController controller,
  ) {
    final isNational = controller.isNational;
    final isDetectedActive = controller.isDetectedProvinceActive;
    final detectedName = controller.detectedProvinceName;
    final isDetecting = controller.isDetectingLocation;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Menu Option 1: "Semua"
            _buildScopePill(
              icon: Icons.public,
              label: 'Semua',
              isSelected: isNational,
              onTap: () => controller.switchToAll(),
            ),
            const SizedBox(width: 8),

            // Menu Option 2: "{Wilayah Terdeteksi}"
            _buildScopePill(
              icon: isDetecting && detectedName == null
                  ? Icons.location_searching_rounded
                  : Icons.my_location_rounded,
              label:
                  detectedName ??
                  (isDetecting ? 'Mendeteksi...' : 'Lokasi Terdeteksi'),
              isSelected: isDetectedActive,
              onTap: () async {
                final success = await controller.switchToDetectedProvince();
                if (!success &&
                    context.mounted &&
                    controller.detectedProvinceName == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tidak dapat mendeteksi lokasi. Pastikan izin lokasi dan GPS aktif.',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopePill({
    IconData? icon,
    Widget? leadingWidget,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final activeColor =
            isDark ? AppColors.darkPrimary : AppColors.primary;
        final inactiveBg =
            isDark ? AppColors.darkSurface : AppColors.surface;
        final inactiveBorder =
            isDark ? AppColors.darkBorder : AppColors.border;
        final inactiveText =
            isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
        final inactiveIcon =
            isDark ? AppColors.darkPrimaryLight : AppColors.primary;

        return InkWell(
          borderRadius: AppRadius.pill,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? activeColor : inactiveBg,
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: isSelected ? activeColor : inactiveBorder,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingWidget != null) ...[
                  leadingWidget,
                  const SizedBox(width: 6),
                ] else if (icon != null) ...[
                  Icon(
                    icon,
                    size: 15,
                    color: isSelected ? Colors.white : inactiveIcon,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : inactiveText,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
