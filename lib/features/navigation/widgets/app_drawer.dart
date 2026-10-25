import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../announcements/controllers/announcement_controller.dart';
import '../../announcements/screens/announcements_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../controllers/navigation_controller.dart';

/// App Drawer navigasi utama aplikasi Laporin
/// Berisi menu wajib per permintaan:
/// 1. Beranda
/// 2. Laporan
/// 3. Pengumuman (dengan badge jika ada pengumuman baru)
/// 4. Notifikasi
/// 5. Profil
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigateToTab(BuildContext context, int tabIndex) {
    final nav = Navigator.of(context);
    nav.pop(); // Tutup drawer

    // Jika pengguna sedang berada di rute push di atas navigasi utama, pop ke root terlebih dahulu
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }

    if (tabIndex == 0) {
      try {
        final auth = context.read<AuthController>();
        context.read<FeedController>().fetchFeed(auth.currentUser?.id, true);
      } catch (_) {}
    }

    try {
      context.read<NavigationController>().setIndex(tabIndex);
    } catch (_) {}
  }

  void _navigateToAnnouncements(BuildContext context) {
    // Segera tandai sebagai sudah dibaca saat menu Pengumuman diklik sehingga badge langsung hilang
    try {
      context.read<AnnouncementController>().markAllAsRead();
    } catch (_) {}

    Navigator.of(context).pop(); // Tutup drawer

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AnnouncementsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final nav = context.watch<NavigationController>();
    final currentTab = nav.currentIndex;

    final unreadAnnouncements = context
        .watch<AnnouncementController>()
        .unreadCount;
    final unreadNotifications = context
        .watch<NotificationController>()
        .unreadCount;

    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header Drawer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryStrong],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.shieldHalved,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Laporin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (auth.isAuthenticated && user != null) ...[
                    Row(
                      children: [
                        UserAvatar(
                          name: user.fullName,
                          username: user.username,
                          avatarUrl: user.avatarUrl,
                          radius: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (auth.isAdmin) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'ADMIN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.username.trim().isNotEmpty
                                    ? '@${user.username.trim().replaceFirst('@', '')}'
                                    : user.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'Selamat Datang di Laporin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Layanan aspirasi dan pengaduan warga resmi.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Daftar Menu Navigasi Utama: Adaptif terhadap peran Admin vs Warga
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                children: [
                  if (auth.isAdmin) ...[
                    // MENU KHUSUS ADMIN (4 Tab Sesuai AdminNavigationScreen)
                    // 1. Beranda
                    _DrawerMenuItem(
                      icon: FontAwesomeIcons.house,
                      title: 'Beranda',
                      isSelected: currentTab == 0,
                      onTap: () => _navigateToTab(context, 0),
                    ),

                    // 2. Panel Laporan
                    _DrawerMenuItem(
                      icon: FontAwesomeIcons.tableColumns,
                      title: 'Panel Laporan',
                      isSelected: currentTab == 1,
                      onTap: () => _navigateToTab(context, 1),
                    ),

                    // 3. Pengumuman Resmi (Tab 2 Admin)
                    _DrawerMenuItem(
                      icon: FontAwesomeIcons.bullhorn,
                      title: 'Pengumuman',
                      badgeCount: 0,
                      badgeColor: AppColors.danger,
                      isSelected: currentTab == 2,
                      onTap: () => _navigateToTab(context, 2),
                    ),

                    // 4. Profil Petugas (Tab 3 Admin)
                    _DrawerMenuItem(
                      icon: FontAwesomeIcons.user,
                      title: 'Profil',
                      isSelected: currentTab == 3,
                      onTap: () => _navigateToTab(context, 3),
                    ),
                  ] else ...[
                    // MENU REGULER WARGA / CITIZEN (5 Menu)
                    // 1. Beranda
                    _DrawerMenuItem(
                      icon: FontAwesomeIcons.house,
                      title: 'Beranda',
                      isSelected: currentTab == 0,
                      onTap: () => _navigateToTab(context, 0),
                    ),

                    // 2. Laporan
                    _DrawerMenuItem(
                      icon: FontAwesomeIcons.clipboardList,
                      title: 'Laporan',
                      isSelected: currentTab == 1,
                      onTap: () => _navigateToTab(context, 1),
                    ),

                    // 3. Pengumuman (Dengan badge jika ada pengumuman baru)
                    _DrawerMenuItem(
                      icon: FontAwesomeIcons.bullhorn,
                      title: 'Pengumuman',
                      badgeCount: unreadAnnouncements,
                      badgeColor: AppColors.danger,
                      isSelected: false,
                      onTap: () => _navigateToAnnouncements(context),
                    ),

                    // 4. Notifikasi
                    _DrawerMenuItem(
                      icon: FontAwesomeIcons.bell,
                      title: 'Notifikasi',
                      badgeCount: unreadNotifications,
                      badgeColor: AppColors.primary,
                      isSelected: currentTab == 3,
                      onTap: () => _navigateToTab(context, 3),
                    ),

                    // 5. Profil
                    _DrawerMenuItem(
                      icon: FontAwesomeIcons.user,
                      title: 'Profil',
                      isSelected: currentTab == 4,
                      onTap: () => _navigateToTab(context, 4),
                    ),
                  ],
                ],
              ),
            ),

            // Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Laporin v1.0.0 • Jawa Tengah',
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (auth.isAdmin) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryStrong,
                        ),
                      ),
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
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    this.badgeCount = 0,
    this.badgeColor = AppColors.danger,
    required this.onTap,
  });

  final FaIconData icon;
  final String title;
  final bool isSelected;
  final int badgeCount;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeBg = isSelected ? AppColors.primarySoft : Colors.transparent;
    final iconColor = isSelected ? AppColors.primary : AppColors.textSecondary;
    final textColor = isSelected
        ? AppColors.primaryStrong
        : AppColors.textPrimary;
    final textWeight = isSelected ? FontWeight.w700 : FontWeight.w500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: activeBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                FaIcon(icon, size: 18, color: iconColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: textWeight,
                      color: textColor,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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

/// Hamburger menu button with notification badge for unread announcements
class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    int unreadAnnouncements = 0;
    // Admin TIDAK mendapatkan badge icon saat ada pengumuman baru
    if (!auth.isAdmin) {
      try {
        unreadAnnouncements = context
            .watch<AnnouncementController>()
            .unreadCount;
      } catch (_) {}
    }

    return IconButton(
      tooltip: 'Menu Utama',
      icon: Badge(
        isLabelVisible: unreadAnnouncements > 0,
        backgroundColor: AppColors.danger,
        label: Text(
          '$unreadAnnouncements',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        child: Icon(Icons.menu_rounded, color: color),
      ),
      onPressed: () {
        Scaffold.of(context).openDrawer();
      },
    );
  }
}
