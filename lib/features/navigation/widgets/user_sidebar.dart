import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../announcements/controllers/announcement_controller.dart';
import '../../announcements/screens/announcements_screen.dart';
import '../../notifications/controllers/notification_controller.dart';

/// Sidebar navigasi desktop untuk pengguna warga (Citizen)
class UserSidebar extends StatelessWidget {
  const UserSidebar({
    super.key,
    required this.activeIndex,
    required this.onTabTapped,
  });

  final int activeIndex;
  final ValueChanged<int> onTabTapped;

  static const double width = 260.0;

  void _navigateToAnnouncements(BuildContext context) {
    try {
      context.read<AnnouncementController>().markAllAsRead();
    } catch (_) {}
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final isOnline = context.isOnline;

    final unreadNotif = context.watch<NotificationController>().unreadCount;
    final unreadAnnouncements =
        context.watch<AnnouncementController>().unreadCount;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          right: BorderSide(color: borderColor, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header & Brand Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo_laporin.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.campaign_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Laporin',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkPrimarySubtle
                                  : AppColors.primarySubtle,
                              borderRadius: AppRadius.pill,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkPrimary.withValues(alpha: 0.3)
                                    : AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              'WARGA',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Portal Pengaduan',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Tombol Utama "+ Buat Laporan"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Buat Laporan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOnline
                    ? primaryColor
                    : (isDark ? AppColors.darkDisabled : AppColors.disabled),
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
                elevation: 0,
                minimumSize: const Size.fromHeight(42),
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: isOnline ? () => onTabTapped(2) : null,
            ),
          ),

          Divider(height: 1, thickness: 1, color: borderSubtle),

          // 3. Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'MENU UTAMA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // 4. Navigation Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                _UserSidebarItem(
                  icon: FontAwesomeIcons.house,
                  label: 'Beranda',
                  isSelected: activeIndex == 0,
                  onTap: () => onTabTapped(0),
                ),
                const SizedBox(height: 4),
                _UserSidebarItem(
                  icon: FontAwesomeIcons.clipboardList,
                  label: 'Laporan Saya',
                  isSelected: activeIndex == 1,
                  onTap: () => onTabTapped(1),
                ),
                const SizedBox(height: 4),
                _UserSidebarItem(
                  icon: FontAwesomeIcons.bell,
                  label: 'Notifikasi',
                  badgeCount: unreadNotif,
                  badgeColor: AppColors.primary,
                  isSelected: activeIndex == 3,
                  onTap: () => onTabTapped(3),
                ),
                const SizedBox(height: 4),
                _UserSidebarItem(
                  icon: FontAwesomeIcons.bullhorn,
                  label: 'Pengumuman',
                  badgeCount: unreadAnnouncements,
                  badgeColor: AppColors.danger,
                  isSelected: false,
                  onTap: () => _navigateToAnnouncements(context),
                ),
                const SizedBox(height: 4),
                _UserSidebarItem(
                  icon: FontAwesomeIcons.user,
                  label: 'Profil',
                  isSelected: activeIndex == 4,
                  onTap: () => onTabTapped(4),
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

class _UserSidebarItem extends StatelessWidget {
  const _UserSidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
    this.badgeColor = AppColors.danger,
  });

  final FaIconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final bgColor = isSelected
        ? (isDark
            ? AppColors.darkPrimarySubtle
            : AppColors.primarySubtle)
        : Colors.transparent;

    final itemColor = isSelected ? primaryColor : textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isDark
                      ? AppColors.darkPrimary.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.25))
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Center(
                  child: FaIcon(
                    icon,
                    size: 16,
                    color: itemColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: itemColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
