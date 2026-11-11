import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/offline_fallback_view.dart';
import '../../../data/models/announcement_model.dart';
import '../../../data/repositories/announcement_repository.dart';
import '../../admin/controllers/admin_announcement_controller.dart';
import '../../admin/screens/admin_edit_announcement_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/announcement_controller.dart';

/// Halaman daftar pengumuman resmi dari petugas / admin untuk warga pengguna
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _selectedCategory = 'Semua';

  final List<String> _categories = const [
    'Semua',
    'Umum',
    'Infrastruktur',
    'Layanan Publik',
    'Keamanan',
    'Darurat',
  ];

  AnnouncementController? _announcementController;
  bool _wasOffline = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _announcementController = context.read<AnnouncementController>();
      final isOnline = context.isOnline;
      if (_wasOffline && isOnline) {
        _wasOffline = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _announcementController?.fetchAnnouncements(forceRefresh: true);
          }
        });
      } else if (!isOnline) {
        _wasOffline = true;
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    // Saat halaman pengumuman dibuka, set viewing dan tandai semua pengumuman sebagai sudah dibaca (badge hilang) serta auto-refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final controller = context.read<AnnouncementController>();
          controller.setViewingAnnouncements(true);
          controller.markAllAsRead();
          controller.fetchAnnouncements(forceRefresh: true);
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _announcementController?.setViewingAnnouncements(false);
    super.dispose();
  }

  Future<void> _handleAdminEdit(AnnouncementModel announcement) async {
    final adminCtrl = AdminAnnouncementController(
      repository: context.read<AnnouncementRepository>(),
    );
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminEditAnnouncementScreen(
          announcement: announcement,
          controller: adminCtrl,
        ),
      ),
    );
    if (updated == true && mounted) {
      context.read<AnnouncementController>().fetchAnnouncements(
        forceRefresh: true,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengumuman berhasil diperbarui.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showAnnouncementDetail(AnnouncementModel announcement) {
    final isAdmin = context.read<AuthController>().isAdmin;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final contentBg =
        isDark ? AppColors.darkSurfaceElevated : AppColors.background;
    final categoryBg =
        isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft;
    final categoryFg =
        isDark ? AppColors.darkPrimaryLight : AppColors.primaryStrong;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          maxWidth: 720,
        ),
        margin: const EdgeInsets.only(top: 48),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: AppRadius.sheet,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryBg,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      announcement.category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: categoryFg,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),

            // Content body
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    announcement.title,
                    style: AppTextStyles.pageTitleOf(context).copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        announcement.authorName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(color: textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        announcement.createdAt.toDisplayDateTime(),
                        style: AppTextStyles.captionOf(context),
                      ),
                    ],
                  ),
                  if (announcement.imageUrl != null &&
                      announcement.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    AppImage(
                      imageSource: announcement.imageUrl!,
                      height: 220,
                      width: double.infinity,
                      borderRadius: AppRadius.card,
                      fit: BoxFit.cover,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: contentBg,
                      borderRadius: AppRadius.card,
                      border: Border.all(color: borderColor),
                    ),
                    child: SelectableText(
                      announcement.content,
                      style: AppTextStyles.bodyOf(context).copyWith(height: 1.6),
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.button,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit Pengumuman'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleAdminEdit(announcement);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isOnline = context.isOnline;
    final isAdmin = auth.isAdmin;
    final controller = context.watch<AnnouncementController>();
    if (controller.unreadCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            context.read<AnnouncementController>().markAllAsRead();
          } catch (_) {}
        }
      });
    }
    final allAnnouncements = controller.announcements;

    final filteredList = _selectedCategory == 'Semua'
        ? allAnnouncements
        : allAnnouncements
              .where((a) => a.category == _selectedCategory)
              .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Pengumuman Resmi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Pengumuman',
            onPressed: () => controller.fetchAnnouncements(forceRefresh: true),
          ),
        ],
      ),
      body: Container(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF0F2F5),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.symmetric(
                vertical: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () =>
                  controller.fetchAnnouncements(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                children: [
                  // Info Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft,
                      borderRadius: AppRadius.card,
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.bullhorn,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pemberitahuan & Siaran Resmi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkPrimary : AppColors.primaryStrong,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Informasi resmi dari pemerintah dan petugas daerah untuk seluruh warga.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = cat == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            showCheckmark: false,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategory = cat);
                              }
                            },
                            selectedColor: primaryColor,
                            backgroundColor: surfaceColor,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.pill,
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : (isDark ? AppColors.darkBorder : AppColors.border),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Announcements list
                  if (controller.isLoading && allAnnouncements.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (filteredList.isEmpty)
                    (!isOnline
                        ? OfflineFallbackView(
                            onRetry: () => controller.fetchAnnouncements(
                              forceRefresh: true,
                            ),
                          )
                        : EmptyState(
                            icon: Icons.campaign_outlined,
                            title: 'Belum Ada Pengumuman',
                            message: _selectedCategory == 'Semua'
                                ? 'Belum ada pengumuman resmi yang diterbitkan saat ini.'
                                : 'Tidak ada pengumuman dalam kategori "$_selectedCategory".',
                          ))
                  else
                    ...filteredList.map((announcement) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AnnouncementCard(
                          announcement: announcement,
                          isAdmin: isAdmin,
                          onTap: () => _showAnnouncementDetail(announcement),
                          onEdit: () => _handleAdminEdit(announcement),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.onTap,
    this.isAdmin = false,
    this.onEdit,
  });

  final AnnouncementModel announcement;
  final VoidCallback onTap;
  final bool isAdmin;
  final VoidCallback? onEdit;

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'darurat':
        return AppColors.danger;
      case 'keamanan':
        return const Color(0xFFE65100);
      case 'infrastruktur':
        return const Color(0xFF00897B);
      case 'layanan publik':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = _getCategoryColor(announcement.category);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.border;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.card,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppRadius.card,
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Date Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    announcement.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: catColor,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  announcement.createdAt.toRelativeTime(),
                  style: AppTextStyles.captionOf(context),
                ),
                if (isAdmin && onEdit != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onEdit,
                    borderRadius: AppRadius.pill,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft,
                        borderRadius: AppRadius.pill,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 12,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              announcement.title,
              style: AppTextStyles.sectionTitleOf(context).copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Content snippet
            Text(
              announcement.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyOf(context).copyWith(
                color: isDark ? AppColors.darkTextBody : const Color(0xFF4A5568),
                height: 1.45,
              ),
            ),
            if (announcement.imageUrl != null &&
                announcement.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              AppImage(
                imageSource: announcement.imageUrl!,
                height: 150,
                width: double.infinity,
                borderRadius: AppRadius.button,
                fit: BoxFit.cover,
              ),
            ],
            const SizedBox(height: 12),

            // Footer: Author & Read more indicator
            Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 15,
                  color: primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  announcement.authorName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Baca Selengkapnya',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
